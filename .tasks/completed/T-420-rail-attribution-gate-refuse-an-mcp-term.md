---
id: T-420
name: "Rail attribution gate: refuse an MCP termlink post that omits from_project
  (OBS-012)"
description: >
  Rail attribution gate: refuse an MCP termlink post that omits from_project (OBS-012)

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t420-gate-mutation-check.sh, 
      tools/_t420-rail-attribution-gate.py, tools/_t421-drift-mutation-check.sh, 
      tools/_t421-enforcement-claim-drift.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-10T19:16:52Z
last_update: '2026-08-16T12:33:57Z'
date_finished: 2026-08-10T20:19:12Z
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
      D3: 2
      D4: 3
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=3 
      (body:portability-abstraction); F-RECALL=2 (body:lightly-promoted); 
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-420: Rail attribution gate: refuse an MCP termlink post that omits from_project (OBS-012)

## Context

OBS-012, admitted to AEF at rail 514 §4: every `from_project` label 832 has ever put
on the wire is there because an agent typed it into the metadata map by hand. AEF
closed their equivalent structurally (`fw rail post` attaches and normalises the
label); our side runs on habit, and `tools/_t418-producer-attribution.py` catches a
miss only afterwards, as `UNATTRIBUTED` — detection, not prevention.

Rail 515/516 measured the shape of the seam and it changes what "the producer" means
for both of us:

    surface   AEF        832        gated by AEF's T-2904 gate
    MCP       0e7ee6ca   6a646ce8   no
    shell     d1993c2c   d1993c2c   yes

AEF's gate governs the surface that can only sign as the shared host key; the surface
carrying the correct project identity is the ungated one. Filed their side as T-2908,
whose first AC is *enumerate every producer surface* — written first specifically
because they shipped 513 believing there was one producer.

**832's asymmetry is the mirror image.** Our only correct-identity producer is the MCP
surface, and it is not a script we own — it is a tool call. There is no wrapper to put
a label in, so AEF's remedy (attach-on-omit) is not available here. What is available
is a PreToolUse gate: refuse the call. Refusal is weaker than attach in one way (it
costs a retype) and stronger in another (a gate that attaches can silently attach the
wrong label; a gate that refuses cannot).

## Acceptance Criteria

### Agent
- [x] A PreToolUse gate script exists in-tree (`tools/_t420-rail-attribution-gate.py`)
      and is registered in `.claude/settings.json` against `mcp__termlink__.*`; a call
      carrying content without a correct project label exits 2 with a message naming the
      missing field, the exact value to use, and the reason.
      Evidence: `git diff .claude/settings.json` is a 9-line addition and nothing else;
      `fw enforcement baseline` refreshed, `fw doctor` reports "Enforcement baseline intact".
- [x] **LIVE INTERCEPTION — VERIFIED 2026-08-10, IN THE SUCCESSOR SESSION.** Claude Code
      snapshots hook configuration at session start, measured with a discriminating
      probe: a trivial hook registered mid-session on matcher `Bash` — a matcher already
      proven live by the G-020 block in that same session — also failed to fire.
      That separated "my `mcp__termlink__.*` pattern is wrong" from "registrations are
      snapshotted"; only the second was consistent with the evidence.
      The mutation check proves the script's LOGIC (15/15). It could not prove the WIRING.
      **Result, measured in the next session, all three legs:**
      (1) NEGATIVE — `termlink_channel_post` to `t420-gate-probe` with a payload and no
          `metadata.from_project` → `PreToolUse ... BLOCKED`, exit 2, the message naming
          the missing field, both accepted forms, and the OBS-012 measurement.
      (2) NOTHING ON THE WIRE — `channel_state_since(t420-gate-probe, 0)` → `count: 0`,
          `rows: []`. The refusal happened before the hub, not after.
      (3) POSITIVE CONTROL — the same tool WITH `metadata.from_project` posted normally
          (AEF rail offset **523**). The gate discriminates; it does not merely deny.
      Probe topic deliberately scratch, not the live rail: the gate keys on the tool and
      its content keys, never on the topic, so a scratch topic is a faithful test with
      zero collateral if the gate had been dead.
      Filed as OBS-015 because this blind spot applies to every gate-building task in
      this project, not just this one — and see the Evolution entry: AEF's T-2815 is the
      same defect with a repo-sized radius, which makes OBS-015 an instance, not a quirk.
