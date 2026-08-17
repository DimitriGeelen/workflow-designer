---
id: T-557
name: "fw note swallows an unrecognised subcommand as the observation text: 11 observations destroyed since 2026-08-09"
description: >
  fw note swallows an unrecognised subcommand as the observation text: 11 observations destroyed since 2026-08-09

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
created: 2026-08-17T14:12:10Z
last_update: 2026-08-17T14:12:10Z
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

# T-557: fw note swallows an unrecognised subcommand as the observation text: 11 observations destroyed since 2026-08-09

## Context

`fw note` routes any unrecognised first word to the capture path, where it becomes the
observation **text** and the real payload is discarded. `agents/observe/observe.sh:305`:

```bash
case "${1:-}" in
    list)       do_list ;;
    ...
    -*)         echo "Unknown flag: $1" >&2; exit 1 ;;   # line 300
    *)          do_capture "$@" ;;                        # line 305
esac
```

So `fw note add "<900 chars>"` calls `do_capture add "<900 chars>"`, `do_capture` takes
`$1` as the text, and the tool prints `OBS-NNN captured` at exit 0. Nothing warns.

**Measured cost: eleven observations destroyed, spanning the register's whole history.**

    OBS-006  2026-08-09    OBS-032  2026-08-12 (urgent)    OBS-262  2026-08-16 ("inbox")
    OBS-011  2026-08-10    OBS-035  2026-08-12             OBS-274  2026-08-17 (urgent)
    OBS-022  2026-08-11    OBS-044  2026-08-12             OBS-285  2026-08-17
    OBS-028  2026-08-11    OBS-241  2026-08-13

Ten `add`, one `inbox`. **OBS-274 is the one that shows the cost**: it was T-556's central
finding, cited in that task's `## Context`, in three commit messages, in two handovers and
in what was reported to the operator — and it sat `pending` + `urgent` for nine hours as
the literal string `add`. Every artifact that counts urgents counted it; the handover's
"57 pending (3 urgent)" was arithmetically correct and one of the three was a word.
Re-filed as OBS-288.

### Why it survived eight days

The register cannot say *why* a row was dismissed. `do_dismiss` (`observe.sh:229-248`)
parses `--reason`, defaults it to `not actionable`, **echoes it at line 247 and never
persists it** — the only write is `_sed_i` flipping `status`. So nine earlier sessions each
met one junk row, cleared it, and left no trace of the diagnosis; the next session met one
junk row too, never a series. That is OBS-289 and **it is a separate task** (different root
cause: this one loses input at capture, that one loses judgement at triage).

### The guard that exists is on the branch that cannot lose data

Line 300 rejects an unrecognised **flag** loudly with exit 1. Input validation was
considered. But a flag typo loses nothing, while a subcommand typo eats the payload — and
that branch falls through to the catch-all. A guard present, reading as protection in
review, covering the harmless half.

### THIS WAS ALREADY KNOWN, FILED, AND DISMISSED — 2026-08-11

Found while attempting AC6's individual accounting, by grepping the register for any
surviving reference to the husk ids. **OBS-024, captured 2026-08-11, says exactly what I
filed today as OBS-287:**

> `fw note` has no unknown-subcommand error: `fw note add "real text"` captures the literal
> string 'add' as the observation and silently discards the argument that follows. The inbox
> then holds a well-formed entry with no content, which is indistinguishable from a real one
> until someone reads it. Same family as T-429's finding — a record that exists and says
> nothing looks exactly like a record.

Status: **`dismissed`**, `promoted_to: None`. It was never turned into a task and never
fixed. T-429's commit message (`c00e534c`, 2026-08-11) records it alongside the note that
*"OBS-022 was that defect happening to me and is dismissed with the reason"*.

**And the dismissal defect was known too.** T-436's triage, 2026-08-12, calls it the
*"third `fw note` defect"*: `observe.sh:229-248` parses `--reason`, echoes it on 247, and the
sed on 246 writes `status: dismissed` and nothing else — *"all 26 dismissals in the register
carry no reason"*. That is my OBS-289, filed today, six days late.

### So the register ate seven more observations after diagnosing why it eats them

Husks captured **after** OBS-024 was filed and dismissed:

    OBS-032  2026-08-12 (urgent)   OBS-241  2026-08-13   OBS-274  2026-08-17 (urgent)
    OBS-035  2026-08-12            OBS-262  2026-08-16   OBS-285  2026-08-17
    OBS-044  2026-08-12

