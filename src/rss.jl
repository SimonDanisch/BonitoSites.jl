using XML
using Dates
using XML: h

struct SiteEntry
    title::String
    link::String
    description::String
    date::DateTime
    image::String
end

function Bonito.jsrender(s::Session, se::SiteEntry)
    human_date = Dates.format(se.date, "e, d u Y H:M:S")
    # Bonito.Link is already relative to current site
    link = replace(se.link, "./" => "/")
    card = Bonito.Card(DOM.div(
        DOM.a(DOM.h3(se.title), href=Bonito.Link(link)),
        DOM.h4(se.description),
        DOM.div(human_date);
    ))
    return Bonito.jsrender(s, card)
end

function from_xml(filename::AbstractString)
    doc = read(filename, Node)
    items = doc.children[1].children
    title = items[1].children[1].value
    link = items[2].children[1].value
    description = items[3].children[1].value

    date = parse(DateTime, items[4].children[1].value, DateFormat("e, d u Y H:M:S"))
    return SiteEntry(title, link, description, date, "")
end

function write_xml(path, entry)
    xml = to_xml(entry)
    open(path, "w") do file
        print(file, XML.write(xml))
    end
end

function to_xml(se::SiteEntry, relative_path="")
    item_element = h.item()
    push!(item_element, h.title(se.title))
    link = se.link
    push!(item_element, h.link(link))
    push!(item_element, h.description(se.description))
    date = Dates.format(se.date, "e, d u Y H:M:S")
    push!(item_element, h.pubDate(date))
    if !isempty(se.image)
        image_link = replace(se.image, "./" => relative_path)
        push!(item_element, h.image(h.url(image_link)))
    end
    return item_element
end


function generate_rss_feed(
        items::Vector{SiteEntry}, rss_path::String;
        title::String,
        link::String,
        description::String,
        relative_path::String = ""
    )
    # Create the RSS and Channel elements
    rss = h.rss(version="2.0")
    channel = h.channel()

    # Add Channel metadata

    push!(channel, h.title(title))
    push!(channel, h.link(link))
    push!(channel, h.description(description))

    # Add each blog post item
    for item in items
        item_element = to_xml(item, relative_path)
        push!(channel, item_element)
    end

    # Add the channel to the RSS feed
    push!(rss, channel)

    # Write the RSS feed to a file
    open(rss_path, "w") do file
        print(file, "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n")
        print(file, XML.write(rss))
    end
end
