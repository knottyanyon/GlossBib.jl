# Default HTML formatting for glossary references, dispatched by category.
#
# Mirrors DocumenterCitations' `styles/*.jl` dispatch pattern
# (`format_citation`/`format_bibliography_reference` dispatched on `Val(style)`),
# but here dispatch is on the entry's `category` since bib2gls categories (not
# alternative citation styles) are what determine formatting.

"""Format the inline display text (markdown) for a `[key](@gls)` reference to `entry`.

`first_use` is `true` the first time `entry.key` is referenced anywhere in the
docs (bib2gls's defining "long form on first use, short form after" behavior
for abbreviations).
"""
function format_reference(entry::GlossaryEntry, first_use::Bool)
    return format_reference(Val(entry.category), entry, first_use)
end

function format_reference(::Val{:abbreviation}, entry::GlossaryEntry, first_use::Bool)
    long = entry_long(entry)
    short = entry_short(entry)
    return first_use ? "$long ($short)" : short
end

function format_reference(::Val{:symbol}, entry::GlossaryEntry, first_use::Bool)
    return get(entry, "symbol", entry_name(entry))
end

function format_reference(::Val{:index}, entry::GlossaryEntry, first_use::Bool)
    return entry_name(entry)
end

function format_reference(::Val{:entry}, entry::GlossaryEntry, first_use::Bool)
    return entry_name(entry)
end

# fallback for unknown categories
function format_reference(::Val{S}, entry::GlossaryEntry, first_use::Bool) where {S}
    return entry_name(entry)
end

"""Format the label shown for `entry` in a rendered ```@glossary``` block."""
function format_glossary_label(entry::GlossaryEntry)
    return format_glossary_label(Val(entry.category), entry)
end

function format_glossary_label(::Val{:abbreviation}, entry::GlossaryEntry)
    return "$(entry_long(entry)) ($(entry_short(entry)))"
end

function format_glossary_label(::Val{S}, entry::GlossaryEntry) where {S}
    return entry_name(entry)
end

"""Format the full definition (markdown) shown for `entry` in a
```@glossary``` block."""
function format_glossary_entry(entry::GlossaryEntry)
    return format_glossary_entry(Val(entry.category), entry)
end

function format_glossary_entry(::Val{S}, entry::GlossaryEntry) where {S}
    desc = entry_description(entry)
    return isempty(desc) ? entry_name(entry) : desc
end
