# Parsing of `[key](@gls)` / `[display](@gls key)` reference links.
#
# Mirrors DocumenterCitations.jl's `citation_link.jl`, adapted to bib2gls
# reference semantics: a bare `[key](@gls)` link resolves to the entry's
# first-use/subsequent-use display form; `[display text](@gls key)` is a
# "direct" reference with explicit display text.

const __GLS_RX_KEY = raw"""[^\s"#'(),{}%]+"""
const _RX_GLS_URL = Regex("^\\@gls\$")
const _RX_GLS_KEY_URL = Regex("^\\@gls\\s+(?<key>$__GLS_RX_KEY)\$")

"""Data structure for a bare glossary reference link: `[key](@gls)`."""
struct GlossaryReferenceLink
    node::MarkdownAST.Node
    key::String
end

"""Data structure for a direct glossary reference link: `[display text](@gls key)`."""
struct DirectGlossaryReferenceLink
    node::MarkdownAST.Node
    key::String
    display::String
end

"""Parse a `MarkdownAST.Link` node that is a `@gls` reference.

Returns a [`GlossaryReferenceLink`](@ref) or [`DirectGlossaryReferenceLink`](@ref).
"""
function read_reference_link(link::MarkdownAST.Node)
    if !(link.element isa MarkdownAST.Link)
        error("Invalid markdown for glossary reference link: not a Link node")
    end
    destination = link.element.destination
    if (match(_RX_GLS_URL, destination)) !== nothing
        # [key](@gls)
        text = ast_linktext(link)
        key = replace(strip(text), "*" => "_")
        return GlossaryReferenceLink(link, key)
    elseif (m = match(_RX_GLS_KEY_URL, destination)) !== nothing
        # [display](@gls key)
        key = replace(strip(convert(String, m[:key])), "*" => "_")
        display = ast_linktext(link)
        return DirectGlossaryReferenceLink(link, key, display)
    else
        error("Invalid @gls reference link destination: $(repr(destination))")
    end
end

"""`true` if `node` is a `MarkdownAST.Link` whose destination begins with `@gls`."""
function is_reference_link(node::MarkdownAST.Node)
    return node.element isa MarkdownAST.Link &&
           startswith(lowercase(node.element.destination), "@gls")
end

# Convert a Link node's children to plain text (markdown source). Mirrors
# DocumenterCitations' `ast_linktext`.
function ast_linktext(node)
    @assert node.element isa MarkdownAST.Link "node must be a Link, not $(typeof(node.element))"
    no_nested_markdown =
        length(node.children) === 1 &&
        (first_node = first(node.children); first_node.element isa MarkdownAST.Text)
    if no_nested_markdown
        return strip(first_node.element.text)
    else
        document = MarkdownAST.@ast MarkdownAST.Document() do
            MarkdownAST.Paragraph()
        end
        paragraph = first(document.children)
        children = [MarkdownAST.copy_tree(child) for child in node.children]
        append!(paragraph.children, children)
        text = Markdown.plain(convert(Markdown.MD, document))
        return strip(text)
    end
end
