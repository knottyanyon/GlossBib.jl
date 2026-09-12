module GlossBib

using Documenter: Documenter
using Documenter.Builder
using Documenter.Selectors
using Documenter.HTMLWriter
using Documenter.LaTeXWriter

import MarkdownAST
import AbstractTrees

using Bibliography: Bibliography
using OrderedCollections: OrderedDict

using Markdown

export GlossBibPlugin, glossaries_extra_preamble

include("entries.jl")

"""Plugin for enabling bib2gls-style glossary/abbreviation/symbol references in Documenter.jl.

```julia
gls = GlossBibPlugin("terms.bib", "abbreviations.bib", "symbols.bib")
```

instantiates a plugin object that must be passed as an element of the
`plugins` keyword argument to `Documenter.makedocs`.

Entries are authored per bib2gls's own `.bib` convention: `@entry{...}`,
`@abbreviation{...}`, `@symbol{...}`, `@index{...}` records (parsed via
`Bibliography.jl`, same as `DocumenterCitations.jl` does for citation `.bib`
files). Reference an entry from any markdown page with `[key](@gls)` (first
use gets a long form; subsequent uses get a short form, for abbreviations) or
`[display text](@gls key)` for a custom display string. Only entries that are
actually referenced somewhere in the docs are rendered by
```@glossary```/```@abbreviations```/```@symbols``` blocks — this "only show
used entries" behavior is bib2gls's defining feature, reimplemented here in
pure Julia (no external bib2gls/Java dependency).

# Internal fields

The following internal fields are used by the glossary pipeline steps and
should not be considered part of the stable API.

* `entries`: dict of entry key to [`GlossaryEntry`](@ref), merged from all
  `bibfiles`
* `used_keys`: ordered dict of key to the order in which it was first
  referenced
* `page_references`: dict of page file name to set of keys referenced on that
  page
* `seen_keys`: mutable set used during `ExpandGlossaryReferences` to track
  first-use vs. subsequent-use rendering
* `anchor_map`: a `Documenter.AnchorMap` tracking link anchors for entries
  rendered in glossary blocks
"""
struct GlossBibPlugin <: Documenter.Plugin
    bibfiles::Vector{String}
    entries::OrderedDict{String,GlossaryEntry}
    used_keys::OrderedDict{String,Int}
    page_references::Dict{String,Set{String}}
    seen_keys::Set{String}
    anchor_map::Documenter.AnchorMap
end

function GlossBibPlugin(bibfiles::AbstractString...)
    files = collect(String.(bibfiles))
    entries = OrderedDict{String,GlossaryEntry}()
    for bibfile in files
        for (key, entry) in parse_glossary_bibfile(bibfile)
            if haskey(entries, key)
                error("Ambiguous key $(repr(key)): defined in multiple bibfiles")
            end
            entries[key] = entry
        end
    end
    if isempty(files)
        @warn "No bibfiles. Did you instantiate `gls = GlossBibPlugin(\"terms.bib\", ...)` and pass `gls` to `makedocs` as an element of the `plugins` keyword argument?"
    elseif isempty(entries)
        @warn "No entries loaded from $(files)"
    end
    return GlossBibPlugin(
        files,
        entries,
        OrderedDict{String,Int}(),
        Dict{String,Set{String}}(),
        Set{String}(),
        Documenter.AnchorMap(),
    )
end

# Parse `str` as an inline markdown "span" (as `Documenter.mdparse(str;
# mode=:span)` does), falling back to a single plain-text node if `str`
# doesn't parse as pure inline content (e.g. bib2gls `symbol` fields
# containing standalone LaTeX math, which are meant for the LaTeX output
# path, not HTML).
function _mdparse_span(str::AbstractString)
    try
        return Documenter.mdparse(str; mode=:span)
    catch
        return [MarkdownAST.@ast MarkdownAST.Text(str)]
    end
end

include("reference_link.jl")
include("glossary_node.jl")
include("collect_references.jl")
include("expand_glossary.jl")
include("styles/default.jl")
include("latex.jl")
include("expand_references.jl")

function __init__()
    for errname in (:glossary_block, :glossary_references)
        if !(errname in Documenter.ERROR_NAMES)
            push!(Documenter.ERROR_NAMES, errname)
        end
    end
end

end # module
