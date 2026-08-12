---
id: T-457
name: "Register the gate comment-boundary class as a gap"
description: >
  T-453, T-455 and T-456 are three separate tickets against .agentic-framework gates, and they are one class: each decides where an HTML comment boundary lies by applying a regex to whichever text is nearest, with no notion of whether that text is prose to be discarded or code to be run. G-020 does not strip comments and so counts commented template examples as real ACs (passes over zero criteria). P-011 strips them from the COMMAND text and so eats live commands (can produce a false green under the T-352 errexit swallow). G-067 sixty lines from G-020 does it correctly. Tasks archive to .tasks/completed/ and become invisible; gaps persist in the register, are visible in Watchtower and are checked by audit - per CLAUDE.md, register the flaw BEFORE or alongside the fix. All three fixes are AEF's under G-008, so the local deliverable is the register entry with a closure condition that names what must move.

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
created: 2026-08-12T12:36:57Z
last_update: 2026-08-12T12:39:54Z
date_finished: 2026-08-12T12:39:54Z
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

# T-457: Register the gate comment-boundary class as a gap

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The register entry names the CLASS, not the three tickets.** A gap that reads
      "T-453, T-455 and T-456 are open" closes when they are closed, which is the wrong
      trigger — the fixes are AEF's and their landing is not the same event as this tree
      no longer being exposed. The entry states the shared mechanism: a comment boundary
      decided by a regex over whichever text is nearest, with no notion of prose-to-discard
      versus code-to-run.
- [x] **The closure condition names what must MOVE, in which direction, and is
      executable.** Per the G-035 precedent: a condition satisfiable by reclassification,
      by closing tickets, or by any change that leaves the mechanism intact is a
      fake-progress channel. It must be checkable by command, and the command must be
      runnable by something other than this task's own Verification block — otherwise the
      gauge joins the 30 instruments G-035 counts.
- [x] **The entry records that one sibling already does it correctly.** `G-067` strips
      HTML comments before counting, sixty lines from the gate that does not. That is the
      strongest single fact in the class: it makes every instance a divergence from an
      in-file precedent rather than an unsolved design question, and it is what turns the
      upstream report into "apply the treatment you already wrote".
- [x] **`concerns.yaml` still parses and the register's own schema check is no worse than
      before the edit.** Measured by running it before and after. **Correction, and the
      reason this AC was written the way it was:** I stated the pre-existing failure as
      `exit 1` from memory of T-441. Measured, it is **rc 2, one line of output** — and
      identical before and after my edit (`diff -q` clean). The register parses (33 entries,
      29 watching). So the criterion holds, but the number in it was inherited rather than
      read, which is the same defect this window has been chasing at larger scale; recorded
      rather than quietly amended.

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

# 1. The register still parses and G-036 is in it.
python3 -c "import yaml; d=yaml.safe_load(open('.context/project/concerns.yaml')); gs=d.get('gaps',d.get('concerns',[])) or []; assert any(g.get('id')=='G-036' for g in gs), 'G-036 missing'"
# 2. The closure gauge RUNS and reports NOT_READY today, with both numbers visible rather
#    than collapsed into a verdict. A gap whose closure command cannot execute is a
#    condition nobody can check — G-035's whole finding, one level out. Note the gauge is
#    referenced from concerns.yaml's closure_check_command, which the T-451 census counts
#    as a LIVE source, so this instrument does not join the 30 it reports.
out=$(python3 -c "import re,json;O=chr(60)+chr(33)+'--';C='--'+chr(62);t=open('.tasks/templates/default.md').read();raw=sum(1 for l in t.splitlines() if re.match(r'\s*- \[ \]',l));st=sum(1 for l in re.sub(O+'.*?'+C,'',t,flags=re.S).splitlines() if re.match(r'\s*- \[ \]',l));u=open('.agentic-framework/agents/task-create/update-task.sh').read();eats=any(('re.sub' in l and 'DOTALL' in l and O[:2] in l) for l in u.splitlines());ok=(raw==st) and not eats;print(json.dumps({'verdict':'READY' if ok else 'NOT_READY','ready':ok,'template_raw_ac_count':raw,'template_comment_stripped_count':st,'p011_strips_command_text':eats}))" 2>&1); echo "$out" | grep -q 'template_raw_ac_count'
# 3. The correct sibling is still present — it is what makes every instance a divergence
#    from an in-file precedent rather than an open design question.
grep -q 'OQ_STRIPPED' .agentic-framework/agents/context/check-active-task.sh

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

### 2026-08-12T12:36:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-457-register-the-gate-comment-boundary-class.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-8a69b1ef
- **Timestamp:** 2026-08-12T12:39:55Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T12:39:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
