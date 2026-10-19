#!/usr/bin/env node
// T-1216 stand-in for tools/_t570-meta-carriage-cdp.mjs: every leg PASSes on the real source and every leg FAILs on
// any other file, including `reproduce-drop`, which no mutant can touch. That is the broken-measurement shape seen
// under load, and _t570-meta-carriage-teeth.py must answer it with COULD NOT MEASURE (exit 3), not FAIL (exit 1).
import { resolve } from 'node:path';

const LEGS = ['reproduce-drop', 'carriage-roundtrip', 'carried-escaping', 'no-acquisition',
  'no-double-emit', 'structured-untouched', 'scalar-emits-survives', 'deterministic-order'];
const i = process.argv.indexOf('--src');
const src = i > -1 ? resolve(process.argv[i + 1]) : '';
const real = resolve(new URL('../../../src/aef-workflow-designer.html', import.meta.url).pathname);
const verdict = src === real ? 'PASS' : 'FAIL';
for (const leg of LEGS) console.log(`${verdict}  ${leg} — stand-in`);
process.exitCode = verdict === 'PASS' ? 0 : 1;
