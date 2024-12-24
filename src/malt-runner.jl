
const PROJ_WORKER = Dict{String,Malt.Worker}()
using Downloads

function rewrite_img(session, current_folder, img)
    imgurl = img.url
    if isfile(img.url)
        imgurl = Bonito.url(session, Bonito.Asset(img.url))
    elseif startswith(img.url, "http")
        file_mime = Bonito.file_mimetype(img.url)
        io = IOBuffer()
        Downloads.download(img.url, io)
        asset = Bonito.BinaryAsset(take!(io), file_mime)
        imgurl = Bonito.url(session, asset)
    elseif startswith(img.url, "./")
        fileurl = img.url[3:end]
        file = Bonito.to_unix_path(joinpath(current_folder, fileurl))
        if isfile(file)
            imgurl = Bonito.url(session, Bonito.Asset(file))
        end
    end
    return return Markdown.Image(imgurl, img.alt)
end

function parse_markdown_with_env(julia_project)
    @assert isdir(julia_project)
    @assert isfile(joinpath(julia_project, "Project.toml"))

    runner = MaltRunner(julia_project)
    file = only(filter(x -> endswith(x, ".md"), readdir(julia_project)))
    source = read(joinpath(julia_project, file), String)
    replacements = Dict(
        Markdown.Image => (img) -> rewrite_img(runner.current_session[], julia_project, img)
    )
    return Bonito.EvalMarkdown(source; runner=runner, replacements=replacements)
end

function parse_markdown_file(mdfile)
    m = Module()
    source = read(mdfile, String)
    runner = Bonito.ModuleRunner(m)
    folder = dirname(mdfile)
    replacements = Dict(
        Markdown.Image => (img) -> rewrite_img(runner.current_session[], folder, img)
    )
    return Bonito.EvalMarkdown(source; runner=runner, replacements=replacements)
end

function MarkdownPage(folder_or_md)
    if isfile(joinpath(folder_or_md, "Project.toml"))
        @assert isdir(folder_or_md)
        @assert isfile(joinpath(folder_or_md, "Project.toml")) "Not a project: $folder_or_md"
        md = parse_markdown_with_env(folder_or_md)
    else
        file = if isfile(folder_or_md)
            folder_or_md
        else
            only(filter(x -> endswith(x, ".md"), readdir(folder_or_md; join=true)))
        end
        md = parse_markdown_file(file)
    end
    return DOM.div(md, BonitoSites.HighlightCode())
end

function create_worker_for_proj(project)
    w = get!(PROJ_WORKER, project) do
        return Malt.Worker(exeflags="--project=$(project)")
    end
    try
        fetch(Malt.remote_eval(w, :(using Pkg; Pkg.instantiate())))
    catch e
        @warn "error in new worker" exception=e
        delete!(PROJ_WORKER, project)
        return create_worker_for_proj(project)
    end
    return w
end

mutable struct MaltRunner <: Bonito.RunnerLike
    project::String
    output_path::String
    overwrite::Bool
    counter::Int
    worker::Union{Nothing,Malt.Worker}
    current_session::Ref{Union{Session,Nothing}}
end

function MaltRunner(project; overwrite=false)
    output_path = joinpath(project, "output")
    isdir(output_path) || mkpath(output_path)
    return MaltRunner(
        project,
        output_path,
        overwrite,
        0,
        nothing,
        Ref{Union{Session,Nothing}}(nothing)
    )
end

function Base.eval(mr::MaltRunner, expr::Expr)

    output_path = mr.output_path
    overwrite = mr.overwrite
    mr.counter += 1
    path = joinpath(output_path, "cell_output_$(mr.counter)")
    extensions = [".png", ".html", ".txt", ".asset", ".nothing"]
    idx = findfirst(x -> isfile(path * x), extensions)
    output_file = ""
    if !overwrite && !isnothing(idx)
        output_file = path * extensions[idx]
    else
        @info("Overwrite $(overwrite), needing to eval file: $(path)")
        paths = nothing
        if !isnothing(mr.current_session[])
            server = mr.current_session[].asset_server
            if server isa Bonito.AssetFolder
                paths = (server.folder, server.current_dir)
            end
        end

        eval_expr = quote

            path = $(path)
            old_pwd = pwd()
            cd($(dirname(mr.output_path)))
            result = try
                result = $(expr)
            finally
                cd(old_pwd)
            end
            if isnothing(result)
                write(path * ".nothing", "nothing")
                return path * ".nothing"
            elseif @isdefined(Makie) && result isa Makie.FigureLike
                Makie.save(path * ".png", result)
                return path * ".png"
            elseif @isdefined(Bonito) && result isa Bonito.Asset
                assetpath = Bonito.get_path(result)
                rest, ext = splitext(assetpath)
                cp(assetpath, path * ext)
                return path * ext
            else
                is_html = showable(MIME"text/html"(), result)
                mime = is_html ? MIME"text/html"() : MIME"text/plain"()
                ext = is_html ? ".html" : ".txt"
                open(path * ext, "w") do io
                    paths = $(paths)
                    asset_server = isnothing(paths) ? Bonito.NoServer() : Bonito.AssetFolder(paths...)
                    show(io, mime, Bonito.jsrender(Session(; asset_server=asset_server), result))
                end
                return path * ext
            end
        end
        worker = create_worker_for_proj(mr.project)
        try
            output_file = fetch(Malt.remote_eval(worker, eval_expr))
        catch e
            @show expr
            rethrow(e)
        end
    end
    if endswith(output_file, ".txt")
        return read(output_file, String)
    elseif endswith(output_file, ".nothing")
        return
    elseif endswith(output_file, ".asset")
        return Bonito.Asset(read(output_file, String))
    else
        return Bonito.Asset(output_file)
    end
end
