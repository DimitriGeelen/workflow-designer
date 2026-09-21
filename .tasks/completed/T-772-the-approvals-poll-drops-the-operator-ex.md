---
id: T-772
name: "The approvals poll drops the operator expand choice every 10 seconds"
description: >
  The approvals poll drops the operator expand choice every 10 seconds

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T12:40:22Z
last_update: 2026-09-21T12:45:15Z
date_finished: 2026-09-21T12:45:15Z
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

# T-772: The approvals poll drops the operator expand choice every 10 seconds

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The poll preserves the operator's expand choice, and the default is unchanged.**
      One line, `approvals.html:238`:

      ```
      hx-get="/approvals/content{% if expand_overflow %}?expand=verifications{% endif %}"
      ```

      Measured after restart: `/approvals?expand=verifications` renders
      `hx-get="/approvals/content?expand=verifications"`; plain `/approvals` still renders
      `hx-get="/approvals/content"`. T-2103's closed-by-default height cap is untouched.

- [x] **Verified the way the operator experiences it, not the way curl does.** Driven in
      a real browser. Load `?expand=verifications` → `details.open === true`. Wait 13s,
      past a full poll cycle → `details.open === true`, with `/tasks/T-736` and
      `/tasks/T-732` both present in the DOM. The page title advancing to
      *"Approvals (77 pending)"* during the wait is the proof the poll actually fired
      rather than the test just sitting on the first paint.

- [x] **A negative control proves the test can fail — and it found something worse than
      the bug being fixed.** On plain `/approvals` (no param), setting `details.open = true`
      by hand and waiting one poll cycle returns `open === false`.

      **So clicking the button did not work either.** The poll swaps the whole container, so
      the operator's manual click was reverted within ten seconds, every time. There was no
      route through the UI to those 57 items at all — not the parameter, not the button. The
      operator reported "I don't see it" and was describing a surface that actively closed
      itself while they looked at it.

- [x] **The divergence is declared.** Appended to `.agentic-framework/.vendor-divergence.yaml`
      as `T-772`, `upstream: fix`, with the measurement and the browser evidence.
      `python3 tools/_t517-vendor-divergence.py` → *"OK — every diverged path is declared,
      and every declared path still diverges"* (51 declared, 51 diverged).

- [x] **The scope boundary is stated and held.** This restores behaviour T-2406 already
      shipped and the poll silently defeated. The cap (10), the sort key (`-age_days`,
      oldest first) and the *"lower priority"* label are **untouched** — they change what the
      operator's queue shows and in what order, and they stay with G-055 for the operator's
      ruling. Fixing a feature that does not work is repair; re-ranking their queue would be
      a decision.

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
         1. Run `bin/fw reviewer T-772`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-772 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 tools/_t517-vendor-divergence.py
grep -q 'expand_overflow %}?expand=verifications' .agentic-framework/web/templates/approvals.html
curl -sf "$(cat .context/working/watchtower.url)/approvals?expand=verifications" -o /tmp/.t772a.html && grep -q 'hx-get="/approvals/content?expand=verifications"' /tmp/.t772a.html
curl -sf "$(cat .context/working/watchtower.url)/approvals" -o /tmp/.t772b.html && grep -q 'hx-get="/approvals/content"' /tmp/.t772b.html
grep -q 'T-772' .agentic-framework/.vendor-divergence.yaml

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

**Symptom:** the operator opened the `?expand=verifications` route given to them, and still
could not see the rulings. Opening the disclosure by hand did not work either.

**Root cause:** `approvals.html:238` polls `/approvals/content` every 10s with no query
string. `_read_expand_overflow()` (`approvals.py:520`) reads the expand state off the
*request*, so every poll rebuilds the fragment with `expand_overflow=False` and swaps it
into the container — discarding both the URL opt-in and any manual `<details>` state.

**Why structurally allowed:** the opt-in and the poll were built by different tasks (T-2406
and T-669) and neither's tests cross the other. A fetch-based check passes, because a single
GET never polls; a browser check would have failed within ten seconds. The property that
broke — *does the operator's choice survive?* — is not expressible in a request/response
assertion at all, and that is the only kind of assertion anything here was making.

**Prevention:** the browser check in this task's Human-visible evidence, plus its negative
control, is the first assertion in this project that a UI state survives the refresh cycle.
It is **not yet automated** — there is no CI that drives a browser, so the guard is a
recorded method, not a gate. Named here rather than implied: G-055 already carries the
related label defect; the absence of any polling-aware UI test is its own hole and is NOT
closed by this task.

**Escalation (G-019):** three verification failures of the same shape landed in two
sessions — I checked the mechanism (status code, server-rendered HTML, template constant)
and reported the operator's experience. PL-260 was already in the register and already cited
at this task's creation. A learning that is quoted back at me by the tooling and still not
applied is not a knowledge gap; it is a method gap. The method that closes it is the one used
here: drive the thing the operator drives, wait as long as they would wait.

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
     fw inception decide T-772 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T12:40:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-772-the-approvals-poll-drops-the-operator-ex.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-7145847a
- **Timestamp:** 2026-09-21T12:45:28Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T12:45:15Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
