# Homepage content for BonitoSites documentation

function index(session::Session)
    # Hero section
    hero_title_style = Styles(
        "font-size" => "3.5rem",
        "font-weight" => "800",
        "color" => "var(--text-primary)",
        "margin-bottom" => "1.5rem",
        "line-height" => "1.1",
        "letter-spacing" => "-0.025em"
    )

    hero_desc_style = Styles(
        "font-size" => "1.25rem",
        "line-height" => "1.8",
        "color" => "var(--text-secondary)",
        "max-width" => "800px",
        "margin" => "0 auto"
    )

    hero_section_style = Styles(
        "text-align" => "center",
        "padding" => "4rem 0 6rem 0"
    )

    hero = DOM.div(
        DOM.h1("Build & Deploy Static Sites with Julia", style=hero_title_style),
        DOM.p(
            "BonitoSites is a powerful toolkit for creating and deploying static websites " *
            "built with Bonito.jl. Generate documentation sites, blogs, and web content " *
            "with built-in deployment to GitHub Pages.",
            style=hero_desc_style
        ),
        style=hero_section_style
    )

    # Key features
    features = section("Key Features", Grid(
        feature_card(
            "Easy Deployment",
            "Deploy your Bonito applications to GitHub Pages with a single function call. " *
            "Automatic handling of branch management and push operations."
        ),
        feature_card(
            "Markdown Blog Support",
            "Create blogs from Markdown files with automatic RSS feed generation. " *
            "Perfect for documentation sites and technical blogs."
        ),
        feature_card(
            "Malt-Based Processing",
            "Run code in isolated Julia processes using Malt.jl for safe and reproducible " *
            "content generation."
        ),
        feature_card(
            "Rich Components",
            "Built-in components for code highlighting, video embedding, and social media integration."
        ),
        feature_card(
            "RSS Feed Generation",
            "Automatically generate RSS feeds from your site entries for easy content syndication."
        ),
        feature_card(
            "GitHub Integration",
            "Some helper functions to extract infos from Github and render them inside Bonito."
        ),
        columns="repeat(auto-fit, minmax(350px, 1fr))",
        gap="2rem"
    ))

    # Quick start
    quick_start_code = """
using Bonito
using BonitoSites

# Create a simple app
app = App() do
    DOM.div(
        DOM.h1("Hello, World!"),
        DOM.p("My first Bonito site")
    )
end

# Create routes
routes = Routes("/" => app)

# Export as static site
Bonito.export_static("build", routes)

# Deploy to GitHub Pages
BonitoSites.deploy(
    "github.com/yourusername/yourrepo.git";
    push_preview=true,
    devbranch="main",
    devurl="docs"
)"""

    quick_start = section("Quick Start", DOM.div(
        DOM.p("Get started with BonitoSites in just a few lines of code:"),
        code_block(quick_start_code)
    ))

    # Installation
    install_code = """
using Pkg
Pkg.add(url="https://github.com/SimonDanisch/BonitoSites.jl")"""

    installation = section("Installation", DOM.div(
        DOM.p("Install BonitoSites directly from GitHub:"),
        code_block(install_code)
    ))

    # Use cases
    use_cases = section("Use Cases", DOM.div(
        DOM.ul(
            DOM.li(DOM.strong("Documentation Sites: "), "Generate beautiful documentation " *
                   "from Bonito applications with automatic deployment."),
            DOM.li(DOM.strong("Technical Blogs: "), "Create markdown-based blogs with " *
                   "RSS feeds and code execution."),
            DOM.li(DOM.strong("Project Showcases: "), "Build interactive demonstrations " *
                   "of your Julia projects."),
            DOM.li(DOM.strong("Static Web Apps: "), "Deploy any Bonito application as a " *
                   "static website."),
            style=Styles("line-height" => "2", "font-size" => "1.05rem")
        )
    ))

    # Link style for next steps
    link_style = Styles("color" => "var(--link-color)")

    # Next steps
    next_steps = section("Next Steps", DOM.div(
        DOM.p("Explore more:"),
        DOM.ul(
            DOM.li(DOM.a("View Examples", href=Link("/examples"), style=link_style)),
            DOM.li(DOM.a("GitHub Repository",
                        href="https://github.com/SimonDanisch/BonitoSites.jl",
                        target="_blank", style=link_style)),
            DOM.li(DOM.a("Bonito.jl Documentation",
                        href="https://simondanisch.github.io/Bonito.jl/stable/",
                        target="_blank", style=link_style)),
            style=Styles("line-height" => "2", "font-size" => "1.05rem")
        )
    ))

    content = DOM.div(
        hero,
        features,
        installation,
        quick_start,
        use_cases,
        next_steps,
        footer(),
        BonitoSites.HighlightCode()  # Enable code highlighting
    )

    return page_container(content)
end
