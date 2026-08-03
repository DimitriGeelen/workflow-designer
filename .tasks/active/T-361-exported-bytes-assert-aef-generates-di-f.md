---
id: T-361
name: "Exported bytes assert AEF generates DI from aef:position — AEF confirms they never have"
description: >
  Exported bytes assert AEF generates DI from aef:position — AEF confirms they never have

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
created: 2026-08-03T21:34:29Z
last_update: 2026-08-03T21:34:29Z
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

# T-361: Exported bytes assert AEF generates DI from aef:position — AEF confirms they never have

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
**MEASURED 2026-08-03.** Trailer now `BPMN DI (visual layout) omitted; node geometry
travels as aef:position`. Guard `tests/test_emitted_comment_claims.py` wired as a gating
leg; bridge suite **70/0** (was 69), geometry 24 clean.

- [x] **The false attribution is gone from the emitter.** Every `.bpmn` we export
      carries `<!-- BPMN DI (visual layout) omitted in this demo; AEF generates it from
      node coordinates -->` (`src:9407` defines it, `src:9582` emits it). AEF does not
      and never did. Replace the claim about *them* with a statement about *us*.
- [x] **Verified on an exported document, not only on the source.** Grep the emitter
      and grep bytes actually produced by an export. A source-only check confirms the
      string was edited, not that the shipped artifact stopped saying it.
      **Done via real export.** `tools/_t361-export-trailer-cdp.mjs` loads the actual
      designer in headless chrome, parses a real fixture, calls the real `buildBpmnXml`,
      and reads the bytes out: trailer as EXPORTED = `"BPMN DI (visual layout) omitted;
      node geometry travels as aef:position"`. Witness committed at
      `tests/fixtures/exported/t361-trailer-witness.bpmn`.
      **Why this mattered beyond the AC:** before it, the guard reported `0 current,
      106 legacy` — its "current" branch had never fired once. A bucket that has never
      filled cannot be reported as working. Now `1 current`.
- [x] **The falsity is demonstrated, not asserted.** Two independent measurements, both
      cited: (a) AEF's own, rail 417 — `bpmndi` occurs exactly once in their entire
      source, `tools/corpus_spec.py:347`, a namespace declaration with no reader and no
      writer behind it; (b) ours — no DI generator exists anywhere in our export path
      either, so the sentence had no referent on either side of the seam.
      Both cited in the guard's own docstring, so the evidence travels with the check.
- [x] **The replacement says only what is true and checkable here.** No claim about any
      party's behaviour but our own. If it names a downstream owner it is wrong again.
      It names no party at all — it describes our own field, `aef:position`.
- [x] **Blast radius stated, and released artifacts NOT rewritten.** Count the `dist/`
      releases carrying the false string and say so. They are historical bytes AEF pins
      by sha; editing them would be falsifying a record to hide a false record. The
      correction ships in the next cut (operator-gated), and the count is the honest
      measure of how far this travelled.
      **11 dist/ releases** carry the false string, `0.1.0` through `0.8.0` — including
      **0.4.0, the one AEF is pinned to today**. **106 stored `.bpmn` documents** carry it,
      among them `tests/fixtures/aef-bpmn/resume-status.bpmn` — the very file AEF asked me
      for. **None rewritten.** Editing a historical record to hide a false historical
      record is a worse defect than the one being hidden.
- [x] **Prevention, and it must fail for the right reason (PL-034).** A guard checking
      internal self-consistency cannot detect a broken promise — the emitter and its own
      constant agreed perfectly for two months. So the guard asserts the trailer matches
      an approved exact string, making any future edit a reviewed change rather than
      drift, AND fails when an emitted comment attributes an *action* to a *named
      external party* — the class this belongs to, not just this instance.
      Guard checks: emitter DERIVES from the constant (not a duplicate literal); prefix
      preserved for compatibility; no external party named as a bare word; and real
      produced `.bpmn` bytes carry the approved tail unless pinned in the legacy ledger.
      **Stated limit, not papered over:** it cannot judge whether an arbitrary sentence is
      true — a subtly false claim naming nobody would pass. The enforceable rule is the
      narrower one: *we describe our own bytes and name no one else's behaviour.*
      **The guard caught its own over-broad matcher on first run:** it fired on
      `aef:position`, a namespace token in our own document, not a claim about anyone.
      Narrowed to a bare-word match excluding namespace usage (`AEF` yes, `aef:` no).
