---
id: T-449
name: "PROVENANCE pair-draft rows are two-sided at last: AEF's records land, dispatch-loop's
  arc ref is wrong, and the two sides define pair-draft differently"
description: >
  PROVENANCE pair-draft rows are two-sided at last: AEF's records land, dispatch-loop's
  arc ref is wrong, and the two sides define pair-draft differently

status: work-completed
workflow_type: refactor
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T09:35:39Z
last_update: '2026-08-16T12:33:30Z'
date_finished: 2026-08-12T09:38:53Z
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
  - ts: '2026-08-16T12:33:30Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-449: PROVENANCE pair-draft rows are two-sided at last: AEF's records land, dispatch-loop's arc ref is wrong, and the two sides define pair-draft differently

## Context

T-446 marked the three `pair-draft` rows in `tests/fixtures/aef-bpmn/PROVENANCE.md` as
**asserted on 832 evidence alone** — labelled pair-draft in our commit subjects and nowhere
else. AEF declined to confirm from memory (DM 549 §6), correctly, and owed a check from
records. That check landed at **DM 556** after being promised on four consecutive rails.

Three things arrived with it:

1. **A factual error in our file.** `dispatch-loop` is cited as AEF arc-015. Measured on
   their side, T-2568 carries `arc:designer-corpus` = **arc-014**; their arc-015 is
   `onboarding-shape-detection`, unrelated. Both fixtures are slices of one five-process
   exercise (session-handover = D3/T-2561, dispatch-loop = D4/T-2563, anchor T-2553).

2. **Zero AEF bytes in all three files.** Their pins match our delivered shas, each with a
   single commit touching it (two for offpage-seam, both ours). Under a "did AEF bytes go
   in" reading, all three collapse into the 832-authored column and 15 becomes 18.

3. **The two sides have been using different definitions of "pair-draft" all along, and
   neither ever said so.** Theirs is fixed in writing at arc-014's inception (T-2553:101,
   operator scope option 2d): the pair is *drafting-agent + their operator*, drafting agent
   explicitly "AEF **or** 832". Under that, a file drafted entirely by us IS a pair-draft
   and their zero bytes are the design, not an anomaly. Ours cannot be that, or the column
   would be empty — our table contrasts "15 are 832-authored outright" with "3 are genuine
   pair-drafts", and that contrast only does work if the three contain something of theirs.

**Both definitions are coherent. They were never diffed.** That is the actual finding, and
it is the same class as the directory-name defect and OBS-230's HOLD-vs-PRODUCES question:
two sides reading one word differently, with nothing in either tree recording that a
reading was chosen.

**What is genuinely AEF's in each, citable and not bytes:** for `session-handover` and
`dispatch-loop`, an independent AEF counterpart draft of the same process, committed 22 and
42 minutes before intake respectively — so "pair" there is carried by two drafts of one
process. For `offpage-seam` there is **no AEF counterpart draft** (they searched all 13
designer projects; none was ever made), but the three legs exercise their compile taxonomy
and the RESOLVED leg needed a live uuid only they could supply — which they supplied at
rail 118 with a RECOMMENDED value and a 3-uuid avoid-list. **We asked precisely because the
T-559 boundary forbids reaching into their :3001.** So the row our ordinal calls #3 is the
weakest of the three under a two-drafts reading and the strongest under a joint-work
reading. Exactly inverted.

**Scope boundary — what this task does NOT do.** AEF recommends relabelling the rows
`832-authored / AEF-paired` and `832-authored / AEF-specified`, and explicitly declines to
assert their definition over ours ("I am deliberately not sending you a 'confirmed'").
Choosing which definition this file ratifies changes the headline count and is a definition
ruling, not a measurement — **it goes to the operator with both readings recorded.** This
task lands the facts and the correction; it does not pick the taxonomy.

## Acceptance Criteria

### Agent
- [x] The `dispatch-loop` arc reference reads arc-014, not arc-015, with the correction
      dated and the evidence cited (T-2568 / their arc-015 being a different arc)
- [x] The "asserted on 832 evidence alone / unconfirmed by AEF" block is replaced by the
      received two-sided evidence — it is no longer a one-sided claim and must stop saying
      it is
- [x] Both definitions of "pair-draft" are stated side by side, with the source of AEF's
      quoted (T-2553:101, operator scope option 2d), so a later reader can see that the
      word was never diffed rather than inferring one reading
- [x] Per-file contribution is recorded factually: zero AEF bytes in all three; counterpart
      drafts exist for two; `offpage-seam` has none but carries a joint spec step that
      exists *because* of the T-559 boundary
- [x] The label question is left OPEN and marked as the operator's, with AEF's recommendation
      recorded verbatim and NOT applied — no row is relabelled and the 15/3 split is
      unchanged by this task
- [x] No claim in the rewritten block is sourced to memory or to this conversation alone;
      every assertion carries a rail offset, a task id, or a file path

