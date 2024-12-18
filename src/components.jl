using Bonito

struct HighlightCode
end

assetpath(files...) = Bonito.Asset(normpath(joinpath(@__DIR__, "assets", files...)))

function Bonito.jsrender(session::Session, ::HighlightCode)
    path = assetpath("highlight", "highlight.pack.js")
    css = assetpath("highlight", "github.min.css")
    return Bonito.jsrender(session, DOM.div(
        css,
        DOM.script(src=path),
        DOM.script("hljs.highlightAll()")
    ))
end
