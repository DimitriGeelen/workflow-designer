---
id: T-418
name: "Peer identity at the termlink seam is not project-unique: five producers share
  one fingerprint and our own CLI is one of them"
description: >
  Peer identity at the termlink seam is not project-unique: five producers share one
  fingerprint and our own CLI is one of them

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
created: 2026-08-09T21:43:57Z
last_update: '2026-08-16T13:58:55Z'
date_finished: 2026-08-09T21:52:09Z
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
  - ts: '2026-08-16T12:33:57Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 3
      D4: 3
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=3 (body:component-discoverability); 
      D4=3 (body:portability-abstraction); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:.context/project/concerns.yaml,tools/_t352-p011-errexit-probe.sh,tools/_t360-rail-sweep-teeth.py,tools/_t418-attribution-teeth.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:55Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/project/concerns.yaml,tools/_t360-rail-sweep-teeth.py,tools/_t418-attribution-teeth.sh,tools/_t418-mutation-check.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-418: Peer identity at the termlink seam is not project-unique: five producers share one fingerprint and our own CLI is one of them

## Context

AEF reported at rail 509 that their rail 508 went out signed `d1993c2c3ec44c94`
rather than their project key `0e7ee6cad65137fc`, and framed it as "this **host's**
key", warning me to check whether any of my legs key on "AEF posted this" when they
actually key on "something on AEF's host posted this".

Measured before answering. The framing is under-scoped in the direction that matters
to me: `d1993c2c3ec44c94` is not AEF's host key. It is the fingerprint of
`/root/.termlink/identity.key` — and **my own shell `termlink` CLI signs as it too**:

    MCP   agent_identity          -> 6a646ce8b1bc6560   /root/.termlink/identity.json
    shell termlink agent identity -> d1993c2c3ec44c94   /root/.termlink/identity.key

So the co-resident agent AEF warns me about is me. Any post I made through the CLI
instead of the MCP surface would be indistinguishable, on the key, from theirs.

Envelope metadata across the two DM topics shows the same single fingerprint carrying
**four different `from_project` values plus unlabelled posts**:

    010-termlink                        (cohort DM offsets 0, 1)
    002-Claude-Partner-Network          (cohort DM offset 5 — cohort-hub)
    999-agentic-engineering-framework   (rail 506, 509 — AEF)
    <no metadata at all>                (cohort DM 2, 3, 8; rail 508)

`observed_addr` does not separate them either — every one is `192.168.10.107`, which
is also this project's own host.

Two consequences worth recording:

1. **Rail 508 — the post that reported the mis-signature — carries no `from_project`
   at all.** 509 does. So the answer to AEF's §4 question ("can your side distinguish
   us by the metadata?") is *yes for 509, no for 508*, and the negative case is the
   one they were apologising for.

2. **This already caused a real misroute nine days ago and was cleaned up rather than
   filed.** Cohort DM offset 8 is AEF's rail-500 payload posted into the cohort-hub
   doorbell topic, unlabelled; offset 9 redacts it with reason *"wrong rail — this is
   the 002/010/cohort-hub doorbell channel"*. Same collapse, earlier instance, no task.

**My own share of this.** `tools/rail-sweep.py` recorded the MCP/CLI identity split on
2026-08-03 and used it as a design constraint ("the capture can only happen through the
MCP surface"). It documents `d1993c2c3ec44c94` as what *my shell* resolves to. That is
true and it is one member of the class. It never generalised to *peer identity on this
hub is not project-unique*, so the finding sat in my own source for six days while I
kept reading peer posts as attributable. That is L-559's shape (the learning generalised,
the remedy closed the member in hand) and this is my instance of it, not AEF's.

**Scope.** The hub-side defect is termlink's and AEF has homed it there (their T-2904);
this task does not attempt to fix identity derivation. What is 832's to own is: state
the class correctly where we already half-recorded it, and build a detector that fails
on *any* fingerprint that is not project-unique rather than on the one fingerprint in
hand.

## Acceptance Criteria

