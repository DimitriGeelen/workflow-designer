---
id: T-327
name: "Gallery verify harnesses synthesise <bpmn:linkEventThrow>, a host tag no emitter
  produces (4 sites)"
description: >
  Found by the T-324 whole-tree sweep (G-009: a copy-paste defect class needs a sweep,
  not a single-site fix). tools/_gallery-claim-verify.py:46, _gallery-list-verify.py:61,
  _gallery-registry-verify.py:52 and :56 each build synthetic BPMN using <bpmn:linkEventThrow>
  as the host element tag. That is not a BPMN element -- it is our canonical YAML
  type name in the BPMN namespace -- and NEITHER emitter can produce it: bridge TYPE_MAP
  and designer TYPE_TAG both rename it to intermediateThrowEvent on export (src/aef-workflow-designer.html:9233-9236).
  Same class as the defect T-324 just repaired in the byte-pinned offpage-seam.bpmn,
  at four more sites. All three harnesses PASS today, and the reason they pass is
  the finding: the store ref-scan classifies off-page legs from <aef:link> and never
  inspects the host tag -- structurally identical to AEF's Pass 5 blindness. So these
  guards prove the scanner handles a document shape the emitter CANNOT produce, and
  say nothing about the shape it does produce. A regression in which the designer
  emitted a wrong host tag would not be caught by any of them. Fix is to generate
  the emitter-faithful tag; the harnesses should then still pass, and that they do
  is the check that they were testing the right document all along. NOT bundled into
  T-324 (one bug = one task): T-324 is a coordinated re-pin with a peer and mixing
  unrelated edits would muddy the delivered sha. Also note .editor-versions/_trash/picker-e2e-referrer-*/versions/v1.bpmn
  carries the same tag -- a trashed artifact produced BY one of these harnesses, which
  is direct evidence the unfaithful shape escapes into stored documents.

