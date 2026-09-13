# How to Use

This page walks through setting up GlossBib.jl in a Documenter.jl project, from
defining entries to producing both HTML and LaTeX output.

## 1. Define entries in `.bib` files

Entries are authored using bib2gls's `.bib` entry types. The type determines the entry's
**category**, not the filename — so you can group entries into separate files however makes
sense for your project (one file per category is a common convention, but not required).

```bibtex
@entry{mps,
  name        = {matrix product state},
  description = {A tensor network representation of a quantum state.}
}

@abbreviation{dmrg,
  short = {DMRG},
  long  = {density matrix renormalization group}
}

@symbol{chi,
  name   = {chi},
  symbol = {χ},
  description = {The bond dimension of a matrix product state.}
}
```

Supported entry types: `@entry` (key terms), `@abbreviation`, `@symbol`, and `@index`.

Field values are raw LaTeX source, exactly as in real bib2gls/BibTeX files — they're inserted
verbatim into both the HTML markdown pipeline and the generated `\newglossaryentry{...}`/
`\newabbreviation{...}` LaTeX definitions, never escaped for you (so a literal `%`, `&`, `_`,
`#`, `~`, or `^` character needs to be escaped by you in the `.bib` file, e.g. `50\%`, the same
way you would in any hand-written LaTeX/BibTeX source). The one exception: a `@symbol` entry's
`symbol` field is automatically wrapped in `$...$` for the LaTeX definition, since bib2gls's own
convention is that symbol entries hold math content — so `symbol = {χ}` or `symbol = {\chi}`
above renders as a properly math-italic χ in the PDF (via a math font with Greek coverage, e.g.
`unicode-math` + `\setmathfont{...}`) without needing to write `\ensuremath{}` yourself.

## 2. Register the plugin

Construct a [`GlossBibPlugin`](@ref) from one or more resource files and pass it to
`makedocs(; plugins=[...])`:

```julia
using Documenter, GlossBib

gls = GlossBibPlugin(
    joinpath(@__DIR__, "src", "terms.bib"),
    joinpath(@__DIR__, "src", "abbreviations.bib"),
    joinpath(@__DIR__, "src", "symbols.bib"),
)

makedocs(; plugins=[gls], pages=["Home" => "index.md", "How to Use" => "howto.md"])
```

## 3. Reference entries inline

Anywhere in your markdown pages or docstrings:

* `[mps](@gls)` — resolves to the entry's display form. Abbreviations show their long form on
  first use and short form on subsequent uses, matching `glossaries-extra`'s standard behavior.
* `[custom display text](@gls mps)` — resolves the `mps` key but renders your own text.

## 4. List referenced entries

Add a fenced code block wherever you want a generated list to appear:

* ` ```@glossary ``` ` — all referenced entries, across every category
* ` ```@abbreviations ``` ` — only referenced abbreviations
* ` ```@symbols ``` ` — only referenced symbols

Only entries that are actually referenced somewhere in the built documentation are listed — an
entry defined in a `.bib` file but never used with `@gls` will not appear, matching bib2gls's
"selection" behavior.

## 5. Building to LaTeX / PDF

When `makedocs` is run with `format=Documenter.LaTeX(...)`, `[key](@gls)` references are
translated to raw `glossaries-extra` macros (`\gls{key}`, `\glsxtrfull{key}`, etc.) instead of
plain text, so the PDF gets real glossary cross-references.

To get the accompanying entry definitions and back-matter lists, call
[`glossaries_extra_preamble`](@ref) after `makedocs` and wire the generated files into your
LaTeX header/preamble:

```julia
glossaries_extra_preamble(gls; output_dir=joinpath(@__DIR__, "build"))
```

This writes, per category, the entries you'll `\input` into your LaTeX header:

* `glossary-terms.tex` — `\newglossaryentry{...}` definitions for `@entry` records
* `glossary-abbreviations.tex` — `\newabbreviation{...}` definitions
* `glossary-symbols.tex` — `\newglossaryentry{...}` definitions with `type=symbols`
* `glossary-print.tex` — the three `\printunsrtglossary[type=...]` calls, one per category, for
  your document's back matter

Your LaTeX header needs `\usepackage{glossaries-extra}` plus the generated definition files
included before `\begin{document}`, and `\input{glossary-print.tex}` wherever you want the
term/abbreviation/symbol lists to appear (typically in the back matter).

## Notes

* Categories map 1:1 onto `glossaries-extra` glossary "types" (`main`, `abbreviations`,
  `symbols`), so terms, abbreviations, and symbols always render as separate lists rather than
  one merged glossary.
* No external `bib2gls`/Java tool is required — entry parsing and selection are implemented
  natively in Julia, so builds stay fast and self-contained.
