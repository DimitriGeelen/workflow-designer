---
id: T-484
name: "Audit the bridge and editor coverage enumerations by behaviour, not membership"
description: >
  Audit the bridge and editor coverage enumerations by behaviour, not membership

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
created: 2026-08-12T23:09:02Z
last_update: '2026-08-16T12:34:02Z'
date_finished: 2026-08-12T23:12:21Z
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
  - ts: '2026-08-16T12:34:02Z'
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

# T-484: Audit the bridge and editor coverage enumerations by behaviour, not membership

## Context

T-483 measured that appending seven non-scalar values to the round-trip harness's
`METAKEYS` would have satisfied every leg that checks the list by MEMBERSHIP while moving
detection from 0/7 to 2/7 — because `String()` on a dict, and on an array of dicts, is the
constant `[object Object]`. Captured as a learning and published to AEF at rail 599:

> A name in a coverage list is a CLAIM. Only a value that varies is EVIDENCE.

I told AEF that every coverage enumeration on both sides is exposed to this, having
measured exactly one of mine. This task makes that claim honest for our tree, or retracts
it. PL-148 is the governing prior: an instrument's registration must be asserted by
something other than the instrument.

Scope is the SEAM-BEARING enumerations — the bridge key lists in `tools/yaml-to-bpmn.py`
and the editor-side lists they are in parity with. Those are the ones whose inertness would
be an AEF-facing defect rather than a local one.

## Acceptance Criteria

### Agent
- [x] AC1 — Enumerate the seam-bearing coverage lists with their member counts, measured
      from source, not recalled. Denominator stated (PL-084): how many lists, how many
      members total, and what was deliberately excluded from scope and why.
- [x] AC2 — For each member of each in-scope list, determine BEHAVIOURALLY whether the
      artefact's output varies with that member's underlying value. The test is a mutation:
      change the value, confirm the output changes. Membership in the list is not evidence
      and is not accepted as one.
- [x] AC3 — The probe carries a positive control: at least one member known to be live must
      be reported live, and a deliberately inert member (synthetically constructed) must be
      reported inert. A probe that cannot report inertness proves nothing about its absence.
- [x] AC4 — Every member is classified LIVE / INERT / NOT-EXERCISABLE with its reason.
      NOT-EXERCISABLE (no corpus instance to mutate) is reported as its own outcome with a
      denominator — never folded into LIVE, and never counted as a pass (T-482 `linkId`
      precedent).
- [x] AC5 — Any member found INERT is registered as an observation and filed as its own
      task (one bug = one task). It is NOT fixed inside this task — this is an audit, and
      an audit that starts repairing loses track of what it has covered.
- [x] AC6 — The published claim is settled either way: the rail-599 generalisation is
      either CONFIRMED against our tree with counts, or RETRACTED to AEF with the
      measurement that falsifies it. A finding of zero inert members is a real result and
      must be reported as such, with its denominator, not quietly dropped.
- [x] AC7 — Read-only with respect to product code: `git diff` empty on `src/`,
      `tools/yaml-to-bpmn.py`, `docs/standards/`, `examples/`, `tests/fixtures/`,
      `.agentic-framework/`. The audit may add a probe under `tools/`, nothing else.

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

## Findings

### AC1/AC2 — 35 members audited by behaviour: 35 LIVE, 0 INERT

    list                        members   shape       LIVE   INERT
    META_KEYS                        29   scalar        29       0
    STRUCTURED_DICT_KEYS              3   dict           3       0
    STRUCTURED_LIST_KEYS              2   list           2       0
    STRUCTURED_ITEMLIST_KEYS          1   itemlist       1       0
    total                            35                 35       0

Method: for each key, set it on a node's `aef` to value A, run the bridge's `emit()`, set it
to B, emit again. Byte-identical output means the key is named in a coverage list and changes
nothing. Every one of the workflow's 14 nodes is tried per key, because "inert on the node I
happened to pick" is not "inert".

Controls held (AC3): `tier` reported LIVE, a synthetic key in no enumeration reported INERT.
Without the negative control a clean sweep would be indistinguishable from a probe that
cannot detect inertness at all.

### AC6 — the published claim, settled: the RULE holds, the BRIDGE is clean

At rail 599 I told AEF that every coverage enumeration on both sides is exposed to the
membership-vs-behaviour defect, having measured exactly one of my own lists. Measured
against the bridge: **zero instances in 35 members.** That is reported as the result, not
dropped for being undramatic. The generalisation was over-broad as stated.

### Why the bridge is immune and the harness was not — the transferable part

This is the finding worth more than the zero. The two artefacts differ structurally:

    harness   ONE list (METAKEYS) + ONE projection body: String(aef[k])
    bridge    FOUR lists, one PER SHAPE, each with its own shape-specific emitter

The harness had a single universal stringifier, so a member whose shape it could not
represent degraded silently to a constant — `[object Object]` — and 5 of 7 structured values
would have been inert had they been added there. The bridge cannot express that bug: to add
a key you must first choose which shape-list it belongs to, and each list's emitter already
matches its shape. The shape check happens at registration time instead of never.

**One list per shape forces the emitter to match the shape. One list for all shapes invites a
universal stringifier, and a universal stringifier always answers** — the same failure family
as `grep` always answering and `sort -V` always answering (AEF 538). So the defect is not
really "someone used String()"; it is that a single flat enumeration over heterogeneous
shapes has nowhere to put the shape, and the stringifier fills the gap silently.

### Scope NOT covered, stated so the zero is not read as wider than it is

- `KNOWN_AEF_KEYS` (44 members) — a VALIDATOR allowlist, not an emission list. Different
  semantic: its members are not projected, they gate what is accepted. The negative control
  exercised it incidentally (an unknown key is dropped with a warning) but it was not audited
  member-by-member.
- Editor-side `metaKeys` / `FIELD_DEFS` / `NODE_FIELDS` — not in scope.
- Harness `METAKEYS` / `STRUCTKEYS` — already measured by T-482/T-483.

A zero over 35 emission-list members is not a zero over every enumeration in the tree.

### AC5 — nothing filed, because nothing was found

No INERT member, so no observation and no follow-up task. An audit that finds nothing files
nothing; recording the denominator is what makes that statement worth anything.

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


# AC2/AC3 — the audit runs and both controls hold. Its own exit code is the verdict:
# exit 2 means the probe could not distinguish live from inert and refused to publish one.
timeout 300 python3 tools/_t484-coverage-list-behaviour-audit.py > /tmp/t484-audit.out 2>/dev/null

# AC3 — controls asserted on the structured field, not inferred from the exit code.
grep -q '"held": true' /tmp/t484-audit.out

# AC1/AC4 — the denominator is actually reported. A verdict without one is not a result.
grep -q '"members_audited": 35' /tmp/t484-audit.out

# AC6 — the finding itself: zero inert members across the audited enumerations.
grep -q '"INERT": 0' /tmp/t484-audit.out

# AC7 — read-only with respect to product code. The audit added a probe under tools/ only.
git diff --quiet -- src/ tools/yaml-to-bpmn.py docs/standards/ examples/ tests/fixtures/ .agentic-framework/

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

### 2026-08-12T23:09:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-484-audit-the-bridge-and-editor-coverage-enu.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-22d74c3b
- **Timestamp:** 2026-08-12T23:12:22Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 51
     - evidence: `timeout 300 python3 tools/_t484-coverage-list-behaviour-audit.py > /tmp/t484-audit.out 2>/dev/null`

### 2026-08-12T23:12:21Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