status: work-completed
workflow_type: build
owner: claude-code
horizon:
tags: []
components: [tests/test_xml_node_type_vocab.py, 
      tools/_offpage-seam-parity-verify.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-01T21:24:20Z
last_update: '2026-08-16T14:33:28Z'
date_finished: 2026-08-01T21:43:26Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:50Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-327: Gallery verify harnesses synthesise <bpmn:linkEventThrow>, a host tag no emitter produces (4 sites)

## Context

Found by the T-324 whole-tree sweep (G-009). Three gallery verify harnesses synthesise BPMN using `<bpmn:linkEventThrow>` as the host element tag — our canonical YAML type name in the BPMN namespace, which neither emitter can produce.

**The fix is the boring half.** The finding is *why they pass*: the store's ref-scan classifies off-page legs from `<aef:link>` and never inspects the host tag — structurally identical to AEF's Pass 5 blindness (their OBS-115). So these guards prove the scanner handles a document shape our emitter **cannot produce**, and say nothing about the shape it does. AEF's framing at rail 367: *"worse than an absent guard, because an absent guard does not report."*

A tag rename alone would repair four sites and leave the class live — the next harness author copies the next wrong tag. So this task owes a **prevention** distinct from the fix (G-019): a guard that derives the permitted element vocabulary **from the emitters**, not from a static list. That principle is AEF's adoption of my rail-366 addition, and it matters here for a concrete reason: `linkEventThrow` no longer appears anywhere in the corpus, so any check built from corpus content would now have nothing to say about it.

**Scope note:** the guard's scan surface must be MEASURED before it is asserted, and the scan must strip comments first — several files legitimately name `<bpmn:linkEventThrow>` in prose explaining T-324 (G-009: a check satisfied by its own explanation).

## Acceptance Criteria

### Agent
- [x] All 4 sites emit an emitter-producible host tag: `tools/_gallery-claim-verify.py`, `tools/_gallery-list-verify.py`, `tools/_gallery-registry-verify.py` (×2). Zero `<bpmn:linkEventThrow` remain in executable code (prose/comments explaining the history may remain and are excluded by comment-stripping, not by hand).
      **EVIDENCE:** all 4 rewritten to `<bpmn:intermediateThrowEvent>`. **Plus a 5th site the measurement found:** `tools/_bpmn-claim-cli-verify.py:54` synthesised `<bpmn:task>` as the host for an `<aef:link>` node. Legal BPMN, but neither emitter produces a bare `task` — same defect, milder (linkEventThrow is not BPMN at all). Fixed alongside; the AC said 4 because 4 was what the grep for one tag found.
- [x] All three harnesses still pass after the change. **This is the actual test of the finding:** if they pass on emitter-faithful bytes as readily as on malformed ones, they were never discriminating on the host tag — which is the claim. If any FAILS, that is a more interesting result and gets recorded, not patched around.
      **EVIDENCE:** all four harnesses rc=0. None discriminated on the host tag — claim confirmed rather than assumed.
- [x] The permitted element vocabulary used by the new guard is **derived from the emitters** (bridge `TYPE_MAP` / designer `TYPE_TAG`, via the existing declared-superset in `tests/test_xml_node_type_vocab.py`), never a hand-written list. A hand-written list drifts from the emitter silently and would go stale the moment a construct stops appearing.
      **EVIDENCE:** permitted = `XML_NODE_TYPES` (11, itself guarded as a declared superset computed from both emitters) ∪ scaffolding literals scanned from the two emitters' own source (12) = 23. No element name is typed by hand anywhere in the guard except the two tolerance keys, which are exemptions rather than permissions.
- [x] Guard scan surface is MEASURED and the measurement recorded in this task (which files, which distinct element names) before any assertion is written against it. An unmeasured scan that finds nothing is indistinguishable from a scan pointed at the wrong place — the exact defect AEF retracted at rail 367 (a capability gap reported against a directory that never existed).
      **EVIDENCE — the measurement, taken before any assertion existed:** 20 files across `tools/ tests/ src/` referenced `<bpmn:*` in comment-stripped source, carrying **20 distinct element names**: collaboration, conditionExpression, definitions, extensionElements, flowNodeRef, incoming, intermediateCatchEvent, lane, laneSet, **linkEventThrow**, outgoing, participant, process, scriptTask, sequenceFlow, serviceTask, subProcess, **task**, **timerEventDefinition**, **transaction**. **This measurement changed the design:** most names are document scaffolding, not node types, so a naive "every tag ∈ XML_NODE_TYPES" check would have flagged `<bpmn:process>` in every harness and been switched off within a day. It also surfaced the 4 non-permitted names, three of which needed individual classification rather than a blanket rule.
- [x] The guard strips comments before scanning. Negative-controlled: a `<bpmn:bogusTask` inside a COMMENT must NOT trip it, and the same literal in code MUST.
      **EVIDENCE:** leg (a) code string → RED, 1 violation, output names `bogusTask`. Leg (b) `#` comment → GREEN. Leg (c) **module docstring → GREEN** — added because docstrings are string literals and comment-stripping alone would not have excluded them; the scan collects non-docstring STRING tokens via `tokenize` + `ast`, so comments never reach it as a token type at all.
- [x] Teeth: introducing a bogus BPMN element tag into a real harness makes the guard RED. Mutation landing asserted before the verdict is read (L-321); the guard's finding count must actually move, not merely the tree (L-326). Tree restored, sha compared.
      **EVIDENCE:** 5 legs, every mutation's landing asserted before its verdict, tree sha-compared after each. (a) code→RED/1 violation, (b) comment→GREEN, (c) docstring→GREEN, (d) a tolerance whose usage vanished→RED via the `(2)` branch, (e) monkeypatching the scaffolding derivation to empty trips the `(0)` branch — so a collapsed permitted set reports as a *guard* problem, not as a clean tree.
- [x] Guard is wired into the GATING runner (`tests/run-bridge-tests.sh`), not merely present — an unrun guard cannot report a failure (L-316/orphaned-test-files).
      **EVIDENCE:** new leg before the T-316 orphan guard; bridge count 64 → **65**. The T-316 orphan guard independently confirms membership.
- [x] Gating suites green with counts recorded: bridge, validator, geometry.
      **EVIDENCE:** bridge **65 passed / 0 failed**; validator **43 passed / 0 failed**; geometry sweep **24 clean / 0 new-fail / 0 stale / 0 tool-err**.

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

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ── T-327 verification ──
# the guard exists, passes, and is named by the GATING runner (not merely present)
python3 tests/test_harness_emitter_fidelity.py
grep -q 'test_harness_emitter_fidelity.py' tests/run-bridge-tests.sh
# no executable site synthesises the malformed TAG. Two anchoring hazards here,
# both hit in practice:
#  (1) comments/docstrings — several files legitimately name the tag in prose
#      explaining T-324, so a whole-file grep is satisfied by its own explanation.
#      Counted on the guard's own comment- and docstring-stripped view.
#  (2) the BARE WORD is not the defect. `linkEventThrow` is our canonical YAML
#      type name and appears legitimately in validate-workflow.py NODE_TYPES,
#      check-lane-bands.py occupancy, and test_t313's type tuple. The first
#      version of this line counted the bare token and failed on all three —
#      a false positive against the project's own vocabulary. Only the tag form
#      `<bpmn:linkEventThrow` is malformed; anchor there.
test "$(python3 -c "import importlib.util; spec=importlib.util.spec_from_file_location('g','tests/test_harness_emitter_fidelity.py'); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m); print(sum(1 for p in m.scan_targets() if '<bpmn:linkEventThrow' in m.code_strings(p)))")" = "0"
# the four harnesses still pass on emitter-faithful bytes (the finding's own test)
python3 tools/_gallery-claim-verify.py
python3 tools/_gallery-list-verify.py
python3 tools/_gallery-registry-verify.py
python3 tools/_bpmn-claim-cli-verify.py
# tolerances are declared and count-asserted, never silent
out=$(python3 tests/test_harness_emitter_fidelity.py 2>&1); test "$(echo "$out" | grep -c 'NOTE (tolerated, T-327)')" = "2"
tests/run-bridge-tests.sh
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

