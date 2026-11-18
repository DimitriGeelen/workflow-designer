// T-1093 feasibility spike (inception evidence, NOT product code). Node 22, no dependencies.
//
// Question (IW-2): can the formats the operator asked for be written and read with what a browser already has,
// inside one HTML file, and at what size cost? Excel (.xlsx), Word (.docx) and Visio (.vsdx) are ZIP packages of
// XML, so the core is a tiny ZIP writer/reader built on CompressionStream / DecompressionStream('deflate-raw'),
// which Node 22 and every current browser ship. Mermaid and CSV are plain text.
//
// Input: one real corpus map (arc-lifecycle.bpmn), reduced to the model every exporter needs: steps (id, name,
// type, lane) and flows (from, to, label). The designer would build this from `state`; the spike reads the BPMN
// with regular expressions only because Node has no DOMParser.
//
// Output (into argv[2]): steps.xlsx, process.docx, process.vsdx, process.mmd, steps.csv, sizes.json, and the
// re-read results of our own reader (xlsx and mermaid), so the independent checks (openpyxl, python-docx,
// LibreOffice) can be compared with them.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';

const OUT = process.argv[2] || '/tmp/t1093-spike';
mkdirSync(OUT, { recursive: true });
const SRC = 'examples/aef-processes/rendered/arc-lifecycle.bpmn';
const xml = readFileSync(SRC, 'utf8');

