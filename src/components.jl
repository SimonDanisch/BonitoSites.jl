using Bonito

struct HighlightCode
end

asset(files...) = Bonito.Asset(normpath(joinpath(@__DIR__, "assets", files...)))

function Bonito.jsrender(session::Session, ::HighlightCode)
    path = asset("highlight", "highlight.pack.js")
    css = asset("highlight", "github.min.css")
    return Bonito.jsrender(session, DOM.div(
        css,
        DOM.script(src=path),
        DOM.script("hljs.highlightAll()")
    ))
end

function BlueSkyComment(post_url)
    js = DOM.script(src=asset("bluesky.js"))
    container = DOM.div(
        id="comments",
        dataUri=post_url,
        style="width: 600px;",
    )
    return DOM.div(container, js)
end

function Video(url)
    return DOM.video(DOM.source(src=url, type="video/mp4"), autoplay=true, controls=true)
end
