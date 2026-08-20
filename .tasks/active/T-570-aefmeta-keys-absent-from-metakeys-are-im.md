---
id: T-570
name: "aef:meta keys absent from metaKeys are imported, hidden, then silently dropped on re-export"
description: >
  Import reads EVERY attribute of <aef:meta> into n.aef unconditionally (src:10183, 'for (const a of metaEl.attributes) aef[a.name] = a.value'). Export emits only keys on the metaKeys whitelist (src:9430, metaKeys.filter(k => aefKeys.includes(k))). The two lists are therefore asymmetric, and any key present in a source document but absent from metaKeys is loaded into memory, rendered nowhere, and dropped on re-export with no warning. Measured over 91 bpmn files / 714 aef:meta values: 'determinism' appears 12 times (examples/app-processes/rendered/customer-refund.bpmn) and is in NEITHER metaKeys NOR AEF_FIELDS. This is distinct from T-566 (invisibility) and worse: T-566 is content nobody can read, this is content the editor destroys. It is also the exact failure 001-CashWeb was asked about on agent-chat-arc T-064 -- 'content an author might unknowingly overwrite because they cannot see it' -- with our own corpus as the witness rather than theirs. T-566's read-only disclosure makes such a key VISIBLE but does not make it survive; the fix here is about the export whitelist, not the panel. Derived from reading two call sites; MUST be measured by an actual import->export round trip before any change.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bug, designer, round-trip]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-20T14:45:26Z
last_update: 2026-08-20T16:55:24Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-570: aef:meta keys absent from metaKeys are imported, hidden, then silently dropped on re-export

## Context

Import reads EVERY attribute of `<aef:meta>` into `n.aef` (src:10255, unconditional loop over
`metaEl.attributes`). Export emits only the 20 keys on the `metaKeys` whitelist (src:9502). The two
lists are asymmetric, so a key present in a source document but absent from `metaKeys` is loaded,
rendered nowhere, and **destroyed on the next save**.

This is NOT T-566. T-566 was invisibility — content nobody could read, faithfully round-tripped.
This is data loss. T-566's disclosure block makes such a key visible *on the way past*; the sentence
it prints — "They are not lost." — is true of every key on `metaKeys` and **false of exactly the keys
this task is about**. Fixing this makes that sentence true; not fixing it means I shipped a claim the
code contradicts.

The fix is a CARRIAGE channel, not a wider contract. Widening `metaKeys` would answer a standards
question (it is in ratified parity with `tools/yaml-to-bpmn.py` META_KEYS) and that ruling is the
operator's. Preserving what a document carried, without claiming to understand it, is not a contract
change — it is the editor declining to destroy input it does not recognise.

## Acceptance Criteria

### Agent
- [x] Corpus census is EXHAUSTIVE and recorded here: every distinct `<aef:meta>` attribute name
      across every `.bpmn` in the tree (excluding `.agentic-framework/`), with counts, and the exact
      subset absent from `metaKeys`. Not a spot-check of the one key named at filing.
- [x] The drop is REPRODUCED before it is fixed: a CDP leg drives a real import → export inside the
      page against UNMUTATED shipping code and asserts the key is ABSENT from the exported bytes.
      Without this arm, "the key is present after the fix" is also what a probe that asserts nothing
      produces.
- [x] Every `<aef:meta>` attribute the source document carried survives a full import → export round
      trip byte-identically, including values containing `&`, `<`, `"` and newlines.
- [x] A node that never carried an unknown key does NOT acquire one — preservation is per-node
      carriage, not a global key union.
- [x] Export ordering is deterministic: known keys in `metaKeys` order, carried keys sorted after
      them. Re-exporting an unchanged document twice yields identical bytes.
- [x] `metaKeys` is UNCHANGED at 20 entries, `tests/test_editor_bridge_meta_parity.py` is green, no
      `aef:` key is added and no standard bump is taken. The contract question stays the operator's.
- [x] T-566's "Other extensions" disclosure text is true after this change (or corrected in the same
      commit if it is not).
- [x] Teeth: a control run on unmutated source FIRST, then mutants each reddening exactly the legs
      they break and no others. A mutant that reddens more than its own legs is reported as a
      failure, not accepted.
- [x] The probe is wired into `tests/run-bridge-tests.sh` in the SAME commit — not left as a
      `## Verification`-block orphan that goes unwired the moment this task completes (T-568).
