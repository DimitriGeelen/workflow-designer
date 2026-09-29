---
id: T-573
name: "Emits panel field writes a scalar where the structured exporter requires an
  array"
description: >
  FIELD_META.emits (src:1922) is a plain text field with no special handler, so the
  inspector's Emits box writes a STRING into n.aef.emits. The structured exporter
  fires on Array.isArray(aef.emits) (src:9620) and silently skips a string. The editor's
  own seed template uses the scalar shape too (src:2083-2086, aef: { emits: 'event:investigate.ready'
  }), so a brand-new document is born with the mismatch. Before T-570 the consequence
  was total: an author typed an event name, saved, and it was gone. T-570's carriage
  now preserves the value -- but as <aef:meta emits="..."/>, NOT as the ratified <aef:emits><aef:emit
  value="..."/></aef:emits> structured form the bridge and tests/test_editor_bridge_structured_parity.py
  agree on. So the data is safe and the SHAPE is still wrong, which is a smaller and
  different defect than the one T-570 fixed and gets its own task rather than being
  folded in. Decide deliberately rather than by reflex: either the panel field parses
  its input into a list (comma-separated, matching how the dict emitter joins lists
  at src:9633) or FIELD_META.emits gains a structured editor. Whichever is chosen,
  a document that ARRIVED with a scalar emits must keep round-tripping as a scalar
  -- promoting it to the structured form on load would rewrite bytes the author did
  not touch, which is the silent-migration failure T-242 already ruled against for
  targetWorkflow. Evidence: tests/fixtures/valid/investigate.bpmn carries the scalar
  form (1 of 823 corpus aef:meta values); tools/_t570-meta-carriage-cdp.mjs leg 'scalar-emits-survives'
  pins the preservation and leg 'structured-untouched' pins that an ARRAY still takes
  its own channel.

