#!/usr/bin/env node
// _t1134-portal-without-endpoints-cdp.mjs — T-1134: on a project server shaped like a third-party portal — it answers
// /api/health, /api/list and /api/save but NOT /api/field-profile or /api/field-suggestions (plain HTML 404, 403 on
// PUT; Greenfield's portal, DM 73) — the designer must not offer field settings or suggestions:
//   A  the field-profile status is 'unsupported' and the Settings readout says the server does not offer them
//   B  Settings -> "Fields shown by default": every row disabled, Save disabled, the map scope not offered, and the
//      status line says why
//   C  "Suggest as a field" is disabled with the reason
//   D  the panel itself still works: empty fields fold (B1 behaviour, designer default)
//   node tools/_t1134-portal-without-endpoints-cdp.mjs [--designer PATH]   (0.19.0 must FAIL A and B)
// Exit 0 = pass; 1 = assertion failed; 2 = misconfig.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, readdirSync, copyFileSync, writeFileSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';
import { pageWsUrl } from './_cdp-attach.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, '..');
const argv = process.argv.slice(2);
const DESIGNER = (argv.indexOf('--designer') >= 0 && argv[argv.indexOf('--designer') + 1]) || join(REPO, 'src', 'aef-workflow-designer.html');
const sleep = ms => new Promise(r => setTimeout(r, ms));

// The portal: health / list / save only; every other /api path is an HTML 404, PUT is a 403.
const STUB = `
import http.server, json, sys, os
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
    def _send(self, code, body, ct):
        b = body.encode(); self.send_response(code); self.send_header('Content-Type', ct)
        self.send_header('Content-Length', str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        if self.path.startswith('/api/health'): return self._send(200, json.dumps({'ok': True}), 'application/json')
        if self.path.startswith('/api/list'): return self._send(200, json.dumps({'maps': [], 'ghosts': []}), 'application/json')
        if self.path.startswith('/api/'): return self._send(404, '<html><body>Not Found</body></html>', 'text/html')
        return super().do_GET()
    def do_POST(self):
        if self.path.startswith('/api/save'): return self._send(200, json.dumps({'ok': True, 'v': 1}), 'application/json')
        return self._send(404, '<html><body>Not Found</body></html>', 'text/html')
    def do_PUT(self): return self._send(403, '<html><body>Forbidden</body></html>', 'text/html')
os.chdir(sys.argv[2])
http.server.ThreadingHTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
`;