- [x] **Teeth by mutation:** re-introducing the attribution must turn the guard RED, and
      the guard must be GREEN on the repaired trailer. Demonstrated, not read.
      `tools/_t361-guard-teeth.py`: **control green + 5 mutations each red on their own
      check.** Includes the one that matters most — a **ledgered document re-exported with
      changed bytes and a wrong tail** still fails. The exemption is keyed on **sha, not
      path**, precisely so it can fail for existing wrongly; a path-keyed allowlist would
      have let a re-export of a listed file stay wrong forever.
- [x] **AEF is told the sha will move,** because they pin these bytes and the change is
      in the pinned surface. Their 417 answer is what made this findable.
      Posted on the rail this session.

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

# The guard itself — its exit code is the whole verdict, no chaining.
python3 tests/test_emitted_comment_claims.py

# Teeth: control green + 5 mutations each red on their own check, including the
# sha-pinned legacy exemption proven able to fail.
python3 tools/_t361-guard-teeth.py

# The false tail must be absent from the emitter. `! grep` is the whole verdict.
! grep -q "AEF generates it from node coordinates" src/aef-workflow-designer.html

# And absent from real EXPORTED bytes, not only from source.
! grep -q "AEF generates it from node coordinates" tests/fixtures/exported/t361-trailer-witness.bpmn


## RCA

**Symptom:** every `.bpmn` we exported carried `<!-- BPMN DI (visual layout) omitted in
this demo; AEF generates it from node coordinates -->`. AEF measured their own source
(rail 417): `bpmndi` occurs exactly once in it, a namespace declaration with no reader
and no writer behind it. They never parsed DI, never emitted it, and hold no record of
agreeing to. No DI generator exists on our side either — the sentence had no referent
anywhere. Shipped in **11 releases** (incl. the 0.4.0 AEF pins today) and **106 stored
documents** (incl. `resume-status.bpmn`, the file AEF asked us for).

**Root cause:** `DI_TRAILER` was defined and **read by nothing**; the emitter carried a
hardcoded duplicate. A comment directly above the constant asserted the two "share one
source of truth" — so the documentation of the coupling was itself false, and the two
strings agreed by coincidence rather than construction.

**Why structurally allowed (PL-034):** a guard that checks internal self-consistency
cannot detect a broken promise. Every internal check passed, because the emitter and its
own constant were in perfect agreement about a claim that was false *outside the
process*. Nothing we had could reach across the seam to test it, and only the party being
named could falsify it — which is exactly what happened, and only because I asked.

**The compounding factor, and the transferable one:** this string had already been
through a **two-party incident** (AEF's T-2682 reader guard, their T-2683 restore, our
`readDocComment` guard). Both investigations asked *where the comment appears*. Neither
asked whether *the sentence in it is true*. An incident **directs** attention rather than
distributing it — the property that drew scrutiny gets fixed, while the artifact's
central claim can walk out of a two-party review still unexamined, and the review then
reads afterwards as evidence the artifact was checked.

**Prevention:** `tests/test_emitted_comment_claims.py`, gating leg (bridge 70/0).
Asserts the emitter derives from the constant, the compatibility prefix is preserved, no
external party is named as a bare word, and **real produced bytes** carry the approved
tail unless pinned by sha in a legacy ledger. Teeth in `tools/_t361-guard-teeth.py`:
control green plus 5 mutations, including a re-exported ledgered document — so the
exemption can fail for existing wrongly. **Stated limit:** the guard cannot judge whether
an arbitrary sentence is true; a subtly false claim naming nobody would pass. The
enforceable rule is the narrower one — *we describe our own bytes and name no one else's
behaviour.*


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

### 2026-08-03T21:34:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-361-exported-bytes-assert-aef-generates-di-f.md
- **Context:** Initial task creation