// ── the model ──
const TYPES = ['startEvent', 'endEvent', 'task', 'userTask', 'serviceTask', 'scriptTask', 'exclusiveGateway', 'parallelGateway'];
const steps = [];
for (const t of TYPES) {
  for (const m of xml.matchAll(new RegExp(`<bpmn:${t}\\b([^>]*)>`, 'g'))) {
    const at = k => (m[1].match(new RegExp(`\\b${k}="([^"]*)"`)) || [])[1] || '';
    steps.push({ id: at('id'), name: at('name').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"'), type: t, lane: '' });
  }
}
for (const lm of xml.matchAll(/<bpmn:lane\b[^>]*\bname="([^"]*)"[^>]*>([\s\S]*?)<\/bpmn:lane>/g)) {
  for (const r of lm[2].matchAll(/<bpmn:flowNodeRef>([^<]+)<\/bpmn:flowNodeRef>/g)) {
    const s = steps.find(x => x.id === r[1]); if (s) s.lane = lm[1];
  }
}
const flows = [...xml.matchAll(/<bpmn:sequenceFlow\b([^>]*)>/g)].map(m => {
  const a = k => (m[1].match(new RegExp(`\\b${k}="([^"]*)"`)) || [])[1] || '';
  return { id: a('id'), from: a('sourceRef'), to: a('targetRef'), label: a('name') };
});

// ── ZIP (stored or deflate-raw), the shared core of xlsx/docx/vsdx ──
const CRC = new Uint32Array(256).map((_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
const crc32 = b => { let c = 0xFFFFFFFF; for (const x of b) c = CRC[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; };
async function pipe(bytes, stream) { return new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(stream)).arrayBuffer()); }
async function zip(files, deflate = true) {
  const enc = new TextEncoder(), parts = [], central = []; let off = 0;
  for (const [name, text] of files) {
    const raw = enc.encode(text), nm = enc.encode(name), crc = crc32(raw);
    const data = deflate ? await pipe(raw, new CompressionStream('deflate-raw')) : raw, method = deflate ? 8 : 0;
    const lh = new DataView(new ArrayBuffer(30));
    lh.setUint32(0, 0x04034b50, true); lh.setUint16(4, 20, true); lh.setUint16(8, method, true);
    lh.setUint32(14, crc, true); lh.setUint32(18, data.length, true); lh.setUint32(22, raw.length, true); lh.setUint16(26, nm.length, true);
    parts.push(new Uint8Array(lh.buffer), nm, data);
    const ch = new DataView(new ArrayBuffer(46));
    ch.setUint32(0, 0x02014b50, true); ch.setUint16(4, 20, true); ch.setUint16(6, 20, true); ch.setUint16(10, method, true);
    ch.setUint32(16, crc, true); ch.setUint32(20, data.length, true); ch.setUint32(24, raw.length, true); ch.setUint16(28, nm.length, true); ch.setUint32(42, off, true);
    central.push(new Uint8Array(ch.buffer), nm);
    off += 30 + nm.length + data.length;
  }
  const csize = central.reduce((n, p) => n + p.length, 0), end = new DataView(new ArrayBuffer(22));
  end.setUint32(0, 0x06054b50, true); end.setUint16(8, files.length, true); end.setUint16(10, files.length, true);
  end.setUint32(12, csize, true); end.setUint32(16, off, true);
  return new Uint8Array(await new Blob([...parts, ...central, new Uint8Array(end.buffer)]).arrayBuffer());
}
async function unzip(u8) {   // central-directory reader: what import of xlsx/vsdx needs
  const dv = new DataView(u8.buffer, u8.byteOffset, u8.byteLength), out = {}, dec = new TextDecoder();
  let e = u8.length - 22; while (dv.getUint32(e, true) !== 0x06054b50) e--;
  let p = dv.getUint32(e + 16, true);
  for (let i = 0; i < dv.getUint16(e + 10, true); i++) {
    const method = dv.getUint16(p + 10, true), csz = dv.getUint32(p + 20, true), nl = dv.getUint16(p + 28, true);
    const xl = dv.getUint16(p + 30, true), cl = dv.getUint16(p + 32, true), lo = dv.getUint32(p + 42, true);
    const name = dec.decode(u8.subarray(p + 46, p + 46 + nl));
    const ds = lo + 30 + dv.getUint16(lo + 26, true) + dv.getUint16(lo + 28, true), data = u8.subarray(ds, ds + csz);
    out[name] = dec.decode(method === 8 ? await pipe(data, new DecompressionStream('deflate-raw')) : data);
    p += 46 + nl + xl + cl;
  }
  return out;
}
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const next = id => flows.filter(f => f.from === id).map(f => f.to + (f.label ? ` [${f.label}]` : '')).join(', ');
const ROWS = [['id', 'name', 'type', 'lane', 'next'], ...steps.map(s => [s.id, s.name, s.type, s.lane, next(s.id)])];

// ── Excel ──
const colL = i => String.fromCharCode(65 + i);
const sheet = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>${
  ROWS.map((r, ri) => `<row r="${ri + 1}">${r.map((v, ci) => `<c r="${colL(ci)}${ri + 1}" t="inlineStr"><is><t xml:space="preserve">${esc(v)}</t></is></c>`).join('')}</row>`).join('')}</sheetData></worksheet>`;
const XLSX = [
  ['[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>'],
  ['_rels/.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'],
  ['xl/workbook.xml', '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Steps" sheetId="1" r:id="rId1"/></sheets></workbook>'],
  ['xl/_rels/workbook.xml.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'],
  ['xl/worksheets/sheet1.xml', sheet],
];

// ── Word: a heading, one paragraph per lane, and the steps table ──
const wp = t => `<w:p><w:r><w:t xml:space="preserve">${esc(t)}</w:t></w:r></w:p>`;
// w:tblGrid is required by the schema (python-docx refused the table without it; LibreOffice was lenient).
const wtable = `<w:tbl><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="4"/><w:bottom w:val="single" w:sz="4"/><w:insideH w:val="single" w:sz="4"/></w:tblBorders></w:tblPr><w:tblGrid>${ROWS[0].map(() => '<w:gridCol w:w="1800"/>').join('')}</w:tblGrid>${
  ROWS.map(r => `<w:tr>${r.map(v => `<w:tc>${wp(v)}</w:tc>`).join('')}</w:tr>`).join('')}</w:tbl>`;
const DOCX = [
  ['[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>'],
  ['_rels/.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'],
  ['word/document.xml', `<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>${wp('Process: arc-lifecycle')}${wp(`${steps.length} steps, ${flows.length} flows`)}${wtable}</w:body></w:document>`],
];

// ── Visio: one rectangle per step at a grid position, one connector per flow ──
const pos = new Map(steps.map((s, i) => [s.id, { x: 1 + (i % 5) * 2, y: 8 - Math.floor(i / 5) * 1.5 }]));
const shapeId = new Map(steps.map((s, i) => [s.id, i + 1]));
let sid = steps.length;
const vshapes = steps.map(s => {
  const p = pos.get(s.id);
  return `<Shape ID="${shapeId.get(s.id)}" Type="Shape"><Cell N="PinX" V="${p.x}"/><Cell N="PinY" V="${p.y}"/><Cell N="Width" V="1.5"/><Cell N="Height" V="0.75"/><Cell N="LocPinX" V="0.75" F="Width*0.5"/><Cell N="LocPinY" V="0.375" F="Height*0.5"/><Section N="Geometry" IX="0"><Row T="RelMoveTo" IX="1"><Cell N="X" V="0"/><Cell N="Y" V="0"/></Row><Row T="RelLineTo" IX="2"><Cell N="X" V="1"/><Cell N="Y" V="0"/></Row><Row T="RelLineTo" IX="3"><Cell N="X" V="1"/><Cell N="Y" V="1"/></Row><Row T="RelLineTo" IX="4"><Cell N="X" V="0"/><Cell N="Y" V="1"/></Row><Row T="RelLineTo" IX="5"><Cell N="X" V="0"/><Cell N="Y" V="0"/></Row></Section><Text>${esc(s.name || s.id)}</Text></Shape>`;
});
const vconns = [], connects = [];
for (const f of flows) {
  const a = pos.get(f.from), b = pos.get(f.to); if (!a || !b) continue;
  const id = ++sid;
  vconns.push(`<Shape ID="${id}" Type="Shape"><Cell N="BeginX" V="${a.x}"/><Cell N="BeginY" V="${a.y}"/><Cell N="EndX" V="${b.x}"/><Cell N="EndY" V="${b.y}"/><Cell N="PinX" V="${(a.x + b.x) / 2}" F="(BeginX+EndX)/2"/><Cell N="PinY" V="${(a.y + b.y) / 2}" F="(BeginY+EndY)/2"/><Cell N="Width" V="${Math.hypot(b.x - a.x, b.y - a.y)}"/><Cell N="Height" V="0"/><Cell N="ObjType" V="2"/><Section N="Geometry" IX="0"><Row T="MoveTo" IX="1"><Cell N="X" V="0"/><Cell N="Y" V="0"/></Row><Row T="LineTo" IX="2"><Cell N="X" V="${Math.hypot(b.x - a.x, b.y - a.y)}"/><Cell N="Y" V="0"/></Row></Section>${f.label ? `<Text>${esc(f.label)}</Text>` : ''}</Shape>`);
  connects.push(`<Connect FromSheet="${id}" FromCell="BeginX" ToSheet="${shapeId.get(f.from)}"/><Connect FromSheet="${id}" FromCell="EndX" ToSheet="${shapeId.get(f.to)}"/>`);
}
const VSDX = [
  ['[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/visio/document.xml" ContentType="application/vnd.ms-visio.drawing.main+xml"/><Override PartName="/visio/pages/pages.xml" ContentType="application/vnd.ms-visio.pages+xml"/><Override PartName="/visio/pages/page1.xml" ContentType="application/vnd.ms-visio.page+xml"/></Types>'],
  ['_rels/.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/document" Target="visio/document.xml"/></Relationships>'],
  ['visio/document.xml', '<?xml version="1.0" encoding="UTF-8"?><VisioDocument xmlns="http://schemas.microsoft.com/office/visio/2012/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>'],
  ['visio/_rels/document.xml.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/pages" Target="pages/pages.xml"/></Relationships>'],
  ['visio/pages/pages.xml', '<?xml version="1.0" encoding="UTF-8"?><Pages xmlns="http://schemas.microsoft.com/office/visio/2012/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><Page ID="0" Name="Process"><PageSheet><Cell N="PageWidth" V="11"/><Cell N="PageHeight" V="9"/></PageSheet><Rel r:id="rId1"/></Page></Pages>'],
  ['visio/pages/_rels/pages.xml.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.microsoft.com/visio/2010/relationships/page" Target="page1.xml"/></Relationships>'],
  ['visio/pages/page1.xml', `<?xml version="1.0" encoding="UTF-8"?><PageContents xmlns="http://schemas.microsoft.com/office/visio/2012/main"><Shapes>${vshapes.join('')}${vconns.join('')}</Shapes><Connects>${connects.join('')}</Connects></PageContents>`],
];

// ── Mermaid and CSV ──
const mmShape = s => /Gateway/.test(s.type) ? `{"${s.name}"}` : /Event/.test(s.type) ? `(("${s.name}"))` : `["${s.name}"]`;
const mermaid = ['flowchart LR', ...steps.map(s => `  ${s.id}${mmShape(s)}`),
  ...flows.map(f => `  ${f.from} -->${f.label ? `|${f.label}|` : ''} ${f.to}`)].join('\n') + '\n';
const csvCell = v => /[",\n]/.test(v) ? `"${String(v).replace(/"/g, '""')}"` : v;
const csv = ROWS.map(r => r.map(csvCell).join(',')).join('\n') + '\n';

