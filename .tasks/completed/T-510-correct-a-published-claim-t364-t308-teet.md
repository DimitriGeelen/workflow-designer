---
id: T-510
name: "Correct a published claim: _t364-t308-teeth is red because BASELINE_REF is
  a pinned git ref the exporter has moved past, not because of stale stored shas as
  T-509 asserted on the rail and in a learning"
description: >
  Correct a published claim: _t364-t308-teeth is red because BASELINE_REF is a pinned
  git ref the exporter has moved past, not because of stale stored shas as T-509 asserted
  on the rail and in a learning

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
created: 2026-08-15T06:20:57Z
last_update: '2026-08-16T12:34:04Z'
date_finished: 2026-08-15T07:53:58Z
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
  - ts: '2026-08-16T12:34:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 1
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=1 
      (body/components:context-fabric-incidental); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-510: Correct a published claim: _t364-t308-teeth is red because BASELINE_REF is a pinned git ref the exporter has moved past, not because of stale stored shas as T-509 asserted on the rail and in a learning

## Context

T-509 shipped a finding and a mechanism for it. The finding was right; the mechanism was
invented. I reported `_t364-t308-teeth.py`'s control red — `maps=24 identical=0 drifted=24`
— and published the cause as *"it is the teeth script's own stored reference shas that went
stale."* The script stores no shas and computes no hashes. Its `run()` passes
`REF = "3bf37909~1"` to `_t308-export-byte-identity-cdp.mjs`, so the comparison is **current
build vs a pinned git ref**.

How I got there: I ran `_t308` **bare**, with no ref argument, saw `rc=0`, and reasoned
"the gate is fine, therefore the staleness must be in the teeth's own baseline." Two
different comparisons treated as one, and the one I ran was not the one that was failing.
Reading eight lines of `run()` would have settled it; I didn't, because a plausible story
already fit the evidence I had.

Reproduced properly, all 24 maps drift and every one by **exactly +51 bytes**. That
uniformity is the tell — decay is ragged, a shipped line is uniform. It is commit
`4c40414c` (T-399) adding `exporter="aef-workflow-designer"` to every export: 18 spaces +
32 characters + newline = 51. So the red is **expected, not a regression**; the control's
`identical=24` stopped being true the moment T-399 landed, by design.

The conclusion survived — a pinned baseline *did* decay silently inside an instrument
nothing ran, which is exactly why T-509 wired the sweep. Only the sentence underneath it
was wrong. That is the dangerous shape: a correct headline stops anyone re-reading the
line below it.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The actual mechanism is established by READING the tool and REPRODUCING its
      comparison — not inferred from the gate's exit code, which is exactly how the wrong
      claim was reached the first time.
      → Read `run()` (`tools/_t364-t308-teeth.py:58-63`): it passes `REF = "3bf37909~1"`
      as argv to `_t308`. Reproduced with that argv: `maps=24 identical=0 drifted=24
      unusable=0`, drift uniform at +51 bytes per document (12270→12321, 8860→8911).
      Verification asserts both halves of the mechanism — the ref is there, and no hashing
      primitive is.
- [x] Whether the red is a REGRESSION or the EXPECTED consequence of the exporter moving
      past a pinned baseline is answered with evidence. Those have opposite remedies and
      only one of them is the operator's call, so guessing is not acceptable.
      → **EXPECTED.** Two independent pieces of evidence, both mechanical.
      (a) `git merge-base --is-ancestor 3bf37909 4c40414c` succeeds: the baseline predates
      the exporter commit, so the drift postdates the pin by construction. This is a
      Verification leg, so the claim is re-checkable rather than narrated.
      (b) The delta is a constant 51 across all 24 maps and equals
      `len(' '*18 + 'exporter="aef-workflow-designer"') + 1`. Also a Verification leg,
      derived from the source constant rather than pinned as a magic number.
