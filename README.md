# GlossBib.jl

Glossary, abbreviation, and symbol linking for [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)
docs, in the style of [bib2gls](https://ctan.org/pkg/bib2gls)/`glossaries-extra`, following the
plugin architecture of [DocumenterCitations.jl](https://github.com/JuliaDocs/DocumenterCitations.jl).

Entries (key terms, abbreviations, symbols) are authored as bib2gls-style `.bib` records
(`@entry`, `@abbreviation`, `@symbol`, `@index`) and referenced from markdown with
`[key](@gls)` / `[display text](@gls key)` syntax. Only entries actually referenced in the docs
are rendered, and only entries that are referenced get expanded — no external bib2gls/Java
dependency, everything is reimplemented natively via `Bibliography.jl` and `MarkdownAST`.

## Usage

```julia
using Documenter, GlossBib

gls = GlossBibPlugin("terms.bib", "abbreviations.bib", "symbols.bib")

makedocs(; plugins=[gls], pages=[...])
```

```markdown
An [mps](@gls) is a compressed state representation. See also [dmrg](@gls).

\```@glossary
\```
```

See the [documentation](https://knottyanyon.github.io/GlossBib.jl) for details,
including LaTeX/`glossaries-extra` output via `glossaries_extra_preamble`.
