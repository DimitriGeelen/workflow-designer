#!/usr/bin/env node
// _save-api-verify.mjs — hermetic integration check for the B2 save sidecar (T-129).
// Spawns tools/gallery-serve.py against a TEMP repo+docroot (never the real repo),
// exercises every /api/* endpoint, asserts, tears down. No browser involved.
// Exit 0 = all pass. Safe to run from the P-011 verification gate.
import { spawn } from 'node:child_process';
import { mkdtempSync, existsSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import net from 'node:net';

const HERE = dirname(fileURLToPath(import.meta.url));
const SERVER = join(HERE, 'gallery-serve.py');
const sleep = ms => new Promise(r => setTimeout(r, ms));

const BPMN1 = `<?xml version="1.0"?><definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL"><process id="p"><task id="a"/></process></definitions>`;
const BPMN2 = BPMN1.replace('<task id="a"/>', '<task id="a"/><task id="b"/>');
// 1x1 transparent PNG
const PNG = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

function freePort() {
  return new Promise((res, rej) => {
    const s = net.createServer();
    s.listen(0, '127.0.0.1', () => { const p = s.address().port; s.close(() => res(p)); });
    s.on('error', rej);
  });
}
async function j(method, url, body) {
  const opt = { method };
  if (body !== undefined) { opt.body = JSON.stringify(body); opt.headers = { 'Content-Type': 'application/json' }; }
  const r = await fetch(url, opt);
  const ct = r.headers.get('content-type') || '';
  const data = ct.includes('json') ? await r.json() : await r.text();
  return { status: r.status, data, ct };
}

const results = [];
const check = (name, cond, got) => { results.push({ name, pass: !!cond, got }); };

async function main() {
  const repo = mkdtempSync(join(tmpdir(), 'saveapi-repo-'));
  const doc = mkdtempSync(join(tmpdir(), 'saveapi-doc-'));
  const port = await freePort();
  const proc = spawn('python3', [SERVER, String(port), '--repo', repo, '--docroot', doc, '--bind', '127.0.0.1'], { stdio: ['ignore', 'ignore', 'pipe'] });
  let stderr = ''; proc.stderr.on('data', d => stderr += d.toString());
  const BASE = `http://127.0.0.1:${port}`;
  try {
    // wait for health
    let up = false;
    for (let i = 0; i < 60; i++) {
      try { const h = await j('GET', BASE + '/api/health'); if (h.status === 200 && h.data.ok) { up = true; break; } } catch (_) {}
      await sleep(100);
    }
    check('health-up', up);
    if (!up) throw new Error('server did not come up:\n' + stderr.slice(-500));

    // empty versions
    const v0 = await j('GET', BASE + '/api/versions?id=test-map');
    check('empty-versions', v0.status === 200 && Array.isArray(v0.data) && v0.data.length === 0, v0.data);

    // save v1
    const s1 = await j('POST', BASE + '/api/save', { id: 'test-map', bpmn: BPMN1, png: PNG, note: 'first' });
    check('save-v1', s1.status === 200 && s1.data.ok && s1.data.v === 1, s1.data);

    // files written
    check('canonical-written', existsSync(join(repo, 'examples/aef-processes/rendered/test-map.bpmn')));
    check('snapshot-written', existsSync(join(repo, '.editor-versions/test-map/v1.bpmn')));
    check('thumb-written', existsSync(join(repo, '.editor-versions/test-map/v1.png')));
    check('index-written', existsSync(join(repo, '.editor-versions/test-map/index.json')));

    // round-trip: GET version 1 returns same bytes
    const g1 = await j('GET', BASE + '/api/version?id=test-map&v=1');
    check('version-roundtrip', g1.status === 200 && g1.data === BPMN1, g1.data === BPMN1 ? 'exact' : g1.data);

    // thumb bytes are a PNG
    const tr = await fetch(BASE + '/api/thumb?id=test-map&v=1');
    const tb = Buffer.from(await tr.arrayBuffer());
    check('thumb-is-png', tr.status === 200 && tb[0] === 0x89 && tb[1] === 0x50, { status: tr.status, sig: tb.slice(0, 4).toString('hex') });

    // save v2 increments
    const s2 = await j('POST', BASE + '/api/save', { id: 'test-map', bpmn: BPMN2, note: 'second' });
    check('save-v2-increments', s2.status === 200 && s2.data.v === 2, s2.data);
    const v2 = await j('GET', BASE + '/api/versions?id=test-map');
    check('versions-list-2', v2.status === 200 && v2.data.length === 2, v2.data);

    // canonical now reflects latest (v2)
    const canon = readFileSync(join(repo, 'examples/aef-processes/rendered/test-map.bpmn'), 'utf8');
    check('canonical-is-latest', canon === BPMN2);

    // path traversal rejected
    const bad1 = await j('POST', BASE + '/api/save', { id: '../evil', bpmn: BPMN1 });
    check('traversal-post-400', bad1.status === 400, bad1.status);
    const bad2 = await j('GET', BASE + '/api/version?id=..%2Fevil&v=1');
    check('traversal-get-400', bad2.status === 400, bad2.status);

    // empty bpmn rejected
    const bad3 = await j('POST', BASE + '/api/save', { id: 'ok-id', bpmn: '' });
    check('empty-bpmn-400', bad3.status === 400, bad3.status);

    const pass = results.every(r => r.pass);
    process.stdout.write(JSON.stringify({ pass, results }, null, 2) + '\n');
    process.exitCode = pass ? 0 : 1;
  } catch (e) {
    process.stdout.write(JSON.stringify({ pass: false, error: String(e && e.stack || e), results }, null, 2) + '\n');
    process.exitCode = 1;
  } finally {
    try { proc.kill('SIGKILL'); } catch (_) {}
    try { rmSync(repo, { recursive: true, force: true }); } catch (_) {}
    try { rmSync(doc, { recursive: true, force: true }); } catch (_) {}
  }
}
main();
