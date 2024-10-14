module BlueSky

using HTTP
using JSON3
using Dates
using Bonito
using ..BonitoSites: load_resized

struct BlueSession
    id::String
    token::String
end

const CURRENT_SESSION = Ref{Union{Nothing,BlueSession}}(nothing)

function get_session()
    if isnothing(CURRENT_SESSION[])
        id_pw = ENV["BLUESKY_TOKEN"]
        id, pw = split(id_pw, ";")
        token = get_session(string(id), string(pw))
        CURRENT_SESSION[] = BlueSession(id, token)
    end
    return CURRENT_SESSION[]
end

# Function to create a session and obtain an access token from Bluesky
function get_session(identifier::String, password::String)
    url = "https://bsky.social/xrpc/com.atproto.server.createSession"
    headers = [
        "Content-Type" => "application/json"
    ]

    # Prepare the body data
    body_data = Dict(
        "identifier" => identifier,
        "password" => password
    )

    # Send the POST request
    body = JSON3.write(body_data)
    response = HTTP.post(url, headers, body)

    if response.status == 200
        response_data = JSON3.read(String(response.body))
        return response_data["accessJwt"]  # Get the access token
    else
        println("Failed to create session. Status code: ", response.status)
        println("Response: ", String(response.body))
        return nothing
    end
end

# Function to upload an image and get the blob reference
function upload_image(image_path::String; session::BlueSession=get_session())
    url = "https://bsky.social/xrpc/com.atproto.repo.uploadBlob"
    mime = Bonito.HTTPServer.file_mimetype(image_path)
    headers = [
        "Authorization" => "Bearer $(session.token)",
        "Content-Type" => mime  # Set to appropriate MIME type
    ]

    # Read the image data
    image_data = load_resized(image_path, 1_000_000)

    # Send the POST request to upload the image
    response = HTTP.post(url, headers, image_data)
    if response.status == 200
        response_data = JSON3.read(String(response.body))
        return response_data.blob
    else
        @warn("Failed to upload image. Status code: ", response.status)
        @warn("Response: ", String(response.body))
        return nothing
    end
end

# Function to post a status with optional image embeds
function post_to_bluesky(status::String, image_paths::Vector{String}=[];
        session::BlueSession=get_session(),
        languages = ["en-US"],
        date = Dates.now()
    )
    url = "https://bsky.social/xrpc/com.atproto.repo.createRecord"
    headers = [
        "Authorization" => "Bearer $(session.token)",
        "Content-Type" => "application/json"
    ]

    post = Dict(
        "text" => status,
        "langs" => languages,
        "createdAt" => Dates.format(date, "yyyy-mm-ddTHH:MM:SS.ssssssZ")  # Current timestamp in ISO 8601 format
    )

    images = []
    for path in image_paths
        blob = upload_image(path; session=session)
        if !isnothing(blob)
            push!(images, Dict(
                "alt" => "$(basename(path))",
                "image" => blob
            ))
        end
    end
    # Create the embed structure
    if !isempty(images)
        post["embed"] = Dict(
            "\$type" => "app.bsky.embed.images",
            "images" => images
        )
    end

    # Prepare the body data for the post
    body_data = Dict{String, Any}(
        "repo" => session.id,  # Replace with your actual repo name
        "\$type" => "app.bsky.feed.post",
        "record" => post,
        "collection" => "app.bsky.feed.post",
    )

    # Send the post request
    body = JSON3.write(body_data)
    response = HTTP.post(url, headers, body)

    if response.status == 200
        println("Status posted successfully on Bluesky!")
    else
        println("Failed to post status on Bluesky. Status code: ", response.status)
        println("Response: ", String(response.body))
    end
end

end
