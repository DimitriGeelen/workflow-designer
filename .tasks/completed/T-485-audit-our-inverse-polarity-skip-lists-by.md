---
id: T-485
name: "Audit our inverse-polarity skip-lists by behaviour (mirror of AEF _KNOWN_EXT
  / their T-2962)"
description: >
  Audit our inverse-polarity skip-lists by behaviour (mirror of AEF _KNOWN_EXT / their
  T-2962)

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
created: 2026-08-13T07:03:08Z
last_update: '2026-08-16T12:34:02Z'
date_finished: 2026-08-13T07:06:40Z
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

# T-485: Audit our inverse-polarity skip-lists by behaviour (mirror of AEF _KNOWN_EXT / their T-2962)

## Context

AEF at rail 601 §3 reported their one real coverage list, `_KNOWN_EXT` in
`tools/corpus_spec.py`, runs at INVERSE POLARITY to our `METAKEYS`: theirs enumerates what
the preserve-everything catch-all SKIPS, on the claim that something else handles it
explicitly. So membership asserts "handled elsewhere", and a member handled NOWHERE is
silently dropped. They audited it by reference count, got 7/7 clean, and correctly refused
to report that as coverage — a reference count is a membership audit one level deeper. The
behaviour version is their T-2962.

The mirror question for our tree is not "do we have a skip-list" — a first look says we do
not; the only passthrough (T-259, src:9318-9325) is narrow, `eventDefKind`/`eventDefBinding`
only. The question their finding actually raises is the one polarity further:

**Our parser reads SPECIFIC KNOWN elements. So it is a strict allowlist with no catch-all
at all, and the failure mode is not "a member handled nowhere" but "an element we were
never told about".** That is the live seam question: when AEF ships a v1.2 element we do
not yet parse, does a round trip through our editor preserve it or silently eat it?

This must be answered behaviourally. Reading the parser tells us which elements it names;
it cannot tell us what happens to one it does not.

## Acceptance Criteria

### Agent
- [x] AC1 — Determine BEHAVIOURALLY, not by reading, what a round trip through the editor
      does to extension content it does not know: (a) an unknown `aef:`-namespaced element,
      (b) an unknown element in a foreign namespace, (c) an unknown ATTRIBUTE on an element
      it does know. Each classified PRESERVED or DROPPED with the evidence.
- [x] AC2 — Positive control: a KNOWN element in the same injected document must survive
      the same round trip. Without it, a probe reporting "everything dropped" is
      indistinguishable from a probe whose injection never parsed at all (PL-095).
- [x] AC3 — Denominator stated (PL-084): how many documents the injection was exercised
      against, and the result per case — not a single-document verdict generalised.
- [x] AC4 — If content is DROPPED, the finding is registered as an observation and told to
      AEF, because it is their seam: it determines whether a v1.2 element they ship
      survives contact with a pinned editor. Not fixed here (one task = one deliverable);
      a fix task is filed if warranted.
- [x] AC5 — The result is reported whichever way it comes out. "Preserved" is a real and
      useful answer and gets the same denominator treatment as "dropped" — this task
      exists to settle the question, not to find a defect.
- [x] AC6 — Read-only with respect to product code: `git diff` empty on `src/`,
      `docs/standards/`, `examples/`, `tests/fixtures/`, `.agentic-framework/`.

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

### AC1/AC3/AC5 — all three unknown-content cases DROPPED, 23/23, control held

    case                                        result     n
    A  unknown aef: element                     DROPPED   23/23
    B  unknown foreign-namespace element        DROPPED   23/23
    C  unknown attribute on a KNOWN element     DROPPED   23/23
    control  mutation of a known value (tier)   PRESERVED 23/23

Denominator (PL-084): **23 documents**, not the 45 in the corpus. The injection anchors on a
node-level `<aef:meta ... tier="...">`, which 23 documents have. The other 22 are not
evidence either way and are excluded rather than counted as passes.

`parseBpmnXml` is a strict allowlist: it reads specific named elements and has no
preserve-everything catch-all. The only passthrough in the file (T-259, src:9318-9325) is
narrow — `eventDefKind` / `eventDefBinding` for hosts the typed-catch override skips.

### AC4 — why this is AEF's finding and not just ours

The seam consequence is concrete. When AEF ships a v1.2 `aef:` element, the sequence
"operator opens the document in a pinned editor, moves one node, saves" **removes it**. No
error, no warning, no diff the operator would look at. Their v1.2 rollout has to assume
that any document touched by a pinned editor comes back stripped of anything the pin does
not know.

Registered as **OBS-046** and sent to AEF. Not fixed here (one task = one deliverable);
whether the fix is a preserve-everything catch-all, a version gate, or an accepted
limitation is a design decision with seam implications, not a patch to slip into an audit.

### Inverse polarity, which is the transferable half

AEF's `_KNOWN_EXT` and our parser fail identically from opposite directions:

    AEF     preserve everything EXCEPT a skip-list  -> a member handled NOWHERE is dropped
    ours    parse ONLY what is named                -> anything UNNAMED is dropped

Both report success. Neither can distinguish "handled" from "silently discarded" without a
behavioural test, and in both cases the natural audit — count the list, count the references
— returns clean. Theirs returned 7/7. Ours would have returned "every element we parse is
parsed", which is true and answers nothing.

### The control is the entire reason this task has a result rather than a false finding

The first form of the probe injected into the document's FIRST `<bpmn:extensionElements>`
and used a fresh `<aef:endpoint>` as its control. The control failed **0/45** and the probe
exited 2 without publishing.

The failure was mine: the first `extensionElements` in these documents is process-level, and
the parser reads `aef:endpoint` off flow nodes. Every payload had been injected somewhere
the parser was never going to look.

**The verdict that run would have published is the same three words this task ended up
reporting — "DROPPED, DROPPED, DROPPED" — for entirely the wrong reason, and I would have
sent it to AEF as a finding about their seam.** The numbers even looked better: 45 documents
instead of 23. A probe reporting a true conclusion from a broken measurement is not a
near-miss; it is the case where nothing downstream can catch you, because the answer is
right. The control caught it, and the control is the only thing that did.

Re-aimed by removing ways to be wrong rather than by making it pass: anchor on `<aef:meta
tier=...>`, which only appears on nodes, so placement is guaranteed rather than assumed; and
make the control a MUTATION of an existing known value, which cannot land in the wrong place
and cannot be shadowed by an element the parser reads first.

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


# AC1/AC2 — the probe runs and its positive control holds. Exit 2 means the control failed
# and no verdict was published; exit 0 means the measurement is usable.
timeout 400 node tools/_t485-unknown-extension-survival.mjs > /tmp/t485-survival.out 2>&1

# AC2 — control asserted on the structured field, not inferred from the exit code.
grep -q '"held": true' /tmp/t485-survival.out

# AC3 — the denominator is reported, so the verdict cannot be read as wider than measured.
grep -q '"population": 23' /tmp/t485-survival.out

# AC1 — the finding itself: an unknown aef-namespaced element does not survive the round trip.
grep -q '"A_unknown_aef_element"' /tmp/t485-survival.out

# AC4 — the observation is registered, not merely described in this task file.
grep -q "OBS-046" .context/inbox.yaml

# AC6 — read-only with respect to product code.
git diff --quiet -- src/ docs/standards/ examples/ tests/fixtures/ .agentic-framework/

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

### 2026-08-13T07:03:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-485-audit-our-inverse-polarity-skip-lists-by.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-84258e07
- **Timestamp:** 2026-08-13T07:06:42Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-13T07:06:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
