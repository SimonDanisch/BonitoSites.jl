# UI components for the documentation site

"""
Load CSS asset from docs/assets
"""
function css_asset(file)
    path = normpath(joinpath(@__DIR__, "..", "assets", file))
    return DOM.link(rel="stylesheet", href=Bonito.Asset(path))
end

"""
Global theme styles with CSS variables for light/dark mode
"""
function theme_styles()
    # Light theme (default)
    light_theme = CSS(
        "@media (prefers-color-scheme: light), (prefers-color-scheme: no-preference)",
        CSS(":root",
            "--bg-primary" => "#f9fafb",
            "--bg-secondary" => "#ffffff",
            "--bg-nav" => "#111827",
            "--bg-code" => "#1f2937",
            "--text-primary" => "#111827",
            "--text-secondary" => "#6B7280",
            "--text-nav" => "#9CA3AF",
            "--text-nav-hover" => "#ffffff",
            "--border-color" => "#e5e7eb",
            "--border-nav" => "#1f2937",
            "--border-code" => "#374151",
            "--link-color" => "#60A5FA",
            "--link-hover" => "#93C5FD"
        )
    )

    # Dark theme
    dark_theme = CSS(
        "@media (prefers-color-scheme: dark)",
        CSS(":root",
            "--bg-primary" => "#0f172a",
            "--bg-secondary" => "#1e293b",
            "--bg-nav" => "#020617",
            "--bg-code" => "#1e293b",
            "--text-primary" => "#f1f5f9",
            "--text-secondary" => "#94a3b8",
            "--text-nav" => "#94a3b8",
            "--text-nav-hover" => "#f1f5f9",
            "--border-color" => "#334155",
            "--border-nav" => "#1e293b",
            "--border-code" => "#475569",
            "--link-color" => "#60A5FA",
            "--link-hover" => "#93C5FD"
        )
    )

    return Styles(light_theme, dark_theme)
end

"""
Create a styled navigation bar for the site
"""
function navbar()
    nav_style = Styles(
        "background-color" => "var(--bg-nav)",
        "padding" => "1.25rem 3rem",
        "display" => "flex",
        "justify-content" => "space-between",
        "align-items" => "center",
        "border-bottom" => "1px solid var(--border-nav)"
    )

    logo_style = Styles(
        "color" => "var(--text-nav-hover)",
        "font-size" => "1.5rem",
        "font-weight" => "700",
        "text-decoration" => "none",
        "letter-spacing" => "-0.025em"
    )

    links_style = Styles(
        "display" => "flex",
        "gap" => "2.5rem",
        "align-items" => "center"
    )

    link_style = Styles(
        CSS("color" => "var(--text-nav)", "text-decoration" => "none", "font-weight" => "500", "transition" => "color 0.2s"),
        CSS(":hover", "color" => "var(--text-nav-hover)")
    )

    # Mobile responsive navbar
    mobile_nav_styles = Styles(
        CSS("@media (max-width: 768px)",
            CSS("nav",
                "padding" => "1rem !important",
                "flex-direction" => "column",
                "gap" => "1rem",
                "align-items" => "flex-start !important"
            ),
            CSS("nav > div",
                "gap" => "1.5rem !important"
            )
        )
    )

    return DOM.nav(
        DOM.style(mobile_nav_styles),
        DOM.a("BonitoSites", href=Link("/"), style=logo_style),
        DOM.div(
            DOM.a("Home", href=Link("/"), style=link_style),
            DOM.a("Examples", href=Link("/examples"), style=link_style),
            DOM.a("GitHub", href="https://github.com/SimonDanisch/BonitoSites.jl",
                  target="_blank", style=link_style),
            style=links_style
        ),
        style=nav_style
    )
end

