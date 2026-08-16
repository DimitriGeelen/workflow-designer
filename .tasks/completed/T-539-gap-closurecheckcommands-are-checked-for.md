---
id: T-539
name: "gap closure_check_commands are checked for renderability but never for whether
  they can FAIL while the gap is open"
description: >
  gap closure_check_commands are checked for renderability but never for whether they
  can FAIL while the gap is open

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
created: 2026-08-16T11:38:07Z
last_update: '2026-08-16T12:34:07Z'
date_finished: 2026-08-16T11:50:46Z
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
  - ts: '2026-08-16T12:34:07Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-539: gap closure_check_commands are checked for renderability but never for whether they can FAIL while the gap is open

## Context

> **The paragraph below is the hypothesis this task was FILED on. It is partly wrong —
> see "Measured before the ACs were written" two sections down for what is actually
> true.** It is kept because the correction is the useful part of the record.

`audit.sh` emits `[PASS] Gap register: every watching gap has a renderable closure
condition`. **Renderable is not discriminating.** A `closure_check_command` that raises,
that prints nothing, or that reports the same verdict no matter what the tree looks like
still satisfies "renderable" — and a gap carrying one is a gap whose closure condition
cannot tell open from closed. The register would then be recording an intention, not a
test.

This is the same shape as PL-159 ("a bar stated in a failure message is not a bar the
instrument holds") and PL-070 ("teeth prove a guard FIRES; they say nothing about whether
it can fail"), applied to the gap register itself — the structure whose entire job is to
hold the project's open problems until they are mechanically demonstrated closed.

The fourth instance this week of one shape, and the first one looked for on purpose
rather than tripped over: T-535 (trend key = the rendered sentence), T-536 (a routing
comment standing in for the section the hook passes), T-537 (`ok:true` standing in for
whether the source contains the arc), T-538 (an id used as a key with nothing checking
uniqueness).

### Measured before the ACs were written — the finding is sharper than the filing

`check_gap_triggers` (T-382, `audit.sh:2175`) audits `decision_trigger`, the **prose**
closure condition, and specifically that it sits under the key `fw gaps` renders. Its
PASS line is accurate to what it checks. It never looks at `closure_check_command`, and
it does not claim to — so the original framing of this task ("the audit's PASS covers
this") was wrong and is not what gets fixed here.

The real contract lives in the **reader**: `lib/gaps.py:run_closure_gauge` parses the
command's *stdout* for `verdict: READY|NOT_READY` or `ready: true|false`. Exit code is
not the signal. Anything else — including a clean exit with a perfectly readable prose
status line — normalises to **UNKNOWN**, and `close_gap` refuses 412 on anything that
is not READY.

Measured against that reader, 6 of 32 watching gaps carry a command:

| gap | verdict | note |
|---|---|---|
| G-032, G-035, G-036, G-037 | `NOT_READY` | conforming — emit a JSON verdict token |
| **G-038** | **UNKNOWN** | mine, T-536, yesterday |
| **G-039** | **UNKNOWN** | mine, T-538, ~1h before this measurement |

Both non-conforming entries are mine. G-039 was written by explicitly matching G-038's
shape, and G-038 was already non-conforming — so the defect propagated by imitating the
adjacent entry instead of reading the consumer. **Conformance-by-imitation copies the
neighbour's non-conformance.** It fails safe (UNKNOWN is never READY, so nothing can be
wrongly closed), but it renders identically to "gauge unavailable or broken" in `fw gaps`
and on the Watchtower gaps page, and it means one-click closure can never succeed for
these two gaps no matter what the tree does.

## Acceptance Criteria

### Agent
- [x] `tools/_t539-gap-closure-gauge-conformance.py` evaluates every `watching`
      gap's `closure_check_command` through the REAL reader
      (`lib/gaps.py:run_closure_gauge`), not a reimplementation of its parsing
- [x] It goes red on any gap whose verdict is `UNKNOWN`, naming the gap id and
      the first line of its output
- [x] It REFUSES (rc 2) rather than passes if zero watching gaps carry a
      closure command — an empty corpus must not read as health
- [x] Anti-vacuity in both directions: a synthetic non-conforming command is
      shown to yield `UNKNOWN` and a synthetic conforming one `NOT_READY`, so a
      green run is a classification rather than an absence
- [x] G-038 and G-039 are repaired to emit a machine-readable verdict token
      while KEEPING their human-readable witness line
- [x] `concerns.yaml` is byte-identical (sha256) across a probe run — the probe
      reads the register, never writes it
- [x] Wired into `tests/run-bridge-tests.sh`; suite green

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
#
# NOTE: nothing below pins the NUMBER of gaps or gauges. Both move as the register does,
# and pinning either would assert a global always-moving property (G-015). What is asserted
# is that no gauge is unreadable, which is a property of the entries themselves.
python3 tools/_t539-gap-closure-gauge-conformance.py
grep -q '_t539-gap-closure-gauge-conformance.py' tests/run-bridge-tests.sh
grep -q "closure gauge returns a verdict the reader accepts (T-539)" tests/run-bridge-tests.sh
python3 -c "import importlib.util as u,yaml,sys;s=u.spec_from_file_location('g','.agentic-framework/lib/gaps.py');m=u.module_from_spec(s);s.loader.exec_module(m);d=yaml.safe_load(open('.context/project/concerns.yaml'));r=[x for x in d['concerns'] if x['id'] in ('G-038','G-039')];sys.exit(0 if len(r)==2 and all(m.run_closure_gauge(x['closure_check_command'],project_root='.')[0]=='NOT_READY' for x in r) else 1)"

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

**Symptom:** 2 of the 6 watching gaps carrying a `closure_check_command` returned
`UNKNOWN` from `lib/gaps.py:run_closure_gauge` — G-038 and G-039, both written by this
agent, the second by copying the first roughly an hour earlier.

**Root cause:** the conformance contract lives in the **reader**, and it is stricter than
it looks: exit 0, *and* stdout parsing as pure JSON, *and* a `verdict`/`ready` key. Both
entries were authored by matching the shape of an adjacent register entry instead. G-038
compounded it by signalling "stranded" through **exit code 1** — the same channel the
reader uses for "the gauge itself failed" — so its otherwise-correct JSON verdict was
discarded before being parsed. Two meanings on one wire, and the stricter one wins.

**Why structurally allowed:** three things had to line up. (1) `audit.sh`'s
`check_gap_triggers` covers the *prose* half of a closure condition and does not claim to
cover the command — so its PASS is honest and gives no signal here. (2) Nothing else reads
the command except `fw gaps` and the Watchtower gaps page, and both render UNKNOWN the
same way they render a genuinely broken gauge, so the display could not distinguish the
two. (3) **The failure mode is fail-safe**, which is why it survived: `close_gap` refuses
anything that is not READY, so a malformed gauge can never wrongly close a gap. It only
loses the ability to ever report success. Nothing breaks; a capability quietly disappears.

**Prevention:** `tools/_t539-gap-closure-gauge-conformance.py`, wired into the bridge
suite, driving the real `run_closure_gauge`. Its four anti-vacuity probes pin the contract
itself, including the exit-code trap, so a change to the reader's rules surfaces as a red
leg rather than as silently-revalidated gauges.

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

### 2026-08-16 — drive the real reader, do not reimplement its parsing

- **Chose:** the probe imports `lib/gaps.py` and calls `run_closure_gauge`.
- **Why:** the defect was a wrong belief about the contract. A probe that reimplemented
  the parsing would encode that same belief and confirm it. The only instrument that can
  catch a misunderstanding of a consumer is the consumer.
- **Rejected:** parsing the JSON myself, which would have been simpler, faster, and would
  have passed while both gauges were still broken.

### 2026-08-16 — exit code is "did the gauge run", not "is the gap open"

- **Chose:** G-038 now always exits 0; its stranded/OK state travels in the `verdict` key.
- **Why:** the reader discards stdout entirely on a non-zero exit, so overloading rc with
  state destroys the verdict. An anti-vacuity probe pins this specific trap so the next
  author meets it as a red leg instead of a silent UNKNOWN.
- **Rejected:** keeping rc 1 and teaching the reader to interpret it — that is AEF's
  vendored code and its current contract is defensible; the entries were wrong, not it.

### 2026-08-16 — the other 26 watching gaps were left prose-only

- **Chose:** no closure commands were invented for the 26 watching gaps that have none.
- **Why:** a prose `decision_trigger` is a legitimate closure condition and is already
  audited by `check_gap_triggers`. Manufacturing 26 mechanical gauges to make a number go
  up would produce exactly the thing this task exists to catch — commands written to
  satisfy a check rather than to measure something.
- **Rejected:** treating "6 of 32" as the finding. It isn't; the finding is that 2 of the
  6 that exist could not be read.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-16T11:38:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-539-gap-closurecheckcommands-are-checked-for.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-065e60cb
- **Timestamp:** 2026-08-16T11:50:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-16T11:50:46Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
