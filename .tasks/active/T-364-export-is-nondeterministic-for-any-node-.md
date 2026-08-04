---
id: T-364
name: "Export is nondeterministic for any node lacking aef:uid: a fresh uid is minted per parse, so third-party documents never round-trip byte-stably"
description: >
  Found under T-358 while measuring repair candidates. buildBpmnXml emits a fresh randomly-minted aef:uid for every node that did not arrive with one, so two consecutive parse->emit cycles of the SAME third-party input produce different bytes (kitchen-sink.bpmn: 81 lines differ). Designer-produced maps carry uids and are stable (audit-process 13563 bytes, arc-lifecycle 12270). Two consequences: (1) opening a third-party file twice yields two different documents, and any consumer keying on aef:uid sees a new identity per open; (2) the _t308 byte-identity gate (24/24 identical) is sound only for the designer-produced population that happens to carry uids, and is structurally incapable of reporting on the third-party population every repair in this arc targets. Evidence: tools/_t358-export-determinism.mjs (exit 1 today, 4 of 6 documents unstable).

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
created: 2026-08-04T10:33:42Z
last_update: 2026-08-04T10:54:14Z
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

# T-364: Export is nondeterministic for any node lacking aef:uid: a fresh uid is minted per parse, so third-party documents never round-trip byte-stably

## Context

Found under T-358 while measuring repair candidates, and found only because a probe
was made to check its own instrument (emit the same document twice in the same build)
rather than trusting a cross-build comparison.

`buildBpmnXml` emits a freshly minted `aef:uid` for every node that did not arrive
carrying one. Two consecutive parse->emit cycles of the **same** third-party input
therefore differ: `kitchen-sink.bpmn` on 81 lines, `simple.bpmn` on 7. Designer-
produced maps carry uids in their bytes and are stable (`audit-process` 13563 bytes,
`arc-lifecycle` 12270).

Two consequences, and the second is why G-023 exists:

1. **Identity churn.** Open a third-party file twice and you have two documents that
   disagree on every node identity. Anything keying on `aef:uid` — ours or a
   consumer's — is tracking a value we re-roll per open. Flagged to AEF at RAIL-430.
2. **An instrument scoped by its population without saying so.** `_t308` byte-identity
   ("24/24 identical, 0 drifted") can only compare documents that emit deterministically,
   which is exactly the designer-produced set. It is structurally incapable of ranging
   over third-party documents — the population every repair in this arc targets — and
   nothing in its output says so. I cited that number as "this change moves no bytes",
   including to AEF at RAIL-427.

Related: G-023 (registered), T-358 (where it surfaced), PL-110.

## Acceptance Criteria

### Agent
- [x] **The nondeterminism is reproduced and its site named**, anchored on a function
      and not a line number. Required: the specific expression that mints a uid during
      import for a node that arrived without one, plus evidence that the same input
      emits differently twice in one page.

      **Site.** `generateUid(prefix)` (`src` ~1644) is
      `Math.floor(Math.random() * 16)` — pure randomness, no seed, no derivation from
      the document. `parseBpmnXml` falls back to it at two places:
      `const uid = uidEl?.getAttribute('value') || generateUid('n')` (nodes, ~9799)
      and the same with `'e'` for edges (~9976). Anchor on those two `|| generateUid(...)`
      fallbacks inside `parseBpmnXml`, not the line numbers.

      **Reproduction** (`tools/_t358-export-determinism.mjs`, two consecutive
      parse→emit cycles of the same input in the same page):

      ```
      lane-provenance/authored-lanes.bpmn   NOT STABLE —  5 lines differ
      third-party/simple.bpmn               NOT STABLE —  7 lines differ
      third-party/kitchen-sink.bpmn         NOT STABLE — 81 lines differ
      corpus/audit-process.bpmn             stable (13563 bytes)
      corpus/arc-lifecycle.bpmn             stable (12270 bytes)

      run 1: <aef:uid value="n_49d94bba"/>
      run 2: <aef:uid value="n_1c40c938"/>
      ```

      The split is exactly "did the document arrive carrying uids": designer maps did,
      third-party documents did not.

