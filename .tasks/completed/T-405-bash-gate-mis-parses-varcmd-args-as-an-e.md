---
id: T-405
name: "Bash gate mis-parses VAR=$(cmd args) as an env-var prefix and takes the next word as the command name"
description: >
  safe-commands.sh:29 strips leading env-var prefixes with the regex KEY=VAL followed by whitespace, where VAL is any run of non-whitespace. A command-substitution assignment such as WURL=$(cat some/path 2>/dev/null || echo fallback) has no whitespace until inside the substitution, so the stripper consumes WURL=$(cat and treats the NEXT word - the file path argument - as the base command name. It matches nothing in the allowlist and the command is blocked with no active task. Discovered while fixing T-404: after that fix the /resume skill Step 5 command reports write=no but safe=no, so it is still blocked, by this second independent mechanism. Consequence: the framework documented post-compaction recovery command remains unrunnable in the exact state compaction creates.

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
created: 2026-08-09T08:27:53Z
last_update: 2026-08-09T08:42:18Z
date_finished: 2026-08-09T08:42:18Z
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

# T-405: Bash gate mis-parses VAR=$(cmd args) as an env-var prefix and takes the next word as the command name

## Context

Second of the two mechanisms blocking the framework's own post-compaction recovery command.
T-404 fixed the first (redirect mis-classification); after it, the `/resume` Step 5 command
reports `write=no` but still `safe=no`. This is why.

Both defects live in `is_bash_safe_command`'s base-command extraction — one function, two
witnesses:

1. **`VAR=$(cmd args)` mis-parsed as an env-var prefix.** The T-1908 stripper matches
   `KEY=` followed by any run of non-whitespace, so in `WURL=$(cat some/path 2>/dev/null)`
   the "value" ends at `$(cat` — the first space falls *inside* the substitution. The next
   word, a file path argument, is then taken as the command name.
2. **Multi-line commands.** `echo "$cmd" | awk '{print $1}'` prints the first word of
   *every* line, producing a multi-word "base" that matches no case arm.

## Acceptance Criteria

### Agent
- [x] `VAR=$(cmd args) ...` is no longer treated as an env-var prefix; the real command
      name is extracted and the allowlist is consulted against it
- [x] The T-1908 contract still holds: `FW_SWITCH_FOCUS=1 fw work-on T-XXX` is still
      recognised as safe (the fix must not break the bypass-mechanism promise it exists for)
- [x] A multi-line read-only command is allowed, and is judged per line — every line must
      be safe, so a multi-line command whose second line is not read-only stays blocked
      (fixes the false negative WITHOUT widening the gate)
- [x] Base extraction no longer forks `awk` and `sed` — pure parameter expansion, since
      this predicate runs on every Bash tool call
- [x] Corpus extended in `web/test_safe_commands.py` covering all of the above, including
      the must-still-block direction, and green (49/49)
- [x] `tools/t404-gate-e2e.sh` extended: with focus null, the `/resume` skill's Step 5
      command shape is ALLOWED end-to-end through the real hook — the deadlock T-404 and
      T-405 jointly close (13/13)
- [x] T-404's corpus and e2e still pass unchanged (no regression in the redirect predicate)

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

(cd .agentic-framework && python3 -m pytest web/test_safe_commands.py -q)
(cd .agentic-framework && python3 -m pytest web/test_safe_commands.py::test_resume_step5_is_allowed -q)
(cd .agentic-framework && python3 -m pytest web/test_safe_commands.py::test_env_prefix_contract_still_holds -q)
(cd .agentic-framework && python3 -m pytest web/test_safe_commands.py::test_segments_are_judged_individually -q)
bash tools/t404-gate-e2e.sh
bash -n .agentic-framework/agents/context/lib/safe-commands.sh
bash -n .agentic-framework/agents/context/check-active-task.sh

## RCA

**Symptom:** with focus null, `WURL=$(cat path 2>/dev/null); curl ...` — the `/resume`
skill's documented Step 5 — was blocked. So was every multi-line command.

**Root cause:** one defect, two witnesses. `is_bash_safe_command` assumed *the command is
the first word*.

1. The T-1908 env-prefix stripper matched `KEY=` followed by any run of non-whitespace. In
   `WURL=$(cat some/path ...)` the first space falls INSIDE the command substitution, so the
   "value" ended at `$(cat` and the next word — a file path ARGUMENT — became the command
   name. Nothing in the allowlist matches `.context/working/watchtower.url`.
2. `echo "$cmd" | awk '{print $1}'` prints the first word of EVERY line, so any multi-line
   command produced a multi-word "base" matching no case arm.

**Why structurally allowed:** the same self-hiding property as T-404 — base extraction only
decides an outcome when focus is null. Beyond that, "first word" is not a wrong heuristic so
much as an ill-defined question: a compound command has no single base. The predicate was
answering a question the input does not have an answer to, and returning a plausible string
either way, so there was nothing to notice.

**Prevention:** the extractor no longer answers that question. Every segment (split on
newline, `;`, `&&`, `||`, `|`, out of the quote-stripped command) is judged on its own and
all must pass. The corpus pins both directions, including the naive-fix trap: a multi-line
command whose FIRST line is read-only and whose second is not must stay blocked.

## Decisions

### 2026-08-09 — segment-wise judgement, which TIGHTENS the gate

- **Chose:** judge every segment; all must be safe.
- **Why:** it is the only reading that is correct for compounds, and it fixes the false
  negatives without opening a false positive. It also closes a real hole: `cd /x && rm -rf y`
  previously extracted base `cd`, matched the allowlist wholesale, and was "safe" as far as
  this predicate was concerned — only the destructive-verb check stood behind it.
- **Rejected:** taking the first line's first word. Simpler, and it would have made the
  resume command work, but it would allowlist a whole multi-line script on the strength of
  its opening word. Pinned by a test so nobody re-introduces it as a simplification.
- **Known cost, measured not assumed:** commands that were allowed ONLY because their first
  word was allowlisted are now blocked under null focus. The one that will be noticed is
  `cd X && python3 -m pytest ...` — previously safe via the `cd` arm, now blocked because
  `python3` is only allowlisted in its `-c` parse-check form. This is the hole closing
  rather than a regression, and the remedy is the framework's actual rule (have an active
  task), but it is a behaviour change and is recorded here so it is not a surprise.

### 2026-08-09 — split the quote-stripped string, not the raw one

- **Chose:** run the segment split over `_sc_strip_quoted`'s output.
- **Why:** splitting the raw string would treat `grep 'a;b' f` as two commands — reintroducing
  on the allowlist side the exact "quotes are not structure" defect T-404 fixed on the
  write-detection side. Same bug, same file, opposite predicate.

<!-- Record decisions ONLY when choosing between alternatives.

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

### 2026-08-09T08:27:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-405-bash-gate-mis-parses-varcmd-args-as-an-e.md
- **Context:** Initial task creation

### 2026-08-09T08:36:49Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-7a19d7e3
- **Timestamp:** 2026-08-09T08:42:27Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T08:42:18Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
