using HTTP
using JSON3

# Function to post a message with optional image to Slack
function post_to_slack(message::String, image_url::String=""; webhook_url::String)
    # Prepare the payload for the message
    attachments = []
    if !isempty(image_url)
        # If an image is specified, add it as an attachment
        attachments = [
            Dict(
                "fallback" => message,
                "image_url" => image_url,
                "text" => message
            )
        ]
    end

    body_data = Dict(
        "text" => message,
        "attachments" => attachments
    )

    headers = ["Content-Type" => "application/json"]
    body = JSON3.write(body_data)

    response = HTTP.post(webhook_url, headers, body)

    if response.status == 200
        println("Message posted successfully to Slack!")
    else
        println("Failed to post message to Slack. Status code: ", response.status)
        println("Response: ", String(response.body))
    end
end
