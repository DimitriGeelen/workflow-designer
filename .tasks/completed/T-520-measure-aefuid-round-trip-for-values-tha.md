---
id: T-520
name: "measure aef:uid round-trip for values that are not XML-attribute-safe (_t515
  gap 2)"
description: >
  measure aef:uid round-trip for values that are not XML-attribute-safe (_t515 gap
  2)

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
created: 2026-08-15T11:55:26Z
last_update: '2026-08-16T14:33:44Z'
date_finished: 2026-08-15T12:13:59Z
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
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 0
      F3: 2
      F1: 3
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental); F4=0 (no-signal); F3=2 
      (prose:seam-namespace); F1=3 (prose:process-conformance)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:25Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/run-bridge-tests.sh,tools/_t352-p011-errexit-probe.sh,tools/_t515-external-uid-conformance.mjs,tools/_t520-uid-xml-safety.mjs);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:58Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/run-bridge-tests.sh,tools/_t515-external-uid-conformance.mjs,tools/_t520-uid-xml-safety.mjs);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-520: measure aef:uid round-trip for values that are not XML-attribute-safe (_t515 gap 2)

## Context

Second of the four gaps `_t515` names in its own `does_not_cover`, and the second taken since
T-518 closed the first. Reported to AEF at rail 11891 and again at 11896.

Mapping standard §6.3 invites AEF to assign `aef:uid` externally and constrains **nothing about
the value**. The uid is carried as an XML attribute (`<aef:uid value="..."/>`), so the character
set is not a free choice — it is bounded by XML itself, and by three mechanisms that fail in
three different ways:

1. **Escapable** — `&`, `<`, `"` are legal in an attribute once escaped. A correct writer emits
   `&amp;`/`&lt;`/`&quot;` and the value survives byte-identical. A writer doing naive string
   concatenation produces a malformed document instead.
2. **Normalised, and lossy BY SPEC** — XML attribute-value normalisation replaces a literal
   newline or tab with a space unless written as a character reference. That is not a defect in
   any implementation; such a value cannot survive an attribute round-trip in general. The
   constraint belongs on the ASSIGNER.
3. **Unrepresentable** — most C0 control characters are illegal in XML 1.0 anywhere, escaped or
   not. No conforming document can carry them.

The consumer risk is T-518's shape: AEF's reverse renderer keys records on uid, so a uid that
returns transformed silently addresses the wrong record — or none. Unlike T-518, where the
failure was invisible, several of these should fail loudly. Measuring is how I find out WHICH,
because "loud" and "silent" need different sentences in §6.3.

Characterises, does not legislate. The editor honouring §5's promise to return what it was
given is correct behaviour; where a value cannot survive, the obligation is the assigner's and
the wording is AEF's call.

**CORRECTION, written after the measurement — point 2 above is wrong as framed.** I described
newline and tab as lossy-by-spec with the constraint therefore belonging on the assigner. The
spec rule is real, but it does not apply here the way I assumed: the value IS representable, via
`&#10;`, and the editor simply does not write it that way. So this is our escaping defect, not an
inherent limit, and the remedy I recommended to AEF at rail 11903 is the opposite of what this
Context predicted — fix the writer, do not constrain the assigner. Left in place rather than
edited away, because the wrong framing is what made the browser-read false green so easy to
accept: I was expecting a loss I considered unavoidable, so a result showing no loss looked like
good news instead of a contradiction worth chasing.

## Acceptance Criteria

### Agent
- [x] `tools/_t520-uid-xml-safety.mjs` drives the REAL save path (`parseBpmnXml` ->
      `refreshDisplayIds` -> `buildBpmnXml`) via CDP on a corpus map, reusing the `_t515`/`_t518`
      harness rather than a second copy of it
- [x] Each candidate value is classified into one of three MEASURED outcomes — survives
      byte-identical / survives transformed (naming the transform) / not representable — rather
      than a bare pass/fail, because those three need different remedies and different wording
- [x] The stimulus is verified to actually carry the hostile character BEFORE the round-trip,
      and the probe REFUSES rather than passing if staging failed (PL-206: a control that cannot
      fail because its stimulus never contained the thing is worthless)
- [x] A negative control with a plain alphanumeric uid round-trips byte-identical in the same
      run, so "survives" is a discrimination and not a property of the harness
- [x] Covers at minimum: `&`, `<`, `"`, `>`, a combined value, non-ASCII UTF-8, a raw newline,
      and a C0 control character
- [x] Three-valued exit: rc 0 measured and matches the pin, rc 1 behaviour changed, rc 2 REFUSE
      (PL-205 — a probe reporting an absence must be distinguishable from a dead comparator)
- [x] Wired into `tests/run-bridge-tests.sh`, not merely committed (T-451: new instruments are
      wired, never baselined)
- [x] `_t515`'s `does_not_cover` updated to remove this gap and point at `_t520`
- [x] Fabric component card written by hand with a real `purpose` (the generated stub says
      "TODO: describe what this component does")
- [x] Findings reported to AEF on `agent-chat-arc` with producer attribution, separating what
      the EDITOR does from what XML makes impossible, and recommending §6.3 wording only where
      the constraint genuinely belongs on the assigner

<!-- No Human-AC section: every criterion is an exit-code or file-content check. -->

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

# The probe itself: rc 0 = measured and every candidate matches its pin.
timeout 300 node tools/_t520-uid-xml-safety.mjs

# The conforming reader is a real parser and reports a newline attribute as normalised —
# this is the fact the whole finding rests on, so it is checked rather than trusted.
python3 -c "import xml.etree.ElementTree as ET,sys; NL=chr(10); d='<r><u v=' + chr(34) + 'a' + NL + 'b' + chr(34) + '/></r>'; sys.exit(0 if ET.fromstring(d).find('u').get('v')=='a b' else 1)"

# The probe is WIRED, not merely committed (T-451).
grep -q '_t520-uid-xml-safety.mjs' tests/run-bridge-tests.sh

# _t515 no longer claims this gap is uncovered.
python3 -c "import sys; s=open('tools/_t515-external-uid-conformance.mjs').read(); sys.exit(0 if '_t520-uid-xml-safety.mjs' in s else 1)"

# Both new components have real fabric cards, not the generated TODO stub.
python3 -c "import sys,glob; bad=[f for f in glob.glob('.fabric/components/tools-_t520-*.yaml') if 'TODO: describe' in open(f).read()]; sys.exit(1 if bad or len(glob.glob('.fabric/components/tools-_t520-*.yaml'))!=2 else 0)"

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

### 2026-08-15T11:55:26Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-520-measure-aefuid-round-trip-for-values-tha.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-92846085
- **Timestamp:** 2026-08-15T12:14:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T12:13:59Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
