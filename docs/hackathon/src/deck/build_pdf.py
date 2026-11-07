"""Render the hackathon deck to docs/hackathon/presentation.pdf with headless Chrome.

The slides are the same HTML files as the claude.ai Slides artifact (project/slides/*.html). There the
images are served from /_blob/<id>; here they are mapped to the local copies in img/.

Usage (from this folder):  python3 build_pdf.py
"""

import json
import pathlib
import re
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent.parent / "presentation.pdf"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Artifact asset id -> local image file
BLOBS = {
    "31440b1e6b8c9718bdc1b989b25a5034": "img/fig_architecture.png",
    "5985d84cec7f94bb4398755f567d41bf": "img/fig_fills.png",
    "0c9ac6291fa256b3958eefb2cbd4c636": "img/fig_trials.png",
    "a1564abc064801be655e2f5e8c5b1bd0": "img/terminal-trade.png",
    "234c2e4952fa5c96db95afae9b2a027f": "img/qr.png",
    "6473e5a5556f3bac249a8af56ce1668a": "img/photo-demidanov.png",
    "ff3f6dfaec9c6b6bf7b71d4342da970a": "img/photo-asadullin.jpg",
}

CSS = (
    "<style>@page{size:1920px 1080px;margin:0}html,body{margin:0;padding:0}"
    "section{position:relative;width:1920px;height:1080px;box-sizing:border-box;overflow:hidden;"
    "page-break-after:always;break-after:page;hyphens:manual}*{margin:0;box-sizing:border-box}"
    "aside{display:none}table{border-collapse:collapse;width:100%}td,th{padding:14px 18px;text-align:left}"
    "img{display:block}</style>"
)
FONTS = (
    '<link href="https://fonts.googleapis.com/css2?family=Manrope:wght@400..800'
    '&family=IBM+Plex+Sans:wght@400;600&display=swap" rel="stylesheet">'
)


def main() -> None:
    order = json.loads((HERE / "deck.json").read_text())["order"]
    body = "".join((HERE / "slides" / f"{s}.html").read_text() for s in order)
    body = re.sub(r"/_blob/(\w+)", lambda m: BLOBS[m.group(1)], body)
    page = HERE / "deck.html"
    page.write_text(f'<!doctype html><html lang="ru"><meta charset="utf-8">{FONTS}{CSS}<body>{body}</body></html>')
    subprocess.run(
        [CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--virtual-time-budget=10000",
         f"--print-to-pdf={OUT}", page.as_uri()],
        check=True, capture_output=True,
    )
    page.unlink()
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
