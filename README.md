# BonitoSites.jl

![CI](https://github.com/SimonDanisch/BonitoSites.jl/workflows/CI/badge.svg)
[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://simondanisch.github.io/BonitoSites.jl/)

**Static site generation and deployment toolkit for Bonito applications.**

## Features

- **GitHub Pages Deployment**: One-command deployment with preview support for PRs
- **Markdown Blogging**: Create blogs from Markdown files with automatic RSS feeds ([example: Makie blog](https://makie.org/website/blog))
- **Executable Documentation**: Run Julia code in markdown files using isolated Malt processes with automatic caching
- **Rich Components**: Code highlighting, video embedding, and social media integration

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/SimonDanisch/BonitoSites.jl")
```

## Quick Start

```julia
using Bonito, BonitoSites

# Create and export your site
app = App() do
    DOM.div(DOM.h1("Welcome"), DOM.p("My site content"))
end

routes = Routes("/" => app)
Bonito.export_static("build", routes)

# Deploy to GitHub Pages (requires DOCUMENTER_KEY secret)
BonitoSites.deploy(
    "github.com/yourusername/yourrepo.git";
    push_preview=true,
    devbranch="main",
    devurl="docs"
)
```

## Markdown Blog Example

Blog posts are organized in folders, each containing `post.md` and `post.xml`:

```
blogposts/
├── my-first-post/
│   ├── post.xml      # Metadata
│   ├── post.md       # Content
│   └── images/       # Optional assets
└── another-post/
    ├── post.xml
    └── post.md
```

**post.xml** contains metadata:
```xml
<item>
  <title>My Post Title</title>
  <link>./blogposts/my-first-post</link>
  <description>A short description</description>
  <pubDate>Mon, 30 Sep 2025 12:00:00</pubDate>
  <image><url>./images/preview.png</url></image>
</item>
```

**Generate the blog and RSS feed:**
```julia
# Load all posts
function all_posts()
    folders = filter(isdir, readdir("blogposts"; join=true))
    entries = map(folders) do dir
        xml_path = joinpath(dir, "post.xml")
        dir => BonitoSites.from_xml(xml_path)
    end
    return sort!(entries; by=x -> x[2].date, rev=true)
end

# Create routes for each post
function add_posts!(routes)
    for (dir, entry) in all_posts()
        route = replace(entry.link, "./" => "/")
        routes[route] = App(title=entry.title) do
            BonitoSites.MarkdownPage(dir)  # Renders post.md
        end
    end
end

# Create blog index
routes = Routes()
add_posts!(routes)
routes["/blog"] = App() do
    # The Post typed renders a preview of the blogpost
    DOM.div(last.(all_posts()))
end

# Export and generate RSS
Bonito.export_static("build", routes)
BonitoSites.generate_rss_feed(
    last.(all_posts()),
    "build/rss.xml";
    title="My Blog",
    link="https://example.com",
    description="My Julia blog"
)
```

## Documentation

Visit the [documentation site](https://simondanisch.github.io/BonitoSites.jl/) for detailed guides and examples.

## Examples

- [BonitoBook Documentation](https://bonitobook.org/)
- [Makie Blog](https://makie.org/website/blog)

## Related Projects

- [Bonito.jl](https://github.com/SimonDanisch/Bonito.jl) - Web framework
- [BonitoBook.jl](https://github.com/SimonDanisch/BonitoBook.jl) - Notebook environment
- [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) - Deployment backend
