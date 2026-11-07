const fs = require("fs");
const d = require("docx");
const C = require("./content.js");
const FONT = "Arial";
const W = 9638; // A4 text width with 2 cm margins (DXA)

const num = Object.fromEntries(C.sources.map(([id], i) => [id, i + 1])); // E1 -> 12, ... (bibliography order)
const heads = [];
let chars = 0;

// Text with clickable citations: "[E1, R5]" -> "[12, 5]", each number linking to its bibliography entry.
function runs(text, size = 22) {
  const out = [];
  let last = 0;
  for (const m of text.matchAll(/\[([ERC]\d+(?:,\s*[ERC]\d+)*)\]/g)) {
    if (m.index > last) out.push(new d.TextRun({ text: text.slice(last, m.index), font: FONT, size }));
    out.push(new d.TextRun({ text: "[", font: FONT, size }));
    m[1].split(/,\s*/).forEach((id, i) => {
      if (!(id in num)) throw new Error(`unknown source ${id}`);
      if (i) out.push(new d.TextRun({ text: ", ", font: FONT, size }));
      out.push(new d.InternalHyperlink({ anchor: `src_${id}`, children: [new d.TextRun({ text: String(num[id]), style: "Hyperlink", font: FONT, size })] }));
    });
    out.push(new d.TextRun({ text: "]", font: FONT, size }));
    last = m.index + m[0].length;
  }
  if (last < text.length) out.push(new d.TextRun({ text: text.slice(last), font: FONT, size }));
  return out;
}

const para = (text) => {
  chars += text.length;
  return new d.Paragraph({ spacing: { after: 120, line: 300 }, alignment: d.AlignmentType.JUSTIFIED, children: runs(text) });
};

function heading(level, text, pageBreak = false) {
  const id = `_Toc_${heads.length + 1}`;
  if (pageBreak) chars = Math.ceil(chars / 3000) * 3000;
  heads.push({ level, text, id, chars });
  chars += 400;
  return new d.Paragraph({
    heading: level === 1 ? d.HeadingLevel.HEADING_1 : d.HeadingLevel.HEADING_2,
    pageBreakBefore: pageBreak,
    children: [new d.Bookmark({ id, children: [new d.TextRun({ text, font: FONT })] })],
  });
}

const WIDTHS = { 2: [4300, 5338], 3: [3000, 3000, 3638], 4: [3238, 2133, 2133, 2134], 5: [2438, 1800, 1800, 1800, 1800] };

function figure(file, caption) {
  const buf = fs.readFileSync(file);
  const w = buf.readUInt32BE(16), h = buf.readUInt32BE(20);
  const width = 620, height = Math.round((h / w) * width);
  chars += Math.round(height * 5);
  return [
    new d.Paragraph({ alignment: d.AlignmentType.CENTER, spacing: { before: 120 }, keepNext: true,
      children: [new d.ImageRun({ type: "png", data: buf, transformation: { width, height } })] }),
    new d.Paragraph({ alignment: d.AlignmentType.CENTER, spacing: { after: 200 },
      children: [new d.TextRun({ text: caption, font: FONT, size: 20, italics: true })] }),
  ];
}

const formula = (text) => {
  chars += 120;
  return new d.Paragraph({ alignment: d.AlignmentType.CENTER, spacing: { before: 80, after: 160 },
    children: [new d.TextRun({ text, font: "Cambria Math", size: 22, italics: true })] });
};

function table(header, rows) {
  const widths = WIDTHS[header.length];
  const cell = (text, i, head) =>
    new d.TableCell({
      width: { size: widths[i], type: d.WidthType.DXA },
      shading: head ? { type: d.ShadingType.CLEAR, color: "auto", fill: "DCE6F2" } : undefined,
      margins: { top: 60, bottom: 60, left: 100, right: 100 },
      children: [new d.Paragraph({ children: head ? [new d.TextRun({ text, font: FONT, size: 20, bold: true })] : runs(text, 20) })],
    });
  for (const r of rows) chars += r.join(" ").length + 60;
  return new d.Table({
    width: { size: W, type: d.WidthType.DXA },
    columnWidths: widths,
    rows: [
      new d.TableRow({ tableHeader: true, children: header.map((h, i) => cell(h, i, true)) }),
      ...rows.map((r) => new d.TableRow({ children: r.map((t, i) => cell(t, i, false)) })),
    ],
  });
}

