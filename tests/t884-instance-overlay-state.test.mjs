#!/usr/bin/env node
// T-884 — instanceOverlayState() sliced out of the designer and run without a browser.
// Pins: current only for a NODE state on this template; done is the shortest flow path from a
// startEvent EXCLUDING current (derived, so a loop the instance took is not drawn); the LATEST
// refusal for this task whose node is on the template wins, its target only when on the template.
// Exit 0 = all cases hold; 1 = a case failed; 4 = the function could not be sliced (anchor moved).
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const HERE = dirname(fileURLToPath(import.meta.url));
const html = readFileSync(join(HERE, '..', 'src', 'aef-workflow-designer.html'), 'utf8');
const m = /function instanceOverlayState\(nodeIds, flows, startIds, instance, refusals\) \{[\s\S]*?\n\}/.exec(html);
if (!m) { console.log('TEST BROKEN — instanceOverlayState not found in the designer'); process.exit(4); }
const f = new Function(m[0] + '; return instanceOverlayState;')();

// a small template: s -> a -> g -> b -> e, with a loop g -> a (b is the only way to e), second start s2 -> b
const ids = ['s', 's2', 'a', 'g', 'b', 'e'];
const flows = { s: ['a'], a: ['g'], g: ['b', 'a'], b: ['e'], s2: ['b'] };
const starts = ['s', 's2'];
const J = JSON.stringify;
let pass = 0, fail = 0;
const t = (name, got, want) => { const ok = J(got) === J(want); if (ok) pass++; else fail++; console.log(`  ${ok ? 'PASS' : 'FAIL'}  ${name}${ok ? '' : `\n       got  ${J(got)}\n       want ${J(want)}`}`); };

t('linear: current g, done is the path from s excluding g',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'g' }, []), { current: 'g', done: ['s', 'a'], refused: null });
t('loop: a loop the instance may have taken is NOT drawn — done is still the shortest prefix',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'a' }, []), { current: 'a', done: ['s'], refused: null });
t('two starts: the shorter path wins (s2 -> b, not s -> a -> g -> b)',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'b' }, []), { current: 'b', done: ['s2'], refused: null });
t('current on a start: done is empty',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 's' }, []), { current: 's', done: [], refused: null });
t('NO-POSITION: nothing is current, nothing is done',
  f(ids, flows, starts, { task: 'T-1', state: 'NO-POSITION', node: '' }, []), { current: null, done: [], refused: null });
t('STALE: a recorded node not on this template is not drawn',
  f(ids, flows, starts, { task: 'T-1', state: 'STALE', node: 'zzz' }, []), { current: null, done: [], refused: null });
t('NODE but the node is not on this template (inception on the other template): not drawn',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'other' }, []), { current: null, done: [], refused: null });
t('unreachable current (no path from any start): current drawn, done empty',
  f(ids, { s: ['a'] }, ['s'], { task: 'T-1', state: 'NODE', node: 'e' }, []), { current: 'e', done: [], refused: null });
t('no instance: empty overlay',
  f(ids, flows, starts, null, []), { current: null, done: [], refused: null });
t('refusal on this template, with a target on it',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'a' }, [{ task: 'T-1', rule: 'template-flow', node: 'a', target: 'e' }]),
  { current: 'a', done: ['s'], refused: { node: 'a', rule: 'template-flow', target: 'e' } });
t('refusal with no target (a gate refusal): target null',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'g' }, [{ task: 'T-1', rule: 'R-033', node: 'b', target: '' }]),
  { current: 'g', done: ['s', 'a'], refused: { node: 'b', rule: 'R-033', target: null } });
t('refusal whose target is off-template: target null, node kept',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'g' }, [{ task: 'T-1', rule: 'template-flow', node: 'b', target: 'nope' }]),
  { current: 'g', done: ['s', 'a'], refused: { node: 'b', rule: 'template-flow', target: null } });
t('refusal whose node is off-template is skipped; an earlier on-template one is used',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'g' }, [{ task: 'T-1', rule: 'P-010', node: 'b', target: '' }, { task: 'T-1', rule: 'x', node: 'nope', target: '' }]),
  { current: 'g', done: ['s', 'a'], refused: { node: 'b', rule: 'P-010', target: null } });
t('latest refusal wins',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'g' }, [{ task: 'T-1', rule: 'P-010', node: 'b', target: '' }, { task: 'T-1', rule: 'R-033', node: 'e', target: '' }]),
  { current: 'g', done: ['s', 'a'], refused: { node: 'e', rule: 'R-033', target: null } });
t('another task\'s refusal is ignored',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'g' }, [{ task: 'T-2', rule: 'R-033', node: 'b', target: '' }]),
  { current: 'g', done: ['s', 'a'], refused: null });
t('a refusal draws even when the instance is NO-POSITION (the refusal is the load-bearing half)',
  f(ids, flows, starts, { task: 'T-1', state: 'NO-POSITION', node: '' }, [{ task: 'T-1', rule: 'template-flow', node: 's', target: 'g' }]),
  { current: null, done: [], refused: { node: 's', rule: 'template-flow', target: 'g' } });
t('missing rule reads as ?',
  f(ids, flows, starts, { task: 'T-1', state: 'NODE', node: 'g' }, [{ task: 'T-1', node: 'b' }]),
  { current: 'g', done: ['s', 'a'], refused: { node: 'b', rule: '?', target: null } });
console.log(`\nPASS ${pass} / FAIL ${fail}`);
process.exit(fail ? 1 : 0);
