using Documenter
using DocumenterGlossip

makedocs(;
    modules=[DocumenterGlossip],
    authors="knottyanyon",
    sitename="DocumenterGlossip.jl",
    repo="https://github.com/knottyanyon/DocumenterGlossip.jl/blob/{commit}{path}#{line}",
    format=Documenter.HTML(; edit_link="main"),
    pages=["Home" => "index.md"],
)