Seven, including both urgents — one of which was T-556's central finding.

### The two defects compose into a closed loop, and that is the actual root cause

Neither bug alone would have survived six days. Together they are self-concealing:

1. The **capture** bug manufactures a husk that looks like a filed observation.
2. The **dismiss** bug erases the reasoning about it, so the judgement *"this is a tool
   defect, not a junk note"* cannot be written anywhere the next session will look.
3. The next session meets one husk with no history, reads it as noise, dismisses it — and
   its reasoning is erased in turn.

Each pass is locally correct. The loop has no memory, so the population never accumulates
into a signal, and **the finding has to be rediscovered from scratch every time.** It was
rediscovered at least three times: OBS-022 (08-11), OBS-024 (08-11), T-436 (08-12), and
today. Every rediscovery was dismissed except this one, and this one only escaped because
writing T-556's verification gate forced a *count* rather than a look.

**That is why this task exists and why the earlier filings did not fix it.** The defect
was never invisible. What was missing is that nothing ever made it *cumulative*.

### What I got wrong on the way here

I reported this to the operator as a fresh discovery, twice — first OBS-287, then the
eleven-husk census — and it was neither. PL-253, captured this morning, says to read the
project's own record before instrumenting a question about it. I applied that rule to the
AEF seam and did not apply it to my own observation register four hours later. The census
numbers are all correct and the fix is still needed; the word "new" was wrong, and it was
wrong for the same reason it was wrong about the rail.

### Scope note

`.agentic-framework/` is vendored. G-008 permits fixing in-tree and upstreaming; the
0503-codex T-024 thread is the working precedent (patch vendored → tests → reviewer →
operator approval → post the outcome upstream). This task does the first three; the
upstream push is the operator's.

## The eleven husks, accounted for individually (AC6)

Recovery method: each husk's `context_task` and `captured` timestamp were used to search
handovers, task files and commit messages for surviving content. "Unrecoverable" below
means the payload exists nowhere in the tree — not that it was not looked for.

| husk | captured | task | disposition |
|---|---|---|---|
| OBS-006 | 08-09 10:59 | — | **Unrecoverable.** No task context, no reference anywhere. First known instance; predates any diagnosis. |
| OBS-011 | 08-10 18:40 | — | **Unrecoverable.** No task context, no surviving reference. |
| OBS-022 | 08-11 14:23 | T-429 | **Content known, and it is this defect.** `c00e534c` records: *"OBS-022 was that defect happening to me and is dismissed with the reason"* — the note was about the swallow bug itself. Superseded by OBS-024/OBS-287; nothing further to re-file. |
| OBS-028 | 08-11 21:25 | T-430 | **Unrecoverable, but its downstream effect survives.** S-2026-0812-0759 records a claim about OBS-028 that T-436 later *falsified* ("the reason the next person will find" — there was nowhere for it to be). The husk's own text is gone. |
| OBS-032 | 08-12 09:40 | T-440 | **Unrecoverable.** Captured `urgent`. T-440 is the zero-leg-blindness task; the note was plausibly a zero-leg finding, but that is inference and is not re-filed as fact. |
| OBS-035 | 08-12 19:22 | — | **Unrecoverable.** |
| OBS-044 | 08-12 23:00 | — | **Unrecoverable.** |
| OBS-241 | 08-13 11:47 | T-490 | **Unrecoverable.** |
| OBS-262 | 08-16 15:15 | T-544 | **Unrecoverable.** Text was `inbox` — the only non-`add` husk, so the mistyped verb was something else and even the intent is unrecoverable. |
| OBS-274 | 08-17 05:48 | T-556 | **RECOVERED and re-filed as OBS-288** (urgent). Content was in this session's working memory; the full text is restored in T-556 and in the new row. |
| OBS-285 | 08-17 12:40 | T-556 | **RECOVERED.** Same session; re-filed correctly as OBS-286 within two minutes. |

**Two of eleven recovered, both from today. Nine are gone.** Eight carry no recoverable
content at all, and one (OBS-022) is only "known" because it happened to be about this very
bug and was therefore quoted in a commit message.

