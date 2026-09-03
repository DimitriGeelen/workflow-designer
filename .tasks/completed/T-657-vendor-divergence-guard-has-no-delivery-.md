---
id: T-657
name: "Vendor-divergence guard has no delivery surface: 6 unrecorded, red twice unnoticed"
description: >
  Vendor-divergence guard has no delivery surface: 6 unrecorded, red twice unnoticed

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t657-vendor-divergence-must-reach-an-audit-line.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-31T18:27:39Z
last_update: 2026-08-31T18:36:47Z
date_finished: 2026-08-31T18:36:47Z
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

# T-657: Vendor-divergence guard has no delivery surface: 6 unrecorded, red twice unnoticed

## Context

OBS-333. `tools/_t517-vendor-divergence.py` is a correct guard with no delivery surface.
It has now been found red after a long unread stretch **twice**: once at "1 unrecorded"
from commit 10a537c1 until 2026-08-29 (recorded in the register's own T-606 entry), and
again on 2026-08-31 at **6 unrecorded**. It is correct both times. Nothing looks at it,
because its only host is a ~13-minute bridge suite that nothing runs on a schedule.

This is the same shape as T-654's completion watchdog: a detector that fired perfectly and
whose every detection was lost. **Detection was never the variable; delivery was.** The
remedy there was one audit line, and the same remedy is available here — the divergence
check alone is seconds, not minutes, so it can be an audit line rather than a suite member.

Scope is the delivery surface plus whatever the newly-visible control then reports, so the
line lands honest rather than landing green by not looking.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The divergence check runs as an **audit line**, not only as a member of the bridge
      suite: `fw audit --section structure` reports a PASS/WARN naming the unrecorded
      count. Reuses `tools/_t517-vendor-divergence.py` — the check is not reimplemented in
      bash (LANDING MODE: never reimplement a framework function, call it).
- [x] The added line is **cheap enough to belong in the audit**: measured wall-clock for
      the divergence check alone is recorded in this task and is under 30s. If it is not,
      the audit line is not the right host and I say so here instead of shipping it.
- [x] Each of the 6 currently-unrecorded entries is **dispositioned individually**, with
      the disposition stated per file. For each, exactly one of:
      (a) a real, intended local divergence → recorded in `.vendor-divergence.yaml` with
          an `upstream:` lane; or
      (b) an accidental/stale local edit that should not exist → reverted, not papered
          over with a manifest entry; or
      (c) genuinely the operator's call (e.g. fork-vs-upstream) → left unrecorded and
          surfaced to /approvals with the exact command. Not decided by me.
      A blanket "record all 6" is a failure of this AC, not a pass.
- [x] After disposition, the new audit line reads green **or** its remaining count is
      exactly the number of (c) entries, and the line names them as operator-gated rather
      than as a defect.
- [x] A prober asserts the audit line has teeth: it greps the real region out of
      `audit.sh` (does not retype it), drives it against fixture state, and includes a
      mutation leg that neutralises the check and confirms the line stops reporting. The
      mutation count is asserted — a half-mutation reads like a passing subject (T-656).
- [x] The prober asserts **which** surface produced the verdict, not merely that a verdict
      appeared. T-654's first green came through the wrong branch; a green that does not
      name its path is not evidence about the path I meant.
- [x] Any framework-file change is declared in `.vendor-divergence.yaml` with an
      `upstream:` lane (G-008) — including the ones this task itself creates.

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

# The guard itself: exit code IS the verdict, so no chaining and no substring question.
python3 tools/_t517-vendor-divergence.py

# The prober over the audit line: 7 legs, exit code is the verdict.
bash tools/_t657-vendor-divergence-must-reach-an-audit-line.sh

# The edited vendored file must still parse.
bash -n .agentic-framework/agents/audit/audit.sh

# The manifest must still parse (it is hand-edited YAML with folded scalars).
python3 -c "import yaml; yaml.safe_load(open('.agentic-framework/.vendor-divergence.yaml'))"

# The line must actually appear in the REAL audit, not merely in the extracted region.
# Deliberately the `a; b` form (T-352): the audit exits non-zero on its 5 pre-existing
# WARNs, so its exit code is not the verdict here — the grep is. If the audit fails to run
# at all the file has no such line and the grep fails, so this cannot go green on silence.
# Single --section only, never a full `fw audit` (OBS-332: it hangs on the transition's locks).
_o=$(mktemp); .agentic-framework/bin/fw audit --section structure > "$_o" 2>&1; grep -q "Vendor divergence: all" "$_o"

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

**Symptom:** `tools/_t517-vendor-divergence.py` sat FAILING at 6 unrecorded entries. It had
already been found red once before, at 1 unrecorded, from commit 10a537c1 until 2026-08-29.
It was correct on both occasions. Nobody acted on either.

**Root cause:** not the guard, and not any one agent. The guard's only host was a ~13-minute
bridge suite that nothing runs on a schedule, so its verdict had no reader. The six
unrecorded entries came from **four consecutive tasks** — T-624/T-625, T-643/T-644/T-645,
T-648 — each of which made a real, well-reasoned fix to vendored code and none of which
declared it. Four independent agents do not forget the same step by coincidence; the step
was invisible at the moment it was owed.

**Why structurally allowed:** the check was priced at its host. 13 minutes is a cost you
schedule around, so it was scheduled nowhere. Measured standalone, the check is 250-340ms
over a 2158-file baseline — roughly three thousand times cheaper than the number that made
it look unaffordable. Nobody had ever separated the two costs, so the guard inherited the
suite's price and, with it, the suite's frequency: never.

**Prevention:** the check now runs as its own structure-section audit line, on every push
and every cron audit, at a cost that made the old objection meaningless. Distinct from the
fix itself (recording the 6): those would recur; this is what reports the next one.
`tools/_t657-vendor-divergence-must-reach-an-audit-line.sh` guards the surface so it cannot
rot back to unread, including a leg asserting the check stays cheap enough to keep its host.

**Known residual:** delivery, not enforcement. The line WARNs; it does not stop an agent from
shipping an undeclared change in the first place. That gap is real and named in Decisions.

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

### 2026-08-31 — WARN, not FAIL

- **Chose:** the audit line WARNs on undeclared divergence.
- **Why:** a structure-section FAIL blocks push (`agents/git/lib/hooks.sh:844`) and its only
  bypass is `--no-verify`, which is Tier-0 gated and not mine to use. The defect this task
  fixes is that nobody SAW the verdict; appearing in an audit read on every push and every
  cron run is the whole remedy for that. Escalating enforcement is a wider blast radius than
  the task scope and a decision that should be made on evidence rather than bundled in here.
- **Rejected:** FAIL. The case for it is genuinely strong — unlike the stray-root-files WARN
  whose debris is inert, an undeclared fix is *destroyed* by the next re-vendor, which is
  the T-517 learning this whole manifest exists to encode. It is rejected on blast radius,
  not on merit, and the escalation trigger is written into the block: **if an unrecorded
  entry survives three consecutive audits, WARN has failed exactly as the bridge suite did
  and this becomes FAIL.**
- **Reversibility note:** WARN→FAIL is cheap to do later; shipping a push-block and
  discovering it strands a session mid-investigation is expensive to undo.

### 2026-08-31 — the audit.sh change is `local-config`, not `fix`

- **Chose:** classify this task's own vendored edit as `local-config` while all six
  pre-existing entries are `fix`.
- **Why:** the block calls a *project*-local tool and validates a manifest that exists only
  because this project vendors the framework. Upstream does not vendor itself and would
  receive a block that never fires — nothing is owed to them. The six others are real code
  fixes upstream lacks and genuinely are debt.
- **Rejected:** marking it `fix` by reflex because the file is vendored. The taxonomy is only
  worth having if its verdicts differ when the facts differ; six `fix` and one
  `local-config` in the same commit is the taxonomy being used rather than defaulted.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-31T18:27:39Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-657-vendor-divergence-guard-has-no-delivery-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a7a0b932
- **Timestamp:** 2026-08-31T18:37:12Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-31T18:36:47Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
