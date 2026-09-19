---
id: T-734
name: "NEW SCOPE: absence claimed from a truncated search — guard the Arc-0 evidence base against the defect that produced OBS-352 and OBS-353"
description: >
  NEW SCOPE: absence claimed from a truncated search — guard the Arc-0 evidence base against the defect that produced OBS-352 and OBS-353

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t734_absence_guard.py]
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-19T21:23:00Z
last_update: 2026-09-19T21:27:35Z
date_finished: 2026-09-19T21:27:35Z
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

# T-734: NEW SCOPE: absence claimed from a truncated search — guard the Arc-0 evidence base against the defect that produced OBS-352 and OBS-353

## Context

**NEW SCOPE** under arc-002 (ewcr-governed-delivery), filed 2026-09-19.

Twice in one week this project told its operator that evidence was missing when it was
not. OBS-352 concluded a rail post was "most likely unread"; OBS-353 corrected it to
"gone", and asserted that **every** offset the Arc-0 exit register cites was dangling.
Both were wrong, and re-measurement (OBS-354) showed the cited chain intact and readable:
`@602 @629 @639 @643 @734 @737 @741 @744 @777 @786`.

The cause is the same in both, and it is not a rail defect — it is a **reading** defect.
Each conclusion rested on a search whose result set was truncated by its own `limit`,
read as though it were exhaustive. A search returning N hits under `limit=N` has said
nothing whatever about hit N+1. Absence was inferred from a window, not measured.

This matters to arc-002 specifically because the Arc-0 exit register is **built out of
rail citations**. An instrument that can silently mistake truncation for absence is
pointed directly at the arc's evidence base, and it has already put a false
`rail_citation_integrity` block into `arc-0-exit-clauses.yaml`.

Fixed at the **definition site**, not the call site — this project posted that exact
lesson to the mesh at agent-chat-arc @557 ("a guard present in four copies and absent
from seventy-three is not a guard, it is a coincidence") and then committed the
call-site version of the error anyway.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/_t734_absence_guard.py` exists and exports `assert_exhaustive(result, *, limit)`
      which **raises** `TruncatedSearchError` when a result set may be truncated, and
      returns the hit list otherwise
- [x] The guard treats **three** distinct signals as "not safe to conclude absence":
      `count >= limit`, an explicit `all: false` in the response, and a present
      `next_cursor`/continuation token — any one of them is sufficient to refuse.
      Each is pinned by a case that carries **only** that signal (cases 5, 6, 7)
- [x] A zero-hit result is refused too when the response carries a truncation signal —
      this is the exact OBS-352/353 shape and the leg is proven failable (it is one of
      the 6 that go red under the poison arm)
- [x] `tools/_t734_absence_guard.py --self-test` runs the full case table and exits 0;
      it exits non-zero if any case is removed or weakened (the table is the test).
      **Both halves mutation-tested** — see `## Verification` evidence below
- [x] The self-test includes a **poison arm** faithful to the pre-fix behaviour: with the
      guard neutered to `return result["hits"]`, the absence cases go red. A partial
      poison is explicitly rejected (the @540 lesson: an unfaithful arm manufactures the
      vacuous leg it exists to prevent). Measured: 6 red of 6 that must
- [x] The real OBS-353 response shape is a fixture in the case table, not a paraphrase —
      `count: 12, limit: 12`, the response that produced the false finding

**Evidence, measured 2026-09-19 (true exit codes, not pipeline tails — L-387):**

| Arm | Result | rc |
|---|---|---|
| live | `GREEN — 11/11 green live, 6 red under poison` | 0 |
| mutation B: one case deleted from the table | `RED — the case table shrank below its floor (10/11 cases, 5/6 refusing)` | 1 |
| mutation C: `count >= limit` signal disabled | `RED — the guard does not hold` | 1 |
| poison arm (faithful, whole pre-fix behaviour) | 6 of 6 refusing cases go red | n/a |

The ratchet in mutation B is the load-bearing one. Without it the table could be quietly
shrunk and the suite would still print GREEN — a green number from a population that can no
longer exercise the check, which is the exact defect this tool exists to catch. It would
have been easy to claim "the table is the test" without building it; the claim was in the AC
before the mechanism was, and the mechanism was added because the claim was checked.

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
         1. Run `bin/fw reviewer T-734`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-734 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# Leg 1 — the guard holds and its legs are failable (case table + poison arm).
python3 tools/_t734_absence_guard.py --self-test

# Leg 2 — the table ratchet actually ratchets. Delete one case in a THROWAWAY copy
# and require a non-zero exit. Asserts the property AC 4 claims, rather than trusting it.
python3 -c 'import subprocess,sys,tempfile,os; src=open("tools/_t734_absence_guard.py").read(); i=src.index("    (\n        \"signal 3 alone"); j=src.index("    # --- the safe cases"); p=os.path.join(tempfile.mkdtemp(),"m.py"); open(p,"w").write(src[:i]+src[j:]); r=subprocess.run([sys.executable,p,"--self-test"],capture_output=True,text=True); ok=(r.returncode!=0 and "shrank below its floor" in r.stdout); print("deleted-case arm rc=",r.returncode,"| ratchet fired:",ok); sys.exit(0 if ok else 1)'

# Leg 3 — the OBS-353 fixture is the real shape, not a paraphrase: the guard must REFUSE
# the exact response that produced the false finding (count 12 == limit 12).
python3 tools/_t734_absence_guard.py --assert-fixture

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

**The AC was written before the mechanism existed, and checking the AC is what built it.**
AC 4 claimed the case table "exits non-zero if any case is removed or weakened". The
weakening half was true from the first draft — disabling a signal makes live cases fail.
The *removal* half was not: deleting a case simply produced a smaller suite that still
printed `GREEN — 10/10`, which is precisely a green number from a population that can no
longer exercise the check. That is the same defect as the rail search this task exists to
guard against, reproduced inside the guard, in the same hour. Fixed with an explicit floor
(`MIN_CASES` / `MIN_REFUSING_CASES`) and then mutation-tested rather than asserted.

**What changed about the scope.** Filed intending a rail-specific citation checker for
`arc-0-exit-clauses.yaml`. Abandoned that shape during build: it needs live rail access, so
its own verification would have depended on the substrate whose trustworthiness is the open
sovereign question in T-733 — a check that cannot be run when the thing it checks is broken.
The guard shipped instead is substrate-free and unit-testable offline, and it sits at the
*reading* step, which is where both OBS-352 and OBS-353 actually failed. The rail was never
the defect; the inference from a windowed result was.

**A lesson this project had already published and then violated.** agent-chat-arc @557,
ours: "a guard present in four copies and absent from seventy-three is not a guard, it is a
coincidence — a fix applied at the call site instead of the definition site will be re-found
as a new bug." OBS-353 was that re-finding. The guard is therefore a single importable
definition, and the OBS-353 fixture lives in the tool as `--assert-fixture` rather than as a
re-typed one-liner in a task file — a verification leg that must be re-typed per call site
is the call-site pattern wearing a different hat.

**One shape the multi-line leg exposed.** The first draft of leg 3 was a four-line
`python3 -c` block. P-011 runs each *line* as its own command, so it would have executed four
broken fragments and been judged on the last one. Caught before completion, not by the gate.

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
     fw inception decide T-734 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-19T21:23:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-734-new-scope-absence-claimed-from-a-truncat.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-c388bd69
- **Timestamp:** 2026-09-19T21:27:37Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-19T21:27:35Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
