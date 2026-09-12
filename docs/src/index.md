# GlossBib.jl

Glossary, abbreviation, and symbol linking for [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)
docs, in the style of [bib2gls](https://ctan.org/pkg/bib2gls)/`glossaries-extra`, following the
same plugin architecture as [DocumenterCitations.jl](https://github.com/JuliaDocs/DocumenterCitations.jl).

See the [How to Use](@ref) page for a full walkthrough of defining entries, registering the
plugin, referencing entries inline, and building to both HTML and LaTeX/PDF.

## Example

An [mps](@gls) is described by its [chi](@gls). Compare [dmrg](@gls) with a plain [dmrg](@gls)
on second use.

```@glossary
```

```@abbreviations
```

```@symbols
```

## API

```@autodocs
Modules = [GlossBib]
```
