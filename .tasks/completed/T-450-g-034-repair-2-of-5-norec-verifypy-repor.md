---
id: T-450
name: "G-034 repair 2 of 5: _norec-verify.py reports a silent zero over an empty approvals
  queue"
description: >
  G-034 repair 2 of 5: _norec-verify.py reports a silent zero over an empty approvals
  queue

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T10:38:20Z
last_update: '2026-08-16T12:33:59Z'
date_finished: 2026-08-12T10:44:11Z
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
  - ts: '2026-08-16T12:33:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-450: G-034 repair 2 of 5: _norec-verify.py reports a silent zero over an empty approvals queue

## Context

Second of the five instruments T-440 measured BLIND (G-034), and the one T-440's
findings now name load-bearing after the T-101 caller claim was retracted:
`tools/_norec-verify.py` is the operator's approvals-queue guard. It exists because
the operator once opened the queue, was told there was nothing to approve, and eight
handed-over tasks were sitting in NO-REC (T-228 + that sweep).

It reports its own zero in exactly that voice. Its last line is a tally of FAILURES
alone —

    %d task(s) with pending Human ACs lack a Recommendation verdict

— so `0 task(s) …` at exit 0 is emitted by three different worlds that the operator
cannot tell apart from the text:

1. the corpus is unreadable / empty (`.tasks/` missing or holding no `*.md`),
2. the corpus is fine and **nobody has handed anything over** (queue genuinely empty),
3. the corpus is fine, N tasks are handed over, and **all of them carry a verdict**.

Only (3) is the green this guard was built to certify. (1) is the G-034 defect. (2) is
a legitimate state the guard should still name, because "nothing to approve" is the
precise sentence that misled the operator in the first place — the guard must not be
able to say it without also saying how many task files it read to get there.

Same repair shape as T-447: derive the denominator from the authority (CLAUDE.md's
`.tasks/active` + `.tasks/completed` file structure), never restate it; refuse at rc 2
rather than collapsing "measured nothing" into 0 or 1 (T-430 abstention discipline);
and verify with the drive harness asserting **three** counts, because an instrument
that becomes undrivable leaves the same trace as one that got fixed (PL-160).

## Acceptance Criteria

### Agent
- [x] An emptied corpus (both task dirs present, zero `*.md`) refuses at **rc 2**, with
      the rc read directly from the process and not through a pipeline (the 553/557 swallow)
- [x] A **missing** task directory refuses at rc 2 and names which directory is missing
- [x] The verdict on the REAL corpus is unchanged by the repair — same exit code and the
      same NO-REC file set as `git show HEAD:tools/_norec-verify.py` produces
- [x] The success line carries **three** counts (task files examined · carrying pending
      Human ACs · lacking a verdict), so world (2) and world (3) above are distinguishable
      in the text alone
- [x] The denominator DERIVES: adding a task file to a throwaway corpus moves the examined
      count with no edit to the tool (PL-158 — behavioural test, not a grep for a constant)
- [x] `bash tools/_t440-drive-empty.sh _norec-verify` reports **driven 1 / BLIND 0 /
      CANNOT-DRIVE 0** — all three asserted together, not the headline alone
- [x] The docstring documents rc 2 as abstention and states no corpus size

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
# Every rc below is read DIRECTLY from the process, never through a pipeline.
# `python3 tool.py | tail -3` reports tail's status — AEF's rail 553 finding, which
# I then committed myself at T-447 while measuring a fix for exit-code blindness,
# and which AEF committed again at rail 560 measuring my report of it. Two
# independent instances in one exchange: the trap is structural, not a lapse.

