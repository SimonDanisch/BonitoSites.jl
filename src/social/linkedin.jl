using HTTP, JSON3
using HTTP
using JSON3
using Bonito
using BonitoSites

struct LinkedinSession
    token::String
    author::String
end

const SESSION = Ref{Union{Nothing, LinkedinSession}}(nothing)
function LinkedinSession()
    if isnothing(SESSION[])
        token = ENV["LINKEDIN_TOKEN"]
        author = ENV["LINKEDIN_AUTHOR"]
        SESSION[] = LinkedinSession(token, author)
    end
    return SESSION[]
end

function get_bot_id(token=ENV["LINKEDIN_TOKEN"])
    url = "https://api.linkedin.com/v2/me"
    headers = ["Authorization" => "Bearer $token"]
    response = HTTP.get(url, headers)

    if response.status == 200
        profile_data = JSON3.read(String(response.body))
        bot_id = profile_data["id"]
        println("The bot's LinkedIn Member ID is: urn:li:member:$bot_id")
        return bot_id
    else
        println("Failed to retrieve LinkedIn member ID. Status code: ", response.status)
        println("Response: ", String(response.body))
        return nothing
    end
end

# Step 1: Register Image Upload
function register_image_upload(; session=LinkedinSession())
    url = "https://api.linkedin.com/v2/assets?action=registerUpload"
    headers = [
        "Authorization" => "Bearer $(session.token)",
        "Content-Type" => "application/json"
    ]
    body_data = Dict(
        "registerUploadRequest" => Dict(
            "owner" => "urn:li:member:$(session.author)",
            "recipes" => ["urn:li:digitalmediaRecipe:feedshare-image"],
            "serviceRelationships" => [
                Dict(
                    "identifier" => "urn:li:userGeneratedContent",
                    "relationshipType" => "OWNER"
                )
            ],
            "supportedUploadMechanism" => ["SYNCHRONOUS_UPLOAD"]
        )
    )

    body = JSON3.write(body_data)
    response = HTTP.post(url, headers, body)

    if response.status == 200
        response_data = JSON3.read(String(response.body))
        upload_url = response_data["value"]["uploadMechanism"]["com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest"]["uploadUrl"]
        asset = response_data["value"]["asset"]
        return upload_url, asset
    else
        println("Failed to register upload. Status code: ", response.status)
        println("Response: ", String(response.body))
        return nothing, nothing
    end
end

# Step 2: Upload Image
function upload_image(image_path::String; session=LinkedinSession())
    upload_url, asset = register_image_upload(; session=session)
    mime = Bonito.HTTPServer.file_mimetype(image_path)
    headers = ["Content-Type" => mime]  # or other appropriate MIME type
    image_data = BonitoSites.load_resized(image_path, 1_000_000)

    response = HTTP.put(upload_url, headers, image_data)

    if response.status == 201
        println("Image uploaded successfully!")
        return asset
    else
        println("Failed to upload image. Status code: ", response.status)
        println("Response: ", String(response.body))
        return nothing
    end
end


function post_to_linkedin(message::String, image_path::String; session=LinkedinSession())
    url = "https://api.linkedin.com/v2/ugcPosts"
    headers = [
        "Authorization" => "Bearer $(session.token)",
        "Content-Type" => "application/json",
        "X-Restli-Protocol-Version" => "2.0.0"
    ]

    # Determine author based on whether posting to profile or company page
    author_id = "urn:li:member:$(session.author)"
    @show author_id
    asset = upload_image(image_path; session=session)
    body_data = Dict(
        "author" => author_id,
        "lifecycleState" => "PUBLISHED",
        "specificContent" => Dict(
            "com.linkedin.ugc.ShareContent" => Dict(
                "shareCommentary" => Dict("text" => message),
                "shareMediaCategory" => "IMAGE",
                "media" => [
                    Dict(
                        "status" => "READY",
                        "description" => Dict("text" => message),
                        "media" => asset,
                        "title" => Dict("text" => "Image post")
                    )
                ]
            )
        ),
        "visibility" => Dict("com.linkedin.ugc.MemberNetworkVisibility" => "PUBLIC")
    )

    body = JSON3.write(body_data)
    response = HTTP.post(url, headers, body)

    if response.status == 201
        println("Message posted successfully to LinkedIn!")
    else
        println("Failed to post message to LinkedIn. Status code: ", response.status)
        println("Response: ", String(response.body))
    end
end


# using Blog
# img = Blog.assetpath("images", "materials.png")
# post_to_linkedin("Test Post", img)

# ENV["LINKEDIN_AUTHOR"] = "222189745"
# SESSION[] = nothing
# session = LinkedinSession()
# session.author
