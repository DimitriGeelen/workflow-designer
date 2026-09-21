---
id: T-774
name: "create-task.sh rewrites the task name and empties the ownership field when
  the name contains the ownership token"
description: >
  create-task.sh rewrites the task name and empties the ownership field when the name
  contains the ownership token

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
created: 2026-09-21T14:11:41Z
last_update: '2026-09-21T20:25:10Z'
date_finished: 2026-09-21T14:22:42Z
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
cost_estimate_proposed:
  - ts: '2026-09-21T20:25:10Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:./tools/_t774-create-task-substitution-probe.sh,.agentic-framework/.vendor-divergence.yaml,.agentic-framework/agents/task-create/create-task.sh,.fabric/components/tools-_t774-create-task-substitution-probe.yaml);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-774: create-task.sh rewrites the task name and empties the ownership field when the name contains the ownership token

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The defect is reproduced against the SHIPPED script before anything is changed.**
      Run against `create-task.sh` itself with `PROJECT_ROOT`/`TASKS_DIR` pointed at a
      throwaway fixture — the same override the framework's own
      `tests/unit/create_task.bats:18` relies on, so this is the supported path and not a
      hole I found.

      ```
      --name 'SQ-9 upstream: report the owner:human-with-zero-ACs fault' --owner agent
      ->  name: "SQ-9 upstream: report the owner: agenthuman-with-zero-ACs fault"
          owner:
      ```

      Identical in shape to the T-768 instance OBS-363 was filed from.
      A task created with a name containing the ownership token must be shown to come out
      with a rewritten name and an empty ownership field. Reproduced by running
      `create-task.sh` itself, not a transcription of its logic into a test — a copy of the
      substitution would prove only that my copy behaves as I wrote it.

- [x] **Every bare-key frontmatter substitution is line-anchored.** `_fm(t, key, line)`
      replaces the first line *inside the frontmatter block* that STARTS WITH the key.
      A key appearing mid-line inside a value can no longer capture the substitution.
      Applied to both template branches — they are near-duplicates and fixing one would
      have left every inception task exposed. Verified on the inception branch
      specifically (leg 5 of the probe), not assumed from the default branch.

      The mechanism was
      `t.replace('<key>:', ..., 1)` over a document into which the user-supplied NAME has
      already been injected, so the first match can land inside the name. Anchoring each
      substitution to a line that *starts with* the key removes the whole class, not just
      the measured instance. Applied to both template branches (inception and default) —
      the code is duplicated and fixing one would leave the other live.

- [x] **The blast radius is stated, not just the reported field.** OBS-363 reports one
      field. Measured: **at least seven**, in two distinct severities.

      | key | substitution | name | field |
      |---|---|---|---|
      | `owner:` | count=1 | corrupted | **emptied** |
      | `workflow_type:` | count=1 | corrupted | **emptied** |
      | `created:` | count=1 | corrupted | **emptied** |
      | `last_update:` | count=1 | corrupted | emptied |
      | `description: >` | count=1 | corrupted | emptied |
      | `status: captured` | unbounded | corrupted | survives |
      | `horizon: now` | unbounded | corrupted | survives |
      | `tags: []` / `related_tasks: []` | unbounded | corrupted | survives |
      | `id: T-XXX` | — | safe | safe (nothing injected yet at that point) |

      The split is mechanical, not incidental. A `count=1` substitution spent inside the
      name never reaches its own line, so the field stays blank. An unbounded one replaces
      every occurrence including its own, so the field is right and only the name is
      wrong. **The dangerous half is the quiet half** — an empty ownership field breaks
      ownership resolution and the audit's compliance checks, and nothing at creation time
      says so.

      **A false negative I nearly shipped.** My first blast-radius sweep reported
      `status`, `horizon` and `tags` CLEAN. They were not: with default arguments the
      substitution is an identity — `status: captured` -> `status: captured` — so the leg
      could not have failed whatever the code did. Re-run with `--start`, `--horizon
      later` and `--tags ui`, all three showed the corruption. Three of five results in
      that sweep were measuring nothing (PL-178), and they looked exactly like passes.

      OBS-363 reports
      `owner:`. The same unanchored first-match pattern governs the other bare-key
      substitutions in the same block. Each one is enumerated with a verdict on whether it
      is reachable, and the ones that are get the same fix.

- [x] **A probe asserts the fix and carries a negative control.**
      `tools/_t774-create-task-substitution-probe.sh` — **13 legs, 13 pass**, covering all
      four reachable key classes plus the inception branch.

      The control rebuilds the pre-fix substitution for the ownership field in a throwaway
      copy of the script and **requires the defect to reappear**; if the poisoned copy comes
      out clean the probe fails itself, on the grounds that it has just demonstrated it
      cannot detect what it claims to. Live output:

      ```
      PASS  pre-fix copy reproduces the defect (name rewritten, ownership emptied)
            name: "SQ-9 upstream: report the owner: agenthuman-with-zero-ACs fault"
      ```

      The control also had to be debugged, which is the evidence it is real: the first
      version put the copy in `$WORK` and it could not start at all, because
      `create-task.sh` derives `FRAMEWORK_ROOT` from `dirname $0`. It reported *"no task
      file"* — which is indistinguishable, from the outside, from a passing fix. Moved
      beside the original under a hidden name, removed on every exit path.

      The standard this meets: the probe was shown to go RED against the pre-fix
      substitution and GREEN after. A probe that has only ever passed has not been shown
      to measure anything (PL-178).

