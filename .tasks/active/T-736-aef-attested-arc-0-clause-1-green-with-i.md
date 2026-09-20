---
id: T-736
name: "AEF attested Arc-0 clause 1 green with its numbers at @1539 — record the response as T-623 did, route ratification to the operator, answer R7"
description: >
  AEF attested Arc-0 clause 1 green with its numbers at @1539 — record the response as T-623 did, route ratification to the operator, answer R7

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-20T08:02:55Z
last_update: 2026-09-20T08:06:47Z
date_finished: 2026-09-20T08:06:47Z
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

# T-736: AEF attested Arc-0 clause 1 green with its numbers at @1539 — record the response as T-623 did, route ratification to the operator, answer R7

## Context

AEF answered on `agent-chat-arc` at **@1539** (their T-3394, arc-019, replying to @643,
acking @1536/@1537). One of three Arc-0 exit clauses moved:

- **Clause 1 — attested GREEN with numbers**, superseding their RED at @650 (recorded by
  T-623). Artifact `docs/research/executable-workflow/arc-0-clause-1-attestation.md` at
  their commit `174f31777`, measured live at `996a4f9a5`: 1279 fabric cards, 544
  Unknown-subsystem, intersection with the Arc-0 CORE write set **0**, BROAD **0**.
  Reported WITH its control (`tools/ewcr-arc0-coverage-check.py`: lib 98.2%, web 98.8%,
  agents/bin/policy 100%) because a bare zero over an uncarded surface is not evidence —
  their words. They also correct their own stale `intersection_count: 3` at 42cd97a2.
- **Clause 2 / R6 — blocked upstream of them.** Their T-3389 needs four external reviews
  copied from `0503-codex-cli-playground` into a `reviews/` directory that does not exist
  in their repo. Two closes, both their operator's: transfer the reviews, or rule the
  DeepSeek/Mistral findings out of Arc-0 scope.
- **R7 — they want our SD-1 disposition record** before naming a source of truth. That
  record is IW-11, `questions-and-dispositions.md:158-167`.
- They confirm H3: manifest correlations still UNASSIGNED; "we are transacting on a
  handoff it forbids opening."

Per roadmap §2.3, @1539 is transport evidence, not collaboration completion. It does not
flip `attestation:` or `definition_ratified:`. Those are the operator's, at
/review/T-732. This task records the response where T-623 recorded the previous one,
answers the one thing that was asked of us, and routes the ruling.

## Acceptance Criteria

### Agent
- [x] Clause 1's `counterparty_response:` in `arc-0-exit-clauses.yaml` carries AEF's @1539
      answer in the same shape T-623 used at @650 — offset, thread, their commit, their
      measurement, their verdict, their own §2.3 disclaimer quoted — as a SUPERSEDING
      entry that keeps the @650 RED record intact beneath it.
      → `counterparty_response_superseding:` added between the @650 block and
      `blocks_arc_0_exit: true`; @650 untouched.
- [x] `attestation:` and `definition_ratified:` on every clause are byte-identical before
      and after this task. The agent records what the counterparty said; it does not
      certify it.
      → Measured: HEAD and worktree both 2× `attestation: null`, 3× `definition_ratified:
      false`, 3× `blocks_arc_0_exit: true`. Verification leg 2 re-asserts it.
- [x] R7 is answered on the rail with the IW-11 disposition record quoted inline and its
      file:line cited — not `file_send`, which is not a delivery mechanism for seam bytes
      until AEF's OBS-108 closes (refs only).
      → @1552, `questions-and-dispositions.md:158-167` quoted verbatim.
- [x] The ACK to @1539 states plainly what we did and did not do: recorded, not ratified;
      clause 2's two closes are noted as their operator's, and not re-asked.
      → @1552 §"WHAT I DID NOT DO" and §"CLAUSE 2 / R6 — NOTED, NOT RE-ASKED".
- [x] The YAML still parses after the edit.
      → `yaml.safe_load` rc=0; verification leg 1.

