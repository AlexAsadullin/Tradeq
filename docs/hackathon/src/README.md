# Sources of the hackathon research and presentation

The two generated documents in `docs/hackathon/` are built from these sources. Edit the sources, rebuild, and
commit both the sources and the output.

## Research (`research.docx`)

`research/main.part.js` holds the Russian text as blocks (`h1`, `h2`, `p`, `list`, `table`, `fig`, `formula`);
`research/biblio.part.js` holds the bibliography (60 sources) and the appendices. `build.js` (docx-js 9)
renders them; `toc.py` inserts the table of contents with cached page numbers. Citations such as `[E1]` and
`[R5]` become clickable links to the bibliography.

```bash
cd docs/hackathon/src/research
npm install                                  # docx 9.x
python3 figures.py                           # optional: regenerates fig_*.png with matplotlib
cat main.part.js biblio.part.js > content.js
node build.js                                # writes raw.docx and heads.json
python3 toc.py r.docx                        # adds the TOC, writes r.docx
cp r.docx ../../research.docx
rm -f content.js raw.docx heads.json r.docx
```

## Presentation (`presentation.pdf`)

`deck/slides/*.html` are the 11 slides of the claude.ai Slides artifact
(https://claude.ai/artifact/6JJr5TwdM6uLMWCuy6zwEj, private), in the order of `deck/deck.json`. Each slide is a
1920×1080 `<section>` with inline styles and Russian speaker notes in `<aside>`.

```bash
cd docs/hackathon/src/deck
python3 build_pdf.py                         # needs Google Chrome; writes ../../presentation.pdf
```

The artifact is the editable master: the user edits slides there by hand. Before changing the slides, read
the artifact again and copy its `project/slides/*.html` here, so that edits made in the editor are not lost.
