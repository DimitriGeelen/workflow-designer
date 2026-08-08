---
id: T-377
name: "Rail payload fidelity: the Part I delivery arrived one byte larger and the mutating stage is unidentified"
description: >
  AEF's extraction of RAIL-454 hashed 7906 B / 9e5c55f8 against my published 7905 B / 970dd530; trimming one trailing byte reproduced my hash exactly, so the content is byte-identical and the delta is a single appended newline. AEF diagnosed 'the rail transport appended one'. That names one of at least three candidate stages (hub send, hub storage/read, their decode+save) from a single observation. Read offset 454 back from the hub here and hash it: a faithful 7905 B read-back places the mutation downstream of the hub on their side; a 7906 B read-back places it at send or storage. Also: I hold one sample of this channel's behaviour and must not promote it to a channel property.

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T14:38:33Z
last_update: 2026-08-08T14:44:53Z
date_finished: 2026-08-08T14:44:53Z
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

# T-377: Rail payload fidelity: the Part I delivery arrived one byte larger and the mutating stage is unidentified

## Context

I delivered Part I of the frozen mapping standard to AEF as rail message text (RAIL-454,
7905 B, sha `970dd530…`) because `file_send` needs a listener I cannot confirm from here.
Their extraction hashed **7906 B / `9e5c55f8…`** — one byte and one line over. Trimming a
single trailing byte reproduced `970dd530…` exactly, which is a proof rather than a
coincidence: a one-byte edit cannot reach a *named* sha256 unless the remaining content is
already identical. So the content is byte-perfect and the delta is a lone appended newline.

Their diagnosis was **"the rail transport appended one."** That is one candidate out of at
least four stages — my send, hub storage, hub read, their decode-and-save — named from a
single observation. It is very likely right and it is not yet measured. Reading 454 back
from the hub *here* discriminates cleanly: a faithful 7905 B read-back exonerates send and
storage and places the mutation downstream of the hub, on their side; a 7906 B read-back
places it at send or storage and makes their diagnosis literally correct.

The second half is the one I would otherwise get wrong. **I hold one sample.** "The rail
appends a newline" is a channel property; what I have is one payload, one transfer, one
observed delta. The recoverable direction (append) is the benign one — the receiver can
always trim and re-hash. The unrecoverable direction is **stripping**: a channel that eats
trailing newlines gives a receiver no way to know how many to restore, and a hash mismatch
then has no one-byte repair that proves anything. I have measured neither direction as a
property. See `one-sample-wearing-proof`.

This matters beyond one delivery: the seam plan pins a **byte-identical fixture** shared by
both projects. Any artifact that ever crosses this channel as text acquires whatever the
channel does to it, and both sides would then pin shas that differ by a byte forever.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Offset 454 is read back from the hub on this side, its raw payload byte count and
      sha256 recorded, and the mutating stage named as **localised** (which stages the
      result exonerates, which it implicates) rather than asserted
- [x] The outcome→conclusion mapping is written down BEFORE the measurement is run, and
      both outcomes are reachable — a probe that can only return one answer localises
      nothing
- [x] Round-trip measured on a scratch topic (NOT the AEF DM — a peer reads that log) over
      at least three trailing-byte shapes, including one with **no** trailing newline and
      one with trailing spaces, so the strip direction is tested and not merely assumed
      absent
- [x] Every claim recorded is scoped to the payload shapes actually measured, with `n`
      stated; no sentence asserts a channel-wide property the run did not exercise
- [x] `tools/_t377-rail-payload-fidelity.sh` exits 0 and reports its own population — if
      the hub is unreachable it must FAIL loudly, never pass over zero transfers
- [x] AEF answered on the rail with the measurement, their resend offer answered explicitly,
      and the measured/inferred boundary drawn in the message itself

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

## Pre-registered outcome mapping

Written before the measurement is run (AC2). Both rows are reachable, so the read-back can
come out either way; a probe whose two outcomes lead to the same sentence localises nothing.

| Read-back of offset 454 on this side | Conclusion |
|---|---|
| **7905 B, sha `970dd530…`** | My send and the hub's storage/read are byte-faithful. The appended newline is downstream of the hub — in AEF's decode, extraction, or save. Their diagnosis ("the rail transport appended one") names the wrong stage while reaching the right verdict about the content. |
| **7906 B, sha `9e5c55f8…`** | The mutation is at send or in hub storage — their diagnosis is literally correct, and every artifact I have ever posted as rail text carries the same extra byte. |
| **anything else** | Neither stage is exonerated; the payload differs from both endpoints and the delivery is not merely a trailing-byte question. |

Note what this does **not** decide: whether the append is deterministic, size-dependent, or
shape-dependent. That needs the round-trip probe over multiple trailing shapes, on a scratch
topic, with `n` reported.

## Measurements

Taken 2026-08-08. Probe: `tools/_t377-rail-payload-fidelity.sh` (10/10). Read-back of the
live delivery done directly against the hub with the termlink CLI.

**1 — the delivered artifact, read back off the hub on this side**

| | bytes | newlines | sha256 |
|---|---|---|---|
| what I published as the pin | 7905 | 116 | `970dd530…` |
| **what the hub returns at offset 454** | **7905** | **116** | **`970dd530258b1cde1682a3ad9068808efbf3bb9a664b181499d8ee8328b9106f`** |
| what AEF's extraction hashed | 7906 | 117 | `9e5c55f8…` |

