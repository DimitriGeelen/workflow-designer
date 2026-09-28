#!/usr/bin/env node
// T-893 — authorityMarkerState() sliced out of the designer and run without a browser.
// Three states, decided in one pure function; this pins the partition so a fourth state or a
// collapsed one cannot enter unnoticed. Exit 0 = all cases hold; exit 1 = a case failed;
// exit 4 = the function could not be sliced (the anchor moved — fix the anchor, not the test).
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const HERE = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(HERE, '..', 'src', 'aef-workflow-designer.html'), 'utf8');
const m = /function authorityMarkerState\(own, laneDefault\) \{[\s\S]*?\n\}/.exec(html);
if (!m) { console.log('TEST BROKEN — authorityMarkerState not found in the designer'); process.exit(4); }
const authorityMarkerState = new Function(m[0] + '; return authorityMarkerState;')();
const cases = [
  // own, laneDefault, expected, why
  ['sovereignty', 'sovereignty', 'none',    'matches the default — the common case must not shout'],
  ['initiative',  'sovereignty', 'differs', 'a choice, made visible'],
  ['initiative',  null,          'none',    'own authority, no default: nothing to differ from (T-894 grammar)'],
  ['initiative',  '',            'none',    'empty default is no default'],
  [null,          'sovereignty', 'none',    'inherits the default'],
  [null,          null,          'missing', 'no authority anywhere: a hole, not a choice'],
  ['',            '',            'missing', 'empty strings are absence, not values'],
  [undefined,     undefined,     'missing', 'undefined is absence'],
];
let fail = 0;
for (const [own, def, want, why] of cases) {
  const got = authorityMarkerState(own, def);
  const ok = got === want;
  if (!ok) fail++;
  console.log(`  ${ok ? 'PASS' : 'FAIL'}  (${JSON.stringify(own)}, ${JSON.stringify(def)}) -> ${got}${ok ? '' : ' (wanted ' + want + ')'}  — ${why}`);
}
// The partition is exactly three states: enumerate every combination of present/absent/equal.
const seen = new Set();
for (const own of [null, 'a', 'b']) for (const def of [null, 'a', 'b']) seen.add(authorityMarkerState(own, def));
const states = [...seen].sort().join(',');
if (states !== 'differs,missing,none') { fail++; console.log(`  FAIL  state set is {${states}}, wanted {differs,missing,none}`); }
else console.log('  PASS  the state set is exactly {differs,missing,none}');
// effectiveLaneDefault: authoringDefault wins; legacy lane authority stands in while T-895 is
// pending; the retired 'none' sentinel is no default at all.
const m2 = /function effectiveLaneDefault\(lane\) \{[\s\S]*?\n\}/.exec(html);
if (!m2) { console.log('TEST BROKEN — effectiveLaneDefault not found in the designer'); process.exit(4); }
const effectiveLaneDefault = new Function(m2[0] + '; return effectiveLaneDefault;')();
const laneCases = [
  [{ authoringDefault: 'initiative', authority: 'sovereignty' }, 'initiative', 'authoringDefault wins over legacy authority'],
  [{ authoringDefault: null, authority: 'authority' }, 'authority', 'legacy lane authority stands in during migration'],
  [{ authoringDefault: null, authority: 'none' }, null, "the retired 'none' sentinel is no default"],
  [null, null, 'no lane (outside every lane) is no default'],
];
let lfail = 0;
for (const [lane, want, why] of laneCases) {
  const got = effectiveLaneDefault(lane);
  const ok = got === want; if (!ok) lfail++;
  console.log(`  ${ok ? 'PASS' : 'FAIL'}  effectiveLaneDefault(${JSON.stringify(lane)}) -> ${JSON.stringify(got)}  — ${why}`);
}
fail += lfail;
console.log(`PASS ${cases.length + 1 + laneCases.length - fail} / FAIL ${fail}`);
process.exit(fail ? 1 : 0);
