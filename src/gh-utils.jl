const GH_AUTH = Ref{Any}(nothing)

function get_auth()
    if isnothing(GH_AUTH[])
        GH_AUTH[] = GitHub.authenticate(ENV["GITHUB_TOKEN"])
    end
    return GH_AUTH[]
end

function gh_compare(args...; kw...)
    GitHub.compare(args...; kw..., auth=get_auth())
end

function gh_comments(args...; kw...)
    GitHub.comments(args...; kw..., auth=get_auth())
end

function get_pr(repo, commit)
    msg = commit.commit.message
    m = match(r"\(#(\d+)\)", msg)
    isnothing(m) && return nothing
    pr = parse(Int, m[1])
    return pull_request(repo, pr; auth=get_auth())
end

function get_tag_info(tag::GitHub.Tag)
    str = sprint() do io
        Downloads.download(tag.object["url"], io)
    end
    dict = JSON.parse(str)
    parts = splitpath(tag.url.path) # why is this not straight-forward?
    repo = GitHub.Repo(parts[3] * "/" * parts[4])
    return (
        commit = dict["object"]["sha"],
        name = dict["tag"],
        repo = repo,
        message = dict["message"],
    )
end

function commits_between(tag1, tag2; repo="MakieOrg/Makie.jl")
    t1 = GitHub.tag(repo, tag1)
    t2 = GitHub.tag(repo, tag2)
    t1info = get_tag_info(t1)
    t2info = get_tag_info(t2)
    params = Dict("per_page" => 100)
    commits, _ = GitHub.commits(repo; auth=get_auth(), params)

    idx1 = findfirst(x-> x.sha == t1info.commit, commits)
    idx2 = findfirst(x-> x.sha == t2info.commit, commits)

    return commits[min(idx1, idx2):max(idx1, idx2)]
end

function Bonito.jsrender(owner::GitHub.Owner)
    name = DOM.span(string(owner.login), style="margin: 2px; color: 'gray")
    img = DOM.img(src=owner.avatar_url, style="border-radius: 50%", width=22)
    img_name = DOM.div(img, name; style="display: flex; align-items: center")
    return DOM.span(
        DOM.a(img_name, href=owner.html_url; style="color: gray; text-decoration: none");
        style="padding: 2px")
end


const GITHUB_OWNERS = Dict{String, GitHub.Owner}()
function gh_owner(name)
    get!(GITHUB_OWNERS, name) do
        GitHub.owner(name)
    end
end

function gh_by(names...)
    by = DOM.span("By: ", style="margin: 2px; font-weight: 500")
    DOM.div(by, map(gh_owner, names)...; style="display: flex; align-items: center")
end
