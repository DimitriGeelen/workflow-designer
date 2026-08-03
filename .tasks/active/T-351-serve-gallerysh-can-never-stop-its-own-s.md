---
id: T-351
name: "serve-gallery.sh can never stop its own server: trap forwards SIGINT, which bash sets to SIG_IGN for background children"
description: >
  serve-gallery.sh's exit trap forwards kill -INT to the gallery-serve.py child, but bash sets SIGINT to SIG_IGN for children started with & when job control is off, and python inherits the ignore across exec (confirmed in /proc/PID/status SigIgn). The child therefore survives every INT its parent sends, and orphans on parent death. The in-file comment asserts the exact inverse: that gallery-serve.py handles SIGINT and ignores SIGTERM. SIGTERM is in fact what stops it. Five orphaned gallery-serve.py processes from 2026-07-22 and 2026-07-29 are still resident on this host holding ports with deleted docroots.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T22:02:21Z
last_update: 2026-08-03T00:11:32Z
date_finished: 2026-08-03T00:11:32Z
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

# T-351: serve-gallery.sh can never stop its own server: trap forwards SIGINT, which bash sets to SIG_IGN for background children

## Context

Found by T-350's probe, which asserts that a server it starts is actually gone afterwards. It
was not. Nothing in this repo had ever checked, which is why the population below accumulated
unnoticed for eleven days.

**Measured, not inferred.** `/proc/<pid>/status` for a running `gallery-serve.py` shows
`SigIgn: 0000000001001006` — bit 1 set, i.e. **SIGINT is ignored**. Direct test on a live
server: `kill -INT` leaves the listener up; `kill -TERM` drops it immediately.

**Mechanism.** `serve-gallery.sh` starts the server with `&`. A non-interactive shell without
job control sets SIGINT (and SIGQUIT) to `SIG_IGN` for asynchronous children, and an *ignored*
disposition — unlike a handler — survives `exec`. Python never installs a SIGINT handler over
it, so `serve_forever()` never sees the KeyboardInterrupt the code is written to catch.

**Consequences, in order of cost:**
1. The exit trap `trap 'kill -INT "$SRV"' INT TERM` is a **no-op**. Ctrl-C, `timeout`, or any
   kill of the parent leaves the python child orphaned holding its port. This is the mechanism
   behind the orphaned `gallery-serve.py` processes still resident on this host, all serving
   `/tmp` docroots that no longer exist. **This paragraph originally said five and the AC4
   census measured six** — four from 2026-07-22, one from 2026-07-29, and one from
   2026-08-02 19:10. The last one matters: it postdates every earlier count and predates this
   task's work, so the leak was still live, not a historical residue.
2. The in-file comment states the **inverse of the truth**: *"gallery-serve.py's HTTPServer
   handles KeyboardInterrupt (SIGINT) but ignores SIGTERM; send TERM once (for other server
   kinds), then INT — never a silent -9."* Both halves are backwards. A future maintainer
   reading it would reach for the signal that cannot work.
3. The T-231 clean-stop loop **works by accident**: its first attempt sends TERM, which is the
   signal that actually stops the server. Attempts 2 and 3 send INT and do nothing. So the
   restart path is fine and the shutdown path is broken, from the same code, for reasons the
   comment gets exactly wrong.

Filed separately from T-350 per the one-bug-one-task rule: different root cause, different fix,
and T-350's probe only needed to stop leaking servers *of its own*, which it does with TERM.

## Acceptance Criteria

### Agent
- [x] **AC1 — the trap stops the child.** Start the server, send the parent the signal a user
      would (`SIGTERM`, and separately `SIGINT` as Ctrl-C delivers it), and assert in both cases
      that the listener is gone and no `gallery-serve.py` process survives. Asserted on a port
      discovered free at runtime, never a literal.

      **AMENDED before ticking.** The AC as written is satisfiable by a probe that proves
      nothing. Backgrounding the subject with `&` from a non-interactive shell hands it
      SIG_IGN for SIGINT — the very mechanism under test — and bash then cannot install an
      INT trap at all, because a signal ignored on entry to the shell cannot be trapped. The
      SIGINT leg would have gone green by never delivering anything. The probe therefore sets
      `set -m` (job control, own process group, default dispositions — what a terminal does)
      AND reads `/proc/PID/status` `SigIgn` before signalling, so an undeliverable signal is
      reported as a HARNESS fault naming the probe rather than as a verdict on
      serve-gallery.sh. Teeth leg (b) removes `set -m` and requires exactly that message.
- [x] **AC2 — the comment states what is true.** The corrected text names SIGTERM as the working
      signal and records *why* SIGINT cannot work here (inherited `SIG_IGN` for `&` children,
      preserved across `exec`), so the next reader does not re-derive it from a wrong premise.
- [x] **AC3 — proven by mutation.** Reverting the fix to the INT-only trap makes AC1 go red
      **naming the surviving PID and port**, not merely returning non-zero.
- [x] **AC4 — the existing orphan population is measured before and after**, and the count is
      reported rather than assumed to be five: `pgrep -f gallery-serve.py` with start times and
      docroots. A cleanup that reports "done" without a count cannot distinguish "cleaned" from
      "nothing matched".

      **Measured: SIX, not five.** Four from 2026-07-22, one from 2026-07-29, and one from
      2026-08-02 19:10 that predates this task's work — so the leak was still producing
      orphans independently of the T-350 harness that surfaced it. The "five" in this task's
      own description was asserted from memory; correcting it is the AC doing its job on its
      author. The census compares PID *identities* before and after, not just the count: two
      processes swapped one-for-one would net to zero.

