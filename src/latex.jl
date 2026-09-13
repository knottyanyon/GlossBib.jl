# LaTeX (glossaries-extra) output support.
#
# bib2gls itself is designed to feed the `glossaries-extra` LaTeX package:
# bib2gls consumes `.bib` resource files and emits definitions that
# `glossaries-extra` loads and prints via `\printunsrtglossary`. We mirror
# that translation natively (no shelling out to bib2gls): entries become
# `\newglossaryentry`/`\newabbreviation` definitions, and `@gls` references
# become raw `\gls{...}` (etc.) commands via a writer-aware branch, exactly as
# DocumenterCitations.jl special-cases citation nodes for `LaTeXWriter`
# instead of reusing the HTML resolved-text path.

"""Inline MarkdownAST node carrying a raw LaTeX command, e.g. `\\gls{key}`.

Only ever produced when the active writer is `Documenter.LaTeXWriter`; the
HTML writer never sees these (HTML expansion goes through
[`format_reference`](@ref) and ordinary `MarkdownAST.Link`/`Text` nodes).
"""
struct RawLaTeXReference <: MarkdownAST.AbstractInline
    text::String
end

function Documenter.LaTeXWriter.latex(
    lctx::Documenter.LaTeXWriter.Context, node::MarkdownAST.Node, raw::RawLaTeXReference
)
    print(lctx.io, raw.text)
    return nothing
end

function Documenter.MDFlatten.mdflatten(io, ::MarkdownAST.Node, raw::RawLaTeXReference)
    print(io, raw.text)
    return nothing
end

# LaTeX rendering for an expanded ```@glossary```/```@abbreviations```/
# ```@symbols``` block. Since the "real" glossary lists in the LaTeX output
# are the generated `\printunsrtglossary[type=...]` calls (see
# `glossaries_extra_preamble`), we render a lightweight description list here
# for the (uncommon) case where such a block is also used directly in a
# LaTeX-built page.
function Documenter.LaTeXWriter.latex(
    lctx::Documenter.LaTeXWriter.Context, node::MarkdownAST.Node, glossary::GlossaryNode
)
    io = lctx.io
    println(io, "\\begin{description}")
    for item in glossary.items
        print(io, "\\item[")
        Documenter.LaTeXWriter.latex(lctx, item.label.children)
        print(io, "] ")
        Documenter.LaTeXWriter.latex(lctx, item.description.children)
        println(io)
    end
    println(io, "\\end{description}")
    return nothing
end

"""Format the raw LaTeX command (e.g. `\\gls{key}`) for referencing `entry` in `form`.

`form` is one of `:long` (first use), `:short` (subsequent use), or `:direct`
(explicit display text via `[display](@gls key)`, rendered as `\\gls{key}`
with the display text passed as the optional argument via `\\glslink`).
"""
function format_latex_reference(entry::GlossaryEntry, form::Symbol)
    return format_latex_reference(Val(entry.category), entry, form)
end

function format_latex_reference(::Val{:abbreviation}, entry::GlossaryEntry, form::Symbol)
    key = entry.key
    if form === :long
        return "\\glsxtrfull{$key}"
    elseif form === :short
        return "\\gls{$key}"
    else
        return "\\gls{$key}"
    end
end

function format_latex_reference(::Val{S}, entry::GlossaryEntry, form::Symbol) where {S}
    key = entry.key
    return "\\gls{$key}"
end

"""Emit a `\\newglossaryentry{...}`/`\\newabbreviation{...}` definition for `entry`.

Field values are inserted verbatim, matching real bib2gls/BibTeX convention: a `.bib`
field's value is raw LaTeX source, not plain text needing escaping. The `.bib` file's
author is responsible for escaping literal special characters themselves (e.g. `50\\%`
for a literal percent sign) exactly as with any hand-written LaTeX/BibTeX source.

For `:symbol` entries specifically, the `symbol` field is additionally wrapped in
`\$...\$` (math mode) — bib2gls's own convention is that symbol entries hold math content
(traditionally authored as `symbol={\\ensuremath{...}}`), so this spares `.bib` authors
from writing the math-mode wrapper themselves for the common case of a bare symbol like
`symbol={\\chi}` or `symbol={χ}`.
"""
function glossaries_extra_definition(entry::GlossaryEntry)
    key = entry.key
    name = entry_name(entry)
    desc = entry_description(entry)
    isempty(desc) && (desc = name)
    if entry.category == :abbreviation
        long = entry_long(entry)
        short = entry_short(entry)
        return "\\newabbreviation{$key}{$short}{$long}\n"
    elseif entry.category == :symbol
        sym = get(entry, "symbol", name)
        return "\\newglossaryentry{$key}{type=symbols,name={\$$sym\$},description={$desc}}\n"
    elseif entry.category == :index
        return "\\newglossaryentry{$key}{type=index,name={$name},description={$desc}}\n"
    else
        return "\\newglossaryentry{$key}{name={$name},description={$desc}}\n"
    end
end

const _CATEGORY_FILE_NAMES = OrderedDict(
    :entry => "glossary-terms.tex",
    :abbreviation => "glossary-abbreviations.tex",
    :symbol => "glossary-symbols.tex",
)

const _CATEGORY_GLSTYPE = Dict(:entry => "main", :abbreviation => "abbreviations", :symbol => "symbols")

"""
    glossaries_extra_preamble(plugin::GlossBibPlugin; output_dir=pwd())

Write one `.tex` file per category (`glossary-terms.tex`,
`glossary-abbreviations.tex`, `glossary-symbols.tex`) into `output_dir`, each
containing that category's `\\newglossaryentry{...}`/`\\newabbreviation{...}`
definitions, plus a `glossary-print.tex` back-matter snippet with the
corresponding `\\printunsrtglossary[type=...]` calls in category order.

Users `\\input{}` the definition files from their LaTeX preamble/header (passed
to `Documenter.LaTeX(; sty=...)`) and `\\input{glossary-print.tex}` where they
want the back-matter lists to appear — standard `glossaries-extra` project
structure, generated instead of hand-written.

Returns the list of generated file paths.
"""
function glossaries_extra_preamble(plugin::GlossBibPlugin; output_dir::AbstractString=pwd())
    mkpath(output_dir)
    generated = String[]
    present_categories = Symbol[]
    for (category, filename) in _CATEGORY_FILE_NAMES
        entries_in_category = [e for e in values(plugin.entries) if e.category == category]
        isempty(entries_in_category) && continue
        push!(present_categories, category)
        path = joinpath(output_dir, filename)
        open(path, "w") do io
            for entry in entries_in_category
                write(io, glossaries_extra_definition(entry))
            end
        end
        push!(generated, path)
    end
    print_path = joinpath(output_dir, "glossary-print.tex")
    open(print_path, "w") do io
        for category in present_categories
            gtype = _CATEGORY_GLSTYPE[category]
            write(io, "\\printunsrtglossary[type=$gtype]\n")
        end
    end
    push!(generated, print_path)
    return generated
end
