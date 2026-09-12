# Glossary entry parsing
#
# Glossary entries are authored as bib2gls-style `.bib` records: `@entry{...}`,
# `@abbreviation{...}`, `@symbol{...}`, `@index{...}`. These are valid BibTeX
# syntax with custom entry types, so we reuse `Bibliography.jl` (the same
# parser DocumenterCitations.jl uses for citation `.bib` files) to read them.

"""Category of a [`GlossaryEntry`](@ref), derived from its bib2gls entry type.

One of `:entry`, `:abbreviation`, `:symbol`, or `:index`.
"""
const GlossaryCategory = Symbol

function _category_from_bibtype(bibtype::AbstractString)::GlossaryCategory
    t = lowercase(bibtype)
    if t in ("entry", "glossaryentry")
        return :entry
    elseif t in ("abbreviation", "abbr")
        return :abbreviation
    elseif t == "symbol"
        return :symbol
    elseif t == "index"
        return :index
    else
        @warn "Unknown bib2gls entry type $(repr(bibtype)); treating as :entry"
        return :entry
    end
end

"""A single glossary/abbreviation/symbol entry, parsed from a bib2gls-style `.bib` record.

# Fields

* `key`: the entry's citation-like key (the BibTeX id)
* `category`: one of `:entry`, `:abbreviation`, `:symbol`, `:index` — derived
  from the bib2gls entry type (`@entry`, `@abbreviation`, `@symbol`, `@index`)
* `fields`: dict of bib2gls fields such as `name`, `description`, `long`,
  `short`, `plural`, `symbol`
"""
struct GlossaryEntry
    key::String
    category::GlossaryCategory
    fields::Dict{String,String}
end

function GlossaryEntry(entry::Bibliography.Entry)
    key = replace(entry.id, "*" => "_")
    category = _category_from_bibtype(entry.type)
    return GlossaryEntry(key, category, entry.fields)
end

Base.getindex(e::GlossaryEntry, field::AbstractString) = e.fields[field]
Base.get(e::GlossaryEntry, field::AbstractString, default) = get(e.fields, field, default)
Base.haskey(e::GlossaryEntry, field::AbstractString) = haskey(e.fields, field)

"""Name/title used to refer to the entry: `name` field, falling back to `long` then `key`."""
function entry_name(e::GlossaryEntry)
    return get(e, "name", get(e, "long", e.key))
end

"""Long form (for abbreviations): `long` field, falling back to `name`/`key`."""
function entry_long(e::GlossaryEntry)
    return get(e, "long", entry_name(e))
end

"""Short form (for abbreviations): `short` field, falling back to `key`."""
function entry_short(e::GlossaryEntry)
    return get(e, "short", e.key)
end

"""Description/definition text for the entry."""
function entry_description(e::GlossaryEntry)
    return get(e, "description", "")
end

"""Parse a bib2gls-style `.bib` resource file into an ordered dict of `key => GlossaryEntry`."""
function parse_glossary_bibfile(bibfile::AbstractString)
    if !isfile(bibfile)
        error("bibfile $(repr(bibfile)) does not exist")
    end
    raw_entries = Bibliography.import_bibtex(bibfile; check=:none)
    entries = OrderedDict{String,GlossaryEntry}()
    for (bibkey, entry) in raw_entries
        key = replace(bibkey, "*" => "_")
        if haskey(entries, key)
            error(
                "Ambiguous key $(repr(bibkey)) in $bibfile. GlossBibPlugin cannot distinguish between `*` and `_` in keys."
            )
        end
        entries[key] = GlossaryEntry(entry)
    end
    return entries
end
