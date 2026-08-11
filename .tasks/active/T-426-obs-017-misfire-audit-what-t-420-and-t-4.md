---
id: T-426
name: "OBS-017 misfire audit: what T-420 and T-421 instruments print when they fire wrongly"
description: >
  OBS-017 misfire audit: what T-420 and T-421 instruments print when they fire wrongly

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-11T08:56:53Z
last_update: 2026-08-11T08:56:53Z
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

# T-426: OBS-017 misfire audit: what T-420 and T-421 instruments print when they fire wrongly

## Context

OBS-017. I shipped two instruments (T-420's PreToolUse rail-attribution gate, T-421's
detector) and verified only that they fire CORRECTLY. Neither was asked the opposite
question: what does it print when it fires WRONGLY, and does the printed remedy launder
the miss?

Committed to this publicly at AEF rail 523 §3 — "the gate you just watched block me
prints a remedy, and if that remedy is ever the wrong advice, it is a laundering path
with an authoritative tone. Doing that audit next, on both, before I build anything
else." This task is that audit.

**Why a remedy can launder.** A block message is the most authoritative text an agent
sees: it is machine-emitted, it cites measured evidence, and it names the fix. When the
remedy is wrong, its authority makes it MORE likely to be followed, not less. Three
distinct failure shapes, all of which leave no record:

  FP-unfollowable  the gate blocks a call that is fine, and names a parameter the tool
                   does not have. The agent cannot comply; the only exits are abandon
                   the tool or bypass the gate, and neither is written down anywhere.
  FP-destructive   the remedy is followable but changes what the call MEANS (e.g. "set
                   project='832-Workflow-designer'" on a tool where `project` is a
                   filter, not attribution). Compliance silently corrupts the call.
  FN-silent        the gate lets a real violator through. Passing and never-examined are
                   the same observable — PL-109/PL-147 again, from the third direction.

**A live specimen arrived before this task existed.** Opening this session, the vendored
`check-active-task` hook blocked with focus on T-423 and printed
`To unblock: fw work-on T-423`. T-423's AC #1 (line 59) reads "this task does not start
until T-340 is ruled and step 1 has landed." The hook's remedy was an instruction to
break the guard T-423 exists to hold, and following it would have left T-423 in
`started-work` with nothing recording that its ordering guard was violated. The hook
prints `fw work-on $CURRENT_TASK` unconditionally
(`.agentic-framework/agents/context/check-active-task.sh:441`) — it never asks whether
the focused task SHOULD start. That is FP-destructive in someone else's instrument, and
it is the reason this audit is not academic.

## Acceptance Criteria

### Agent
- [x] **Both instruments located and pinned by path**, with the registration site for
      each (settings.json matcher, or the caller that invokes it). An instrument that is
      not registered anywhere is a PL-147 finding in its own right and is recorded as
      such rather than silently skipped.
      **MEASURED 2026-08-11 — and the two answers differ:**
      - `tools/_t420-rail-attribution-gate.py` — REGISTERED, `.claude/settings.json`
        PreToolUse, matcher `mcp__termlink__.*`. Live.
      - `tools/_t421-enforcement-claim-drift.py` — **REGISTERED NOWHERE.** Its only
        invocation sites are the `## Verification` block of its own completed task
        (`.tasks/completed/T-421-*.md:187`) and T-422's Human AC steps. P-011 runs a
        task's Verification once, at completion — so that line stopped running the
        moment T-421 moved to `completed/`. Not in settings.json, not in audit.sh, not
        in `fw doctor`, not in cron (grep across `.agentic-framework/{agents/audit,lib,bin}`
        returns empty). **It exits 1 today** (measured — `FAIL — 1 hook(s) claimed
        active, none registered`), and has been doing so into a void for days.
        This is PL-147 turned on its author: the detector built to find gates the tree
        claims are live but nothing registers is ITSELF an unregistered gate.
- [x] **T-420 gate: every misfire mode enumerated against the LIVE tool surface, by
      PROBE not by code-read.** Each candidate tool is fed a synthetic PreToolUse JSON
      on stdin and the gate's actual stdout/stderr + exit code recorded. Reading the
      source to predict the verdict does not satisfy this AC — the whole point is that
      my prediction of my own instrument is the thing under test.
      **DONE — `tools/_t426-gate-misfire-matrix.sh`, 23 probes, all verdicts asserted.**