Tail bytes as stored: `b'go.bpmn`.\n\n---\n\n'`. **Row 1 of the pre-registered mapping.**

And the closing step, derived here rather than taken from their report: **the hub's stored
bytes plus exactly one `\n` hash to `9e5c55f8…`** — the value their extraction produced. So
the two artifacts differ by one appended newline *and nothing else*, confirmed from this
side independently.

**2 — round trip over five trailing shapes (CLI stdin path, n=5, 10–17 B)**

`two-trailing-newlines`, `no-trailing-newline`, `trailing-spaces`, `crlf-line-endings`,
`utf8-multibyte-tail` — **5 of 5 VERBATIM**. The two shapes that make the strip direction
visible are in that set, and the comparator is proven able to report APPENDED, STRIPPED and
CHANGED before any of them run.

**Conclusion, with the measured/inferred line drawn**

- *Measured:* my send, the hub's storage, and the hub's read are byte-faithful — for the
  real 7905 B artifact and for five small trailing shapes in both mutation directions.
- *Inferred:* the appended newline therefore enters **downstream of the hub, on the receiving
  side** — AEF's decode, their extraction, or their save. Their diagnosis, *"the rail
  transport appended one"*, reaches the right verdict about the content and names the wrong
  stage.
- *Not knowable from here:* whether their client pulls the same stored bytes I do. If it
  renders rather than decodes `payload_b64`, "downstream of the hub" still holds but the
  stage is their rendering, not their save. One step discriminates on their side: decode
  `payload_b64` at 454 and hash **before** any file write.

**Scope of the claim.** Five shapes at 10–17 B plus one real transfer at 7905 B. This says
nothing about payloads larger than ~8 KB, about `file_send`, or about any client other than
the two involved. "The rail is byte-transparent" is not a sentence this run earns.

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

# Round-trip fidelity, both mutation directions, with its own teeth and population guard.
# Exit code IS the verdict — no chaining, so the errexit question above never arises.
bash tools/_t377-rail-payload-fidelity.sh

# The delivered artifact still hashes to the published pin as the hub stores it. This is a
# literal sha in a gate, which is normally G-015 — legitimate here for the same reason
# AEF's own pin test is: the subject is a FROZEN document at a FIXED offset in an
# append-only log. Neither can move. If this ever goes red, the artifact or the message
# changed; do NOT refresh the expected hash to whatever it now returns.
termlink channel subscribe "dm:0e7ee6cad65137fc:6a646ce8b1bc6560" --cursor 454 --limit 1 --json > /tmp/.t377-454.json 2>&1 && python3 -c "import json,base64,hashlib,sys; e=json.loads(open('/tmp/.t377-454.json').readline()); sys.exit(0 if hashlib.sha256(base64.b64decode(e['payload_b64'])).hexdigest()=='970dd530258b1cde1682a3ad9068808efbf3bb9a664b181499d8ee8328b9106f' else 1)"

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

### 2026-08-08 — measure the stage rather than accept the peer's attribution
- **Chose:** read 454 back off the hub and localise the mutating stage before repeating
  AEF's diagnosis anywhere.
- **Why:** their evidence proved the *content* identical and the delta one byte. It did not
  establish *where* the byte was added — that was a plausible reading of a single
  observation across four candidate stages. Their conclusion happened to be wrong about the
  stage, and a stage I own is a thing to route around while a stage they own is a thing to
  fix once. Accepting the attribution would have cost them the fix.
- **Rejected:** taking it as established. It came from a peer who has been right about hard
  things all week, which is exactly when an unmeasured claim travels furthest.

### 2026-08-08 — choose shapes where the UNOBSERVED direction is visible
- **Chose:** include `no-trailing-newline` and `trailing-spaces` alongside the shape that
  mirrors the real artifact.
- **Why:** the observed direction (append) is recoverable — trim and re-hash, and a match on
  a named sha proves everything. The inverse (strip) is not: the receiver cannot know how
  many bytes to restore, so a mismatch is permanently undiagnosable. A payload already
  ending in newlines cannot exhibit a strip if the channel also appends, so testing only the
  artifact's own shape would have been blind to the failure most worth ruling out.
- **Rejected:** re-sending the standard as the test payload. It reproduces one case and is
  blind in the direction that matters.

### 2026-08-08 — scratch topic, not the AEF DM
- **Chose:** post the probe payloads to `t377-fidelity-probe`.
- **Why:** the DM rail is a log a peer reads and cites by offset. Five junk payloads per run
  would shift nothing semantically and would make the shared record harder to read.
- **Rejected:** the DM rail — convenient, and the convenience is entirely mine.

### 2026-08-08 — a literal sha256 in a P-011 gate, deliberately
- **Chose:** assert `970dd530…` as a literal in the Verification block.
- **Why:** normally G-015 — an assertion true only at authoring time. Legitimate here
  because the subject is a frozen document at a fixed offset in an append-only log, and
  neither can move. The rule is not "never pin a literal" but "pin one only where the
  subject cannot move, and record the property that makes that true". Proven to discriminate
  against offsets 453/455/456 rather than merely observed green.
- **Rejected:** re-deriving the expectation from the artifact at run time, which would pass
  over a corrupted artifact — the same defect T-354 found in a release gate.

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

### 2026-08-08T14:38:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-377-rail-payload-fidelity-the-part-i-deliver.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cd2c8627
- **Timestamp:** 2026-08-08T14:44:54Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T14:44:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
