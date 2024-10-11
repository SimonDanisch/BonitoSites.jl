
function deployparameters(; repo, push_preview, devbranch, devurl)
    cfg = Documenter.GitHubActions()
    deploy_decision = Documenter.deploy_folder(cfg; repo, push_preview, devbranch, devurl)
    (;
        all_ok=deploy_decision.all_ok,
        branch=deploy_decision.branch,
        repo=deploy_decision.repo,
        subfolder=deploy_decision.subfolder,
        is_preview=deploy_decision.is_preview,
        config=cfg,
    )
end

function _deploy(params; root=Documenter.currentdir(), target)
    if !params.all_ok
        @warn "Deploy decision status not all ok. Not deploying."
        return
    end

    deploy_branch = params.branch
    deploy_repo = params.repo

    # Change to the root directory and try to deploy the docs.
    cd(root) do
        sha = readchomp(`$(Documenter.git()) rev-parse --short HEAD`)

        @debug "pushing new documentation to remote: '$deploy_repo:$deploy_branch'."
        mktempdir() do temp
            push_build(;
                root,
                temp,
                target,
                params.repo,
                params.branch,
                params.subfolder,
                params.is_preview,
                sha,
                params.config,
            )
        end
    end
end

function push_build(;
        root, temp, repo,
        branch="gh-pages", dirname="", target="site", sha="",
        config, subfolder,
        is_preview::Bool
    )
    dirname = isempty(dirname) ? temp : joinpath(temp, dirname)
    isdir(dirname) || mkpath(dirname)

    target_dir = abspath(target)

    git = Documenter.git

    NO_KEY_ENV = Dict(
        "DOCUMENTER_KEY" => nothing,
        "DOCUMENTER_KEY_PREVIEWS" => nothing,
    )

    # Generate a closure with common commands for ssh and https
    function git_commands(sshconfig=nothing)
        # Setup git.
        run(`$(git()) init`)
        run(`$(git()) config user.name "Documenter.jl"`)
        run(`$(git()) config user.email "documenter@juliadocs.github.io"`)
        if sshconfig !== nothing
            run(`$(git()) config core.sshCommand "ssh -F $(sshconfig)"`)
        end

        # Fetch from remote and checkout the branch.
        run(`$(git()) remote add upstream $upstream`)
        try
            run(`$(git()) fetch upstream`)
        catch e
            @error """
            Git failed to fetch $upstream
            This can be caused by a DOCUMENTER_KEY variable that is not correctly set up.
            Make sure that the environment variable is properly set up as a Base64-encoded string
            of the SSH private key. You may need to re-generate the keys with DocumenterTools.
            """
            rethrow(e)
        end

        try
            run(`$(git()) checkout -b $branch upstream/$branch`)
        catch e
            @info """
            Checking out $branch failed, creating a new orphaned branch.
            This usually happens when deploying to a repository for the first time and
            the $branch branch does not exist yet. The fatal error above is expected output
            from Git in this situation.
            """
            @debug "checking out $branch failed with error: $e"
            run(`$(git()) checkout --orphan $branch`)
            run(`$(git()) commit --allow-empty -m "Initial empty commit for docs"`)
        end

        # Copy docs to `subfolder` directory.
        deploy_dir = subfolder === nothing ? dirname : joinpath(dirname, subfolder)
        Documenter.gitrm_copy(target_dir, deploy_dir)
        # Add, commit, and push the docs to the remote.
        run(`$(git()) add -A .`)
        if !success(`$(git()) diff --cached --exit-code`)
            run(`$(git()) commit -m "build based on $sha"`)
            run(`$(git()) push -q upstream HEAD:$branch`)
        else
            @debug "new docs identical to the old -- not committing nor pushing."
        end
    end

    # upstream is used by the closures above, kind of hard to track
    upstream = Documenter.authenticated_repo_url(config)
    try
        cd(() -> withenv(git_commands, NO_KEY_ENV...), temp)
        Documenter.post_status(config; repo=repo, type="success", subfolder=subfolder)
    catch e
        @error "Failed to push:" exception = (e, catch_backtrace())
        Documenter.post_status(config; repo=repo, type="error")
        rethrow(e)
    end
end

function make(f, page_folder, destination)
    routes = Routes()
    folders = filter(isdir, readdir(page_folder; join=true))
    entries = map(folders) do dir
        dir = normpath(dir)
        path = joinpath(dir, "post.xml")
        return dir => BonitoSites.from_xml(path)
    end
    sort!(entries; by=x -> x[2].date, rev=true)
    for (dir, entry) in entries
        page = BonitoSites.MarkdownPage(dir)
        routes[entry.link] = f(page)
    end
    routes["/"] = f(Bonito.Col(map(x -> x[2], entries)...))
    Bonito.export_static(destination, routes)
end

function deploy(repo; target="build", devbranch="main", devurl="website", push_preview=true)
    params = deployparameters(; repo, devbranch, devurl, push_preview)
    _deploy(params; target=target)
end