### Human
- [ ] [REVIEW] Decide whether the six pre-existing orphans should be killed
      **Steps:**
      1. `cd /opt/832-Workflow-designer && bash tools/_t351-shutdown-probe.sh 2>&1 | head -12`
      **Expected:** SIX processes, not five — the count in the first draft of this task was
      asserted from memory and the AC4 census corrected it. Four from 2026-07-22, one from
      2026-07-29 (docroot in a session scratchpad), and **one from 2026-08-02 19:10**, which
      predates this task's work and shows the leak was still producing orphans independently
      of the T-350 harness. Every listed docroot is gone from disk.
      **If not:** fewer means someone or something reaped them since — record which PIDs and
      when, because a shrinking population without a named reaper is its own question.
      **Why this is yours:** they are long-lived processes on your host, not artifacts of this
      task. The agent did not kill them; it killed only the two it started itself. Reply with
      go/no-go and the agent will clean them under this task.

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

## Recommendation

**Recommendation:** GO — kill all six orphans.

**Rationale:** They are pure residue. Every one serves a docroot that no longer exists on
disk, so none of them can be answering a useful request; what they still hold is six TCP
ports and six python processes. They exist because the shutdown path never worked, and that
cause is now fixed and proven fixed by mutation — so killing them is a one-off cleanup, not
a recurring chore, and the population cannot regrow from this mechanism.

Two reasons it is still yours rather than mine. They are long-lived processes on your host
that predate this task, and one of the six binds `0.0.0.0:60701` from **2026-08-02 19:10** —
recent enough that I cannot rule out something of yours having started it deliberately.
`kill -TERM` is sufficient for all six; none needs `-9`.

**Evidence:**
- `bash tools/_t351-shutdown-probe.sh` — AC4 census prints all six with start time and full
  docroot argv; 6 before, 6 after, identities compared not just counted (3/3 green).
- Docroots `/tmp/t231-gallery-*`, `/tmp/t231-reg-*`, `/tmp/tmp.yzgHh4L1DE/g-serve` and the
  session-scratchpad pair are all absent from disk.
- `bash tools/_t351-teeth.sh` — 3/3. Leg (a) reverts the trap to the pre-fix `kill -INT` and
  the probe goes red naming the surviving PID and the port, which is the orphan being
  manufactured on demand. That is the direct evidence that this mechanism produced them.
- The fix itself: `trap 'kill -TERM "$SRV"' INT TERM` in `tools/serve-gallery.sh`, plus the
  clean-stop loop no longer "escalating" from TERM to a signal the child ignores.

**If you decline:** nothing breaks. The six keep holding high ports until the host reboots.
The only cost is that `ss -ltnp` stays noisy and a future port collision on those numbers
would be diagnosed slowly.

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

# NOTE ON THE HINT ABOVE (T-352, found while writing this block). P-011 runs each line as
# `if ( ...; eval "$cmd" ); then` — the subshell is the CONDITION of an `if`, so `set -e` is
# SUPPRESSED inside it. A line of the form `a; b` is therefore judged on `b` alone. The
# capture-then-grep shape the hint prescribes is exactly that shape, so the producing
# command's exit code is discarded. Proven, not reasoned: a validate-workflow.py run that
# exits 2 and prints INVALID returns PASS through the gate's own construct, because
# `grep -q "VALID"` matches INVALID as a substring. Every line below is therefore a SINGLE
# command whose own exit code is the verdict, and the two greps were checked against a
# reverted copy of serve-gallery.sh to confirm they go red rather than merely being present.
# Runtime is ~4 min: the probe and teeth start real servers and do full gallery rebuilds.

bash tools/_t351-shutdown-probe.sh
bash tools/_t351-teeth.sh
bash -n tools/serve-gallery.sh
grep -qE '^[^#]*kill -TERM "\$SRV"' tools/serve-gallery.sh
! grep -qE '^[^#]*kill -INT' tools/serve-gallery.sh
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

## What the harness caught about itself

**The probe's own cleanup had the defect it was built to find.** Each case ended with
`kill -TERM "$parent"; wait "$parent"` — which assumes the parent dies on TERM, i.e. assumes
exactly the property under test. Against teeth leg (a)'s INT-only mutant the parent traps
TERM, forwards an ignored INT, and returns to `wait`; against leg (c)'s stub it traps TERM
and loops. In both cases the unbounded `wait` blocked until the outer 400s timeout, and the
run had to be killed by hand. A stop path that assumes its signal works, in the tool written
because a stop path assumed its signal worked. Replaced with `stop_hard()`: TERM, bounded
poll, then KILL — TERM first so a well-behaved subject still exits cleanly and that exit
remains observable, KILL only after TERM has demonstrably not worked.

**A `pkill -f` pattern matched its own command line.** Clearing the hung run with
`pkill -f '_t351'` killed the invoking shell, because the shell's own argv contained the
pattern. Not a framework defect and not novel, but it is the same byte-space collision as
T-350's comment-quoting-the-command: the matcher cannot distinguish the thing from the
mention of the thing.

## Updates

### 2026-08-02T22:02:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-351-serve-gallerysh-can-never-stop-its-own-s.md
- **Context:** Initial task creation

### 2026-08-02T22:31:46Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-604f6839
- **Timestamp:** 2026-08-03T00:14:33Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-03T00:11:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
