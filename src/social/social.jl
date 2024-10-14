using ImageBase
using ImageIO
using FileIO

function load_resized(image_path, size=1_000_000)
    fm = FileIO.DataFormat{FileIO.querysym(image_path)}
    image_data = read(image_path)
    while sizeof(image_data) > size
        img = load(Stream{fm}(IOBuffer(image_data)))
        img = restrict(img)
        io = IOBuffer()
        save(Stream{fm}(io), img)
        image_data = take!(io)
    end
    return image_data
end

include("bluesky.jl")
include("mastodon.jl")
include("discord.jl")
