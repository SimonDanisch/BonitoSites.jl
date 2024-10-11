

function ask_openai(prompt, system="you're a level headed technical author of the open source plotting library Makie.jl. Your tone is neutral, without bullshit and no smileys and overhype.")
    user = Dict("role" => "user", "content" => prompt)
    system = Dict("role" => "system", "content" => system)
    message = OpenAI.create_chat(ENV["OPENAI_API_KEY"], "gpt-4o", [user, system]).response[:choices][begin][:message][:content]
    return message
end

function generate_prompt(comments)
    """
    Here are all the comments for a github pr for my open source plotting library Makie.jl:
    ```markdown
    $(comments)
    ```
    I want you to make a concise summary that works well for a blogpost about all the changes this PR introduced.
    These summaries will get a manually written intro and concatenated to a blogpost, so please refrain from mentioning that this is a PR for makie, since it will be redundant.
    KEEP IT REALLY SHORT AND LEAVE OUT ANYTHING THAT WAS ONLY DISCUSSED!!!
    Dont repeat discussions or contemplate about the changes.
    Dont add your own thoughts.
    You should not talk about any changes to tests or testing infrastructure.
    If there are very little information to go on, dont try to add more.
    Dont do any intro to the topic, just keep it concise and to the point.
    No talk about how recent the PR is.
    Leave out any discussion, and only summarize the FINAL changes.
    Make sure to extract relevant images from the comments (in the form ![image-name](image-url)) and leave out all discussions and only put the most important results in your summary
    Please make remove the business talk and make the summaries very concise, short and to the point.
    This should be maximally informative for users of Makie and doesn't need any bullshit.
    Keep it simple and best fit the whole summary in one short paragraph unless the changes are really important.
    No bullet points no update/impact lingu.
    Please dont add any of your own comments.
    Don't speculate about performance or any consequences of the PR.
    Your summary should not contain any information that isn't directly discussed in the PR.
    """
end

function get_comments(pr; filter_comments=(x) -> true)
    pr_comments, _ = gh_comments(repo, pr, :pr)
    return sprint() do io
        println(io, "# ", title(pr))
        println(io)
        println(io, pr.body)
        println(io)
        for comment in pr_comments
            if filter_comments(comment)
                println(io, "### Use $(comment.user) says:")
                println(io, comment.body)
            end
        end
    end
end

function ai_pr_summary(filename, tag1, tag2)
    diff = gh_compare(repo, tag2, tag1)
    open(filename, "w") do io
        for c in diff.commits
            pr = get_pr(repo, c)
            isnothing(pr) && continue
            println(io, "# ", title(pr))
            pr_comments = get_comments(pr)
            summary = ask_openai(generate_prompt(pr_comments))
            println(io)
            println(io, summary)
            println(io)
        end
    end
end


title(pr) = string(pr.title, "[#$(pr.number)]($(pr.html_url))")
