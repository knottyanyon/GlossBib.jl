# Expand Glossary
#
# Runs after CollectGlossaryReferences but before ExpandGlossaryReferences,
# mirroring DocumenterCitations.jl's `ExpandBibliography` stage.

"""Pipeline step to expand ```@glossary```/```@abbreviations```/```@symbols``` blocks.

Each block is rendered as a definition list ([`GlossaryNode`](@ref)) of the
entries that were actually referenced elsewhere in the docs (bib2gls's
defining "only show used entries" behavior), optionally filtered to a single
category.
"""
abstract type ExpandGlossary <: Builder.DocumentPipeline end

Selectors.order(::Type{ExpandGlossary}) = 2.12  # after CollectGlossaryReferences

function Selectors.runner(::Type{ExpandGlossary}, doc::Documenter.Document)
    Documenter.is_doctest_only(doc, "ExpandGlossary") && return
    @info "ExpandGlossary: expanding glossary blocks."
    expand_glossary(doc)
end

const _GLOSSARY_BLOCK_CATEGORY = Dict(
    # `@glossary` shows key-term entries (category :entry) only, matching the
    # per-category split used for LaTeX output (glossary-terms.tex vs.
    # glossary-abbreviations.tex vs. glossary-symbols.tex): each block type
    # renders one glossaries-extra "type" so that combining
    # @glossary/@abbreviations/@symbols on a page shows each entry exactly
    # once, never duplicated across blocks.
    "@glossary" => :entry,
    "@abbreviations" => :abbreviation,
    "@symbols" => :symbol,
    "@index" => :index,
)

function expand_glossary(doc::Documenter.Document)
    gls = Documenter.getplugin(doc, GlossBibPlugin)
    for (src, page) in doc.blueprint.pages
        empty!(page.globals.meta)
        expand_glossary(doc, page, page.mdast, gls)
    end
end

function expand_glossary(doc::Documenter.Document, page, mdast::MarkdownAST.Node, gls)
    for node in AbstractTrees.PreOrderDFS(mdast)
        if node.element isa MarkdownAST.CodeBlock
            info = strip(node.element.info)
            block_name = split(info)[1:min(1, length(split(info)))]
            key = isempty(block_name) ? "" : first(block_name)
            if haskey(_GLOSSARY_BLOCK_CATEGORY, key)
                expand_glossary_block(node, _GLOSSARY_BLOCK_CATEGORY[key], page, doc, gls)
            end
        end
    end
end

function expand_glossary_block(
    node::MarkdownAST.Node, category::Union{Nothing,Symbol}, page, doc, gls
)
    anchors = gls.anchor_map
    items = GlossaryItem[]
    # sorted by first-use order (bib2gls default: order of use)
    keys_to_show = [k for (k, _) in sort(collect(gls.used_keys); by=(kv -> kv[2]))]
    for key in keys_to_show
        entry = gls.entries[key]
        (category === nothing || entry.category === category) || continue
        anchor_key = key
        if Documenter.anchor_exists(anchors, anchor_key)
            continue
        end
        Documenter.anchor_add!(anchors, entry, anchor_key, page.build)

        label = MarkdownAST.@ast MarkdownAST.Paragraph()
        append!(label.children, _mdparse_span(format_glossary_label(entry)))

        description = MarkdownAST.@ast MarkdownAST.Paragraph()
        append!(
            description.children, _mdparse_span(format_glossary_entry(entry))
        )

        push!(items, GlossaryItem(anchor_key, label, description))
    end
    node.element = GlossaryNode(category, items)
    return nothing
end
