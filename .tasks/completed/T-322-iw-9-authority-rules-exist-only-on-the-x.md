---
id: T-322
name: "IW-9 authority rules exist only on the XML form: the canonical YAML form has no sovereignty check (T-320 gap)"
description: >
  T-320 census, direction XML-to-YAML. W-TYPE-LANE-MISMATCH (task-type vs lane authority) and E-INCEPTION-NOT-SOVEREIGN (an inception's go/no-go boundary MUST sit in a sovereignty lane) exist on XmlValidator only. The canonical YAML form can express both constructs -- lane authority is a REQUIRED lane field and workflowType is in the canonical aef: vocabulary (0 of 26 maps author it today) -- and no rule describes them there. The filing claim "workflowType=inception on 2/24 yaml" was wrong and is corrected in Evolution: those 2 carriers are .bpmn, the rule's own form. 0 live violations today, which is priority not classification: the absence of a rule is what makes the absence of violations unfalsifiable. Kept as one task because it is one construct (mapping-v1 section 3/7 authority collapse) on one form, not two independent defects. Governance-bearing: this is the half that decides whether an inception is human-sovereign.

status: work-completed
workflow_type: build
owner: claude-code
horizon: null
tags: []
components: [tests/fixtures/invalid/E-INCEPTION-NOT-SOVEREIGN.xml, tests/fixtures/warn/W-TYPE-LANE-MISMATCH.xml, tests/test_rule_form_parity.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-31T12:16:05Z
last_update: 2026-08-01T10:23:27Z
date_finished: 2026-08-01T10:23:27Z
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

# T-322: IW-9 authority rules exist only on the XML form: the canonical YAML form has no sovereignty check (T-320 gap)

## Context

The T-320 census (`docs/reports/T-320-rule-form-parity-census.md`) found the parity gap runs
in BOTH directions. This is the XML→YAML half, and it is the governance-bearing one: the two
rules that decide **who is authoritative** — `E-INCEPTION-NOT-SOVEREIGN` (an inception's
go/no-go boundary MUST sit in a sovereignty lane) and `W-TYPE-LANE-MISMATCH` (task-type vs
lane-authority collapse) — exist on `XmlValidator` only, at `tools/validate-workflow.py:1287`.

The construct is fully present on the canonical form: `authority` is a REQUIRED lane field
(`REQUIRED_LANE_FIELDS`) and `subProcess`/`userTask`/`serviceTask`/`scriptTask` are all in
`NODE_TYPES`. So this is a GAP by the census discriminator (construct presence), not an
out-of-scope asymmetry. AEF's framing, rail 356: *if sovereignty is only decidable on the
rendered form, the canonical form cannot answer the governance question it exists to answer.*

Zero live violations today. Per the census's two-axis rule that is **priority, not
classification** — the missing rule is exactly what makes the missing violations
unfalsifiable.

**Carrier is the open question, and it must be measured, not assumed.** The XML rule reads
`aef:meta workflowType="inception"` off the subProcess. Whether the canonical YAML form
carries that field, carries it under another name, or does not carry it at all decides whether
O-3 is portable or whether this task ships only O-1 and reclassifies O-3. Do not port
verbatim — T-320's own lesson (`NODE_TYPES` copied to the XML form would hard-fail 8 of our
fixtures) is that the missing rule can be real while the obvious fix is wrong.

Relevant precedent surfaced at work-on: **PL-035 (T-199)** — when a spec names X the sole
source of a decision, ABSENCE of X is a violation. The XML rule already encodes this (a
lane-less diagram must not become the one diagram that passes O-3); the YAML port must too.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Carrier measured and recorded before implementation: **0 of 26** `.workflow.yaml` carry `workflowType` as a node key; the construct is nonetheless expressible — `workflowType` is in the canonical `aef:` vocabulary (`tools/yaml-to-bpmn.py` `META_KEYS`) and the designer offers it on `subProcess` (`src/aef-workflow-designer.html:1805`, options at `:1897`). Recorded in `## Evolution` with the corpus named, together with the census row it disproves (claimed 2/24 yaml; the 2 carriers are `.bpmn`).
- [x] `W-TYPE-LANE-MISMATCH` (O-1) emits from `Validator` at `tools/validate-workflow.py:_check_iw9_authority`, WARN, off the same module-scope `AUTHORITY_OWNER`/`TYPE_PERFORMER` tables the XML form now reads. Guarded on `authority is not None`, so absent authority stays silent. Fixture `tests/fixtures/warn/W-TYPE-LANE-MISMATCH.yaml` carries an in-file silence control (a `userTask` in the same sovereignty lane that must NOT warn).
- [x] O-3 ported as `E-INCEPTION-NOT-SOVEREIGN` on `Validator` with PL-035 semantics — absent lane authority is a violation, not a skip. Proven by mutation M3: with the lane's `authority` removed the rule fires `…its lane authority is absent (O-3, mapping-v1 §7)`.
- [x] Teeth by mutation on the REAL tree (PL-061), three mutations, tree restored byte-identical (`git diff -- examples/` = 0 lines): **M1** real `userTask` in a sovereignty lane retyped `serviceTask` → `W-TYPE-LANE-MISMATCH` (pre-change build: `VALID — no findings`); **M2** real `subProcess` marked `workflowType: inception` in an `authority` lane → `E-INCEPTION-NOT-SOVEREIGN` (pre-change: `VALID — no findings`); **M3** same with the lane's authority stripped → fires with `absent` (pre-change reported only `E-LANE-FIELD`, a different rule — verified, not assumed).
- [x] Silence proven: 26 maps scanned, **0** findings for either new rule. Pinned as a Verification line.
- [x] `tests/test_rule_form_parity.py` updated — both entries moved to the new `PAIRED (same id, both forms)` classification, `EXPECTED_GAPS` 11 → 9 with the arithmetic re-derived in the comment. Guard green at `45 rules classified, 9 gaps`; no assertion was loosened to fit — one was **added** (see the third `## Evolution` entry: plain `PAIRED` did not survive its own teeth test).
- [x] Pinned by fixtures in the GATING runner rather than a new orphan-prone module (`tests/run-validator-tests.sh` globs `fixtures/{invalid,warn}/*` by the `<RULE-ID>.<ext>` contract): 4 fixtures, both forms, the XML pair generated by bridging the YAML pair so the parity property is asserted directly. Validator suite 38 → **42 passed, 0 failed**; bridge **62 passed, 0 failed**.

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

out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "^rule-form parity: OK$"
# T-323 legitimately moved the gap count (9 -> 12, scopeOf reclassified). The count
# assertion belongs in the guard's EXPECTED_GAPS, where it executes every run --
# pinning it here would be the T-317 mistake of parking a counter in a completed
# task's Verification block, where it silently stops running (or, re-run, lies).
out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "rules classified"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -qE "^== summary: [0-9]+ passed, 0 failed ==$"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -qE "^bridge round-trip: [0-9]+ passed, 0 failed$"
out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-INCEPTION-NOT-SOVEREIGN.yaml 2>&1); echo "$out" | grep -q "E-INCEPTION-NOT-SOVEREIGN"
out=$(python3 tools/validate-workflow.py tests/fixtures/warn/W-TYPE-LANE-MISMATCH.yaml 2>&1); echo "$out" | grep -q "W-TYPE-LANE-MISMATCH"
# silence: the whole canonical YAML corpus must stay at zero findings for both new rules
test "$(for f in $(find examples -name '*.workflow.yaml'); do python3 tools/validate-workflow.py "$f" 2>&1; done | grep -cE 'E-INCEPTION-NOT-SOVEREIGN|W-TYPE-LANE-MISMATCH')" = "0"

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
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