- [x] **The probe creates no task files in the project's own register.** Every leg runs
      against a `mktemp -d` fixture holding its own `.tasks/active`, `.tasks/templates`
      and `.framework.yaml`. Nothing is written under this project's `.tasks/`, and the
      negative-control copy of the script is deleted by a trap that fires on failure paths
      too. Confirmed after the run: the hidden copy is gone and `.tasks/` is untouched.

      It runs the script
      against a throwaway tasks directory. A test that leaves T-NNN debris in `.tasks/`
      corrupts the very register this script exists to maintain.

- [x] **The vendor divergence is declared.** Appended to
      `.agentic-framework/.vendor-divergence.yaml` as `T-774`, `upstream: fix`, carrying
      the measurement, the two-severity split and the two known limits.
      `python3 tools/_t517-vendor-divergence.py` -> *"OK — every diverged path is declared,
      and every declared path still diverges"* (51 declared, 51 diverged).

      Not a duplicate: this path now carries two entries, T-660 and T-774. One entry per
      TASK is the file's established convention — `audit.sh` carries six. Checked rather
      than assumed, because the checker counts unique paths and would not have told me.

      The file is under `.agentic-framework/`, so
      the fix is in-tree per G-008 and owed upstream — every consumer vendoring this script
      has the same defect.

- [x] **Scope held, and the residue is filed rather than buried.** Two adjacent defects
      were found, both confirmed by measurement before filing, neither fixed here:

      - **OBS-364 (urgent)** — a newline inside `--name` **defeats this fix entirely**.
        The injected line break creates a real new line starting with `owner:`, which the
        anchor then honours, so the ownership field is emptied again by a different route
        — and `yaml.safe_load` raises `ParserError` on the result, meaning the generator
        emits a structurally broken task and nothing at creation time notices. Pre-existing;
        this change neither causes nor cures it. **Stated here because a fix with a known
        bypass that is only recorded in the inbox is a fix that reads as complete.**
      - **OBS-365 (urgent)** — a name containing the id placeholder is still rewritten by
        the body-wide pass T-660 added, on both branches. Same root family, different
        mechanism, untouched by frontmatter anchoring.

      One bug, one task: both get their own record rather than riding in on this one.

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
         1. Run `bin/fw reviewer T-774`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-774 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

./tools/_t774-create-task-substitution-probe.sh
bash -n .agentic-framework/agents/task-create/create-task.sh
python3 tools/_t517-vendor-divergence.py
test "$(grep -c 'def _fm(t, key, line):' .agentic-framework/agents/task-create/create-task.sh)" -eq 2
! grep -q "t = t.replace('owner:'" .agentic-framework/agents/task-create/create-task.sh
test -f .fabric/components/tools-_t774-create-task-substitution-probe.yaml

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

**Symptom:** a task whose name contained the ownership token came out with the name
rewritten and the ownership field empty (OBS-363, measured on T-768).

**Root cause:** the generator substitutes frontmatter values with unanchored first-match
`str.replace` calls, and it injects the user-supplied NAME into the document *before* most
of them run. From that point on the document contains attacker-shaped text above every
remaining anchor. The name is not sanitised, the keys are not anchored, and the ordering
puts the two facts in the worst possible sequence.

**Why structurally allowed:** nothing validates the generator's own output. A task file
with an empty ownership field is written, moved into `active/`, and reported as created
successfully — the failure surfaces later and somewhere else, in ownership resolution and
in the audit's compliance checks, where it reads as a task authoring problem rather than a
generator problem. L-302: fix the generator before shipping the detector, or the detector
just reports the generator's output. Here there was no detector either.

**Why it stayed invisible for so long:** PL-164 — prose about a string-matching mechanism
contains the string it matches. The tasks most likely to trigger this are the tasks filed
to describe it, which is a population of roughly one per incident, each of which looks like
a typo at the time.

**Prevention:** `tools/_t774-create-task-substitution-probe.sh`, 13 legs with a negative
control, runnable from any task's `## Verification`. It is a probe, not a gate — nothing
runs it automatically, and saying so is the honest version. OBS-364 names the remaining
hole in the same mechanism and is NOT closed by this task.

**Method note, against myself.** My first blast-radius sweep called three of five keys
clean. They were identity substitutions that could not fail. I caught it by asking why
three keys in the same code path would behave differently from the other two, not by any
check in the probe — the probe as first written would have inherited the same blind spot.
The leg that saves this is the negative control, and it only works because it was built to
fail and then observed failing.

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
     fw inception decide T-774 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T14:11:41Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-774-create-tasksh-rewrites-the-task-name-and.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-599cfe9f
- **Timestamp:** 2026-09-21T14:23:00Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T14:22:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
