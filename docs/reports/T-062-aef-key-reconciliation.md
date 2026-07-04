# T-062 — aef.* key reconciliation across the corpus

**Task:** T-062 · depends on T-061 (FC-13 fix) · workflow_type: build
**Trigger:** the T-061 loud-drop WARN surfaced that 14 authored corpus maps carried
`aef.*` keys that had been silently dropped since authoring — prior sessions wrote
them believing `aef:` was free-form passthrough. This reconciles every one.

## The three-way split

Each unknown `aef.*` key was routed by a single rule: **frequency + whether it is a
real shared modelling concept.** 27 distinct keys / ~87 occurrences resolved.

### 1. PROMOTE to first-class vocabulary (12 keys, 63 occurrences)

Recurring scalar keys that name a genuine AEF/BPMN modelling concept. Added to both
the bridge `META_KEYS` (`tools/yaml-to-bpmn.py`) and the editor `metaKeys`
(`src/aef-workflow-designer.html`) so they round-trip (import→export) instead of
being dropped on re-export. Parity enforced by `test_editor_bridge_meta_parity.py`.

| key | × | meaning |
|-----|---|---------|
| `terminalKind` | 13 | end-event kind (error/success) |
| `state` | 13 | node lifecycle state (validated/issues/closed…) |
| `note` | 7 | free-text annotation |
| `softFail` | 5 | failure advisory kind (advisory/accumulating) |
| `section` | 5 | source-section grouping label |
| `guard` | 4 | guard-condition text |
| `external` | 4 | external-participant flag |
| `exitCode` | 3 | terminal exit code |
| `autoTrigger` | 3 | auto-trigger description |
| `trigger` | 2 | trigger description |
| `gatewayKind` | 2 | gateway fork/join |
| `gate` | 2 | gate id/name |

### 2. ALIGN to an existing canonical key (3 keys)

The author used a synonym for a channel that already exists — renamed, no new vocab.

| authored | canonical | note |
|----------|-----------|------|
| `reads` (list, ×4) | `contextReads` (scalar) | joined list → comma string |
| `writes` (list, ×1) | `artifactsWrites` (scalar) | joined list → comma string |
| `sideEffects` (×1) | `sideEffect` | plural→singular; already in `META_KEYS` |

### 3. RENAME to the explicit `aef.x-*` passthrough (12 keys)

One-off, map-specific keys — documentation, not shared concepts. Routed through the
T-061 opt-in extension channel so they survive as visible `<aef:meta>` attributes.

- **Scalar one-offs (8):** `umbrellaBypass`, `subProcessPerMember`, `rule`,
  `requiresForClose`, `handoffTo`, `groupConstraint`, `collection`, `branchesModeledOf`
- **Structured one-offs (4), flattened to a scalar `x-*` note:** `gates`, `ladder`,
  `sources`, `grouping`. These are the constituent lists of collapsed nodes — **FC-11**
  (a collapsed node has no structured constituent channel in the bridge). Flattening to
  readable text preserves the information; a real constituent channel is future feature
  work, not reconciliation.

## Bridge hardening (T-062)

The scalar `<aef:meta>` attribute channel cannot carry a dict/list. Previously a
`META_KEYS`-or-`x-*` key holding a structured value fell through **silently**. Added a
WARN for that case — same "no silent failures" contract as the T-061 unknown-key WARN.

This immediately surfaced a **new, distinct class**: five *known* `META_KEYS` keys that
carry structured values in the corpus and have been silently dropped all along —
`emits` (list, ×5), `aggregation` (dict), `compensates` (list), `multiInstance` (dict),
`timer` (dict). These want a *structured representation* (a feature), not flattening, so
they are **out of scope for T-062** and filed as a follow-up (one-finding-one-task,
mirroring how T-061's WARN surfaced T-062).

## Result

- `unknown aef key` WARN lines over the corpus: **0** (was ~87).
- Bridge suite: **26/26**, geometry sweep 20 clean.
- Every corpus map still converts + validates clean.
- Residual (loud, not silent): 5 structured-`META_KEYS` keys → follow-up task.