function findChrome() { const cache = join(homedir(), '.cache', 'ms-playwright'); const c = []; if (existsSync(cache)) for (const d of readdirSync(cache)) if (d.startsWith('chromium-')) c.push(join(cache, d, 'chrome-linux64', 'chrome')); c.sort().reverse(); for (const x of c) if (existsSync(x)) return x; throw new Error('no chromium'); }
function freePort() { return new Promise((res, rej) => { const s = net.createServer(); s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); }); s.on('error', rej); }); }
async function waitPortFile(f) { const t0 = Date.now(); while (Date.now() - t0 < 15000) { if (existsSync(f)) { const t = readFileSync(f, 'utf8').split('\n'); if (t[0] && t[0].trim()) return parseInt(t[0].trim(), 10); } await sleep(100); } throw new Error('no devtools port'); }
function cdp(ws) { const s = new WebSocket(ws); let id = 0; const p = new Map(); s.addEventListener('message', ev => { const m = JSON.parse(ev.data); if (m.id && p.has(m.id)) { p.get(m.id)(m); p.delete(m.id); } }); const ready = new Promise((res, rej) => { s.addEventListener('open', res); s.addEventListener('error', rej); }); const cmd = (me, pa = {}) => new Promise((res, rej) => { const mid = ++id; p.set(mid, m => m.error ? rej(new Error(me + ': ' + JSON.stringify(m.error))) : res(m.result)); s.send(JSON.stringify({ id: mid, method: me, params: pa })); }); return { ready, cmd, close: () => s.close() }; }
async function ev(cmd, e) { const r = await cmd('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true }); if (r.exceptionDetails) throw new Error('eval: ' + JSON.stringify(r.exceptionDetails)); return r.result.value; }
async function waitReady(cmd) { const t0 = Date.now(); for (;;) { const ok = await ev(cmd, `(typeof adoptImportedXml==='function'&&_appReady===true&&(typeof _deepLinkSettled==='undefined'||_deepLinkSettled!==null))`).catch(() => false); if (ok) return; if (Date.now() - t0 > 20000) throw new Error('editor not ready'); await sleep(150); } }

const SYN = `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" xmlns:aef="http://anchorpoint.framework/aef/extensions" id="Defs_1" targetNamespace="https://example.invalid/t1134">
  <bpmn:process id="Process_t1134" isExecutable="false">
    <bpmn:extensionElements><aef:workflowMeta id="portal-map" uuid="11111111-2222-3333-4444-666666666666" version="1" schemaVersion="2" title="portal-map"/></bpmn:extensionElements>
    <bpmn:laneSet id="LaneSet_1"><bpmn:lane id="lane_a" name="Agent"><bpmn:flowNodeRef>s1</bpmn:flowNodeRef></bpmn:lane></bpmn:laneSet>
    <bpmn:serviceTask id="s1" name="Call the service"><bpmn:extensionElements><aef:meta endpoint="svc/call" costCentre="CC-1"/></bpmn:extensionElements></bpmn:serviceTask>
  </bpmn:process>
</bpmn:definitions>`;

async function main() {
  if (!existsSync(DESIGNER)) { console.log(JSON.stringify({ ok: false, error: 'missing ' + DESIGNER })); process.exitCode = 2; return; }
  const doc = mkdtempSync(join(tmpdir(), 't1134-doc-'));
  copyFileSync(DESIGNER, join(doc, 'designer.html'));
  const stub = join(doc, '_stub.py'); writeFileSync(stub, STUB);
  const port = await freePort();
  const py = spawn('python3', [stub, String(port), doc], { stdio: ['ignore', 'ignore', 'pipe'] });
  const BASE = `http://127.0.0.1:${port}`;
  const udd = mkdtempSync(join(tmpdir(), 't1134-udd-'));
  const br = spawn(findChrome(), ['--headless=new', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage', '--window-size=1900,1000', '--remote-debugging-port=0', `--user-data-dir=${udd}`, 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
  const legs = []; const leg = (ok, name, detail) => legs.push({ ok: !!ok, name, detail });
  let cl;
  try {
    for (let i = 0; i < 60; i++) { try { const r = await fetch(BASE + '/api/health'); if (r.ok) break; } catch (_) {} await sleep(100); }
    const dp = await waitPortFile(join(udd, 'DevToolsActivePort'));
    cl = cdp(await pageWsUrl(dp)); await cl.ready; const { cmd } = cl;
    await cmd('Page.enable'); await cmd('Runtime.enable');
    await cmd('Page.addScriptToEvaluateOnNewDocument', { source: 'window.alert = function(){}; window.confirm = function(){ return true; }; try { localStorage.clear(); } catch (_) {}' });
    await cmd('Page.navigate', { url: `${BASE}/designer.html` }); await waitReady(cmd);
    // wait for the API detection and the profile load to settle
    const t0 = Date.now(); while (Date.now() - t0 < 8000) { const s = await ev(cmd, `typeof _fieldProfileStatus !== 'undefined' ? _fieldProfileStatus : 'n/a'`); if (s !== 'standalone') break; await sleep(150); }
    await sleep(300);
    await ev(cmd, `(function(){ adoptImportedXml(${JSON.stringify(SYN)}, { userImport: true }); renderAll(); return true; })()`); await sleep(200);

    // A
    const status = await ev(cmd, `({ api: _apiAvailable, status: _fieldProfileStatus })`);
    const readout = await ev(cmd, `(syncSettingsUI(), document.getElementById('set-field-profile-status').textContent)`);
    leg(status.api === true && status.status === 'unsupported' && /does not offer field settings/.test(readout),
      'A status unsupported; readout says the server does not offer field settings', { status, readout });

    // B
    await ev(cmd, `(openSettings(), true)`);
    const ui = await ev(cmd, `(function(){ var sels = document.querySelectorAll('#set-fd-rows select'); return {
      rows: sels.length, allDisabled: Array.prototype.every.call(sels, function(s){ return s.disabled; }),
      save: document.getElementById('btn-fd-save').disabled, map: document.querySelector('input[name="set-fd-scope"][value="map"]').disabled,
      text: document.getElementById('set-fd-status').textContent }; })()`);
    leg(ui.rows > 0 && ui.allDisabled && ui.save && ui.map && /does not offer field settings/.test(ui.text),
      'B Settings read-only: rows and Save disabled, no map scope, says why', ui);
    await ev(cmd, `(closeSettings(), true)`);

    // C
    await ev(cmd, `(function(){ var n = state.nodes.find(function(x){ return x.name === 'Call the service'; }); selection = { kind: 'node', id: n.uid }; multiSelect = new Set([n.uid]); renderProperties(); return true; })()`);
    await sleep(600);
    await ev(cmd, `(renderProperties(), true)`);
    const btn = await ev(cmd, `(function(){ var b = document.querySelector('#properties [data-testid="suggest-field"]'); return b ? { disabled: b.disabled, title: b.title } : null; })()`);
    leg(btn && btn.disabled && /does not offer field suggestions/.test(btn.title), 'C "Suggest as a field" disabled, says the server does not offer it', btn);

    // D
    const fold = await ev(cmd, `(function(){ var r = document.querySelector('#properties .props-empty-fields'); return r ? r.textContent : null; })()`);
    leg(fold && /empty field/.test(fold), 'D the panel still folds empty fields (designer default)', fold);
  } catch (e) {
    leg(false, 'harness', String(e && e.stack || e));
  } finally {
    try { cl && cl.close(); } catch (_) {}
    br.kill('SIGKILL'); py.kill('SIGKILL');
  }
  const ok = legs.length > 0 && legs.every(l => l.ok);
  for (const l of legs) console.log(`${l.ok ? 'ok  ' : 'FAIL'} ${l.name}${l.ok ? '' : '  ' + JSON.stringify(l.detail).slice(0, 600)}`);
  console.log(`T-1134: ${legs.filter(l => l.ok).length}/${legs.length}`);
  process.exitCode = ok ? 0 : 1;
}
main();