- [x] **`_t308` states the population it ranges over, and cannot silently range over
      less than it claims.**

      **Done.** `_t308` now exports every map **twice in the same build** and reports a
      third outcome: a document that is not byte-stable with itself is `unusable` —
      never `identical`, never `drifted` — and an unusable map **fails the run** (`ok:
      false`). The gate exists to answer "did any byte move?"; for a document it cannot
      compare it has no answer, and a green with a silent hole is the failure G-023
      records. Its JSON now carries a `population` block naming the source, why that
      population is comparable at all (it carries `aef:uid`), and what it does not cover,
      pointing at `tools/_t358-byteid-thirdparty.mjs` for third-party fidelity.

      Current run vs `3bf37909~1`: **24 identical, 0 drifted, 0 unusable, ok true.**

      **That zero is only worth something because the bucket was shown to fill.**
      `tools/_t364-t308-teeth.py` runs the gate against a temp corpus (the real one is
      never touched — `_t308` takes `T308_CORPUS`):

      ```
      control : rc=0 maps=24 identical=24 drifted=0 unusable=0
      teeth   : rc=1 maps=25 identical=24 drifted=0 unusable=1
      ```

      The injected document is a real third-party fixture — the population the gate was
      silently omitting, so it is the honest thing to inject. The load-bearing assertion
      is the middle column: `identical` stays **24**. Had the unstable document been
      counted identical, or dropped from every count, the gate would be overstating or
      quietly shrinking its own denominator — the two failure modes G-023 exists for.
      The teeth also assert the run names the population it cannot cover, so deleting
      that statement goes red.

      Not wired into `tests/run-bridge-tests.sh`: the teeth run the full CDP gate twice
      over 25 maps, and `_t308` is itself an on-demand instrument rather than a bridge
      leg. Stated rather than left as a silent omission.

- [ ] **`_t308` states the population it ranges over, and cannot silently range over
      less than it claims.** A byte-identity run must report its denominator, and a
      document that is not byte-stable **with itself** must be reported `unusable` —
      never counted as `identical`. Evidence: the run's own output naming the count and
      the population, and a mutation showing an unstable document is NOT counted green.

      This is G-023's prevention half. Mitigation would be making export deterministic;
      prevention is a gate that cannot overstate its reach even after that fix, because
      the next nondeterministic field will not announce itself either.

- [ ] **Export is deterministic for third-party input**, i.e.
      `tools/_t358-export-determinism.mjs` exits 0 with every document stable — OR the
      repair is deliberately deferred and this AC records the measured reason, since a
      stable uid must come from somewhere and inventing one is how T-358 started.

- [ ] **No emitted byte moves for the existing corpus.** Any repair must keep
      `_t308` byte-identity green over the designer-produced maps, whose uids are real
      authored data and must not be renumbered by a determinism fix.

- [ ] Bridge suite green (`tests/run-bridge-tests.sh`), no leg lost.

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
# Final test IS the verdict (errexit-safe form) — see T-353.

# the two import-side mint fallbacks are still where AC1 says they are
out=$(grep -c "|| generateUid('n')" src/aef-workflow-designer.html); [ "$out" = "1" ]
out=$(grep -c "|| generateUid('e')" src/aef-workflow-designer.html); [ "$out" = "1" ]

# the byte-identity gate states its population and holds out what it cannot compare
out=$(node tools/_t308-export-byte-identity-cdp.mjs 3bf37909~1); echo "$out" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if (d['ok'] and d['unusable']==0 and d['population']['does_not_cover']) else 1)"

# and that unusable bucket can actually fill — a zero from a check that cannot fire is a constant
python3 tools/_t364-t308-teeth.py > /dev/null 2>&1
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

### 2026-08-04T10:33:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-364-export-is-nondeterministic-for-any-node-.md
- **Context:** Initial task creation

### 2026-08-04T10:54:14Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