status: work-completed
workflow_type: build
current_node: frw_11_task
owner: agent
horizon: null
tags: [bug, designer, round-trip]
components: [src/aef-workflow-designer.html, tests/run-bridge-tests.sh, tests/test_editor_bridge_structured_parity.py, tools/_roundtrip-serialization-cdp.mjs, tools/_t570-meta-carriage-cdp.mjs, tools/_t570-meta-carriage-teeth.py, tools/_t573-emits-panel-shape-cdp.mjs, tools/_t573-one-vocabulary-teeth.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-20T17:06:34Z
last_update: 2026-09-29T08:32:30Z
date_finished: 2026-09-29T08:32:30Z
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
bvp_scores_proposed: []
cost_estimate_proposed:
  - ts: '2026-09-21T20:24:51Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-09-24T22:02:36Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=2 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
bvp_scores:
  D1: 4
  D2: 0
  D3: 2
  D4: 2
  F-RECALL: 0
  F2: 0
  F4: 0
  F3: 4
  F1: 2
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-29T08:12:59Z'
---

# T-573: Emits panel field writes a scalar where the structured exporter requires an array

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The ratified structured shape is REACHABLE from the panel.** Typing into the Emits
      box produces `<aef:emits><aef:emit value="..."/></aef:emits>` on export — the form
      `tools/yaml-to-bpmn.py` and `tests/test_editor_bridge_structured_parity.py` agree on —
      not `<aef:meta emits="..."/>`. Input is parsed comma-separated, matching the hint
      convention `contextReads`/`artifactsWrites` already use and the `join(', ')` the dict
      emitter already round-trips. Proven in the page by CDP, reading the exported XML —
      not by reading the handler.

- [x] **A scalar that ARRIVED in the document and was NOT touched still round-trips as a
      scalar.** This is T-242's ruling against silent migration (made for `targetWorkflow`)
      applied here: promoting a shape on load rewrites bytes the author did not touch.
      `tools/_t570-meta-carriage-cdp.mjs` leg `scalar-emits-survives` must stay green, and
      leg `structured-untouched` must stay green with it — the two channels are disjoint by
      construction (T-570's shape-derived skip set) and this task must not couple them.

- [x] **A no-op edit writes nothing.** If the parsed input is content-equal to what is
      already stored, the stored value is left ALONE — including its shape. The guard is
      about content, not about guessing intent: without it a stray keystroke in a
      scalar-arrived field silently promotes the shape and moves bytes. Proven by a leg that
      types the identical value into a scalar field and asserts the export is unchanged.

- [x] **Clearing the field removes the key rather than storing an empty value.** An empty
      parse yields no key at all, so neither emitter has to decide what `emits=""` or
      `emits: []` means. Proven by a leg that clears a populated field and asserts no
      `emits` survives in either channel.

- [x] **ONE module-scope vocabulary for the structured-list keys, read by all three sites.**
      The `emits`/`compensates` wrapper-item-attribute triple is currently written out twice
      (export at src:10485, import at src:11465) and the panel would have been a third. Hoist
      it to one module-scope constant all three read — T-322's rule, the same reasoning
      T-886/T-910 used for the derived denominator. Proven by a grep asserting the triple
      literal occurs exactly ONCE, with a control proving the grep can count.

- [x] **No corpus bytes move.** All 24 rendered maps still round-trip byte-identically, and
      `tests/test_editor_bridge_structured_parity.py` is green. A panel change that moved
      corpus bytes would be the opposite defect.


**EVIDENCE, per criterion.** `tools/_t573-emits-panel-shape-cdp.mjs` **8/8** — it drives the
REAL input element (found by its rendered label, `.value` set, a real `input` event
dispatched) and reads the exported XML, because calling the callback directly would pass on a
build where the field never renders at all, which is the F-11 defect one level up.
· AC1 `panel-authors-structured` + `single-value-promotes` (one event with no comma still
  reaches the ratified form — it is not reserved for lists).
· **The control arm for AC1 is `reproduce-string-write`**: it reproduces the pre-fix
  assignment `n.aef.emits = v` in the page and requires NO `<aef:emits>` to appear. Without it
  a fixture that arrived structured would report the same green (T-560).
· AC2 `untouched-channels-stay-disjoint` (scalar node: meta=true structured=false; structured
  node: meta=false structured=true; two exports byte-identical) **plus
  `tools/_t570-meta-carriage-cdp.mjs` 8/8**, its `scalar-emits-survives` and
  `structured-untouched` legs unchanged.
· AC3 `noop-edit-moves-no-bytes` — retyping the identical scalar left the export
  byte-identical and the shape a scalar.
· AC4 `clear-deletes-key` — no `<aef:emits>`, no meta attribute, key absent.
· AC5 `tools/_t573-one-vocabulary-teeth.py` **5/5 against mutants**: a second export-style
  copy caught, a second import-style copy caught, the constant RENAMED reported as BLINDNESS
  rather than health, and a dropped key caught as a bridge disagreement (which proves leg 1's
  green is about agreement, not merely about the count).
· AC6 `tools/_t308-export-byte-identity-cdp.mjs` **24 maps / 24 identical**,
  `tests/test_editor_bridge_structured_parity.py` green, `tools/_roundtrip-serialization-cdp.mjs`
  `pass: true`.

**TWO GUARDS HAD TO BE UPDATED, AND BOTH REFUSED ME FIRST — which is the system working.**
Neither was edited to go green; each was refused, diagnosed, and then told the truth about the
new code, with a control proving it can still bite. See `## Decisions`.

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
         1. Run `bin/fw reviewer T-573`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-573 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

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


# T-573. The CDP harnesses are slow (each spawns a sidecar + headless Chromium); that is the
# price of proving a PANEL behaviour in the page rather than by reading the handler.
#
# 1. The panel authors the ratified shape — 8 legs, one of them the pre-fix control arm.
node tools/_t573-emits-panel-shape-cdp.mjs
#
# 2. The "exactly one structured-list vocabulary" check, against 5 mutants. Includes the
#    rename-reads-as-blind leg: a guard that cannot find its subject must not report health.
python3 tools/_t573-one-vocabulary-teeth.py
#
# 3. Editor/bridge parity on structured keys, now including the copy COUNT.
python3 tests/test_editor_bridge_structured_parity.py
#
# 4. T-570's carriage must be untouched: the scalar channel and the structured channel are
#    disjoint by construction and this task must not have coupled them.
node tools/_t570-meta-carriage-cdp.mjs
#
# 5. No corpus bytes move: 24 maps, 24 identical.
node tools/_t308-export-byte-identity-cdp.mjs
#
# 6. The derived-denominator guard passes with the new moduleObject source kind.
node tools/_roundtrip-serialization-cdp.mjs
#
# 7. The triple literal exists in exactly ONE place. Pinned as an invariant (1), and the
#    grep is the same one test_editor_bridge_structured_parity.py counts with.
python3 -c "import sys; t=open('src/aef-workflow-designer.html').read(); n=t.count(\"['emits', 'emit', 'value']\"); print('triple literal copies:', n); sys.exit(0 if n==1 else 1)"

## Visual Verification

The panel change is visible to an author in two ways — the hint now names the separator (it is
load-bearing: it is what produces the list) and a document-supplied ARRAY has to render as
something editable rather than `[object Object]` or blank. DOM values were checked AND the
rendered output was read, per CLAUDE.md §Visual Verification.

The designer has exactly ONE visual mode: `grep -oE "data-theme|prefers-color-scheme|\.theme-[a-z]+|toggleTheme"` over
`src/aef-workflow-designer.html` returns nothing — no theme attribute, no media query, no
toggle. So two element screenshots cover every mode this change can affect, rather than the
usual light/dark/contrast matrix.

| shot | state | read back |
|---|---|---|
| `docs/reports/t573-shots/emits-field-array-joined.png` | a document-supplied `<aef:emits>` array of two | label `Emits`, hint `· event name(s) · comma-separated`, value `event:one, event:two` — legible, not truncated, no overlap |
| `docs/reports/t573-shots/emits-field-three-typed.png` | three events typed by hand | value `event:alpha, event:beta, event:gamma` renders in full; stored as `["event:alpha","event:beta","event:gamma"]` |

## RCA

**Symptom:** an author typed an event name into the inspector's Emits box, saved, and the
document came back carrying `<aef:meta emits="event:x"/>` — never the ratified
`<aef:emits><aef:emit value="event:x"/></aef:emits>` that `tools/yaml-to-bpmn.py` and
`tests/test_editor_bridge_structured_parity.py` agree on. Before T-570 the same keystrokes
produced nothing at all: the value was simply gone.

**Root cause:** `FIELD_META.emits` had no `special` handler, so it took the generic
`field()` path whose callback is `v => { n.aef[f] = v; }` — a STRING. `buildBpmnXml`'s
structured emitter fires on `Array.isArray(aef.emits)`. Two pieces of code held the same
concept in two incompatible **shapes**, and the reason they could is that neither read the
other: the wrapper/item/attribute triple that defines the structured channel was written out
**twice** (once in the emitter, once in the import reader) and the panel read **neither**. A
third reader with a fourth opinion was the only possible outcome — and it is exactly the
T-322 defect ("one module-scope vocabulary, never a second copy") that the codebase has
already paid for in T-886 and T-910 on the round-trip denominator.

**Why structurally allowed:** the guard that existed — `test_editor_bridge_structured_parity.py`
— asserted that the editor's **two** copies each agree with the bridge. That property was
**true the whole time the defect was live.** It compared the two serialiser copies and had no
opinion about any other writer of `n.aef.emits`, so the panel was outside its denominator BY
CONSTRUCTION. This is the same shape as T-885's finding one instrument over (document-level
`workflowMeta` outside the round-trip denominator by construction) and as T-570's
(`metaKeys` and the import loop asymmetric with nothing holding them in correspondence).
Two copies agreeing is a weaker claim than one copy existing, and the gap between those two
claims is precisely where this bug lived.

Secondary: T-570 **reduced the symptom without closing the defect**, and did so knowingly —
its shape-derived carriage rescued the string as a meta attribute and its comment records
that the two channels are "disjoint by construction". That was correct and it made the
remaining defect quieter: the data stopped disappearing, so nothing hurt enough to force the
shape question. A fix that removes the pain of a defect postpones the defect.

**Prevention:**
1. The vocabulary is now **one** module-scope `STRUCT_LIST_KEYS`, and
   `test_editor_bridge_structured_parity.py` no longer compares two copies — it asserts there
   is **exactly one**. `0` copies (renamed/removed) reads as BLINDNESS, not health. So the
   class of defect (a new reader with its own opinion) now has something to fail against
   instead of something to agree with.
2. `tools/_t573-one-vocabulary-teeth.py` gives that assertion teeth against **5 mutants**,
   including the rename-reads-as-blind arm — because a count check that cannot go wrong is
   not a check.
3. `tools/_t573-emits-panel-shape-cdp.mjs` drives the **rendered input element** and reads the
   exported XML, with `reproduce-string-write` as its control arm. A probe that called the
   handler directly would pass on a build where the field never renders — the F-11 defect
   (an authored value nobody can reach) one level up, which is the defect this task is a
   special case of.
4. Learning to carry forward: **when adding a reader of a shared shape, the question is not
   "does my reader agree" but "how many readers are there".** Both guards that refused this
   change (see `## Decisions`) refused because their denominators were scoped to the writers
   that existed when they were written.

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

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->


### PD (T-573) — parse comma-separated in the panel, rather than build a structured sub-editor

T-573 named two routes and asked for a deliberate choice. Chosen: **the field parses its
input into a list.** Reasons, in order of weight:
1. `contextReads` and `artifactsWrites` already carry the hint `paths · comma-separated`, so
   the separator is this panel's existing convention for many-valued text; a bespoke
   sub-editor for one key would be a second convention for the same question.
2. The dict emitter already round-trips lists through `join(', ')`, so the separator is
   already load-bearing in the serialiser — the panel now agrees with it instead of differing.
3. It is reversible. A structured sub-editor can be added later over the same stored shape;
   the stored shape is the contract and it is now correct.

Rejected: a structured sub-editor now. It is more UI for a key carried by **1 of 823** corpus
`aef:meta` values, and it would have delayed the shape fix behind a widget.

### PD (T-573) — the shape follows CONTENT, and a content-equal edit writes nothing

T-242 ruled against silent migration for `targetWorkflow`: promoting a shape on load rewrites
bytes the author did not touch. The obvious reading — "only migrate when the author edits" —
is not implementable honestly, because `field()`'s non-deferred path fires on every `input`
event, so "the author edited" and "the author brushed the field" are the same signal.

So the guard decides by **content**, not intent (`structListUnchanged`): a scalar `'a'` and an
array `['a']` are content-equal, and a write whose parse is content-equal to what is stored is
dropped, shape included. A real change writes the ratified array. This needs no guess about
what the author meant, and it is what leg `noop-edit-moves-no-bytes` pins.

Clearing DELETES the key rather than storing `''` or `[]`, so neither emitter ever has to
decide what an empty `emits` means.

### PD (T-573) — two guards refused this change first; both were told the truth, not silenced

Recorded because "I updated two guards" is the sentence that should always attract suspicion.

1. **`tests/test_editor_bridge_structured_parity.py`** failed with `SELFTEST FAIL: editor
   extraction returned empty`. Its premise was that the editor holds the triple TWICE and each
   copy is compared to the bridge. The hoist collapsed them to one, so its regex found nothing
   — and its selftest correctly refused to report vacuous parity. Rather than restore its
   pattern, the check was made **stronger**: it now reads the single `STRUCT_LIST_KEYS` and
   asserts the editor holds **exactly one** copy. Two copies agreeing was always the weaker
   property — it was satisfied for as long as the panel wrote an incompatible third shape,
   which is this task's whole defect. `0` copies (constant renamed) now reads as BLINDNESS,
   not health. Proven by 5 mutants in `tools/_t573-one-vocabulary-teeth.py`.

2. **`tools/_roundtrip-serialization-cdp.mjs`** went `pass: true` → `pass: false` with
   *"COMPUTED_SOURCES.key declares object source `structList` which does not exist in the
   emitter"*, then, after the name was updated, with the same complaint about
   `STRUCT_LIST_KEYS` — because its `object` kind resolves **inside the emitter body** and the
   constant is now at module scope. **This is T-905's guard behaving exactly as designed** (it
   was built so a misdeclaration could not be mistaken for a correct one), and it was a real
   regression I introduced, caught by the instrument rather than by me.
   Fixed by adding a `moduleObject` source kind — a module-scope object whose KEYS are
   projected keys — resolved from the whole module. A NEW kind rather than widening `object`
   to search module scope: `object` asserts body-locality, and relaxing it would let a
   genuinely absent literal resolve against any same-named thing in a 12k-line file.
   **Control run, because widening a guard's resolution is how guards get defanged:** the
   declaration was pointed at `STRUCT_LIST_KEYS_NOT_A_THING`, and the guard refused on all
   three of its checks (`does not exist in the emitter` / `the declaration is narrower than
   the code` / `names a source it does not iterate`). Restored and verified clean.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-20T17:06:34Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-573-emits-panel-field-writes-a-scalar-where-.md
- **Context:** Initial task creation

### 2026-09-29T08:13:04Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-f9d956df
- **Timestamp:** 2026-09-29T08:32:45Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-29T08:32:30Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
