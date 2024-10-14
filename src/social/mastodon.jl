module Mastodon

using HTTP
using JSON3
using Bonito

function upload_media(file_path::String; token::String=ENV["MASTODON_TOKEN"])
    url = "https://mastodon.social/api/v2/media"
    headers = [
        "Authorization" => "Bearer $token"
    ]
    mime_type = Bonito.HttpServer.file_mimetype(file_path)
    file = HTTP.Multipart(basename(file_path), open(file_path, "r"), mime_type)

    # Post the media to Mastodon
    form = HTTP.Form(Dict("file" => file))

    response = HTTP.post(url, headers, form)

    if response.status == 200
        response_data = JSON3.read(String(response.body))
        media_id = response_data["id"]
        println("Media uploaded successfully with ID: $media_id")
        return media_id
    else
        println("Failed to upload media. Status code: ", response.status)
        println("Response: ", String(response.body))
        return nothing
    end
end

function post(
        status::String, image_path::Union{String, Nothing}=nothing;
        token::String=ENV["MASTODON_TOKEN"]
    )
    media_ids = String[]
    # Upload the image if the path is provided
    if !isnothing(image_path)
        media_id = upload_media(image_path; token=token)
        if media_id !== nothing
            push!(media_ids, media_id)
        else
            println("Image upload failed, posting text-only status.")
        end
    end

    url = "https://mastodon.social/api/v1/statuses"
    headers = [
        "Authorization" => "Bearer $token",
        "Content-Type" => "application/json"
    ]
    body_data = Dict{String, Any}("status" => status)
    if !isempty(media_ids)
        body_data["media_ids"] = media_ids
    end
    body = JSON3.write(body_data)

    response = HTTP.post(url, headers, body)

    if response.status == 200
        println("Message posted successfully!")
    else
        println("Failed to post message. Status code: ", response.status)
        println("Response: ", String(response.body))
    end
end

end
