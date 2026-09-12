# Expand Glossary References
#
# Runs after ExpandGlossary, so that the anchors defined by expanded
# ```@glossary``` blocks are available to link to. Mirrors
# DocumenterCitations.jl's `ExpandCitations` stage.

"""Pipeline step to expand all `@gls` reference links.

Resolves each `[key](@gls)` / `[display](@gls key)` link into a link pointing
at the entry's anchor (defined by [`ExpandGlossary`](@ref)), with display text
formatted per-category (first-use long form for abbreviations, then short
form on subsequent uses) via [`format_reference`](@ref).
"""
abstract type ExpandGlossaryReferences <: Builder.DocumentPipeline end

Selectors.order(::Type{ExpandGlossaryReferences}) = 2.13  # After ExpandGlossary

function Selectors.runner(::Type{ExpandGlossaryReferences}, doc::Documenter.Document)
    Documenter.is_doctest_only(doc, "ExpandGlossaryReferences") && return
    @info "ExpandGlossaryReferences"
    expand_glossary_references!(doc)
end

function expand_glossary_references!(doc::Documenter.Document)
    gls = Documenter.getplugin(doc, GlossBibPlugin)
    empty!(gls.seen_keys)
    for (src, page) in doc.blueprint.pages
        empty!(page.globals.meta)
        expand_glossary_references!(doc, page, page.mdast, gls)
    end
end

function expand_glossary_references!(doc::Documenter.Document, page, mdast::MarkdownAST.Node, gls)
    replace!(mdast) do node
        if node.element isa Documenter.DocsNode
            for docstr in node.element.mdasts
                expand_glossary_references!(doc, page, docstr, gls)
            end
            node
        else
            expand_reference(node, page, doc, gls)
        end
    end
end

# Return the replacement node(s) for a single reference Link node. Any node
# that is not a `@gls` reference link is returned unchanged.
function expand_reference(node::MarkdownAST.Node, page, doc, gls)
    is_reference_link(node) || return node
    ref = read_reference_link(node)
    key = ref.key
    if !haskey(gls.entries, key)
        @error "Key $(repr(key)) not found in glossary entries"
        push!(doc.internal.errors, :glossary_references)
        return node
    end
    entry = gls.entries[key]

    is_latex = _is_latex_writer(doc)

    first_use = !(key in gls.seen_keys)
    push!(gls.seen_keys, key)

    if is_latex
        form = ref isa DirectGlossaryReferenceLink ? :direct : (first_use ? :long : :short)
        latex_str = format_latex_reference(entry, form)
        return MarkdownAST.Node(RawLaTeXReference(latex_str))
    end

    anchors = gls.anchor_map
    display = if ref isa DirectGlossaryReferenceLink
        ref.display
    else
        format_reference(entry, first_use)
    end

    if Documenter.anchor_exists(anchors, key)
        anchor = Documenter.anchor(anchors, key)
        expanded_node = MarkdownAST.copy_tree(node)
        path = relpath(anchor.file, dirname(page.build))
        expanded_node.element.destination = string(path, Documenter.anchor_fragment(anchor))
        # replace display text
        empty!(expanded_node.children)
        for child in _mdparse_span(display)
            push!(expanded_node.children, child)
        end
        return expanded_node
    else
        @debug "No glossary anchor for key=$(repr(key)); rendering as plain text"
        return _mdparse_span(display)
    end
end

function _is_latex_writer(doc::Documenter.Document)
    return any(f -> f isa Documenter.LaTeX, doc.user.format)
end