### 2026-08-01 — the carrier measurement, and the census row it disproved

- **What changed:** the AC required measuring the inception carrier before porting O-3.
  Result: **zero of 26** `.workflow.yaml` in the tree carry `workflowType` — as a node
  key it appears nowhere. But the T-320 census row for this rule claims "**2/24** yaml".
  Those two carriers are `tests/fixtures/aef-bpmn/{inception-gonogo,two-lane-joint}.bpmn`
  — XML files, the rule's **own** form. The census counted carriers on the wrong side of
  the comparison the column exists to make.
- **Plan impact:** none to the deliverable — the classification survives, because
  `workflowType` IS in the canonical `aef:` vocabulary (`tools/yaml-to-bpmn.py` `META_KEYS`;
  designer `metaKeys` at `src/aef-workflow-designer.html:9283`, offered on `subProcess`
  with `inception` among its options at `:1897`). So the construct is expressible on the
  canonical form and the rule was genuinely missing. Same verdict, different reason,
  different number.
- **Triggered:** census row corrected in place; the general defect filed as **T-323**.

### 2026-08-01 — the discriminator itself was wrong, and it cost the one out-of-scope call

- **What changed:** chasing the row above exposed the method. T-320 classified a rule
  OUT-OF-SCOPE when **no file on the other form carries the construct today** — a corpus
  count. The census's own two-axis rule forbids exactly that: a corpus count is priority,
  never classification. It was applied to the GAP rows and not to the OUT-OF-SCOPE rows.
  Proof that this bites: `aef:scopeOf` is in the shared vocabulary and the bridge emits it,
  yet 0 files carry it, so it was called out of scope. A `subProcess` whose `scopeOf` points
  at itself is `ERROR [E-SCOPEOF-SELF]` rc=2 on the YAML form and `VALID — no findings`
  rc=0 on the BPMN bridged from those same bytes.