That ratio is the honest measure of the cost: an observation register that loses a payload
loses it permanently, because the whole point of the register is that the thought was
captured *instead of* being held somewhere else.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **A bare-word first argument that looks like a subcommand is REFUSED, not captured.**
      `fw note add "text"` exits non-zero, writes nothing to `.context/inbox.yaml`, and
      names the correct form. "Looks like a subcommand" must be defined by a rule written
      down in the script, not by a hardcoded list of the words we happen to have typed
      wrong — a list would pass today's eleven and miss the twelfth.
- [x] **A legitimate short observation is still capturable.** The fix must not make the
      tool refuse real input. `fw note "port 3012 is wrong"` still captures. Without this
      arm the repair trades a silent-loss bug for a silent-refusal bug, and the second is
      only better because we happen to be looking.
- [x] **The refusal is proven by a test that FAILS against the current script.** Written as
      a runnable check under `tests/`, wired into `tests/run-bridge-tests.sh`, and shown
      red on the pre-fix file before it is shown green on the fixed one. A test authored
      after the fix that has never seen the bug is a description of the fix, not a check on
      it.
- [x] **Mutation-verified against at least three mutants**, each named with which leg it
      kills: (a) revert the guard → the refusal leg goes red; (b) make the guard refuse
      everything → the still-capturable leg goes red, which is the discrimination arm;
      (c) make the guard warn on stderr but still capture → the "writes nothing" leg goes
      red, because warning-and-proceeding is the plausible cheap fix and it does not
      prevent the loss.
- [x] **The eleven existing husks are left in place as dismissed rows, not deleted.** They
      are the evidence for this task and for OBS-289. A verification leg asserts no husk is
      `pending`; it must NOT assert husks do not exist. Deleting evidence to make a check
      pass is how the eight-day blindness happened.
- [x] **The eleven lost payloads are accounted for individually** — for each, either the
      content is recoverable and re-filed with a pointer, or it is recorded as
      unrecoverable with the date and the task it was attached to. "Eleven were lost" is a
      count; this AC asks what was in them. Nine predate this session and may well be
      unrecoverable, and saying so explicitly is the deliverable, not a failure of it.
- [x] **`fw doctor` and the audit still pass**, and the enforcement baseline is unchanged
      or refreshed — the file is framework tooling reached by a hook path.

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

# 1. The guard itself: 6 legs including the discrimination arm (a legitimate note must
#    still capture) and the flags-not-miscounted arm. Isolated PROJECT_ROOT — leg 0
#    asserts the live .context/inbox.yaml is byte-identical after the run, because a
#    suite that quietly wrote to the real register would be a worse version of the bug.
python3 tests/test_note_capture_refuses_lost_payload.py

# 2. The guard is actually present in the file that RUNS, not only in a patch. The
#    vendored tree is re-vendored wholesale (see ebf0c721), so this fix is one framework
#    bump away from silently disappearing — and its disappearance would look like nothing.
grep -q "_note_positional_count" .agentic-framework/agents/observe/observe.sh

# 3. The test is wired into the bridge suite. An unwired test is the T-555 shape and it
#    is the shape that let OBS-024 sit dismissed for six days: found, written down,
#    and connected to nothing that would re-raise it.
grep -q "test_note_capture_refuses_lost_payload" tests/run-bridge-tests.sh

# 4. No husk is left PENDING, and — deliberately — no assertion that husks do not exist.
#    The eleven dismissed husks are the evidence for this task and for OBS-289. Deleting
#    evidence to make a check pass is how the six-day blindness worked.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/inbox.yaml')); rows=d if isinstance(d,list) else d['observations']; assert isinstance(rows,list) and rows, 'inbox shape changed — this leg cannot see rows'; h=[r['id'] for r in rows if isinstance(r,dict) and len(str(r.get('text','')))<40 and r.get('status')=='pending']; print('pending husks:',h); sys.exit(1 if h else 0)"

# 5. The script still parses and the framework still starts. This file is on a hook path.
bash -n .agentic-framework/agents/observe/observe.sh

# 6. No mutant file was left behind in the vendored tree. Mutation testing here required
#    writing mutants INTO agents/observe/ (observe.sh derives FRAMEWORK_ROOT from its own
#    location, so a copy elsewhere dies at line 18 before running any code — the first
#    mutation run "passed" on exactly that path error, PL-206). A stray mutant would be
#    executable framework code nobody wrote on purpose.
test 0 -eq "$(ls .agentic-framework/agents/observe/ | grep -c mutant)"

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

### 2026-08-17T14:12:10Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-557-fw-note-swallows-an-unrecognised-subcomm.md
- **Context:** Initial task creation
