# DocumenterGlossip.jl

Glossary linking for [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) docs: pairs
[Glossaries.jl](https://github.com/) docstring/code-term interpolation with a prose-tooltip
linker for `{glossary:Term}` references in markdown.

## Usage

In each module that wants docstring term interpolation, call `Glossaries.@Glossary()` yourself
(per [Glossaries.jl](https://github.com/) conventions — this must live in the target module):

```julia
module MyPackage
using Glossaries
Glossaries.@Glossary()
include("glossary_terms.jl")
end
```

In `docs/make.jl`, before `makedocs`, rewrite prose `{glossary:Term}` references:

```julia
using DocumenterGlossip
DocumenterGlossip.setup_glossary(joinpath(@__DIR__, "src"))
```

Then in your markdown pages: `An {glossary:MPS} is a compressed state representation.`
