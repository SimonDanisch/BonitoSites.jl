# Examples page for BonitoSites documentation

function examples(session::Session)
    # Load content from markdown file
    markdown_content = BonitoSites.MarkdownPage(joinpath(@__DIR__, "examples.md"))
    content = DOM.div(
        css_asset("markdown-mobile.css"),
        DOM.div(markdown_content, class="markdown-body"),
        footer(),
    )
    return page_container(content)
end


"""
Add individual example routes (placeholder for future expansion)
"""
function add_example_routes!(routes)
    # Future: Add individual example pages as separate routes
    # For now, all examples are on one page
    return routes
end