// ── write, then read back with OUR reader (the import side) ──
const sizes = {};
for (const [name, files] of [['steps.xlsx', XLSX], ['process.docx', DOCX], ['process.vsdx', VSDX]]) {
  const z = await zip(files); writeFileSync(join(OUT, name), z); sizes[name] = z.length;
}
writeFileSync(join(OUT, 'process.mmd'), mermaid); writeFileSync(join(OUT, 'steps.csv'), csv);
const back = await unzip(readFileSync(join(OUT, 'steps.xlsx')));
const xlsxRows = [...back['xl/worksheets/sheet1.xml'].matchAll(/<row[^>]*>([\s\S]*?)<\/row>/g)]
  .map(r => [...r[1].matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g)].map(t => t[1].replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&amp;/g, '&')));
const mmBack = { nodes: [...mermaid.matchAll(/^ {2}(\w+)[[({]/gm)].length, edges: [...mermaid.matchAll(/-->/g)].length };
writeFileSync(join(OUT, 'readback.json'), JSON.stringify({ steps: steps.length, flows: flows.length,
  xlsxRoundTripEqual: JSON.stringify(xlsxRows) === JSON.stringify(ROWS), xlsxRows: xlsxRows.length, mermaid: mmBack, sizes }, null, 1));
console.log(JSON.stringify({ steps: steps.length, flows: flows.length, sizes, xlsxRoundTripEqual: JSON.stringify(xlsxRows) === JSON.stringify(ROWS), mermaid: mmBack }));
