using Documenter
using Documenter: Remotes
using GlossBib

gls = GlossBibPlugin(
    joinpath(@__DIR__, "src", "terms.bib"),
    joinpath(@__DIR__, "src", "abbreviations.bib"),
    joinpath(@__DIR__, "src", "symbols.bib"),
)

makedocs(;
    modules=[GlossBib],
    authors="knottyanyon",
    sitename="GlossBib.jl",
    repo=Remotes.GitHub("knottyanyon", "GlossBib.jl"),
    format=Documenter.HTML(;
        canonical="https://knottyanyon.github.io/GlossBib.jl", edit_link="main"
    ),
    pages=["Home" => "index.md", "How to Use" => "howto.md"],
    plugins=[gls],
)

if get(ENV, "CI", "false") == "true"
    deploydocs(; repo="github.com/knottyanyon/GlossBib.jl", devbranch="main")
end