"""
Create a styled section container
"""
function section(title, content; id="")
    section_style = Styles(
        "margin" => "4rem 0",
        "padding" => "0"
    )

    title_style = Styles(
        "color" => "var(--text-primary)",
        "font-size" => "2.25rem",
        "font-weight" => "700",
        "margin-bottom" => "2rem",
        "letter-spacing" => "-0.025em"
    )

    return DOM.section(
        DOM.h2(title, style=title_style),
        content,
        style=section_style,
        id=id
    )
end

"""
Create a code block with syntax highlighting
Note: BonitoSites.HighlightCode() must be included on the page for highlighting to work
"""
function code_block(code::String; language="julia")
    pre_style = Styles(
        "border-radius" => "12px",
        "padding" => "0",
        "overflow-x" => "auto",
        "margin" => "1.5rem 0",
        "background-color" => "var(--bg-code)",
        "border" => "1px solid var(--border-code)"
    )

    code_style = Styles(
        "font-family" => "'Fira Code', 'Monaco', 'Courier New', monospace",
        "font-size" => "0.875rem",
        "line-height" => "1.7",
        "padding" => "1.5rem",
        "color" => "var(--text-primary)"
    )

    return DOM.pre(
        DOM.code(code, class="language-$language", style=code_style),
        style=pre_style
    )
end

"""
Create a feature card
"""
function feature_card(title, description)
    card_style = Styles(
        "padding" => "1.5rem",
        "background-color" => "var(--bg-secondary)",
        "border-radius" => "12px",
        "border" => "1px solid var(--border-color)",
        "transition" => "all 0.3s ease",
        "display" => "flex",
        "flex-direction" => "column"
    )

    title_style = Styles(
        "color" => "var(--text-primary)",
        "margin" => "0 0 0.75rem 0",
        "font-size" => "1.25rem",
        "font-weight" => "600"
    )

    desc_style = Styles(
        "color" => "var(--text-secondary)",
        "line-height" => "1.7",
        "font-size" => "0.938rem",
        "margin" => "0"
    )

    return DOM.div(
        DOM.h3(title, style=title_style),
        DOM.p(description, style=desc_style),
        style=card_style
    )
end

"""
Create main content container with centered layout
"""
function page_container(content)
    # Mobile-responsive container
    container_style = Styles(
        "max-width" => "1280px",
        "margin" => "0 auto",
        "padding" => "3rem 2rem",
        "min-height" => "100vh"
    )

    # Global styles for html and body elements
    global_styles = Styles(
        CSS("html, body",
            "margin" => "0",
            "padding" => "0",
            "background-color" => "var(--bg-primary)",
            "color" => "var(--text-primary)",
            "font-family" => "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif"
        ),
        # Mobile responsive container
        CSS("@media (max-width: 768px)",
            CSS(".page-container",
                "padding" => "1rem 1rem !important"
            )
        )
    )

    return DOM.div(
        DOM.style(theme_styles()),  # Inject theme CSS variables
        DOM.style(global_styles),   # Inject global styles
        navbar(),
        DOM.div(content, style=container_style, class="page-container")
    )
end

"""
Create a footer
"""
function footer()
    footer_style = Styles(
        "background-color" => "var(--bg-nav)",
        "color" => "var(--text-nav)",
        "padding" => "3rem 2rem",
        "text-align" => "center",
        "margin-top" => "6rem",
        "border-top" => "1px solid var(--border-nav)"
    )

    text_style = Styles(
        "margin" => "0.5rem 0",
        "font-size" => "0.875rem"
    )

    link_style = Styles(
        CSS("color" => "var(--link-color)", "text-decoration" => "none", "transition" => "color 0.2s"),
        CSS(":hover", "color" => "var(--link-hover)")
    )

    return DOM.footer(
        DOM.p("BonitoSites.jl - Static site generation for Bonito applications", style=text_style),
        DOM.p(
            "Built with ",
            DOM.a("Bonito.jl", href="https://github.com/SimonDanisch/Bonito.jl",
                  target="_blank", style=link_style),
            style=text_style
        ),
        style=footer_style
    )
end
