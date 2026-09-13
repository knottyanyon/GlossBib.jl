using GlossBib
using GlossBib: GlossaryEntry, parse_glossary_bibfile, format_reference,
    glossaries_extra_preamble, GlossBibPlugin
using Documenter
using Test

const FIXTURES_DIR = mktempdir()

function write_fixtures(dir)
    src = joinpath(dir, "src")
    mkpath(src)
    write(
        joinpath(src, "terms.bib"),
        """
        @entry{mps,
          name = {matrix product state},
          description = {A tensor network representation of a quantum state.}
        }
        """,
    )
    write(
        joinpath(src, "abbreviations.bib"),
        """
        @abbreviation{dmrg,
          short = {DMRG},
          long  = {density matrix renormalization group}
        }
        """,
    )
    write(
        joinpath(src, "symbols.bib"),
        """
        @symbol{chi,
          name = {chi},
          symbol = {χ},
          description = {The bond dimension of an MPS.}
        }
        """,
    )
    write(
        joinpath(src, "index.md"),
        """
        # Home

        An [mps](@gls) is described by its [chi](@gls). Compare [dmrg](@gls) with a
        second use of [dmrg](@gls). Here is [a custom label](@gls mps).

        ```@glossary
        ```

        ```@abbreviations
        ```

        ```@symbols
        ```
        """,
    )
    return src
end

@testset "GlossBib" begin

    @testset "entries.jl: parsing" begin
        dir = mktempdir()
        bibfile = joinpath(dir, "t.bib")
        write(
            bibfile,
            """
            @entry{foo, name = {Foo Term}, description = {A description.}}
            @abbreviation{bar, short = {BAR}, long = {Big Abbreviation Result}}
            """,
        )
        entries = parse_glossary_bibfile(bibfile)
        @test entries["foo"].category == :entry
        @test entries["bar"].category == :abbreviation
        @test entries["bar"].fields["short"] == "BAR"
    end

    @testset "format_reference: abbreviation first/subsequent use" begin
        dir = mktempdir()
        bibfile = joinpath(dir, "t.bib")
        write(bibfile, "@abbreviation{dmrg, short = {DMRG}, long = {density matrix renormalization group}}")
        entries = parse_glossary_bibfile(bibfile)
        entry = entries["dmrg"]
        @test format_reference(entry, true) == "density matrix renormalization group (DMRG)"
        @test format_reference(entry, false) == "DMRG"
    end

    @testset "integration: makedocs HTML build" begin
        src = write_fixtures(FIXTURES_DIR)
        build = joinpath(FIXTURES_DIR, "build")

        gls = GlossBibPlugin(
            joinpath(src, "terms.bib"),
            joinpath(src, "abbreviations.bib"),
            joinpath(src, "symbols.bib"),
        )

        makedocs(;
            sitename="Fixture",
            root=FIXTURES_DIR,
            source="src",
            build="build",
            format=Documenter.HTML(; edit_link=nothing),
            pages=["Home" => "index.md"],
            plugins=[gls],
            warnonly=true,
            remotes=nothing,
        )

        @test isdir(build)
        html = read(joinpath(build, "index.html"), String)

        # resolved references
        @test occursin("matrix product state", html)
        @test occursin("density matrix renormalization group (DMRG)", html)
        @test occursin(">DMRG<", html)  # second use, short form
        @test occursin("a custom label", html)

        # glossary block: only referenced entries shown, with descriptions
        @test occursin("A tensor network representation", html)
        @test occursin("The bond dimension of an MPS", html)

        # collected usage tracked on the plugin
        @test haskey(gls.used_keys, "mps")
        @test haskey(gls.used_keys, "dmrg")
        @test haskey(gls.used_keys, "chi")
    end

    @testset "integration: makedocs LaTeX build" begin
        root = mktempdir()
        src = write_fixtures(root)

        gls = GlossBibPlugin(
            joinpath(src, "terms.bib"),
            joinpath(src, "abbreviations.bib"),
            joinpath(src, "symbols.bib"),
        )

        makedocs(;
            sitename="Fixture",
            root=root,
            source="src",
            build="build",
            format=Documenter.LaTeX(; platform="none"),
            pages=["Home" => "index.md"],
            plugins=[gls],
            warnonly=true,
            remotes=nothing,
        )

        texfile = joinpath(root, "build", "Fixture.tex")
        @test isfile(texfile)
        content = read(texfile, String)

        # raw LaTeX passthrough, not flattened prose
        @test occursin("\\gls{mps}", content)
        @test occursin("\\gls{chi}", content)
        @test occursin("\\glsxtrfull{dmrg}", content)  # first use: long form
        @test occursin("\\gls{dmrg}", content)  # subsequent use: short form
        # the prose sentence itself must be raw \gls{} commands, not flattened text
        @test occursin(
            "An \\gls{mps} is described by its \\gls{chi}. Compare \\glsxtrfull{dmrg}", content
        )
    end

    @testset "LaTeX / glossaries-extra output" begin
        src = write_fixtures(mktempdir())
        gls = GlossBibPlugin(
            joinpath(src, "terms.bib"),
            joinpath(src, "abbreviations.bib"),
            joinpath(src, "symbols.bib"),
        )
        outdir = mktempdir()
        files = glossaries_extra_preamble(gls; output_dir=outdir)
        @test isfile(joinpath(outdir, "glossary-terms.tex"))
        @test isfile(joinpath(outdir, "glossary-abbreviations.tex"))
        @test isfile(joinpath(outdir, "glossary-symbols.tex"))
        @test isfile(joinpath(outdir, "glossary-print.tex"))

        terms = read(joinpath(outdir, "glossary-terms.tex"), String)
        @test occursin("\\newglossaryentry{mps}", terms)

        abbrevs = read(joinpath(outdir, "glossary-abbreviations.tex"), String)
        @test occursin("\\newabbreviation{dmrg}{DMRG}{density matrix renormalization group}", abbrevs)

        symbols = read(joinpath(outdir, "glossary-symbols.tex"), String)
        @test occursin("type=symbols", symbols)
        # symbol field is auto-wrapped in math mode for the LaTeX definition
        @test occursin("name={\$χ\$}", symbols)

        print_tex = read(joinpath(outdir, "glossary-print.tex"), String)
        @test occursin("\\printunsrtglossary[type=main]", print_tex)
        @test occursin("\\printunsrtglossary[type=abbreviations]", print_tex)
        @test occursin("\\printunsrtglossary[type=symbols]", print_tex)
    end

    @testset "no Glossaries.jl coupling" begin
        srcfile = joinpath(pkgdir(GlossBib), "src", "GlossBib.jl")
        content = read(srcfile, String)
        @test !occursin("using Glossaries", content)
        @test !occursin("Glossaries.@Glossary", content)
    end

end
