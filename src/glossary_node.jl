# MarkdownAST node for an expanded ```@glossary``` block, analogous to
# DocumenterCitations' `BibliographyNode`/`BibliographyItem`.

"""One entry rendered within a [`GlossaryNode`](@ref).

# Fields

* `anchor_key`: the HTML anchor key for the entry (matches `entry.key` unless
  normalized)
* `label`: `MarkdownAST.Node` for the entry's label/name
* `description`: `MarkdownAST.Node` for the entry's rendered description
"""
struct GlossaryItem
    anchor_key::String
    label::MarkdownAST.Node{Nothing}
    description::MarkdownAST.Node{Nothing}
end

"""Node in `MarkdownAST` corresponding to an expanded ```@glossary``` (or
```@abbreviations```/```@symbols```) block.

Rendered as a definition list (`:dl`) of the entries in `items`, in the given
`category` (or `nothing` for "all categories").
"""
struct GlossaryNode <: Documenter.AbstractDocumenterBlock
    category::Union{Nothing,GlossaryCategory}
    items::Vector{GlossaryItem}
end

function Documenter.MDFlatten.mdflatten(io, ::MarkdownAST.Node, g::GlossaryNode)
    for item in g.items
        Documenter.MDFlatten.mdflatten(io, item.label)
        print(io, ": ")
        Documenter.MDFlatten.mdflatten(io, item.description)
        print(io, "\n\n")
    end
end

function Documenter.HTMLWriter.domify(
    dctx::Documenter.HTMLWriter.DCtx,
    node::Documenter.Node,
    glossary::GlossaryNode
)
    @assert node.element === glossary
    return domify_glossary(dctx, glossary)
end

function domify_glossary(dctx::Documenter.HTMLWriter.DCtx, glossary::GlossaryNode)
    Documenter.DOM.@tags dl dt dd div
    html_list = dl()
    for item in glossary.items
        html_label = Documenter.HTMLWriter.domify(dctx, item.label.children)
        html_description = Documenter.HTMLWriter.domify(dctx, item.description.children)
        anchor_id = "#$(item.anchor_key)"
        push!(html_list.nodes, dt[anchor_id](html_label))
        push!(html_list.nodes, dd(html_description))
    end
    return div[".glossary"](html_list)
end

function Documenter.linkcheck(
    node::MarkdownAST.Node,
    glossary::GlossaryNode,
    doc::Documenter.Document
)
    success = true
    for item in glossary.items
        success &= !(Documenter.linkcheck(item.description, doc) === false)
    end
    return success
end
