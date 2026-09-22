---
id: T-793
name: "Remove the semgrep Guardian plugin: its hooks demand a commercial-service login and block Write/Edit"
description: >
  Remove the semgrep Guardian plugin: its hooks demand a commercial-service login and block Write/Edit

status: started-work
workflow_type: decommission
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T08:24:35Z
last_update: 2026-09-22T08:24:35Z
date_finished: null
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

# T-793: Remove the semgrep Guardian plugin: its hooks demand a commercial-service login and block Write/Edit

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the actual enablement source is found, not guessed.** `semgrep` is absent from
      the 23 entries in the user-scope plugin registry, yet its hooks fire and its cache is on
      disk at `2.3.0`. Whatever is loading it is named with evidence before anything is
      removed — uninstalling from the wrong scope would leave the hooks running and look like
      a fix.
      **ANSWERED, AND THE ANSWER INVALIDATES THE TASK'S PREMISE.** It is not installed for
      this session at all:
      - absent from `installed_plugins.json` (23 entries, none matching)
      - absent from `enabledPlugins` in `/root/.claude/settings.json` (17 entries)
      - absent from `claude plugin list` (24 plugins listed, none matching)
      - `claude plugin uninstall semgrep@claude-plugins-official -y` →
        *"not found in installed plugins"*

      What IS on disk: the cache at `semgrep/2.3.0/` with `.in_use` PID markers stamped
      09:38, 09:56 and 10:07 today. This machine runs a fleet of sessions for other projects
      and they share the plugin cache, so the markers are consistent with a transient load
      around the `/plugin` install rather than with a standing enablement here.

      **The investigation could not be completed, and that is a boundary, not a shrug.**
      Reading `/root/.claude.json` — the per-project config, and the last place the
      enablement could hide — is refused by the T-559 project-boundary hook
      (*"Outside-path argument /root/.claude.json (not in read-side allowlist)"*). So the
      residual possibility (an enterprise/managed or foreign-project scope) is **unverified,
      not excluded**.
- [x] **AC2 — the hooks stop firing, proven by an action that they previously blocked.** Not
      "the command reported success": an `Edit` to a file must complete without the
      `Not logged into Semgrep Guardian` refusal. The block is the symptom, so the block's
      absence is the only evidence that counts.
      Evidence: this very file has been edited **three times** since, by the `Edit` tool, with
      no refusal — including the edit that wrote this sentence. The blocking window was
      **two consecutive calls** (one `Write`, one `Edit`, ~10:14–10:16); every `Edit` since
      has passed. **The block was transient, and I reported it as a standing condition.**
- [x] **AC3 — nothing else is removed.** The other 23 plugins remain installed and enabled.
      A removal that quietly takes neighbours with it is a worse outcome than the block.
      Evidence: trivially satisfied — **nothing was removed at all.** The uninstall was
      refused by the CLI because there was nothing there to uninstall.
- [x] **AC4 — the mis-classification is corrected where it was recorded.** T-784's decision
      record lists `semgrep` in the borderline group read as PASSING the operator's
      plugin-independence constraint. That reading was wrong — it judged the local CLI, not
      Guardian, which has an account and blocks rather than degrades. Corrected in place so
      the register does not keep asserting it.
      Evidence: **PD-307**, carrying both corrections — the plugin's classification, and my
      own reporting of the block as standing when it was transient. Four of the five
      borderline verdicts stand; only `semgrep` moves, into the same class as `qdrant-skills`
      rather than the same class as `pyright-lsp`.

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
         1. Run `bin/fw reviewer T-793`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-793 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ── AC1: it is not installed here, on every register that can be read ─────────
# Positive controls first: each register IS readable and DOES contain plugins, so
# the three silences below are evidence about semgrep and not about a bad path.
python3 -c "import json;d=json.load(open('/root/.claude/plugins/installed_plugins.json'));ks=list(d['plugins']);assert len(ks)>=20;assert not [k for k in ks if 'semgrep' in k.lower()]"
python3 -c "import json;d=json.load(open('/root/.claude/settings.json'));ep=d.get('enabledPlugins',{});assert len(ep)>=10;assert not [k for k in ep if 'semgrep' in k.lower()]"

# ── AC4: the correction is recorded where the wrong reading was recorded ──────
grep -q 'PD-307' .context/project/decisions.yaml
grep -q 'Semgrep Guardian is a different product from the semgrep CLI' .context/project/decisions.yaml

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
     fw inception decide T-793 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T08:24:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-793-remove-the-semgrep-guardian-plugin-its-h.md
- **Context:** Initial task creation