const body = [];
let listNo = 0;
for (const [type, a, b] of C.blocks) {
  if (type === "h1") body.push(heading(1, a, true));
  else if (type === "h2") body.push(heading(2, a));
  else if (type === "p") body.push(para(a));
  else if (type === "list") {
    listNo += 1; // each list restarts its numbering
    for (const item of a) {
      chars += item.length;
      body.push(new d.Paragraph({ numbering: { reference: "tasks", level: 0, instance: listNo }, spacing: { after: 80, line: 300 }, alignment: d.AlignmentType.JUSTIFIED, children: runs(item) }));
    }
  }
  else if (type === "table") { body.push(table(a, b)); body.push(new d.Paragraph({ children: [] })); }
  else if (type === "fig") body.push(...figure(a, b));
  else if (type === "formula") body.push(formula(a));
}

body.push(heading(1, "Список литературы", true));
C.sources.forEach(([id, text, url]) => {
  chars += text.length + url.length + 40;
  body.push(new d.Paragraph({
    numbering: { reference: "biblio", level: 0 },
    spacing: { after: 80 },
    children: [
      new d.Bookmark({ id: `src_${id}`, children: [new d.TextRun({ text: `${text}. URL: `, font: FONT, size: 20 })] }),
      new d.ExternalHyperlink({ link: url, children: [new d.TextRun({ text: url, style: "Hyperlink", font: FONT, size: 20 })] }),
      new d.TextRun({ text: ` (дата обращения: ${C.accessed}).`, font: FONT, size: 20 }),
    ],
  }));
});

for (const [title, header, rows] of C.appendices) {
  body.push(heading(1, title, true));
  body.push(table(header, rows));
}

const children = [
  new d.Paragraph({ heading: d.HeadingLevel.TITLE, children: [new d.TextRun({ text: C.title, font: FONT })] }),
  new d.Paragraph({ spacing: { after: 120 }, children: [new d.TextRun({ text: C.subtitle, font: FONT, size: 26, italics: true })] }),
  new d.Paragraph({ spacing: { after: 240 }, children: [new d.TextRun({ text: C.meta, font: FONT, size: 20, color: "666666" })] }),
  new d.Paragraph({ spacing: { after: 160 }, children: [new d.TextRun({ text: "Содержание", font: FONT, size: 30, bold: true, color: "1F3864" })] }),
  new d.Paragraph({ children: [new d.TextRun({ text: "TOC_PLACEHOLDER" })] }),
  ...body,
];

const numberedList = (reference) => ({
  reference,
  levels: [{ level: 0, format: d.LevelFormat.DECIMAL, text: "%1.", alignment: d.AlignmentType.LEFT, style: { paragraph: { indent: { left: 567, hanging: 425 } }, run: { font: FONT } } }],
});

const doc = new d.Document({
  creator: "Tradeq",
  title: C.title,
  features: { updateFields: true },
  numbering: { config: [numberedList("tasks"), numberedList("biblio")] },
  styles: {
    default: { document: { run: { font: FONT, size: 22 } } },
    paragraphStyles: [
      { id: "Title", name: "Title", basedOn: "Normal", run: { font: FONT, size: 40, bold: true, color: "1F3864" }, paragraph: { spacing: { before: 0, after: 160 }, keepNext: true } },
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true, run: { font: FONT, size: 30, bold: true, color: "1F3864" }, paragraph: { spacing: { before: 0, after: 160 }, keepNext: true, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true, run: { font: FONT, size: 25, bold: true, color: "2E5597" }, paragraph: { spacing: { before: 200, after: 100 }, keepNext: true, outlineLevel: 1 } },
    ],
  },
  sections: [{
    properties: { page: { margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
    footers: { default: new d.Footer({ children: [new d.Paragraph({ alignment: d.AlignmentType.CENTER, children: [new d.TextRun({ children: [d.PageNumber.CURRENT], font: FONT, size: 18 })] })] }) },
    children,
  }],
});

d.Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync("raw.docx", buf);
  const perPage = 3000;
  const tocPages = Math.ceil(heads.length / 34);
  fs.writeFileSync("heads.json", JSON.stringify(heads.map((h) => ({ ...h, page: tocPages + 1 + Math.floor(h.chars / perPage) }))));
  console.log("raw written, headings", heads.length);
});