- **Plan impact:** the census headline "8 gap families, exactly one correctly out of scope"
  becomes **9 families, zero correctly out of scope**. Out of T-322's scope to repair — the
  probes need to interrogate the vocabulary rather than walk the corpus.
- **Triggered:** **T-323** filed. Census corrected so it no longer carries the disproved
  claim. Posted to AEF at **rail 359** ahead of their own one-form-only sweep, so they do
  not inherit the discriminator.

### 2026-08-01 — the guard did not protect the parity it recorded

- **What changed:** teeth-testing the table update found a live hole. Moving the two ids to
  `PAIRED` and then **deleting the entire YAML rule from the code** left the guard
  **green** — `XmlValidator` still emitted the ids, so the stale-entry check (which only
  fires when *no* validator emits an id) stayed quiet while the table went on claiming
  parity. `PAIRED` was the one classification the guard took on trust: OUT-OF-SCOPE needed
  a probe, GAP was counted, PAIRED was believed.
- **Plan impact:** in scope and fixed here rather than deferred, because it is specifically
  the claim T-322 ships — shipping a parity claim nothing enforces is the false-green class
  this whole arc exists to remove. New classification `PAIRED (same id, both forms)` with an
  assertion that both classes still emit the id, plus negative control (b2). The deletion
  mutation now goes red on both rules.
- **Triggered:** nothing new. The *other* half — PAIRED via a differently-**named**
  counterpart (`E-EDGE-DANGLING` ↔ `E-FLOW-DANGLING`) — is still only a note, and belongs
  with T-323's classification-falsifiability work.

### 2026-08-01 — the two rules had no fixture coverage on either form

- **What changed:** neither `E-INCEPTION-NOT-SOVEREIGN` nor `W-TYPE-LANE-MISMATCH` had a
  fixture in `tests/fixtures/`, including on the XML form where they have existed all along.
  The parity census tracks whether a rule EXISTS on each form; it says nothing about whether
  anything exercises it.
- **Plan impact:** added fixtures for both forms, not just the new YAML half. The XML
  fixtures are generated by bridging the YAML ones, so the pair asserts the parity property
  directly: same map, same rule id, same exit code on both forms.
- **Triggered:** nothing filed. Worth noting as a candidate axis for a future census —
  "rule exists" and "rule is exercised" are independent, and this census only measured
  the first.

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

### 2026-07-31T12:16:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-322-iw-9-authority-rules-exist-only-on-the-x.md
- **Context:** Initial task creation

### 2026-08-01T10:08:02Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-589416a7
- **Timestamp:** 2026-08-01T10:24:49Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Agent)** — Carrier measured and recorded before implementation: **0 of 26** `.workflow.yaml` carry `workflowType` as a node key; the construct is nonetheless expressible — `workflowType` is in the canonical `aef
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/yaml-to-bpmn.py in: Carrier measured and recorded before implementation: **0 of 26** `.workflow.yaml` carry `workflowType` as a node key; the construct is nonetheless exp`

### 2026-08-01T10:23:27Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
