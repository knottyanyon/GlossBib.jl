# Collect Glossary References
#
# Runs after ExpandTemplates, so that e.g. docstrings which may contain
# `@gls` references have already been expanded, mirroring
# DocumenterCitations.jl's `CollectCitations` stage.

"""Pipeline step to collect `@gls` glossary references from all pages.

Walks all pages, looking for `@gls` links, and fills the `used_keys` and
`page_references` fields of the [`GlossBibPlugin`](@ref).
"""
abstract type CollectGlossaryReferences <: Builder.DocumentPipeline end

Selectors.order(::Type{CollectGlossaryReferences}) = 2.11  # After ExpandTemplates

function Selectors.runner(::Type{CollectGlossaryReferences}, doc::Documenter.Document)
    Documenter.is_doctest_only(doc, "CollectGlossaryReferences") && return
    @info "CollectGlossaryReferences"
    collect_glossary_references(doc)
end

function collect_glossary_references(doc::Documenter.Document)
    gls = Documenter.getplugin(doc, GlossBibPlugin)
    nav_sources = [node.page for node in doc.internal.navlist]
    other_sources = filter(src -> !(src in nav_sources), keys(doc.blueprint.pages))
    for src in Iterators.flatten([nav_sources, other_sources])
        page = doc.blueprint.pages[src]
        empty!(page.globals.meta)
        try
            _collect_glossary_references(gls, page.mdast, src, doc)
        catch exc
            #! format: off
            @error "Error collecting glossary references from $(repr(src))" exception=(exc, catch_backtrace())
            #! format: on
            push!(doc.internal.errors, :glossary_references)
        end
    end
end

function _collect_glossary_references(gls, mdast::MarkdownAST.Node, src, doc)
    for node in AbstractTrees.PreOrderDFS(mdast)
        if node.element isa Documenter.DocsNode
            for docstr in node.element.mdasts
                _collect_glossary_references(gls, docstr, src, doc)
            end
        elseif is_reference_link(node)
            collect_reference(gls, node, src, doc)
        end
    end
end

function collect_reference(gls, node::MarkdownAST.Node, src, doc)
    ref = read_reference_link(node)
    key = ref isa GlossaryReferenceLink ? ref.key : ref.key
    if haskey(gls.entries, key)
        if !haskey(gls.used_keys, key)
            gls.used_keys[key] = length(gls.used_keys) + 1
        end
        if !haskey(gls.page_references, src)
            gls.page_references[src] = Set{String}()
        end
        push!(gls.page_references[src], key)
    else
        @error "Key $(repr(key)) not found in glossary entries"
        push!(doc.internal.errors, :glossary_references)
    end
    return false
end