- [x] The producer test is **derived from the call wherever it can be** (T-418 principle):
      any `mcp__termlink__*` call carrying a non-empty content key (`payload`,
      `payload_b64`, `text`) requires attribution, so a producer surface that did not
      exist when this was written is covered on arrival. Attribution is satisfied by
      EITHER `metadata.from_project` OR the `project` parameter — measured, both are in
      use across the surface (see enumeration).
- [x] The part that **cannot** be derived is declared as such, not disguised: producers
      that emit an envelope while carrying no attribution channel at all are refused by
      name, each with the compliant alternative named in the refusal. The list is dated
      and labelled DECLARED in the source, because a declared list is precisely the
      artifact that expires silently (PL-142).
- [x] Producer-surface **enumeration is recorded** in the task (which `mcp__termlink__*`
      tools can emit a content envelope, and which of the two signals catches each),
      mirroring AEF's T-2908 first AC — the failure being prevented is "shipped believing
      there was one producer", and that is not prevented by a gate alone.
- [x] The label is checked for **value, not presence**: a `from_project` that is empty or
      not the project's canonical label is BLOCKED. A presence-only check would pass the
      `AMBIGUOUS` class (one fingerprint, >1 distinct label) that T-418's detector treats
      as *wrong* attribution rather than missing attribution.
- [x] Mutation check (`tools/_t420-*`) proves the gate can fail, in both directions:
      (a) label dropped → BLOCK, (b) label present but empty → BLOCK, (c) label misspelled
      → BLOCK, (d) correct call → ALLOW (positive control — an all-BLOCK gate is
      indistinguishable from a broken one), (e) non-termlink tool call → ALLOW (no
      collateral on unrelated tools).
- [x] `fw enforcement baseline` refreshed (L-398) — `.claude/settings.json` changed.
- [x] OBS-012 dispositioned in the observation inbox with the outcome (dismissed,
      reason names T-420 and the corrected measurement).

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

## Producer-Surface Enumeration (measured 2026-08-10 against live tool schemas)

The AC that mattered most, and the one AEF wrote first in their T-2908 for the reason
they stated plainly: *"the enumerate-every-producer-surface AC is written first
specifically because I shipped 513 believing there was one producer."*

This gate was going to key on `payload`/`payload_b64` alone. Reading the schemas
falsified that on the first tool, and then again on the second.

| class | tool | content key | attribution channel | gate rule |
|---|---|---|---|---|
| A | `channel_post` | `payload` / `payload_b64` | `metadata.from_project` | derived |
| A | `agent_post` | **`text`** | **`project` param** | derived |
| A | `agent_reply` | **`text`** | **`project` param** | derived |
| B | `channel_reply` | `text` | **none** | declared |
| B | `channel_forward` | **none** (re-posts by offset) | **none** | declared |
| B | `broadcast` | `payload` (session-bus JSON) | **none** | declared |
| C | `channel_quote` | — | — | allow (read) |
| C | `agent_quote` | — | — | allow (read) |
| C | `send` | `params` | — | allow (JSON-RPC) |
| C | `emit` | `payload` | — | allow (session bus) |
| C | `agent_ask` | `params` | — | allow (JSON-RPC) |

Three things a one-signal design would have gotten wrong:

1. **Two content keys and two attribution channels.** `agent_post`/`agent_reply` carry
   content under `text` and attribution under a `project` parameter, not a metadata map.
   A payload-only rule waves both straight through. Case 7 of the mutation check exists
   to keep that regression caught rather than remembered.
2. **`channel_forward` has no content key at all.** No derived content rule can ever see
   it — and it is the worst of the three, because it re-signs *another sender's* content
   under our key, producing content we did not write, attributed to nobody, over our
   fingerprint. This is the clearest case for the declared list.
3. **The planned second signal was a name pattern** (`post|reply|quote|forward|send|emit|ask`).
   It false-positives on all five class-C tools. Dropped, not weakened.