# 1. An EMPTY corpus (both task dirs present, zero *.md) refuses at rc 2.
S=$(mktemp -d); mkdir -p "$S/tools" "$S/.tasks/active" "$S/.tasks/completed"; cp tools/_norec-verify.py "$S/tools/"; (cd "$S" && python3 tools/_norec-verify.py > /tmp/.t450-1.out 2>&1); test $? -eq 2
grep -q "REFUSING" /tmp/.t450-1.out
# 2. A MISSING task directory refuses at rc 2 and names which one is missing.
S=$(mktemp -d); mkdir -p "$S/tools" "$S/.tasks/active"; cp tools/_norec-verify.py "$S/tools/"; (cd "$S" && python3 tools/_norec-verify.py > /tmp/.t450-2.out 2>&1); test $? -eq 2
grep -q "task directory missing: .tasks/completed" /tmp/.t450-2.out
# 3. The REAL corpus verdict is unchanged by the repair: still rc 1.
python3 tools/_norec-verify.py > /tmp/.t450-new.out 2>&1; test $? -eq 1
# 3b. ...and the NO-REC set is byte-identical to what the pre-repair file produces.
git show HEAD:tools/_norec-verify.py > /tmp/.t450-head.py && python3 /tmp/.t450-head.py > /tmp/.t450-head.out 2>&1; grep '^NO-REC:' /tmp/.t450-head.out > /tmp/.t450-a; grep '^NO-REC:' /tmp/.t450-new.out > /tmp/.t450-b; diff -q /tmp/.t450-a /tmp/.t450-b
# 4. Three counts, not one — an empty queue and a clean queue are different sentences.
A=$(mktemp -d); mkdir -p "$A/tools" "$A/.tasks/active" "$A/.tasks/completed"; cp tools/_norec-verify.py "$A/tools/"; printf -- '---\nid: T-001\n---\n## Acceptance Criteria\n### Agent\n- [x] done\n' > "$A/.tasks/active/T-001.md"; (cd "$A" && python3 tools/_norec-verify.py > /tmp/.t450-4.out 2>&1); test $? -eq 0
grep -q "Queue is EMPTY, not merely clean" /tmp/.t450-4.out
# 4b. A queue that is non-empty AND clean must NOT claim to be empty.
B=$(mktemp -d); mkdir -p "$B/tools" "$B/.tasks/active" "$B/.tasks/completed"; cp tools/_norec-verify.py "$B/tools/"; printf -- '---\nid: T-002\n---\n## Acceptance Criteria\n### Human\n- [ ] check it\n\n## Recommendation\n**Recommendation:** GO\n' > "$B/.tasks/active/T-002.md"; (cd "$B" && python3 tools/_norec-verify.py > /tmp/.t450-4b.out 2>&1); test $? -eq 0
grep -q "1 with pending Human ACs" /tmp/.t450-4b.out && ! grep -q "Queue is EMPTY" /tmp/.t450-4b.out
# 5. The denominator DERIVES from TASK_DIRS: grow a throwaway corpus, the count follows
#    with no edit to the tool. A grep for a constant cannot show this either way (PL-158).
C=$(mktemp -d); mkdir -p "$C/tools" "$C/.tasks/active" "$C/.tasks/completed"; cp tools/_norec-verify.py "$C/tools/"; for n in 1 2 3 4 5 6 7; do printf -- '---\nid: T-00%s\n---\n### Agent\n- [x] d\n' "$n" > "$C/.tasks/completed/T-00$n.md"; done; (cd "$C" && python3 tools/_norec-verify.py > /tmp/.t450-5.out 2>&1); grep -q "examined 7 task file(s)" /tmp/.t450-5.out
# 6. The drive harness: THREE counts asserted together. `BLIND 0` alone is unreadable —
#    an instrument that becomes undrivable and one that got repaired print the same
#    headline (PL-160, and the false finish this repair pattern hit at T-447).
bash tools/_t440-drive-empty.sh _norec-verify > /tmp/.t450-6.out 2>&1; test $? -eq 0
grep -qE "^  driven +1$" /tmp/.t450-6.out && grep -qE "^  BLIND +0$" /tmp/.t450-6.out && grep -qE "^  CANNOT-DRIVE +0$" /tmp/.t450-6.out
# 7. The docstring documents rc 2 and states no corpus size.
grep -q "2  the corpus could not be enumerated" tools/_norec-verify.py

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

**Symptom:** `tools/_norec-verify.py` prints
`0 task(s) with pending Human ACs lack a Recommendation verdict` and exits 0 when run
against a tree with no `.tasks/` directory at all — character-identical to the sentence
it prints over a healthy, fully-verdicted queue. Measured, both before and after:

| corpus | before T-450 | after |
|---|---|---|
| no `.tasks/` directory | `0 task(s) …` **rc 0** | `REFUSING: task directory missing: …` **rc 2** |
| dirs present, zero `*.md` | `0 task(s) …` **rc 0** | `REFUSING: no *.md task files …` **rc 2** |
| corpus fine, queue empty | `0 task(s) …` **rc 0** | `examined 1 · 0 pending · 0 without` + `Queue is EMPTY, not merely clean` **rc 0** |
| corpus fine, queue clean | `0 task(s) …` **rc 0** | `examined 1 · 1 pending · 0 without` **rc 0** |
| real corpus | 14 NO-REC, **rc 1** | 14 NO-REC (identical set), **rc 1** |

**Root cause:** the verdict was computed from a tally of FAILURES alone. `len(bad)` is a
count of things that went wrong, and a count of things that went wrong is 0 both when
nothing went wrong and when nothing was looked at. The subject population — tasks
carrying pending Human ACs — was computed implicitly inside the loop and never named,
so neither the denominator nor the handed-over count reached the operator's eye.

**Why structurally allowed:** nothing in the framework requires a guard's output to name
the population it ranged over. P-011 reads an exit code; a zero exit code satisfies it
whether or not anything was examined. This is G-034, and it is the second of five
instances measured under T-440.

The aggravating factor specific to this tool is that its *only* invocation is inside
`.tasks/completed/T-236-*.md`'s `## Verification` block. P-011 runs a Verification block
on the `work-completed` transition and at no other time — so this "standing guard" has
executed exactly once, on 2026-07-22, and never since. Its silence has therefore never
been anyone's evidence of anything, which is why nobody noticed the queue regrow from
0 NO-REC to 14. Filed separately as **T-451** (one bug, one task).

**Prevention:** the repair is not the prevention. The prevention is
`tools/_t440-drive-empty.sh`, which drives every in-population instrument against an
emptied tree and reports `driven / BLIND / CANNOT-DRIVE` as three numbers. It scores
this file `driven 1 / BLIND 0 / CANNOT-DRIVE 0` and would score a regression BLIND 1.
G-034 remains `watching` until the remaining three are repaired and the 59 undrivable
instruments are addressed — a repair count is not a closure condition.

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

### 2026-08-12T10:38:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-450-g-034-repair-2-of-5-norec-verifypy-repor.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-415a0655
- **Timestamp:** 2026-08-12T10:44:18Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T10:44:11Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