- [x] **Each false positive is classified FP-unfollowable or FP-destructive**, with the
      tool's real parameter list quoted as the evidence. "Unfollowable" means: the
      remedy names a parameter absent from that tool's schema.
      **3 false positives, all FP-unfollowable** (schemas read from the live MCP
      surface 2026-08-11):
      - `termlink_inject` {target, text, enter} — blocked on `text`. Remedy said add
        `metadata` or `project`. Has neither.
      - `termlink_remote_inject` {hub, session, text, enter, scope, secret,
        secret_file, timeout} — same, on `text`.
      - `termlink_emit` {target, topic, payload} — blocked when `payload` is a JSON
        **string**, allowed when the same call passes an **object**, because Rule 1
        tests `isinstance(v, str)`. Same call, same semantics, verdict decided by the
        caller's serialization choice. Nondeterministic from the caller's side, which
        is worse than a consistent false positive: it teaches that the gate is flaky.
      None is FP-destructive — the remedy could not be followed at all, so it could not
      corrupt a call. That is luck, not design: `attribution_of()` reads any `project`
      key as attribution, so a tool where `project` meant a filter WOULD have produced
      "expected '832-Workflow-designer'" and complying would have silently retargeted
      the call. No such tool exists on today's surface. Recorded as a standing exposure
      rather than a finding, because the next tool added could create it.
- [x] **False negatives enumerated for the class the gate was BUILT for** — a hub
      producer that carries content under a key not in `CONTENT_KEYS`, or that has no
      attribution channel and is missing from `UNATTRIBUTABLE_PRODUCERS`. This is the
      harder half: FPs announce themselves, FNs are silent by construction.
      **1 false negative, and it is the more serious half of this audit.**
      `termlink_agent_contact` — allowed, exit 0, in silence. It posts a **signed
      msg_type=chat envelope** to a `dm:<a>:<b>` topic with retention=forever (its own
      schema says "WRITES state"), carries content under `message` or `body_file` —
      neither in `CONTENT_KEYS`, and `body_file` puts a whole FILE on the wire — and has
      no producer-attribution channel: `target='<peer>:<project>'` stamps
      `metadata.to_project` (the RECIPIENT), and `sender_id` only overrides the host
      fingerprint this gate exists because of. Textbook class B, missed by the
      2026-08-10 enumeration, invisible to both rules.
      **The FN class is not closed** — only this instance. A future tool using
      `message`/`body_file` reopens it, which the matrix states as a LIMIT rather than
      implying coverage it does not have.
- [ ] **T-421's instrument given the same two-sided treatment** (what does it print on a
      false hit, and would acting on that print make things worse).
- [ ] **Every finding is either fixed in the instrument or registered** as a gap/
      observation with the reason it is not being fixed now. No finding is left as prose
      in this task file only — that is the G-030/PL-145 shape this project already has a
      gap open for.
- [x] **The fix does not widen the gate's blast radius unmeasured**: after any edit,
      re-run the full probe matrix and show the before/after verdict for EVERY probed
      tool, not just the ones changed. A fix that silently flips an unrelated verdict is
      the regression this AC exists to catch.
      **`tools/_t426-gate-misfire-matrix.sh` — 23/23, fail=0.** Only the four intended
      verdicts moved (inject, remote_inject, emit×2: BLOCK→ALLOW; agent_contact×2:
      ALLOW→BLOCK). T-420's original teeth re-run unchanged: `_t420-gate-mutation-check.sh`
      **15/15 PASS**, so the eight spoilings it detects are still detected — the fix
      narrowed the gate exactly where it was wrong and nowhere else.
- [ ] **AEF told on the rail**, with the specimen and the generalization — they own the
      `check-active-task` instrument that produced the live FP-destructive case, and
      their `fw rail post` attach-side remedy has the mirror-image exposure (a gate that
      ATTACHES can attach a wrong label silently, which the T-420 docstring already
      names as the trade it accepted).

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

# The two-sided matrix: gate must block real producers AND allow non-producers.
bash tools/_t426-gate-misfire-matrix.sh

# T-420's original teeth still hold — the fix narrowed, it did not blunt.
bash tools/_t420-gate-mutation-check.sh

# PL-147: a green matrix over an UNREGISTERED gate is the same observable as a green
# matrix over a live one. Assert registration separately from behaviour — this is the
# check whose absence this whole task is about.
python3 -c "import json,sys; s=json.load(open('.claude/settings.json')); h=[x.get('command','') for a in s.get('hooks',{}).get('PreToolUse',[]) for x in a.get('hooks',[])]; sys.exit(0 if any('_t420-rail-attribution-gate.py' in c for c in h) else 1)"

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

### 2026-08-11T08:56:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-426-obs-017-misfire-audit-what-t-420-and-t-4.md
- **Context:** Initial task creation
