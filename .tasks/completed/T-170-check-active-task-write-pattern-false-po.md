---
id: T-170
name: "check-active-task write-pattern false-positive blocks safe bootstrap commands"
description: >
  has_bash_write_pattern mis-flags safe bootstrap commands (fw context focus, fw task
  create) as writes when arguments contain a benign redirect like dev-null or angle-bracket
  text, skipping the line 77 allowlist and blocking them under a placeholder-build
  focus. Scope the write-pattern check so redirects inside fw bootstrap commands do
  not defeat the allowlist. Discovered during T-169.

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
created: 2026-07-10T04:40:07Z
last_update: '2026-08-16T12:33:41Z'
date_finished: 2026-07-10T05:05:21Z
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
  - ts: '2026-08-16T12:33:41Z'
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

# T-170: check-active-task write-pattern false-positive blocks safe bootstrap commands

## Context

`has_bash_write_pattern()` in `agents/context/lib/safe-commands.sh` flags a command as a "write"
purely from the redirect regex `[^2>&]>[^>&]|>>` (line 166). This false-positives on two safe cases,
both hit this session:
1. **`/dev` sink redirects** — `fw context focus T-169 >/dev/null 2>&1` — a discard, not a source
   write, but the `>` matches. The command then loses its safe/bootstrap fast-pass and is blocked
   when no task is active.
2. **Angle-bracket tokens in quoted args** — `fw task create --description "…<T>…"` — the substring
   `T>` matches `[^2>&]>[^>&]`. Shell never interprets a quoted `>` as a redirect, yet the gate does.

Root fix (principled): shell redirect operators only act **outside quotes**, and `/dev` sinks are not
source-file writes. Strip quoted spans and `/dev` redirects before the redirect test. Security note:
`sh`/`bash`/`eval` are NOT in the safe-command allowlist, so a redirect hidden inside `sh -c "…"`
never gets a fast-pass regardless — stripping quotes for redirect detection introduces no evasion for
an allowlisted command (a quoted `>` is not a real redirect for `cat`/`echo`/`fw`/etc.).

Scope: only the redirect check (line 166) changes. The `rm`/`sed -i`/heredoc/`tee` checks stay on the
raw command (unquoting them would be wrong — `"rm" file` still executes rm).

## Acceptance Criteria

### Agent
- [x] `has_bash_write_pattern` no longer flags a `/dev` sink redirect (`>/dev/null`, `2>/dev/null`, `&>/dev/null`) as a write.
- [x] `has_bash_write_pattern` no longer flags angle-bracket text inside a quoted arg (e.g. `--description "a <T> b"`) as a write.
- [x] Genuine writes are STILL detected: `echo x > src/f.js`, `echo x >> log`, `cat a > b`, `sed -i`, `rm f`, `tee f`, heredoc all still return 0 (write) — 10/10 function corpus.
- [x] A hook harness confirms the two false-positive commands are ALLOWED with no active task ([0]), and real-redirect commands are still gated ([2]) — evidence in Updates.

### Human-removed
<!-- Human section removed: fix is fully agent-verifiable via hook harness.
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

# T-170 — false positives now pass, real writes still caught:
bash -c 'source .agentic-framework/agents/context/lib/safe-commands.sh; has_bash_write_pattern "fw context focus T-1 >/dev/null 2>&1" && exit 1 || exit 0'
bash -c 'source .agentic-framework/agents/context/lib/safe-commands.sh; has_bash_write_pattern "fw task create --description \"adds a <T> placeholder\"" && exit 1 || exit 0'
bash -c 'source .agentic-framework/agents/context/lib/safe-commands.sh; has_bash_write_pattern "echo pwned > src/app.js" && exit 0 || exit 1'
bash -c 'source .agentic-framework/agents/context/lib/safe-commands.sh; has_bash_write_pattern "echo x >> build.log" && exit 0 || exit 1'
bash -c 'source .agentic-framework/agents/context/lib/safe-commands.sh; has_bash_write_pattern "echo safe > realfile" && exit 0 || exit 1'

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

**Symptom:** Safe bootstrap commands were blocked by the active-task gate: `fw context focus T-169
>/dev/null 2>&1` and `fw task create --description "…<T>…"` each hit "No active task" (or lost their
safe-command fast-pass) even though they write nothing.

**Root cause:** `has_bash_write_pattern` classified them as writes purely from the redirect regex
`[^2>&]>[^>&]|>>`. That regex fires on (a) `>/dev/null` — a discard, not a source write; and (b) the
`T>` inside a quoted `<T>` — a `>` that shell never interprets as a redirect because it is inside
quotes. The detector reasoned about raw characters, not shell semantics.

**Why structurally allowed:** the write-pattern check was a coarse character-level heuristic with no
notion of quoting or of harmless sinks. It over-approximated "write" and there was no test corpus
pinning the false-positive/true-positive boundary, so the over-broad match went unnoticed until it
blocked real bootstrap commands.

**Prevention:** the fix strips quoted spans and `/dev` redirects before the redirect test (redirects
only act outside quotes; `/dev` sinks aren't source writes). A 5-case Verification corpus pins the
boundary — two former false-positives must pass, three genuine writes must still be caught — so a
future regression in either direction fails the completion gate.

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

### 2026-07-10T04:40:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-170-check-active-task-write-pattern-false-po.md
- **Context:** Initial task creation

### 2026-07-10T05:00:59Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-10 — verification evidence [agent]
- **Fix:** `safe-commands.sh` `has_bash_write_pattern` redirect check now strips quoted spans
  (`sed "s/\"[^\"]*\"//g; s/'…'//g"`) and `/dev/{null,stderr,stdout}` redirects before applying the
  redirect regex. Shell redirects only act outside quotes; `/dev` sinks are discards, not writes.
- **Function corpus (10/10):** false-positives `>/dev/null`, quoted `<T>`, `cat >/dev/null` → not
  writes; genuine writes `> src/app.js`, `>>`, `> realfile`, `"safe" > realfile` (quoted arg + REAL
  redirect), `sed -i`, `rm`, `tee` → still writes.
- **Hook harness (PROJECT_ROOT=temp, focus→nonexistent T-9999, i.e. no active task):**
  `[0]` `fw context focus T-5 >/dev/null 2>&1` (was falsely blocked) · `[0]` `fw task create … --description "…<T>…"` (was falsely blocked) · `[2]` `echo pwned > src/app.js` · `[2]` `echo "safe" > realfile.js` · `[0]` `git status` (control).
- **Counterfactual:** the old regex `[^2>&]>[^>&]|>>` MATCHED both false-positive commands, confirming
  the harness detects the bug (not a no-op test).

### 2026-07-10T05:05:21Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
