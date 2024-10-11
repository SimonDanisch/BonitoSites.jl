module BonitoSites

using Bonito
using Bonito: Asset, ES6Module, AssetFolder, Routes
using GitHub
using Malt
using Documenter

include("malt-runner.jl")
include("gh-utils.jl")
include("rss.jl")
include("ai-utils.jl")
include("deploy.jl")
include("components.jl")

end