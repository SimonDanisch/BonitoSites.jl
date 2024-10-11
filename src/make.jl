


function make(f, page_folder, destination)
    routes = Routes()
    for project in readdir(page_folder; join=true)
        if isdir(project)
            name = dirname(project)
            routes["blogposts/"*name] = f(project)
        end
    end
    routes["/"] = f(markdown("..", "index.md"))
    Bonito.export_static(destination, routes)
end
