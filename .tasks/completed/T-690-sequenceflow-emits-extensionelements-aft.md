---
id: T-690
name: "sequenceFlow emits extensionElements after conditionExpression: 113 occurrences make 24 of 24 corpus maps schema-invalid"
description: >
  sequenceFlow emits extensionElements after conditionExpression: 113 occurrences make 24 of 24 corpus maps schema-invalid

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-08T21:39:56Z
last_update: 2026-09-08T21:41:59Z
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

# T-690: sequenceFlow emits extensionElements after conditionExpression: 113 occurrences make 24 of 24 corpus maps schema-invalid

## Context

Found by `tools/_t423-di-schema-validate.py` on its first run, 2026-09-08, while closing
T-423's last acceptance criterion. **Measured, not inferred:** 113 occurrences across 24 of 24
corpus maps, all on `bpmn:sequenceFlow`, all the same single cause.

`src/aef-workflow-designer.html:10276-10283` opens `sequenceFlow`, emits the conditional
`conditionExpression`, then emits the unconditional `extensionElements` block. BPMN's
`tBaseElement` declares `extensionElements` first, so every conditional flow this designer has
ever exported is schema-invalid.

**Why nothing caught it, which is the more useful half.** Every check the corpus had was
name-based or byte-based. A name-based check sees the correct element names, in the correct
document, with the correct attributes — the *only* thing wrong is their order, and order is
exactly what a name scan discards. The byte-identity baseline is worse than silent: it pins the
invalid bytes, so it would go RED on the fix. That is the shape of a control that defends a
defect.

Separate from T-423 deliberately (CLAUDE.md: one bug = one task). It is not a DI defect — it
predates DI, affects conditional flows whether or not DI is emitted, and lives in a different
branch of the exporter. Folding it in would have put two root causes behind one checkbox.

**Scope note on the corpus.** The committed maps are additionally pre-DI: 24 of 24 contain a
`bpmndi` namespace declaration and zero `BPMNDiagram` elements. So regenerating them is not
just a re-emit of this fix, it is the first time DI bytes land in the corpus, with the byte
churn T-423 §"Seam cost, corrected" describes. That is why the last AC permits recording the
residual rather than forcing the regeneration into this task.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `src/aef-workflow-designer.html` emits `bpmn:extensionElements` BEFORE
      `bpmn:conditionExpression` inside `bpmn:sequenceFlow`. BPMN's `tBaseElement` puts
      `extensionElements` first in the sequence, so the current order is invalid rather than
      merely unconventional. The fix is a reorder of two emission blocks — no element added,
      removed, or altered in content.
- [x] A map exported through the REAL exporter (CDP, not the committed corpus) validates
      clean on the schema leg of `python3 tools/_t423-di-schema-validate.py <exported.bpmn>`.
      The committed corpus is deliberately NOT the artefact under test: it predates DI
      emission entirely and is a separate regeneration problem.
      **Measured:** all 24 maps re-exported through a real browser
      (`_t423-additive-export-cdp.mjs`) → `24 document(s): 0 schema-invalid, 0 missing DI
      geometry`. Both legs clean, not just the schema one, which also closes T-423's last AC.
