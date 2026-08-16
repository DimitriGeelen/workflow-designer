---
id: T-524
name: "fw fabric validate exits 0 while validating nothing - the missing detector
  for T-522's malformed-card class"
description: >
  fw fabric validate exits 0 while validating nothing - the missing detector for T-522's
  malformed-card class

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
created: 2026-08-15T14:56:16Z
last_update: '2026-08-16T14:33:44Z'
date_finished: 2026-08-15T15:08:23Z
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
  - ts: '2026-08-16T12:34:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 1
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=2
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=1 
      (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:.agentic-framework/.vendor-divergence.yaml,.agentic-framework/agents/fabric/lib/drift.sh,.agentic-framework/docs/reports/T-191-cf-enforcement-design.md,.fabric/components/tools-_t524-fabric-validate-teeth.yaml);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-524: fw fabric validate exits 0 while validating nothing - the missing detector for T-522's malformed-card class

## Context

`.agentic-framework/agents/fabric/lib/drift.sh:195` — `do_validate()` loops every card, prints
its `name:` followed by `checking...`, then prints *"Deep validation not yet implemented"* and
**`return 0`**. The banner is honest; the exit code is not. Anything that consumes the verdict
rather than the prose — `fw fabric validate && echo ok`, a CI leg, a P-011 line, a reader
skimming for red — gets a pass for work that was never done. PL-205: an abstention must be
distinguishable from a pass. PL-178 is the same shape one level in: green while asserting nothing.

**Why this is worth doing now, and it is not the stub's age.** T-522 found that a component card
missing `location:` aborted `update-task.sh` mid-completion under `set -euo pipefail`, silently
losing two episodics. The fix was `{ grep ... || true; }` at both greps — correct, and it makes a
malformed card **non-fatal**. It does not make it **visible**. Before T-522 a bad card was
catastrophic-but-eventually-diagnosable; after T-522 it is inert — the card simply stops
participating in dependency and blast-radius resolution, and nothing anywhere says so. That is
the fix trading a loud failure for a quiet one, which is the honest reading of what I shipped.
The detector that closes it is the command that already exists and does nothing.

**Not a feature request dressed as a bug.** The design document for the subsystem
(`.agentic-framework/docs/reports/T-191-cf-enforcement-design.md:95,142,282`) specifies
`fw fabric validate` and has the audit advise it as the remedy for stale edges. So the command has
a documented role, an entry in the CLI dispatcher (`agents/fabric/fabric.sh:131`), and no
implementation. The gap between the two is the defect.

**Scope discipline.** This task does NOT bulk-register the 189 unregistered files the audit warns
about (3× in 14 days). That is a different question — whether the watch set is right — and
compounding them would hide both. One bug, one task.

**Vendored.** `.agentic-framework/` is vendored; G-008 permits in-tree fix + upstream, declared in
`.vendor-divergence.yaml` with `upstream: fix`, exactly as T-522 did for `update-task.sh`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The required-field set is DERIVED from real consumers, not invented.** Every field the
      validator treats as required is justified by a cited reader (`file:line`) that would
      misbehave or silently no-op without it. A field nobody reads is not required — inventing a
      schema and then enforcing it would make the validator a source of busywork rather than a
      detector, and would be exactly the "convention used as a classifier" failure of T-509.

- [x] **`fw fabric validate` no longer returns 0 for work it did not do.** It either performs the
      check and reports a real verdict, or it REFUSES with a non-zero exit that says so (PL-205).
      There is no path on which "I validated nothing" and "everything is valid" share an exit code.

- [x] **It detects the T-522 card.** A card missing `location:` is reported by name and by the
      field that is missing — verified by constructing one, not by reading the code.

- [x] **It is green on the real tree.** All 53 current cards pass (they do carry `id:` and
      `location:` — I repaired the two bad ones in T-522), so a red here means the validator is
      wrong, not the tree.

- [x] **Teeth (PL-206): red is asserted FOR THE NAMED REASON.** A mutation-based teeth script
      proves the validator goes red on a malformed card *and* names the right card and field —
      asserting only a non-zero exit would pass on a validator that errors for any reason at all,
      which is the OBS-255 failure mode. Includes a leg proving green is a real classification
      (a look-alike card that is valid must NOT be flagged), and a leg proving the refusal path
      is distinguishable from the pass path.

- [x] **Hermetic.** Teeth build their fixtures under `mktemp`; the working tree is byte-identical
      after a run (verified with `git status --porcelain`, not by inspection).