**Symptom:** five sites across four verification harnesses synthesised BPMN host elements neither emitter can produce — `<bpmn:linkEventThrow>` ×4 (not a BPMN element at all) and `<bpmn:task>` ×1 (legal BPMN, never emitted by us). All five harnesses passed.

**Root cause:** the harnesses were written against *what the consumer needs to see* (an `<aef:link>` child on some host) rather than *what the emitter produces*. Since the store's ref-scan classifies off-page legs from `<aef:link>` and never inspects the host tag, any host worked — so nothing pushed back.

**Why structurally allowed:** nothing anywhere compared harness-synthesised documents against the emitters' vocabulary. The node-type gate (T-321) reads *files*, not *string literals in test code*, so synthetic documents were outside every existing check. The harnesses' own green was actively reassuring: they exercised the ref-scan and passed, which reads as "the seam is covered".

**Prevention (distinct from the fix):** `tests/test_harness_emitter_fidelity.py`, in the gating runner. Its permitted set is derived from both emitters, so it cannot go stale as the corpus changes — the concrete case being that after T-324 no corpus file contains `linkEventThrow`, so a corpus-derived check would now be silent about it while the emitters still cannot produce it. Tolerances for deliberate un-producible fixtures are counted, printed every run, and count-asserted, and leg (d) proves a tolerance that stops describing the tree fails the build rather than lingering as a blanket exemption.

**Cross-side note:** AEF hit the identical blindness from the other direction (their OBS-115/OBS-116) — a byte pin green on the malformed element for its entire life, and their own teeth going red on a sha-to-sha comparison rather than on the malformation. Two toolchains, same structural hole, found by reading rather than by any gate.

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

### 2026-08-01 — the measurement changed the guard's design
- **What changed:** AC4 forced a measurement before any assertion. It found that most `<bpmn:*>` names in code are document *scaffolding* (definitions, process, lane, laneSet, sequenceFlow…), not node types.
- **Plan impact:** the obvious guard — "every synthesised tag ∈ XML_NODE_TYPES" — would have flagged `<bpmn:process>` in every harness. A guard that noisy gets switched off, and AEF's L-527 applies: a rule that gets tuned out is weaker than no rule, because its silence stops meaning anything. Permitted set became node types ∪ the emitters' own scaffolding literals — still fully derived, no hand-written names.
- **Triggered:** also surfaced 3 names needing individual classification (`task` → a 5th site to fix; `transaction` and `timerEventDefinition` → deliberate negative fixtures, tolerated with reasons).

### 2026-08-01 — my teeth driver had two defects, one of which faked a guard failure
- **What changed:** first run reported 3 failures. None were the guard.
  - Leg (b) chained a `.replace()` across the whole file and rewrote a `%s>` inside real code, manufacturing a genuine violation. It went RED and read exactly like "comments are not stripped". **Only the landing assertion caught it** — `+2` occurrences instead of `+1`. Without asserting landing I would have "discovered" a comment-stripping bug that did not exist and gone looking for it in the guard.
  - Leg (d) asserted "red implies ≥1 violation". The stale-tolerance branch legitimately reports **zero** violations, being a `(2)` failure. A correct guard failed a wrong probe.
- **Plan impact:** "went red" is not evidence a guard works. Each leg now names the specific evidence its own failure mode should produce (`expect_violations`, `expect_text`), so a leg passing means the branch under test fired — not merely that something did.
- **Triggered:** nothing filed; recorded because this is [[probes-that-cannot-falsify]] in its other form. There the probe passed when the claim was wrong; here the probe failed when the claim was right. Both come from writing the check beside the answer instead of deriving it from the claim.

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

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-01T21:24:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-327-gallery-verify-harnesses-synthesise-bpmn.md
- **Context:** Initial task creation

### 2026-08-01T21:31:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-779f6ccb
- **Timestamp:** 2026-08-01T21:44:45Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#3 (Agent)** — The permitted element vocabulary used by the new guard is **derived from the emitters** (bridge `TYPE_MAP` / designer `TYPE_TAG`, via the existing declared-superset in `tests/test_xml_node_type_vocab.
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/test_xml_node_type_vocab.py in: The permitted element vocabulary used by the new guard is **derived from the emitters** (bridge `TYPE_MAP` / designer `TYPE_TAG`, via the existing dec`

### 2026-08-01T21:43:26Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
