module DocumenterGlossip

using Glossaries

export glossary_link_preprocessor, preprocess_glossary_links, setup_glossary
export glossary_term, glossary_html, glossary_term_with_brief, @gref

# ── Prose glossary linking: {glossary:Term} -> markdown link ────────────────

"Convert `{glossary:Term Name}` references in `content` into markdown links pointing at `glossary_path`."
function glossary_link_preprocessor(content::String; glossary_path::String="/references/glossary/")::String
    result = content
    for m in eachmatch(r"\{glossary:([^}]+)\}", content)
        term = m.captures[1]
        anchor = lowercase(replace(term, r"\s+" => "-"))
        replacement = "[`$term`]($glossary_path#$anchor)"
        result = replace(result, m.match => replacement; count=1)
    end
    return result
end

"Walk `dir_path` and rewrite every `.md` file's `{glossary:Term}` references in place."
function preprocess_glossary_links(dir_path::String; glossary_path::String="/references/glossary/")
    for (root, _, files) in walkdir(dir_path)
        for file in files
            endswith(file, ".md") || continue
            filepath = joinpath(root, file)
            content = read(filepath, String)
            modified = glossary_link_preprocessor(content; glossary_path=glossary_path)
            modified != content && write(filepath, modified)
        end
    end
end

# ── Markdown helpers for referencing glossary terms inline ──────────────────

"Build a markdown link (with optional hover `brief`) to a glossary `term`."
function glossary_term(term::String; brief::String="")
    anchor = replace(lowercase(term), " " => "-")
    title = isempty(brief) ? "" : " title=\"$brief\""
    return "[$term](@ref Glossary#$(anchor))$title"
end

"Build an HTML `<abbr>` + link (with optional hover `brief`) to a glossary `term`."
function glossary_html(term::String, brief::String="")
    anchor = replace(lowercase(term), " " => "-")
    title = isempty(brief) ? "" : " title=\"$brief\""
    return "<abbr$(title)><a href=\"#$(anchor)\">$term</a></abbr>"
end

"Macro form of [`glossary_term`](@ref) for use inline in docstrings/markdown."
macro gref(term)
    return esc(glossary_term(term))
end

"Look up `term` in `briefs` and build a [`glossary_term`](@ref) link with that hover text."
function glossary_term_with_brief(term::String, briefs::AbstractDict{String,String})
    return glossary_term(term; brief=get(briefs, term, ""))
end

# ── Unified setup: prose links, alongside Glossaries.jl docstring terms ──────
#
# `Glossaries.@Glossary()` must be written inside the *target* module itself
# (it binds `current_glossary` there) - see Qritical's CLAUDE.md conventions.
# It can't be invoked generically on a `Module` argument from here, so this
# package only automates the prose-link half; call `Glossaries.@Glossary()`
# yourself in each module that needs docstring term interpolation.

"""
    setup_glossary(src_dir::String; glossary_path="/references/glossary/")

Call once from a package's `docs/make.jl` before `makedocs`: rewrites
`{glossary:Term}` prose references under `src_dir` into markdown links.
"""
function setup_glossary(src_dir::String; glossary_path::String="/references/glossary/")
    preprocess_glossary_links(src_dir; glossary_path=glossary_path)
    return nothing
end

end # module