- [x] The reorder does not disturb the additive-export guarantee — T-423's
      `_t423-additive-export-guard.py` still reports every non-DI element equal in tag,
      attributes and document order. This must read as a move within a document, not a
      rewrite of one.
      **This AC was WRONG AS WRITTEN and is recorded rather than quietly reinterpreted.**
      The fix *is* a reorder, and the guard compares document order against a corpus that
      still holds the invalid order, so it went red on all 24 — the outcome this task's own
      Context predicted for the byte-identity baseline ("a control that defends a defect").
      The guarantee the AC was reaching for is *additivity*, not order-identity. Resolved by
      teaching the guard an asymmetric normalisation: `extensionElements` is hoisted on the
      SOURCE side (forgiving the corpus's historical order) and any EXPORT that needs the
      hoist is reported as a violation. **Green on the real exports: `PASS — 24 document(s)
      identical outside DI`, 2012 DI elements added.**
- [x] The regression is caught by the suite, not by whoever next runs a validator by hand:
      `_t423-di-schema-validate.py` wired into `tests/run-bridge-tests.sh`. Its `--self-test`
      already carries this exact case (`extensionElements-after-conditionExpression`) and has
      been watched red, so the leg is known capable of failing before it is relied on.
      **Wired** immediately after the additive-export leg, validating the fresh exports that
      leg produces — not the committed corpus, which would go red every run on T-691's
      residual and be muted within a week. The leg runs `--self-test` first (7/7) so a broken
      validator fails loudly instead of certifying silently, and REFUSES rather than passing
      when there are no exports to range over.
- [x] The 24 committed corpus maps are addressed explicitly — regenerated so they validate,
      or the residual recorded with its reason and follow-up task id. Leaving 24 known-invalid
      documents in the tree with no statement is not acceptable, because the next reader
      cannot distinguish known-and-scheduled from undetected.
      **Residual recorded as T-691** (`owner: human`, horizon `later`). Not regenerated under
      agent initiative: regeneration lands DI bytes for the first time in an artefact AEF
      pins against, which supersedes T-340 ruling (b) in a way a consumer can see. That is a
      seam decision, and the mandate does not delegate it.

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
         1. Run `bin/fw reviewer T-690`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-690 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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
#
# NOTE ON WHAT IS *NOT* HERE. The browser legs (real export -> schema-valid, real export ->
# additive, teeth) take ~400s and need Chromium plus the gallery sidecar. They are wired into
# tests/run-bridge-tests.sh, which is where they belong; duplicating them here would make the
# completion gate a second, slower copy of the suite. Everything below runs in seconds and
# fails if the fix, the controls, or the wiring is undone.

# 1. The exporter emits extensionElements BEFORE conditionExpression. Pinned as the exact
#    adjacency rather than by line number, which moves whenever anything above it is edited.
python3 -c 'import sys;s=open("src/aef-workflow-designer.html").read();sys.exit(0 if "</bpmn:extensionElements>`);\n    // T-690: emitted here, AFTER extensionElements" in s else 1)'

# 2. The schema validator is capable of failing — 7 cases, each watched red on a purpose-built
#    document, including this task's exact fault. A green verdict from an unexercised
#    validator is the thing this leg exists to prevent.
python3 tools/_t423-di-schema-validate.py --self-test

# 3. The vendored OMG XSDs are the bytes the OMG served. A silent local edit to a schema
#    weakens every validation downstream while every run stays green.
python3 tools/_t423-di-schema-validate.py --verify-schemas

# 4. The guard's EXPORT-side order check is live, proved without a browser: feed it the
#    corpus as BOTH sides. Source and export are then byte-identical, so the sequence
#    comparison cannot fail — the only thing that can speak is the T-690 leg, and it must,
#    because the corpus carries the invalid order (T-691). Non-zero exit is EXPECTED here;
#    the grep is the verdict.
out=$(python3 tools/_t423-additive-export-guard.py examples/aef-processes/rendered examples/aef-processes/rendered 2>&1); echo "$out" | grep -q "tBaseElement puts it first"

# 5. Both changed Python controls still compile.
python3 -c 'import py_compile;py_compile.compile("tools/_t423-additive-export-guard.py",doraise=True);py_compile.compile("tools/_t423-additive-export-teeth.py",doraise=True)'

# 6. The suite is syntactically whole after the new leg was inserted.
bash -n tests/run-bridge-tests.sh

# 7. The validator is actually WIRED, not merely present. _t451's census exists because
#    standing guards with no live caller are how a control becomes decoration.
grep -q '_t423-di-schema-validate.py" --self-test' tests/run-bridge-tests.sh

# 8. The AC-5 residual is recorded, not asserted. A follow-up task id in prose that resolves
#    to no file is the same as no residual at all.
test -f .tasks/active/T-691-regenerate-the-24-rendered-corpus-maps-s.md

## RCA

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

**Symptom:** Every conditional sequence flow the designer has ever exported is schema-invalid
BPMN. 113 occurrences across 24 of 24 rendered corpus maps; reproduced in the live exporter,
so it was current behaviour and not stale bytes.

**Root cause:** `src/aef-workflow-designer.html` opened `bpmn:sequenceFlow`, emitted the
conditional `conditionExpression`, then emitted the unconditional `extensionElements` block.
BPMN's `tBaseElement` declares `extensionElements` as the first element of its sequence and
`tSequenceFlow` extends it, so `conditionExpression` can only follow. The two emission blocks
were simply in the wrong order — no element was ever missing, misnamed or misattributed.

**Why structurally allowed:** every control the export path had was name-based or byte-based,
and **order is exactly what a name scan discards.** Three separate controls were green across
all 113 violations, each for its own reason:

- `_t423-additive-export-guard.py` compares SOURCE against EXPORT. Every corpus map carried
  the invalid order, so every export matched it. A source↔export comparison is blind by
  construction to any fault both sides share — the guard was structurally incapable of seeing
  this, not merely unlucky.
- The byte-identity baseline (`_t308-export-byte-identity-cdp.mjs`) pins the current bytes,
  so it does not merely miss the defect: **it goes red on the fix.** A control that defends
  a defect is worse than an absent one, because it produces resistance in the correct
  direction.
- `tools/validate-workflow.py` validates the project's own dialect, never the OMG XSD.
  Nothing in the tree had ever validated an exported document against the real schema.

The deeper omission: the exporter emits a *standard*, and no control held it to the standard's
own document. Conformance was asserted in prose and checked by proxies.

**Prevention** (distinct from the fix):
1. `tools/_t423-di-schema-validate.py` validates against five vendored OMG XSDs with pinned
   digests, wired into `tests/run-bridge-tests.sh` against FRESH exports. Its `--self-test`
   carries this exact fault plus six more, each watched red first.
2. The additive guard now reports an export whose `sequenceFlow` needs the hoist, so the
   ordering regression fails there too — teeth case 12 in `_t423-additive-export-teeth.py`
   proves the normalisation did not absorb its own subject.
3. Recorded as a learning: a source↔export comparison cannot detect a fault present on both
   sides; conformance to an external standard needs that standard's own validator.

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

### 2026-09-09 — AC 3 was self-contradictory with AC 1, and saying so was the work

- **What changed:** At filing I wrote "the reorder does not disturb the additive-export
  guarantee — the guard still reports every non-DI element equal in tag, attributes and
  **document order**." The fix is a reorder. Those two ACs cannot both hold, and I did not
  see it until the guard went red on all 24 documents. The Context of this very task had
  already predicted the mechanism one paragraph earlier, about a different control.
- **Plan impact:** The guarantee worth having is *additivity*, not order-identity. The guard
  now normalises asymmetrically — forgiving the hoist on the source side, reporting it on the
  export side. Symmetric normalisation was one line shorter and would have made the guard
  blind to the exact defect that prompted the change.
- **Triggered:** teeth case 12. Its first draft matched a process-level `extensionElements`
  against a `conditionExpression` hundreds of lines away and was caught on the generic
  "diverges" path — rc=1 for the wrong reason, which looks identical to success. Re-scoped to
  a single `sequenceFlow` block, then 13/13.

### 2026-09-09 — the corpus regeneration is a seam decision, not a chore

- **What changed:** I expected regeneration to be the tidy ending — make source and export
  agree again and the additive guard recovers full strength with no exception carved into it.
  Measuring stopped that: the 24 maps carry **no DI at all**, so regenerating is not a re-emit
  but the first landing of DI bytes in an artefact AEF pins against, superseding T-340 ruling
  (b) visibly to a consumer.
- **Plan impact:** AC 5's residual branch taken deliberately, not for convenience. The suite
  leg was pointed at fresh exports rather than the corpus for the same reason — a leg that
  goes red every run on a defect nobody is fixing today gets muted, and then it is not a
  control.
- **Triggered:** T-691 (`owner: human`, horizon `later`), carrying the measurement and the
  reason the decision is the operator's.

### 2026-09-09 — the bridge was already right, which relocates the defect

- **What changed:** I assumed both emitters shared the fault. `tools/yaml-to-bpmn.py:340-344`
  emits the correct order and always has. The corpus is invalid because it was last written
  by the *designer*, not the bridge — visible in the inline `xmlns:xsi` on every condition.
- **Plan impact:** No second fix site; scope stayed one file. Recorded in T-691 so nobody
  re-derives it and "fixes" a correct emitter.
- **Triggered:** nothing — this is the case where measuring cheaply prevented work.

## Decisions

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
     fw inception decide T-690 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-08T21:39:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-690-sequenceflow-emits-extensionelements-aft.md
- **Context:** Initial task creation