- [x] **Wired.** The validator and its teeth are reachable from `tests/run-bridge-tests.sh` — an
      instrument nobody runs is the T-451/PL-192 class this project has already paid for twice
      (T-508, T-509). Registered in the T-451 unwired-guard census.

- [x] **Divergence declared.** `.agentic-framework/.vendor-divergence.yaml` records the change
      with `upstream: fix`, so a re-vendor cannot silently restore the stub.

- [x] **Fabric cards written for any new tool**, each carrying `location:` — the field whose
      absence started this. Writing a card without it while fixing the bug about cards without it
      would be its own finding.

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
# T-524: the whole-suite run is deliberately NOT a line here. "the bridge suite is
# green" is global moving state and would go red under a daily re-runner for someone
# else's change (T-508's learning). The two greps below assert the property this task
# is responsible for — that the instrument is REACHABLE — which is what wiring means
# and does not move when unrelated legs do.
.agentic-framework/bin/fw fabric validate
python3 tools/_t524-fabric-validate-teeth.py
python3 tools/_t517-vendor-divergence-teeth.py
grep -q "^location:" .fabric/components/tools-_t524-fabric-validate-teeth.yaml
grep -q "_t524-fabric-validate-teeth.py" tests/run-bridge-tests.sh
grep -q "agents/fabric/lib/drift.sh" .agentic-framework/.vendor-divergence.yaml

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

**Symptom:** `fw fabric validate` printed *"Deep validation not yet implemented — use 'fw fabric
drift' for basic checks"* and exited **0**, for any register, including an empty one. The banner
was honest; the exit code was not. Nothing that consumes a verdict rather than prose — a CI leg,
a P-011 line, `&& echo ok`, or a person skimming for red — could tell "validated nothing" from
"everything is valid."

**Root cause:** the command was specified in the subsystem's own design note
(`docs/reports/T-191-cf-enforcement-design.md:95,142,282`, which has the audit advise it as the
stale-edge remedy) and wired into the CLI dispatcher (`agents/fabric/fabric.sh:131`), then left
as a `TODO` body. The defect is not the missing implementation — a `TODO` is an honest state —
it is that the unimplemented path **returned success**. A stub that exits non-zero is a backlog
item; a stub that exits 0 is a false instrument.

**Why structurally allowed:** nothing calls it. Confirmed by search: the only references in the
tree are the dispatcher line and prose. An instrument nobody runs never has its verdict examined,
so a wrong verdict costs nothing until the day someone trusts it — the PL-192/T-508/T-509 class
this project has now paid for three times. The T-451 unwired-guard census reads reachability by
textual reference to `tools/<name>`, so a *framework* subcommand is outside its population
entirely; it could not have flagged this.

**Why it mattered now, and this is the honest part:** T-522 fixed the crash a malformed card
caused and, in doing so, converted a loud failure into a quiet one. Before it, a card missing
`location:` killed `update-task.sh` mid-completion and cost two episodics. After it, the same
card is simply skipped — and measured here (teeth leg 9), not merely inert: because `do_drift`
builds its `registered` set by grepping `^location:` (`lib/drift.sh:25`), a card without one
makes **its own file report as UNREGISTERED**, and the printed remedy is `fw fabric scan`, which
would mint a **second** card for that one file. So the silence does not just lose information, it
manufactures duplicates. I shipped the resilience half in T-522 and left the detection half open.

**Prevention (distinct from the fix):** `tools/_t524-fabric-validate-teeth.py`, wired into
`tests/run-bridge-tests.sh`, feeds stimuli that CONTAIN the fault and asserts red *for the named
field* rather than merely non-zero. Two legs exist specifically because their absence is how this
class survives: leg 6/7 prove a refusal (rc 2) is distinguishable from a pass, which is the exact
property the stub violated; leg 3 proves green is a classification rather than absence — and it
had to be rewritten, because its first form (`"good.yaml" not in out`) passed **vacuously**
against the regressed stub, since a validator that prints nothing flags nothing. Verified by
mutation: regressing `do_validate` to `return 0` fails 7 of 10 legs. The divergence entry
(`upstream: fix`) stops a re-vendor restoring the stub.

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

### 2026-08-15T14:56:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-524-fw-fabric-validate-exits-0-while-validat.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4d31709c
- **Timestamp:** 2026-08-15T15:08:27Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T15:08:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