- [x] Suite total rises and reports 0 failed.

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

node tools/_t570-meta-carriage-cdp.mjs
python3 tools/_t570-meta-carriage-teeth.py
python3 tests/test_editor_bridge_meta_parity.py
python3 tests/test_editor_bridge_structured_parity.py
python3 tools/_t566-note-field-cdp.mjs
# Positive counts, not absence assertions (T-560): "no metaKeys-only filter remains" passes
# just as readily when the pattern is mis-quoted. metaKeys stays at exactly 20 literals (no
# contract widening), and the carriage path exists exactly once — one definition, one
# conditional add, one use.
python3 -c "import sys,re;s=open('src/aef-workflow-designer.html',encoding='utf-8').read();i=s.index('const metaKeys = [');j=s.index('];',i);sys.exit(0 if len(re.findall(chr(39)+'[^'+chr(39)+']+'+chr(39),s[i:j]))==20 and s.count('scalarHandled')==3 and s.count('carriedKeys')==2 else 1)"
# Every key our own bridge can emit must survive the editor's export whitelist. This is the
# assertion the meta-parity test does NOT make (it checks the other direction — see T-572),
# and it is the one that would have caught this bug.
python3 -c "import importlib.util,sys;sp=importlib.util.spec_from_file_location('p','tests/test_editor_bridge_meta_parity.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);e=m.editor_meta_keys(open('src/aef-workflow-designer.html',encoding='utf-8').read());b=m.bridge_meta_keys(open('tools/yaml-to-bpmn.py',encoding='utf-8').read());sys.exit(0 if len(e)==20 and len(b)>=29 and m.check(e,b)==[] else 1)"
# The suite is the leg, with a floor — "0 failed" is also what deleting legs produces.
bash tests/run-bridge-tests.sh > /tmp/.t570-suite.out 2>&1 && python3 -c "import re,sys;m=re.search(r'bridge round-trip: (\d+) passed, (\d+) failed',open('/tmp/.t570-suite.out').read());sys.exit(0 if m and int(m.group(1))>=124 and int(m.group(2))==0 else 1)"

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom.** A key present on `<aef:meta>` in a source document and absent from the editor's
20-entry `metaKeys` export whitelist was loaded into `node.aef`, displayed nowhere, and gone from
the file after the next save. No warning, no log line, HTTP-200-equivalent silence.

**Measured, not reasoned.** Census over 91 `.bpmn` files / 823 `<aef:meta>` values: 24 distinct
keys, of which 4 sit outside `metaKeys` — `determinism` (16), `endpoint` (10), `sideEffect` (2),
`emits` (1), across 3 files. A real import → export → re-parse in the page then split those four
in a way the census could not: **`determinism`, `sideEffect` and `emits` are destroyed; `endpoint`
survives**, because it has its own `<aef:endpoint>` element emitter and merely migrates from
attribute form to element form. Reading the two whitelists would have reported four losses; three
is the true number, and the difference is the entire justification for driving the round trip.

**The census measured the sample; the producer's vocabulary is the population.** Using the parity
test's own extractors: editor `metaKeys` = 20, bridge `META_KEYS` (`tools/yaml-to-bpmn.py`) = 29,
and **9 keys our own bridge can emit were absent from the editor's export whitelist** —
`determinism`, `authority`, `endpoint`, `sideEffect`, `autoTriggerKind`, `restoresFrom`,
`compensationSnapshot`, `compensatedBy`, `advisory`. So the blast radius was never "3 keys in 3
files"; it was "up to 9 keys in any map our own producer writes", and today's corpus simply does
not exercise six of them yet. All 9 now round-trip (8 carried on `<aef:meta>`, `endpoint` on its
element) — measured, not inferred.

**Root cause.** Two whitelists governing one value with nothing holding them in correspondence:
import unconditional (src:10255), export enumerated (src:9502). The same two-lists shape as T-566,
one layer down — there it decided what was SEEN, here it decided what was KEPT.