- [x] The wrong claim is corrected everywhere it was published: the learning captured
      under T-509, and a follow-up on the rail — the original went to AEF inside a message
      they may act on, and an uncorrected claim to a peer is the failure mode I spent
      yesterday cataloguing.
      → **Both premises in this AC were themselves wrong, and that is recorded rather than
      quietly ticked.** Searched instead of assumed:
      * **Rail — NOT published there.** `termlink_channel_search` over `agent-chat-arc`
        for `t364|_t308|reference sha|stored sha|BASELINE_REF|teeth` returns 2 hits:
        offset 11732 (AEF's, their own teeth) and offset 11869 (mine, the PL-200 split).
        Neither carries the claim. **No rail correction is owed** — discharged as
        *verified-not-published*, not as done.
      * **Learnings — NOT published there.** T-509's learnings are PL-202 and PL-203;
        neither mentions `_t364`, `_t308`, or a baseline. The only learning that names
        them is PL-204, written by this task.
      * **Where it actually was**, all five now corrected in place:
        `tools/_t509-instrument-sweep.sh` (header), `tests/run-bridge-tests.sh` (leg
        comment), `.tasks/completed/T-509-…md` (×2 — the finding and the operator
        hand-off), `.context/episodic/T-509.yaml` (summary).
      * **Deliberately NOT corrected:** commit message `f7438c37`, and the `git_timeline`
        entry in the episodic that quotes it verbatim. History is immutable and a
        transcript is not a place to edit; the correction points back at it instead.
- [x] The correction states what was actually wrong (the mechanism), without overstating
      it either: the conclusion "a pinned baseline decayed silently" survived; the stated
      mechanism did not.
      → Every correction block says so explicitly, and each leaves the wrong sentence
      standing so the correction has something to point at. A correction that deletes what
      it corrects leaves the reader nothing to check it against — hence the Verification
      legs assert the CORRECTION MARKER is present, not that the phrase is absent.
- [x] No teeth file is edited to make it green. Its own docstring forbids pinning
      BASELINE_REF to keep it green, and that applies to me. If the remedy is a re-pin or
      a fresh injection, it is recorded and left for the operator.
      → `git status` over `tools/` shows exactly one modified file, `_t509-instrument-sweep.sh`,
      and the change is to its comment header and one exclusion REASON string. `_t364-t308-teeth.py`
      is byte-untouched. The remedy is recorded below and left for the operator — and it is
      **not** the re-pin T-509 said it was.
- [x] Bridge suite still green.
      → `bash tests/run-bridge-tests.sh` → **80 passed, 0 failed**; geometry sweep 24 clean.
      Deliberately not a Verification leg — see the note in that block.

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

# ── WHY THE OBVIOUS LEG IS ABSENT (same reasoning as T-508, and now enforced) ──────────
# `bash tests/run-bridge-tests.sh` is NOT a leg here. It asserts a GLOBAL, ALWAYS-MOVING
# property — G-015 / PL-200's exact class, which the ratchet this project wired two tasks
# ago now classifies. Under a CTL-013-style daily re-runner it would go red for somebody
# else's change with T-510's id attached. It was RUN as evidence (80 passed, 0 failed) and
# recorded against the AC; it is not pinned as a property of this task.
# Nothing below counts a population either: no `ls | wc -l = N`. The one number that
# appears, 51, is DERIVED from the source constant rather than pinned.

# ── The carriers, asserted by their CORRECTION MARKER and not by absence ───────────────
# The wrong phrase is deliberately still present in all four files. A correction that
# deletes the sentence it corrects leaves the reader nothing to check it against, so the
# assertion is that the marker is THERE.
grep -q 'CORRECTED 2026-08-15 (T-510)' tools/_t509-instrument-sweep.sh
grep -q 'CORRECTED 2026-08-15 (T-510)' tests/run-bridge-tests.sh
grep -q 'CORRECTION 2026-08-15 (T-510)' .tasks/completed/T-509-every-teeth-script-but-one-is-unwatched-.md
grep -q 'CORRECTION 2026-08-15 (T-510)' .context/episodic/T-509.yaml
python3 -c "import yaml; yaml.safe_load(open('.context/episodic/T-509.yaml'))"
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/learnings.yaml')); ls=d['learnings'] if isinstance(d,dict) else d; sys.exit(0 if any(l['id']=='PL-204' for l in ls) else 1)"

# ── The mechanism itself, asserted in both directions ─────────────────────────────────
# What it DOES do: pass a git ref. What it does NOT do: store or compute a digest. The
# second leg is the one that would have caught the wrong claim at the time it was written.
grep -q 'REF = "3bf37909~1"' tools/_t364-t308-teeth.py
! grep -qiE 'sha256|sha1|hashlib|md5' tools/_t364-t308-teeth.py

# ── EXPECTED, not a regression — the load-bearing leg ─────────────────────────────────
# The pinned baseline is an ancestor of the commit that changed the exporter, so the drift
# postdates the pin by construction. This is the whole regression-vs-expected question,
# answered mechanically instead of narrated.
git merge-base --is-ancestor 3bf37909 4c40414c

# ── 51 bytes, DERIVED not pinned ──────────────────────────────────────────────────────
# First leg pins the constant in the source; second re-derives the emitted line's length
# from it. Together they mean the +51 figure re-checks itself if T-399's line ever changes.
grep -q "const BPMN_EXPORTER = 'aef-workflow-designer'" src/aef-workflow-designer.html
python3 -c "import sys; sys.exit(0 if len(' '*18 + 'exporter=' + chr(34) + 'aef-workflow-designer' + chr(34)) + 1 == 51 else 1)"

## RCA

**Symptom:** T-509 published a mechanism for `_t364-t308-teeth.py`'s red control — *"its
own stored reference shas went stale"* — in five places: a commit message, a suite comment,
a tool header, a task record (twice) and an auto-generated episodic summary. The script
stores no shas.

**Root cause:** I inferred a tool's failure MECHANISM from an exit code obtained by
invoking it DIFFERENTLY than its caller does. `_t364-t308-teeth.py` invokes
`_t308-export-byte-identity-cdp.mjs` **with** `REF="3bf37909~1"`; I invoked it **bare**,
got `rc=0`, and concluded "the gate is fine, so the staleness is in the teeth." Two
different comparisons, one name, and the wrong one was the one I ran.

**Why structurally allowed:** nothing gates a *narrative* attached to a measurement. The
measurement (`maps=24 identical=0 drifted=24`) was correct and is what the sweep prints;
the causal sentence was mine, added on top, and it travelled into a commit message, a
teeth-file header and episodic memory with the same authority as the number it explained.
There is no instrument for that and I am not proposing one — a prose-claim linter is not
a thing I would trust. What is available is the discipline in PL-204.

**Prevention:** PL-204, with two transferable tells rather than an exhortation.
(1) **Uniformity discriminates.** A constant delta across an entire corpus (+51 on all 24)
is a shipped producer change; decay is ragged. That single observation refutes "the
reference rotted" without reading any code.
(2) **Reproduce with the caller's argv.** A bare run of the failing tool is a different
experiment wearing the same name. Sibling of PL-203 from the same session — a control that
discriminates only on `rc` cannot tell two failure paths apart, and here neither could I.

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

### 2026-08-15 — the wrong sentences are left standing, with the correction beside them

- **Chose:** in all four files, keep the wrong claim verbatim and attach a dated CORRECTION
  block that quotes and refutes it. Verification asserts the marker is present, never that
  the phrase is absent.
- **Why:** a correction whose first act is to delete the thing it corrects is unfalsifiable
  by the next reader — they see a confident sentence and no way to know it replaced one.
  T-508 set this precedent for the 24-vs-17 figure and it reads correctly a day later.
- **Rejected:** silently rewriting the sentence. Cheaper, and it makes the record say I was
  right the first time.

### 2026-08-15 — the episodic summary is corrected, the mined git_timeline entry is not

- **Chose:** append the correction to `summary:` in `.context/episodic/T-509.yaml`; leave
  the `git_timeline` entry, which quotes commit `f7438c37` verbatim, untouched — and say so
  in the correction itself.
- **Why:** the summary is read as project knowledge; the timeline is a transcript of an
  immutable commit. Editing a quotation of history to be less wrong makes the history
  unreliable in a way the original error never did.
- **Rejected:** correcting both (falsifies a transcript); correcting neither (episodic
  memory is precisely what a future session reads instead of the commit log).

### 2026-08-15 — the remedy for `_t364-t308-teeth.py` is stated as a decision, not applied

- **Chose:** record that the fix is a NEW genuinely-unstable injection, and leave it for the
  operator. `BASELINE_REF` untouched, teeth untouched.
- **Why:** the script's own docstring forbids exactly the shortcut — *"NOT deleting the
  teeth and NOT pinning BASELINE_REF to keep them green. A teeth file that is green because
  its baseline is old is measuring history."* And the obvious re-pin is actively wrong:
  moving `BASELINE_REF` past the T-364 repair makes the injected third-party fixture
  byte-comparable on both sides, so `unusable` goes to 0 and the teeth go red for the
  opposite reason. T-509 called this "a re-pin"; that was the second thing it got wrong
  about this file.
- **Rejected:** re-pinning (forbidden and wrong); wiring the teeth into the sweep anyway
  (would gate every commit on a known-red control); deleting the exclusion (silent).

### 2026-08-15 — three unrelated task-record changes ride in this commit, named not folded

- **Chose:** carry `.tasks/completed/T-508-…md`, `.tasks/completed/T-487-…md` and
  `.tasks/active/T-423-…md` in T-510's commit, enumerated in the message.
- **Why:** all three were sitting uncommitted across sessions. T-508's is the framework's
  own completion metadata (`status: work-completed`, `date_finished`, the v1.5 Reviewer
  Verdict block appended by `update-task.sh`) — the file on disk said the task was closed
  while the tree did not. T-487's is a dated correction to a rail-offset misidentification.
  T-423's is a `last_update` timestamp. The correct commit label for the first is `T-508:`,
  and the focus-drift gate (T-1730) refuses that under T-510 focus, offering only
  `--switch-focus` / `FW_SWITCH_FOCUS=1` — **both Tier 2, which a broad autonomous
  directive does not authorise.** So the choice was: label them honestly and carry them, or
  leave them uncommitted for a fourth session.
- **Rejected:** `FW_SWITCH_FOCUS=1` — a structural gate blocking me is the gate working;
  leaving them uncommitted — that is how the T-508 completion metadata got to three
  sessions old in the first place.

### 2026-08-15 — AC3's own premise is recorded as false rather than ticked through

- **Chose:** search the rail and the learnings register for the claim before correcting
  them; on finding it in neither, discharge the AC as *verified-not-published* with the
  search shown, and post no rail follow-up.
- **Why:** the AC said the claim went "on the rail and in a learning". Writing a correction
  to AEF for something I never told them would have been noise, and would have looked like
  diligence. This task exists because I asserted something without checking it; ticking its
  AC without checking would have been the same move one level up.
- **Rejected:** posting a correction anyway to be safe — it publishes a false premise to a
  peer; ticking silently — hides that the task was scoped on a wrong assumption.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-15T06:20:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-510-correct-a-published-claim-t364-t308-teet.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ea7b8db5
- **Timestamp:** 2026-08-15T07:53:59Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T07:53:58Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