### Human
- [ ] [REVIEW] Rule on clause 1 — this is the ratification AEF's post explicitly declines
      to be.
  **Steps:**
  1. Read @1539 (or the `counterparty_response_superseding` block in
     `docs/research/executable-workflow/arc-0-exit-clauses.yaml`, which quotes it).
  2. Open http://192.168.10.107:3013/review/T-732 — H1/H3/H5/H6 are already queued
     there, and this ruling belongs alongside them because H3 gates the same handoff.
  3. Decide clause 1. Pick one:
     **A — Ratify.** Set `attestation:` to cite @1539 / their commit `174f31777` and
     `definition_ratified: true` on clause 1. Arc-0 moves to 1 of 3.
     **B — Ratify conditionally** on re-measuring at a pinned AEF commit you name.
     **C — Decline** and say what a satisfying attestation would carry that this one
     does not. AEF has answered twice on their own numbers; a third ask should be
     specific.
  **Expected:** One letter, and the two field edits if A or B. Both fields are yours —
  the agent left them byte-identical to HEAD and verified that.
  **If not:** Nothing regresses. The record stands as transport evidence; Arc 0 stays at
  0 of 3 and `blocks_arc_0_exit` stays true.

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
         1. Run `bin/fw reviewer T-736`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-736 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# 1. The register still parses.
python3 -c "import yaml; yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml'))"
# 2-3. The operator's fields are pinned at their pre-task values. Only the operator may
#      move them; if this goes red, someone other than the operator did.
test "$(grep -c '^    attestation: null' docs/research/executable-workflow/arc-0-exit-clauses.yaml)" -eq 2
test "$(grep -c '^    definition_ratified: false' docs/research/executable-workflow/arc-0-exit-clauses.yaml)" -eq 3
# 4. The superseding record exists.
grep -q 'counterparty_response_superseding:' docs/research/executable-workflow/arc-0-exit-clauses.yaml
# 5. The @650 RED record it supersedes is still there — history kept, not replaced.
grep -q '^      offset: 650' docs/research/executable-workflow/arc-0-exit-clauses.yaml

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

**Recommendation:** GO — ratify clause 1 (option A), and rule it at /review/T-732 alongside
H3 rather than separately, because the same handoff gates both.

**Rationale:** This is the second counterparty answer on the clause and the first that
satisfies it. It is stronger than a bare green: it carries the measurement, the commit it
was measured at, a control that discriminates a real zero from a zero over an uncarded
surface (and once caught exactly that), and a correction against their own stale figure.
It is also scoped honestly — Arc-0 write set, not repo-wide — which is the scoping error
they declined to make in our direction at @650. Declining it would need a reason this
post does not already answer.

**Evidence:**
- @1539 on `agent-chat-arc`, correlation EWCR-ARC0-ATTEST-832, their T-3394 / `174f31777`.
- Recorded verbatim as `counterparty_response_superseding` in `arc-0-exit-clauses.yaml`;
  @650 RED retained above it. YAML parses.
- `attestation: null` ×2 and `definition_ratified: false` ×3 — byte-identical to HEAD,
  measured, and pinned by verification legs 2-3.
- Our reply @1552: recorded-not-ratified stated; R7 answered with IW-11 inline.

**What it unblocks:** Arc 0 moves 0 → 1 of 3. Clause 2 is then the sole counterparty
blocker, and its two closes are AEF's operator's, not ours. Clause 3 stays on H1/H5/H6.

## Evolution

### 2026-09-20 — the thing AEF asked for was already on our side, and it was a deferral
- **What changed:** R7 read as "reconcile SD-1 against the dossier". The actual record,
  IW-11, does not attempt reconciliation — it DEFERS to AEF by name and asks one question
  (successor or extension). So "send the disposition record" was not a request for our
  position; it was a request to confirm we did not have one. Ten lines, quotable inline,
  no transfer needed.
- **Plan impact:** No `file_send`, no new artifact, no dossier edit. The only Designer-side
  act R7 needed was pointing at the right ten lines.
- **Triggered:** nothing new. IW-13(b) already records that a "successor" ruling changes
  the interchange contract's owner — the predicate is filed and waiting.

### 2026-09-20 — the register edit is the T-623 shape, and the earlier refusal to edit it stands
- **What changed:** Earlier this session I declined to correct the `rail_citation_integrity`
  block in this same file and called it governance. This task DOES edit the file. The two
  are consistent: that block is a prior measurement now at operator review (T-733), and
  rewriting it would be rewriting history under review; this task APPENDS a new
  counterparty record, which is what T-623 did for @650 and touches no operator field.
- **Plan impact:** The line is "append transport records; never move `attestation:` or
  `definition_ratified:`; never rewrite a prior entry". Verification legs 2-3 and 5 make
  that line mechanical for this task.

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
     fw inception decide T-736 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-20T08:02:55Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-736-aef-attested-arc-0-clause-1-green-with-i.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ff260d0b
- **Timestamp:** 2026-09-20T08:06:48Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-20T08:06:47Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
