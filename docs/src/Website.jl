module Website

using BonitoSites
using BonitoSites.Bonito
using Markdown
using BonitoSites.Bonito: Link
# Asset helpers
function asset_path(files...)
    return normpath(joinpath(@__DIR__, "assets", files...))
end

img_asset(files...) = Asset(asset_path("images", files...))
css_asset(files...) = Asset(asset_path("css", files...))

# Include components
include("components.jl")
include("index.jl")
include("examples.jl")

export index, examples, add_example_routes!

end
