---
id: T-325
name: "Classify every validator rule universal vs dialect-relative (T-309 IW-1b)"
description: >
  Classify every validator rule universal vs dialect-relative (T-309 IW-1b)

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: [tests/test_rule_dialect_axis.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-01T19:53:36Z
last_update: 2026-08-01T20:21:52Z
date_finished: 2026-08-01T20:21:52Z
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

# T-325: Classify every validator rule universal vs dialect-relative (T-309 IW-1b)

## Context

Closes the prerequisite T-309 named ahead of IW-2. `W-XML-GW-AMBIGUOUS` fires on 47 of AEF's 48 live
gateways and 0 of ours: it measures which toolchain wrote the file, not whether the gateway is
correct. Surfacing that to an author (the whole point of T-309) would show 47 warnings on a map
correct by its own conventions, and a rule that gets tuned out is weaker than no rule because its
silence stops meaning anything (AEF's L-527).

So each rule has to say which kind of claim it makes. The tempting discriminator — measure how
differently a rule fires across the two corpora — is the T-323 mistake one level up, and it is more
seductive here because a firing-rate table looks exactly like evidence for this question. The
classification is derived from the frozen standard's normative carrier partition instead; corpus
counts are priority only.

Findings recorded in `docs/reports/T-309-validator-surfacing.md` (§ "IW-1b RESOLVED").

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Every rule id in `tests/test_rule_form_parity.py`'s `PARITY` table carries a second-axis
      classification — `UNIVERSAL` / `DIALECT_RELATIVE` / `PRESENTATIONAL` — and an unclassified
      rule id FAILS the guard (same shape as the existing form-parity axis; no rule may be silently
      absent from the new axis) — 46 rules; unclassified/stale both FAIL (checks 1a/1b), negative control (a) proves it.
- [x] The discriminator is **derived from the frozen standard, never from corpus firing rates** —
      classification follows the normative carrier partition in `docs/standards/aef-bpmn-mapping-v1.md`
      §1 (Semantic vs Presentational) plus whether the carrier the rule's predicate depends on is
      MUST-emit or one of several standard-admitted alternatives. This is the T-323 correction applied
      one level up: a corpus count is PRIORITY, never CLASSIFICATION — `classify()` holds the whole discriminator and no corpus term appears in it; guard prints `No corpus term participates in this classification`.
- [x] Each rule declares the **carrier(s)** its predicate reads, and the classification is computed
      from a carrier→class map rather than hand-asserted per rule; a rule declaring a carrier that is
      not in the carrier map FAILS — `RULE_CARRIERS` declares (carriers, polarity); class is COMPUTED by `classify()`, never written per rule. Unclassified carrier FAILS (check 2 + control b).
- [x] The carrier map is drift-guarded **bidirectionally against the frozen standard**: every
      `aef:` token listed in the standard's Presentational bullet appears in the map classified
      presentational, and every token the map calls presentational appears in that bullet. Anchored on
      a structural literal (backtick-delimited `aef:` tokens inside the located bullet), not a loose
      prose match — the guard RAISES if the bullet cannot be located rather than passing on an empty set — check (3) both ways vs §1, anchored on the `**Presentational…**` bold run; `_bullet()` RAISES if the bullet is gone; control (f) proves the raise.
- [x] `docs/standards/aef-bpmn-mapping-v1.md` is **NOT modified** (frozen, Part I, not editable under
      agent control) — `git diff --exit-code` clean for that path — `git diff --exit-code` clean, in the Verification block.
- [x] Teeth proven by mutation on the real tree: (a) removing a rule's classification goes RED,
      (b) mis-declaring a carrier goes RED, (c) editing the carrier map away from the standard goes
      RED — each shown pre/post with the mutation asserted to have LANDED before the verdict is read
      (T-321 null-result lesson), and the tree restored byte-identical afterwards — 4 mutations, each with anchor-occurrence asserted =1 BEFORE the verdict: dropped declaration, mis-declared carrier, FLIPPED POLARITY, carrier map off-standard. All rc=1 RED; restored sha 35d40a8a6380 identical, post-restore GREEN.
- [x] Negative controls prove the new axis is *checked* and not *believed* (the unfalsifiable-PAIRED
      trap from T-323): at minimum a synthetic rule with a carrier absent from the map, and a
      synthetic presentational token present in the standard but missing from the map — 6 controls run every pass (no declaration / unclassified carrier / §1 token demoted / unratified absorbed / dialect-relative rule unprobed / unreadable standard must RAISE).
- [x] Firing rates are measured across the separated dialect populations and PRINTED as priority
      evidence, explicitly labelled as not-the-classification; the summary line names its SUBJECT
      (which populations, how many maps) per G-013 — 4 populations tabulated in the artifact with subjects named; our own 0 explicitly recorded as discriminating nothing for this question.
- [x] `tests/run-bridge-tests.sh` green (all legs) and `tools/validate-workflow.py`'s own fixture
      suite green — counts stated in the Verification block, not pinned to a moving number in prose — bridge 64 passed/0 failed (63→64), validator 43 passed/0 failed; Verification asserts `0 failed`, not the moving pass count.
- [x] `docs/reports/T-309-validator-surfacing.md` updated with the IW-1b resolution: the classification,
      the discriminator, and the consequence for the surfacing options (i)/(ii)/(iii) — closing the
      prerequisite that currently sits ahead of IW-2 — new section `2026-08-01 — IW-1b RESOLVED (T-325)`; Recommendation updated: IW-2 is next and is an operator architecture call.

### Human
- [ ] [REVIEW] Rule on the two carriers §1 does not classify, and on whether `W-GW-AMBIGUOUS` should accept the standard's other condition carrier
  **Steps:**
  1. Read `docs/reports/T-309-validator-surfacing.md` § "2026-08-01 — IW-1b RESOLVED (T-325)" — the hole is the paragraph beginning "A hole in the frozen standard".
  2. Decide (a) how `aef:laneMeta/@height` and `@abbr` are classified under §1, which today claims "Every `aef:` datum is exactly one of two classes" while listing neither; and (b) whether `W-GW-AMBIGUOUS`/`W-XML-GW-AMBIGUOUS` should treat a branch `name=` label as a condition carrier, which mapping-v1 §5 ("edge label = condition") and forward-compile §3.1 both admit.
  3. (a) is a v1.1 standard edit and batches with the T-189/T-195 deltas already awaiting sign-off — the standard is frozen and I do not edit it under agent control. (b) is a rule change I can make on your GO, and it is a rail conversation with AEF because it changes what fires on their bytes.
  **Expected:** A recorded ruling on each. On GO for (b) I relax the predicate and re-run both suites; the dialect-relative count then drops from 3 to 1.
  **If not:** Leave partial-complete. The classification stands and the guard keeps both carriers PRINTED every run, so neither question can go quiet.

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
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Deliberately NOT pinned to any count that later work legitimately moves (T-317:
# a counter parked in a completed task's Verification block silently stops running,
# or lies when re-run). Rule-class totals live in the guard, which is authoritative.
python3 tests/test_rule_dialect_axis.py > /tmp/.t325-axis.out 2>&1
# the three rules whose class changes what a designer may show an author. Anchored
# on line-start + the class token, not a bare rule id — a bare id also matches the
# fixture FILENAME echoed in validator output (the defect P-011 caught in T-321).
grep -qE '^  W-GW-AMBIGUOUS +DIALECT-RELATIVE$' /tmp/.t325-axis.out
grep -qE '^  W-XML-GW-AMBIGUOUS +DIALECT-RELATIVE$' /tmp/.t325-axis.out
grep -qE '^  W-IO-INPUT +DIALECT-RELATIVE$' /tmp/.t325-axis.out
# the classification must not be derived from a corpus term (the T-323 correction)
grep -q 'No corpus term participates in this classification' /tmp/.t325-axis.out
# carriers the frozen standard's supposedly-total partition does not cover are
# PRINTED, not absorbed
grep -q 'NOTE (unratified, T-325): carrier aef:laneMeta/@height' /tmp/.t325-axis.out
# the frozen standard is read, never written, under agent control
git diff --exit-code -- docs/standards/aef-bpmn-mapping-v1.md
# wired into the GATING runner, not merely present on disk (T-316)
grep -q 'tests/test_rule_dialect_axis.py' tests/run-bridge-tests.sh
# both suites green, stated as "no failures" rather than a moving pass count
bash tests/run-bridge-tests.sh > /tmp/.t325-bridge.out 2>&1 && grep -qE 'bridge round-trip: [0-9]+ passed, 0 failed' /tmp/.t325-bridge.out
bash tests/run-validator-tests.sh > /tmp/.t325-val.out 2>&1 && grep -qE 'summary: [0-9]+ passed, 0 failed' /tmp/.t325-val.out
# the T-309 prerequisite this task exists to close is recorded in the artifact
grep -q 'IW-1b RESOLVED' docs/reports/T-309-validator-surfacing.md
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

## Recommendation

**Recommendation:** GO on (b) — relax the gateway rule to accept a branch label as a condition
carrier. DEFER (a) — the §1 carrier-class hole — into the v1.1 batch already awaiting your sign-off.

**Rationale:** These two look like one question and are not. (b) is a rule that is wrong by the
frozen standard we already agreed: mapping-v1 §5 says "edge label = condition" and forward-compile
§3.1 says "branch label / `conditionExpression`". Two carriers are admitted; our predicate demands
one, so it reports a violation against documents that conform. That is not a dialect accommodation
made to be polite to a peer — it is a false positive, and the cleanest evidence is our own fixture
`tests/fixtures/warn/W-XML-GW-AMBIGUOUS.xml`, which labels its branches `name="code"`,
`name="design"`, `name="environment"` and ships as the file demonstrating the warning. Fixing it
removes 47 of AEF's 48 gateway findings without weakening anything: a gateway with neither a label
nor a condition on 2+ outflows still warns.

(a) is different in kind. §1 opens "Every `aef:` datum is exactly one of two classes" and then lists
neither `aef:laneMeta` nor its attributes, while `height` and `abbr` are both read by live rules.
That is a standards edit, the standard is frozen, and it batches naturally with the T-189 IW-9 and
T-195 G-3 deltas already sitting for graduation — three v1.1 edits ruled on together beats one
ruled on alone. Nothing degrades while it waits: both carriers are PRINTED every run and the count
is asserted, so the hole cannot go quiet.

Both are rail conversations before they are code. (b) changes what fires on AEF's bytes, and the
last three times either side changed a shared predicate unilaterally we found the divergence
afterwards.

**Evidence:**
- `tests/test_rule_dialect_axis.py` — 46 rules classified; 39 universal, 3 dialect-relative, 4
  presentational. Guard in the gating runner; bridge 64/0, validator 43/0.
- Standard citations: `docs/standards/aef-bpmn-mapping-v1.md` §1 (carrier partition, normative) and
  §5 (edge label = condition); `aef-bpmn-forward-compile-v1.md` §3.1 (label / conditionExpression).
- `docs/reports/T-309-validator-surfacing.md` § "2026-08-01 — IW-1b RESOLVED (T-325)" — discriminator,
  classification table, firing-rate cross-check with subjects named.
- Teeth: 4 real-tree mutations all RED (including a flipped polarity label), tree restored
  byte-identical; 6 negative controls run every pass.
- Firing rates as PRIORITY only: our 25+25 maps give 0 findings and discriminate nothing here; the
  two AEF populations we hold disagree (34 vs 1) because both are bridge-blends. AEF's own live
  measurement (rail 356) is 47 of 48 gateways firing, 0 of 381 flows conditioned.
- `git diff --exit-code -- docs/standards/aef-bpmn-mapping-v1.md` clean — frozen standard untouched.

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

### 2026-08-01T19:53:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-325-classify-every-validator-rule-universal-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-76cb28bb
- **Timestamp:** 2026-08-01T20:23:08Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Per-AC findings:**

- **AC#1 (Agent)** — Every rule id in `tests/test_rule_form_parity.py`'s `PARITY` table carries a second-axis
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/test_rule_form_parity.py in: Every rule id in `tests/test_rule_form_parity.py`'s `PARITY` table carries a second-axis`
- **AC#9 (Agent)** — `tests/run-bridge-tests.sh` green (all legs) and `tools/validate-workflow.py`'s own fixture
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/validate-workflow.py in: `tests/run-bridge-tests.sh` green (all legs) and `tools/validate-workflow.py`'s own fixture`

### 2026-08-01T20:21:52Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
