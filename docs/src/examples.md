# Examples

Explore common use cases and patterns for BonitoSites.

## Static Site Generation

Generate a static site from Bonito applications:

```julia
# no-eval
using Bonito
using BonitoSites

# Create your pages
home = App() do
    DOM.div(
        DOM.h1("Welcome"),
        DOM.p("My static site")
    )
end

about = App() do
    DOM.div(
        DOM.h1("About"),
        DOM.p("About this site")
    )
end

# Setup routes
routes = Routes(
    "/" => home,
    "/about" => about
)

# Export to static files
Bonito.export_static("build", routes)
```

## Markdown Blog

Create a blog from Markdown files:

```julia
# no-eval
using BonitoSites

# Load all blog posts from folders
function all_posts()
    folders = filter(isdir, readdir("blogposts"; join=true))
    entries = map(folders) do dir
        xml_path = joinpath(dir, "post.xml")
        dir => BonitoSites.from_xml(xml_path)
    end
    return sort!(entries; by=x -> x[2].date, rev=true)
end

# Create routes for each individual post
function add_posts!(routes)
    for (dir, entry) in all_posts()
        route = replace(entry.link, "./" => "/")
        routes[route] = App(title=entry.title) do
            BonitoSites.MarkdownPage(dir)  # Renders post.md
        end
    end
end

# Create blog index showing all posts
routes = Routes()
add_posts!(routes)
routes["/blog"] = App() do
    entries = last.(all_posts())
    # SiteEntry has a jsrender method that renders it as a card
    DOM.div(DOM.h1("My Blog"), entries...)
end
```

## RSS Feed Generation

Generate an RSS feed from blog entries:

```julia
# no-eval
using BonitoSites

# Create RSS from blog posts
feed = BonitoSites.generate_rss_feed(
    all_posts();
    feed_url="https://example.com/feed.xml",
    site_url="https://example.com",
    title="My Blog",
    description="A blog about Julia"
)

# Write to file
open("build/feed.xml", "w") do io
    write(io, feed)
end
```

## Executable Documentation with Malt

`MarkdownPage` can automatically execute Julia code blocks in your markdown files when it detects a `Project.toml` file in the same directory. This allows you to create tutorials and documentation with code execution in it's own project.

**How it works:**

1. Create a folder for your tutorial (e.g., `my-tutorial/`)
2. Add a `Project.toml` file listing the required packages
3. Write your markdown in `post.md` with Julia code blocks
4. Use `MarkdownPage("my-tutorial")` to render it

When a `Project.toml` is present, BonitoSites uses `MaltRunner` to:
- Execute code blocks in an isolated Julia process
- Cache results for fast rebuilds
- Ensure reproducibility with pinned dependencies

This is perfect for creating interactive documentation, tutorials with working examples, or blog posts that demonstrate package functionality. The code executes during the build step, and the output is embedded in the static site.
This is what actually gets used for the Makie [blog](https://github.com/MakieOrg/Website/tree/main/src/blogposts)
