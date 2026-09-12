using Documenter
using Documenter: Remotes
using DocumenterGlossip

makedocs(;
    modules=[DocumenterGlossip],
    authors="knottyanyon",
    sitename="DocumenterGlossip.jl",
    repo=Remotes.GitHub("knottyanyon", "DocumenterGlossip.jl"),
    format=Documenter.HTML(;
        canonical="https://knottyanyon.github.io/DocumenterGlossip.jl", edit_link="main"
    ),
    pages=["Home" => "index.md"],
)

if get(ENV, "CI", "false") == "true"
    deploydocs(; repo="github.com/knottyanyon/DocumenterGlossip.jl", devbranch="main")
end