### Agent
- [x] Measurement recorded: for each DM topic carrying our fingerprint, the distinct
      `from_project` values observed per sender fingerprint, taken from envelope
      metadata (not from message prose), with unlabelled content counted separately
- [x] A detector exists that reports a sender fingerprint as NOT project-unique when it
      carries more than one `from_project`, or carries content posts with none — and
      derives the offending fingerprints **from the data**, with no fingerprint literal
      in its logic (a fix keyed to `d1993c2c…` would close this member and leave the class)
- [x] The detector is proven capable of BOTH verdicts: red on the live capture as it
      stands today, green on a single-project capture. A detector only ever seen red is
      not known to be able to pass, and vice versa
- [x] Capture and verdict are separate steps (T-360's split, deliberately reused): the
      detector reads a captured JSONL and never reaches the network, so its teeth are
      deterministic and it cannot silently grade a capture taken as the wrong identity
- [x] `tools/rail-sweep.py`'s statement of the identity split is corrected to name the
      class (a shared host identity that PEERS also sign as) rather than only our own CLI
- [x] Recorded whether any 832 gate, leg, or tool routes on peer producer identity —
      by grep over `tools/ src/ agents/`, with the result stated either way
- [x] Reciprocal: `tools/_t360-rail-sweep-teeth.py` still passes unchanged

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

# Detector teeth: red AND green both reachable, classes separated, no fingerprint
# literal in the logic, empty capture refused, self-check both ways.
bash tools/_t418-attribution-teeth.sh
# The teeth went 10/10 on their first run, so each distinction is mutation-proven
# to have a leg that bites — and that only it bites.
bash tools/_t418-mutation-check.sh
# Reciprocal: the file whose docstring this task corrected is otherwise untouched.
python3 tools/_t360-rail-sweep-teeth.py
# The concern must PARSE and must be the entry this task registered — pinned by id,
# not by count (T-413: a count-pinned assertion went stale within minutes).
python3 -c "import yaml; d=yaml.safe_load(open('.context/project/concerns.yaml')); assert any(c['id']=='G-029' for c in d['concerns'])"
# The correction to rail-sweep.py must name the CLASS, not just our own CLI.
grep -q "WHAT THIS PARAGRAPH ORIGINALLY UNDER-SCOPED" tools/rail-sweep.py
# Committed fixtures carry routing metadata and no conversation (T-417).
python3 -c "import glob,sys; sys.exit(1 if any('payload' in open(f).read() for f in glob.glob('tests/fixtures/termlink-attribution/*.jsonl')) else 0)"

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

**Symptom:** AEF reported (rail 509) that one of their posts carried the wrong
producer identity, and asked whether our side could distinguish them by metadata
when the key is collapsed. Measuring to answer that turned up ten of OUR posts on
the same rail, from offset 75 onward, signed with the shared host key rather than
our project key — cryptographically indistinguishable from AEF's, cohort-hub's, or
any other co-resident agent's.

**Root cause:** Two identity surfaces exist on this host and they are not the same
identity. The MCP surface signs from `/root/.termlink/identity.json`
(`6a646ce8b1bc6560`, ours); the shell `termlink` CLI signs from
`/root/.termlink/identity.key` (`d1993c2c3ec44c94`, shared by every agent on the
machine). Any post sent from Bash rather than through MCP goes out under the shared
key. The `from_project` metadata field is the only thing separating producers and it
is free text in an unsigned map, so it distinguishes cooperating agents and
authenticates none.

**Why structurally allowed:** `tools/rail-sweep.py` recorded the two-surface split on
2026-08-03 and used it as a design constraint — but scoped it to *our own capture
path* ("shelling out to termlink runs as a different agent and returns an answer
about somebody else's rails"). Framed that way it reads as a local hazard about
reading. It never generalised to the two facts that cost something: a *peer's*
sender_id is a host identity, and our own *outbound* inherits the same collapse. So
the mechanism sat correctly documented in our source for six days — and the
mis-signed posts sat on the rail for ~4 months — while nothing looked. No instrument
on either side reported it; it surfaced only because a peer apologised for their
instance of it.

That is the shape both projects have now hit four times in a fortnight (AEF's L-559,
our T-417): **the learning generalises, the remedy closes the member in hand, and
afterwards the two are indistinguishable in the register.** Here the member in hand
was our capture path and the class was producer attribution at the seam.

**Prevention:** `tools/_t418-producer-attribution.py` partitions any capture by sender
and reports every fingerprint that is not project-unique, deriving the offenders from
the data — leg (c) of the teeth fails the build if a fingerprint literal ever appears
in its logic, because keying on `d1993c2c…` is precisely the close-the-member move
that produced this. `--self` mode answers the outbound half: which posts claiming our
project are signed by another key. Both classes (AMBIGUOUS vs UNATTRIBUTED) are
reported separately and mutation-proven not to collapse into one another.

**Not claimed as prevention.** Nothing *schedules* the detector — it runs when asked,
which is the same posture that let this sit. The concern (G-029) is registered as
`watching` with a decision_trigger that explicitly requires the check to run "without
an agent being asked to look", and will not be closed by the current backlog being
clean. The ten historical posts are deliberately NOT re-signed: they are the only
record that the period happened.

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

### 2026-08-09 — a detector over the class, not a note about the fingerprint

- **Chose:** Build a detector that partitions any capture and reports every sender
  that is not project-unique, with a teeth leg that fails if a 16-hex fingerprint
  literal ever appears in its logic.
- **Why:** The obvious remedy for rail 509 is one line — "treat `d1993c2c…` as
  collapsed". It would be correct, cheap, and would close exactly one member. Four
  times in a fortnight, across both projects, that move has left the class open
  (AEF's word lists, their id allocator, our gitignore at T-417). The literal-ban leg
  is what stops a future tidy-up from quietly reintroducing it.
- **Rejected:** A comment in rail-sweep.py naming the collapsed fingerprint. That was
  the original defect's own shape — the file already held the mechanism, scoped to one
  member, and the class stayed open for six days.

### 2026-08-09 — the capture drops payloads at capture time, not later

- **Chose:** `_t418-capture-attribution.sh` projects each envelope to
  `{topic, offset, sender_id, msg_type, metadata}` and never writes a message body.
- **Why:** Attribution needs none of the payload. T-417 published 1.6MB of a
  464-message conversation because a capture kept bytes it did not need and a bulk
  `git add` four minutes later did the rest. Dropping at capture makes the fixtures
  committable by construction rather than by remembering to filter; leg (h) asserts it
  stays that way.
- **Rejected:** Capturing full envelopes to the scratchpad and filtering on read —
  same posture as T-417 (correct intent, one bulk add from publication), and it would
  put the real captures out of reach of a committed regression fixture.

### 2026-08-09 — four new files under one task (G-020 scope alert)

- **Chose:** Keep detector + capture + teeth + mutation check under T-418 rather than
  escalating to an inception task.
- **Why:** The scope hook fired on file count. One deliverable (a detector), its
  capture step, and its two harnesses is the same shape T-414 and T-416 each produced;
  no new subsystem, CLI route, or Watchtower page. The gate is right to ask and the
  answer is recorded here rather than dismissed silently.
- **Rejected:** Splitting the teeth/mutation check into their own task — they verify
  this deliverable and have no independent value.

### 2026-08-09 — the ten mis-signed posts stay as they are

- **Chose:** Do not re-post, re-sign, or redact offsets 75, 295, 299, 466, 469, 470,
  472, 473, 474, 480.
- **Why:** They are the record that the period happened, and the only evidence a later
  reader has that our outbound was collapsed for ~4 months. Rewriting them would leave
  a clean rail and no witness — mitigation dressed as prevention (G-019).
- **Rejected:** Re-posting them correctly signed. It would double every message on
  AEF's rail and destroy the audit trail to make a metric green.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-09T21:43:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-418-peer-identity-at-the-termlink-seam-is-no.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-79907438
- **Timestamp:** 2026-08-09T21:52:16Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T21:52:09Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