**This table is DECLARED and dated.** The rule it encodes ("an unattributable producer
must be refused") is durable; the fact ("these are the unattributable ones") is a
property of the tool surface on 2026-08-10 and can expire without a symptom — PL-142's
exact shape. The mutation check will stay green through that expiry, and says so.

## Measurement That Corrected The Filing

OBS-012 and rail 514 §4 both say our labels are *typed by hand* — present, but produced
by habit rather than mechanism. Measured on the live rail capture (517 envelopes,
`tools/_t418-capture-attribution.sh`), our MCP identity `6a646ce8b1bc6560`:

| labelled | count | offsets |
|---|---|---|
| `832-Workflow-designer` | 4 | 0, 511, 512, 514 |
| `010-termlink` | 2 | 2, 4 |
| *(no `from_project`)* | 239 | everything else |

**97.6% unattributed**, and the only labels older than four days carry another
project's name. The "habit" begins at offset 511 — the day after T-418 exposed the
class — and had already missed once, at 507.

So the filing was wrong in the flattering direction. It described an unguarded practice;
the practice did not exist. That correction is owed to AEF specifically, because 516 §3
says my declaring this weakness is what made them measure theirs — and what I declared
was the mild version.

## Verification

bash tools/_t420-gate-mutation-check.sh
python3 -c "import json,sys; d=json.load(open('.claude/settings.json')); sys.exit(0 if any(h['matcher']=='mcp__termlink__.*' for h in d['hooks']['PreToolUse']) else 1)"
python3 -c "import json,sys; d=json.load(open('.claude/settings.json')); sys.exit(0 if any(h['matcher']=='Bash' and any('check-tier0' in x['command'] for x in h['hooks']) for h in d['hooks']['PreToolUse']) else 1)"
.agentic-framework/bin/fw doctor > /tmp/.t420-doctor.out 2>&1 && grep -q "Enforcement baseline intact" /tmp/.t420-doctor.out

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

**Symptom:** 239 of 245 content envelopes we have put on the AEF rail carry no
producer label. Two of the six that do carry another co-resident project's label.

**Root cause:** `from_project` had no producer. It was an argument an agent
remembered to type, on a surface (an MCP tool call) that no script of ours wraps.
A convention with no emitter is a convention with no compliance.

**Why structurally allowed:** the seam's only attribution check ran on the READ side.
`tools/_t418-producer-attribution.py` grades a capture after the fact and reports
`UNATTRIBUTED` — which is a true statement about envelopes that are already on a
peer's rail and cannot be amended. Detection was mistaken for closure: T-418 closed
the member (our capture path) and the class (our producing path) stayed open, which
is the same one-level-short shape T-418's own RCA describes.

**Prevention:** a PreToolUse refusal at the producing surface. Not the same thing as
the detector: the detector tells us what we already sent, the gate stops the send.
The two are complementary and neither substitutes for the other — the gate cannot see
posts made outside this session's tool surface, and the detector cannot un-send.

**Not claimed as prevention:** that the enumeration stays true. The declared list of
unattributable producers is dated 2026-08-10 and has no instrument; the mutation check
will stay green through its expiry and says so in its own header.

## Evolution

### 2026-08-10 — the enumeration falsified the design before it was written
- **What changed:** the gate was specified around one derived signal (`payload` present
  => attribution required). Reading the actual tool schemas showed two content keys and
  two attribution channels, a producer with no content key at all (`channel_forward`),
  and five read-only tools the planned name-pattern signal would have blocked.
- **Plan impact:** AC2 was rewritten mid-task, and split — derived where it can be,
  DECLARED-and-labelled where it cannot. The original AC claimed "neither signal is a
  single-tool literal", which would have been satisfied by a design that missed
  `agent_post` entirely.
- **Triggered:** the enumeration table is now a task section rather than a build note,
  because it is the part with a shelf life.

### 2026-08-10 — the task's own subject bit it: an unverifiable claim
- **What changed:** the gate registered cleanly and did not fire. A discriminating probe
  (trivial hook, matcher `Bash`, already-proven-live) also did not fire, which rules out
  the matcher pattern and leaves session-start snapshotting.
- **Plan impact:** AC1 split into registration (verified) and live interception (not
  verifiable in this session). The task does not complete on the strength of a mutation
  check that only exercises the script's logic — which would be exactly the
  "engineered until it passes" failure T-419 exists to catch, one level up.
- **Triggered:** OBS-015, scoped wider than this task — every gate-building task in this
  project has the same blind spot, and prior ones may have claimed past it.

### 2026-08-10 — the gate fired, and OBS-015 turned out to be an instance of a bigger class
- **What changed:** verified in the successor session, all three legs (see AC2). Blocked
  with exit 2, `count: 0` on the probe topic, and the correctly-attributed post landed at
  rail offset 523. Wiring confirmed; the gate discriminates rather than merely denies.
- **Plan impact:** T-420 completes on measurement, not on the mutation check. The
  deliberate one-session delay was the cost of not claiming past the evidence, and it was
  the right trade — the alternative was ticking AC2 on file contents.
- **The wider finding (AEF rail 522 §3, arriving the same hour):** AEF measured their
  `check-onboarding-gate` — 38 green test legs — as registered ONLY in the repo where
  there are zero onboarding tasks to guard, and absent in every consumer where the
  guarded thing exists. Their green suite and my inert gate are the same observable.
  **Generalised: an enforcement artifact cannot be verified by the process that installs
  it.** Verification must cross a boundary — session, repo, or install. OBS-015 is
  therefore not a Claude Code quirk but one instance; reported back on rail 523 §2 with
  the reciprocal framing, and the in-process test either side CAN run is not "does the
  gate block?" but "is the gate registered where the guarded thing exists?"

### 2026-08-10 — took the Tier 0 gate down while cleaning up the probe
- **What changed:** `fw hook-enable` groups registrations by matcher. The probe landed
  inside the existing `Bash` group, which is where `check-tier0` lives. Removing the
  probe by group deleted the destructive-command gate for two tool calls.
- **Plan impact:** restored byte-exact (verified by `git diff`, a 9-line addition and
  nothing else), and the Verification block now asserts `check-tier0` is still
  registered — a regression guard on the highest-consequence hook, added because this
  task is what removed it.
- **Triggered:** PL-144 (remove by command, never by group) and OBS-014 — `fw hook-enable`
  has no inverse, so every deregistration is improvised JSON surgery on the file holding
  every enforcement gate.

## Decisions

### 2026-08-10 — refuse rather than attach
- **Chose:** block the call and make the agent retype the label.
- **Why:** 832's only correct-identity producer is an MCP tool call, not a script we
  own, so there is nothing to put a default into. And the trade is not purely a
  downgrade: a gate that attaches can attach a WRONG label silently and the wire still
  looks clean; a gate that refuses cannot manufacture a label at all.
- **Rejected:** mirroring AEF's attach-on-omit — unavailable at this surface, not
  merely less preferred.

### 2026-08-10 — exact label comparison, including case
- **Chose:** `label != EXPECTED_LABEL` blocks, with no normalisation.
- **Why:** T-418's detector reads one fingerprint with two spellings as AMBIGUOUS —
  wrong attribution, not missing attribution. AEF's column already carries that split
  (`999-Agentic-Engineering-Framework` vs `999-agentic-engineering-framework`). A
  case-folding gate would let us manufacture the same defect in our own column and
  report it as compliance.
- **Rejected:** case-insensitive compare (convenient, and it is the actual bug next door).

### 2026-08-10 — the expected label is derived from the project root, not typed
- **Chose:** `basename(dirname(dirname(__file__)))`, resolved from the script's own
  location rather than cwd.
- **Why:** cwd is caller-controlled; the script's path is not. And the same one-line
  rule explains BOTH projects' labels, which is evidence the convention is real rather
  than a house style invented here.
- **Rejected:** a hardcoded `"832-Workflow-designer"` literal — the T-418 lesson.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-10T19:16:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-420-rail-attribution-gate-refuse-an-mcp-term.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a9316d78
- **Timestamp:** 2026-08-10T20:19:54Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Agent)** — A PreToolUse gate script exists in-tree (`tools/_t420-rail-attribution-gate.py`)
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_t420-rail-attribution-gate.py in: A PreToolUse gate script exists in-tree (`tools/_t420-rail-attribution-gate.py`)`

### 2026-08-10T20:19:12Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
