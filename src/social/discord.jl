module Discord

using HTTP
using JSON3
using ..BonitoSites: load_resized
using Bonito

# Function to post a message to a Discord channel via Webhook
function post(message::String, image_path::String=""; webhook_url::String=ENV["DISCORD_HOOK"])
    msg_json = JSON3.write(Dict("content" => message))
    if isempty(image_path)
        response = HTTP.post(webhook_url, ["Content-Type" => "application/json"], msg_json)
    else
        # If image is provided, send as a multipart form
        bytes = load_resized(image_path, 1_000_000)
        mime_type = Bonito.HTTPServer.file_mimetype(image_path)
        file = HTTP.Multipart(basename(image_path), IOBuffer(bytes), mime_type)
        # Post the media to Mastodon
        form = HTTP.Form(Dict("file" => file))
        form_data = HTTP.Form(Dict(
            "payload_json" => msg_json,
            "file" => file
        ))
        response = HTTP.post(webhook_url, [], form_data)
    end
    if response.status == 204
        println("Message posted successfully on Discord!")
    else
        println("Failed to post message on Discord. Status code: ", response.status)
        println("Response: ", String(response.body))
    end
end

end