**Why structurally allowed.** `tests/test_editor_bridge_meta_parity.py` is named *parity* and
asserts a *subset*: `check(editor_keys, bridge_keys)` returns editor keys missing from the bridge
and nothing else (its own self-test at :94 confirms that is the only case it flags). It therefore
returned `[]` — green — for the entire period in which the bridge emitted 9 keys the editor
destroyed. A stated property standing in for a checked one, with the gap rendering as health: the
fifth instance of that shape in a week, and the first found inside a guard rather than in product
code. Filed as **T-572**, not fixed here — the repair is not "assert equality" (the two lists now
legitimately differ, because carriage is generic where the bridge enumerates) but a round-trip
assertion, which is its own design.

**Prevention.** `tools/_t570-meta-carriage-teeth.py`, wired into `tests/run-bridge-tests.sh` in
this commit rather than left in a `## Verification` block that goes unwired at completion (T-568).
Leg `reproduce-drop` reproduces the PRE-fix rule in-page and requires it to lose what the shipped
path keeps, so the repair is evidenced rather than asserted. Mutant D is the tempting narrow fix —
widen `metaKeys` by the two keys the census found — and is distinguished from mutant A by exactly
one leg, which is what stops "repair the sample" from passing as "repair the mechanism".

**Not fixed here.** T-572 (the subset-shaped parity guard) and T-573 (the Emits panel field writes
a scalar where the structured exporter requires an array — `FIELD_META.emits` at src:1922 has no
`special` handler, and the editor's own seed template at src:2083 uses the scalar shape, so a
brand-new document was born losing it). T-573's data loss is closed by this commit; its *shape*
defect is not, and it gets its own task rather than being folded in.

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

## Decisions

### 2026-08-20 — carriage on `<aef:meta>`, not a wider `metaKeys`
- **Chose:** emit, on the existing `<aef:meta>` element, every scalar `node.aef` value that no
  other emitter in `aefExtensionXml` claims. `metaKeys` stays at 20.
- **Why:** widening the whitelist answers a standards question by shipping code. `metaKeys` is in
  ratified parity with the bridge's `META_KEYS`, and whether any of these keys is promoted into the
  frozen v1 contract is the operator's ruling. Carriage changes no contract: `<aef:meta>` is already
  a bag of scalar attributes, and this stops filtering the bag on the way out. Round trips become
  byte-identical instead of editing a document down to the subset we happen to name.
- **Rejected:** adding `determinism`/`sideEffect` to `metaKeys` — this is mutant D in the teeth. It
  repairs every key the census found and none it did not, so the next producer key files this bug
  again. Also rejected: a new `<aef:carried>` element, which would add an `aef:` element to the wire
  format — the exact contract change this task refuses to make.

### 2026-08-20 — the skip set is shape-derived, not a list of exceptions
- **Chose:** skip a key only when another emitter will ACTUALLY emit it for this node's current
  value; scalars carry, objects and arrays belong to the structured emitters.
- **Why:** load-bearing for `emits`. The structured exporter fires on `Array.isArray(aef.emits)`, so
  a SCALAR `emits="ev.done"` — which is what `tests/fixtures/valid/investigate.bpmn` and the
  editor's own seed template carry — falls through it silently. Filtering carriage by NAME would
  re-drop exactly that value; filtering by SHAPE carries the scalar and leaves the array its own
  channel. The two populations are disjoint by construction, so no coordination is needed. The
  kind-specific event binding (`errorStatus`/`timerSpec`/`busTopic`) is skipped conditionally for
  the same reason: `<aef:eventDef>` emits it only for a typed event node.
- **Rejected:** a per-node `carried` side-list recorded at import. It has to survive every copy,
  duplicate and undo path that clones a node, and the first one that clones `.aef` without it loses
  the keys again — reintroducing the two-lists-with-nothing-holding-them-in-correspondence shape
  this task exists to remove. Deriving at export means carriage travels with `.aef` automatically.

### 2026-08-20 — three defects, three tasks
- **Chose:** ship carriage here; file the subset-shaped parity guard as T-572 and the Emits
  scalar/array panel mismatch as T-573.
- **Why:** one bug, one task. T-572 is a guard defect with its own design question (a round-trip
  assertion, not a set comparison) and T-573 is a shape question whose data loss this commit already
  closes. Folding either in would bury a distinct root cause inside this one's episodic.

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-20T14:45:26Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-570-aefmeta-keys-absent-from-metakeys-are-im.md
- **Context:** Initial task creation

### 2026-08-20T16:54:53Z — status-update [task-update-agent]
- **Change:** horizon: now → now

### 2026-08-20T16:55:24Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