### Human
- [ ] [REVIEW] Rule which definition of "pair-draft" this table ratifies. Both are coherent
      and AEF explicitly declined to assert theirs over ours; the choice changes the
      headline count, so it is not a measurement an agent can make.
  **Steps:**
  1. `cd /opt/832-Workflow-designer && sed -n '/^## What it actually is/,/^## `inception-gonogo/p' tests/fixtures/aef-bpmn/PROVENANCE.md`
  2. Read the two definitions in the quoted block: AEF's (drafting-agent + THEIR operator,
     drafting agent being either side — T-2553:101) versus ours (the three rows contain
     something of AEF's, which is what makes them distinct from the 15).
  3. Choose one:
     **(a)** Keep as-is — "pair-draft" means their reading; the 15/3 split stands and the
     block explains why zero AEF bytes is not a contradiction.
     **(b)** Adopt AEF's recommendation — relabel the first two `832-authored / AEF-paired`
     and `offpage-seam` `832-authored / AEF-specified`, keeping them distinct from the 15.
     **(c)** Byte-authorship only — all three become 832-authored, split becomes 18/0, and
     the counterpart-draft evidence moves to a footnote.
  **Expected:** one of a/b/c recorded. If (b) or (c), say so and the agent applies it in a
  follow-up task — the rows are deliberately unchanged today.
  **If not:** leaving it open is a valid outcome; the block already states both readings and
  names the open question, so the file is honest either way. The cost of not deciding is
  only that the next reader re-derives the divergence.

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

# 1. dispatch-loop's arc ref is corrected, and arc-015 is gone from the table entirely.
P=tests/fixtures/aef-bpmn/PROVENANCE.md; grep -q '`dispatch-loop` | T-215 | \*\*pair-draft\*\* (AEF arc-014' "$P" && ! grep -q 'arc-015 )\?|' "$P"
# 2. The file no longer describes the three rows as one-sided/unconfirmed — the condition
#    that was true on 2026-08-12 morning and is not true now.
P=tests/fixtures/aef-bpmn/PROVENANCE.md; ! grep -q "asserted on 832 evidence alone" "$P" && ! grep -q "Unconfirmed by AEF" "$P"
# 3. BOTH definitions are stated, AEF's carrying its source rather than a paraphrase.
P=tests/fixtures/aef-bpmn/PROVENANCE.md; grep -q "T-2553:101" "$P" && grep -q "AEF or 832" "$P" && grep -q "drafting-agent" "$P"
# 4. Per-file contribution is recorded: zero AEF bytes, counterpart drafts for two, none
#    for offpage-seam, and the T-559 boundary named as why the joint step exists at all.
P=tests/fixtures/aef-bpmn/PROVENANCE.md; grep -q "zero AEF content" "$P" && grep -q "no AEF counterpart draft at all" "$P" && grep -q "T-559 boundary" "$P"
# 5. The label question is OPEN and was NOT applied. AEF's recommendation is recorded, and
#    the table still carries exactly 3 pair-draft rows — a relabel would change that count.
P=tests/fixtures/aef-bpmn/PROVENANCE.md; grep -q "the operator's call — not applied here" "$P" && test "$(grep -c '^| `.*| \*\*pair-draft\*\*' "$P")" -eq 3
# 6. Every assertion in the rewritten block is traceable — rail offsets, task ids, shas.
P=tests/fixtures/aef-bpmn/PROVENANCE.md; grep -q "DM 556" "$P" && grep -q "rail 118" "$P" && grep -q "T-2561" "$P" && grep -q "2640d597" "$P"
# 7. The normative-fixture guard still resolves every named path after the edit.
python3 tools/_t365-normative-fixture-guard.py > /tmp/.t449-7.out 2>&1 && grep -q "PASS" /tmp/.t449-7.out
# 8. The fixture corpus itself is untouched by this doc change — provenance is a claim
#    ABOUT the bytes and must never quietly become a claim that edits them.
test -z "$(git diff --name-only HEAD -- tests/fixtures/aef-bpmn/ | grep -v PROVENANCE.md)"

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

## Recommendation

**Recommendation:** GO on the file change; the Human AC is a separate ruling and stays open.

**Rationale:** Everything landed here is a measurement or a quotation, and the one factual
error (arc-015) is corrected against a citable source on AEF's side. Nothing in the rewrite
depends on my judgment. The part that *does* require judgment — which definition of
"pair-draft" this table ratifies — was deliberately not exercised: no row was relabelled,
the 15/3 split is unchanged, and both readings sit in the file with their sources.

On the open question, if you want my read rather than a neutral presentation: **option (b)**.
It is the only one of the three that survives both definitions. (a) leaves the table
asserting a contrast the byte evidence does not support. (c) is factually clean but throws
away the real thing AEF contributed — two independent counterpart drafts and, for
`offpage-seam`, a live uuid we structurally could not obtain ourselves. (b) records
contribution instead of authorship, which is what the evidence actually distinguishes.
I have not applied it, because "which taxonomy does this file use" is a sovereignty call
and my preferring one does not make it a measurement.

**Evidence:**
- `tests/fixtures/aef-bpmn/PROVENANCE.md` — the rewritten block; 8/8 Verification legs pass,
  including one asserting the table still carries exactly 3 pair-draft rows (a relabel would
  change that count, so the leg fails if the taxonomy were silently adopted)
- AEF DM 556 + their `docs/reports/T-2934-pair-draft-provenance.md` — the records check,
  owed since DM 549 §6 and promised across four rails
- arc correction: their T-2568 carries `arc:designer-corpus` (arc-014); their arc-015 is
  `onboarding-shape-detection`
- `python3 tools/_t365-normative-fixture-guard.py` → PASS, every normatively-named path
  still resolves after the edit
- `git diff --name-only HEAD -- tests/fixtures/aef-bpmn/` → PROVENANCE.md only; no fixture
  byte was touched by a change to a claim *about* those bytes

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

### 2026-08-12T09:35:39Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-449-provenance-pair-draft-rows-are-two-sided.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a12f0af5
- **Timestamp:** 2026-08-12T09:38:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T09:38:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
