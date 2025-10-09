using BonitoSites
using Test
using BonitoSites.Bonito
using BonitoSites.Markdown
using BonitoSites.Dates
using BonitoSites.XML

@testset "BonitoSites.jl" begin

    @testset "RSS Feed Generation" begin
        # Test SiteEntry creation
        entry = BonitoSites.SiteEntry(
            "Test Post",
            "./test.html",
            "A test post description",
            DateTime(2025, 9, 30, 12, 0, 0),
            "",
            ""
        )

        @test entry.title == "Test Post"
        @test entry.link == "./test.html"
        @test entry.description == "A test post description"
        @test entry.date == DateTime(2025, 9, 30, 12, 0, 0)

        # Test XML parsing round-trip
        mktempdir() do tmpdir
            xml_file = joinpath(tmpdir, "post.xml")
            xml_content = """
            <item>
              <title>Test Post</title>
              <link>./test.html</link>
              <description>Test description</description>
              <pubDate>Mon, 30 Sep 2025 12:00:00</pubDate>
            </item>
            """
            write(xml_file, xml_content)

            parsed_entry = BonitoSites.from_xml(xml_file)
            @test parsed_entry.title == "Test Post"
            @test parsed_entry.link == "./test.html"
            @test parsed_entry.description == "Test description"
        end
    end

    @testset "Deploy Parameters" begin
        # Test deployparameters function with minimal config
        # This tests the parameter extraction without actually deploying
        params = BonitoSites.deployparameters(
            repo="github.com/test/repo.git",
            push_preview=false,
            devbranch="main",
            devurl="docs"
        )

        @test haskey(params, :all_ok)
        @test haskey(params, :branch)
        @test haskey(params, :repo)
        @test haskey(params, :subfolder)
        @test haskey(params, :is_preview)
        @test haskey(params, :config)

        # The params struct should be a NamedTuple
        @test params isa NamedTuple
    end

    @testset "Components" begin
        # Test HighlightCode component
        highlight = BonitoSites.HighlightCode()
        @test highlight isa BonitoSites.HighlightCode

        # Test that jsrender doesn't error
        session = Session()
        result = Bonito.jsrender(session, highlight)
        @test result isa Bonito.Node

        # Test Video component
        video = BonitoSites.Video("test.mp4")
        @test video isa Bonito.Node
    end

    @testset "Malt Runner Utilities" begin
        # Test ToSVG wrapper
        to_svg = BonitoSites.ToSVG("test object")
        @test to_svg.obj == "test object"

        # Test file extension utilities
        @test BonitoSites.get_file_ext(:PNG) == ".png"

        # Test find_file_without_ext
        mktempdir() do tmpdir
            test_file = joinpath(tmpdir, "test.txt")
            write(test_file, "content")

            found = BonitoSites.find_file_without_ext(tmpdir, "test")
            @test found == test_file

            not_found = BonitoSites.find_file_without_ext(tmpdir, "nonexistent")
            @test isnothing(not_found)
        end
    end

    @testset "Markdown Page Creation" begin
        # Test with a simple markdown file
        mktempdir() do tmpdir
            md_file = joinpath(tmpdir, "test.md")
            write(md_file, """
            # Test Page

            This is a test markdown page.

            ## Section

            Some content here.
            """)

            page = BonitoSites.MarkdownPage(md_file)
            @test page isa Bonito.Node
        end
    end

    @testset "Image URL Handling" begin
        # Test image rewriting logic
        mktempdir() do tmpdir
            session = Session()

            # Test with local file path
            img_file = joinpath(tmpdir, "test.png")
            write(img_file, "fake image data")

            img = Markdown.Image(img_file, "alt text")
            result = BonitoSites.rewrite_img(session, tmpdir, img)

            @test result isa Markdown.Image
            @test result.alt == "alt text"
        end
    end

    @testset "MaltRunner Construction" begin
        # Test MaltRunner creation without actually running code
        mktempdir() do tmpdir
            # Create a minimal Julia project
            write(joinpath(tmpdir, "Project.toml"), """
            name = "TestProject"
            """)

            runner = BonitoSites.MaltRunner(tmpdir)

            @test runner isa BonitoSites.MaltRunner
            @test runner.project == tmpdir
            @test isdir(runner.output_path)
            @test runner.counter == 0
            @test isnothing(runner.worker)
            @test isnothing(runner.current_session[])
        end
    end
end
