"""Replace the TOC placeholder with a real Word TOC field whose cached result is already filled in.

Each entry links to its heading's bookmark and carries a PAGEREF field, so the contents are clickable at once,
and Word recomputes the page numbers when it updates fields (the document asks on open).
"""
import json
import re
import shutil
import sys
import zipfile
from xml.sax.saxutils import escape

src, out = "raw.docx", sys.argv[1]
heads = json.load(open("heads.json"))

def run(text, extra=""):
    return f'<w:r><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/><w:sz w:val="22"/>{extra}</w:rPr><w:t xml:space="preserve">{escape(text)}</w:t></w:r>'

def fld(kind):
    return f'<w:r><w:fldChar w:fldCharType="{kind}"/></w:r>'

def instr(text):
    return f'<w:r><w:instrText xml:space="preserve"> {text} </w:instrText></w:r>'

def ppr(level):
    ind = 0 if level == 1 else 440
    return (f'<w:pPr><w:tabs><w:tab w:val="right" w:leader="dot" w:pos="9638"/></w:tabs>'
            f'<w:spacing w:after="60"/><w:ind w:left="{ind}"/></w:pPr>')

paras = []
for i, h in enumerate(heads):
    bold = "<w:b/>" if h["level"] == 1 else ""
    start = (fld("begin") + instr('TOC \\o "1-2" \\h \\z \\u') + fld("separate")) if i == 0 else ""
    end = fld("end") if i == len(heads) - 1 else ""
    entry = (f'<w:hyperlink w:anchor="{h["id"]}" w:history="1">'
             + run(h["text"], bold) + '<w:r><w:tab/></w:r>'
             + fld("begin") + instr(f'PAGEREF {h["id"]} \\h') + fld("separate") + run(str(h["page"])) + fld("end")
             + '</w:hyperlink>')
    paras.append(f'<w:p>{ppr(h["level"])}{start}{entry}{end}</w:p>')

with zipfile.ZipFile(src) as z:
    xml = z.read("word/document.xml").decode("utf-8")
    pattern = re.compile(r'<w:p>(?:(?!<w:p>).)*?TOC_PLACEHOLDER.*?</w:p>', re.S)
    assert pattern.search(xml), "placeholder not found"
    xml = pattern.sub(lambda _: "".join(paras), xml, count=1)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zo:
        for item in z.infolist():
            if item.filename.endswith("/"):
                continue
            data = xml.encode("utf-8") if item.filename == "word/document.xml" else z.read(item.filename)
            zo.writestr(item, data)
print("written", out, len(heads), "entries")
