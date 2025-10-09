# Getting Started with BonitoSites

Welcome to BonitoSites! This example post demonstrates how to create content for your static site using Markdown.

## What is BonitoSites?

BonitoSites is a Julia package that makes it easy to:

- Generate static websites from Bonito applications
- Deploy to GitHub Pages automatically
- Create blogs with RSS feeds
- Execute code safely using Malt

## Creating Your First Site

Here's a simple example to get started:

```julia
using Bonito
using BonitoSites

# Create your app
app = App() do
    DOM.div(
        DOM.h1("Hello, World!"),
        DOM.p("My first static site")
    )
end

# Export it
routes = Routes("/" => app)
Bonito.export_static("build", routes)
```

## Next Steps

1. Explore the [examples](/examples) page
2. Check out the [GitHub repository](https://github.com/SimonDanisch/BonitoSites.jl)
3. Build something amazing!

---

*Published on September 30, 2025*