title = "BonitoSites Documentation"
link = "https://github.com/SimonDanisch/BonitoSites.jl"
description = "Static site generation and deployment for Bonito applications"

# Load packages
using BonitoSites
using BonitoSites.Bonito
using Markdown

# Include our website module
include("src/Website.jl")
using .Website

function create_routes()
    routes = Routes(
        "/" => App(Website.index, title="BonitoSites"),
        "/examples" => App(Website.examples, title="Examples"),
    )
    # Add individual example pages
    Website.add_example_routes!(routes)
    return routes
end

# Build static site
dir = joinpath(@__DIR__, "build")
!isdir(dir) && mkdir(dir)
Bonito.export_static(dir, create_routes())

# Serve locally with FolderServer
if get(ENV, "SERVE_DOCS", "false") == "true"
    server = Bonito.Server("127.0.0.1", 8239)
    route!(server, r".*" => Bonito.FolderServer(dir))
    @info "Serving docs at http://127.0.0.1:8239"
end

# Deploy to GitHub Pages (self-hosting the docs)
if get(ENV, "DEPLOY_DOCS", "false") == "true"
    BonitoSites.deploy(
        "github.com/SimonDanisch/BonitoSites.jl.git";
        push_preview=true,
        devbranch="main",
        devurl="docs"
    )
end
