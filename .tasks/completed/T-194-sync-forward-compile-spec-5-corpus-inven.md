---
id: T-194
name: "Sync forward-compile spec §5 corpus inventory with the 5th (inception) fixture"
description: >
  T-192 added tests/fixtures/aef-bpmn/inception-gonogo.bpmn (a hand-authored positive
  inception case embodying the provisional G-3 marker), but docs/standards/aef-bpmn-forward-compile-v1.md
  §5 still says 'Four authentic editor-emitted diagrams' and lists only 4. Close the
  spec-vs-reality drift accurately: distinguish the 4 authentic editor exports from
  the 1 hand-authored provisional-G-3 fixture, without overstating G-3's status (still
  Part II provisional pending Dimitri's v1.1 graduation).

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
created: 2026-07-12T19:31:01Z
last_update: '2026-08-16T12:33:42Z'
date_finished: 2026-07-12T19:34:30Z
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
  - ts: '2026-08-16T12:33:42Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-194: Sync forward-compile spec §5 corpus inventory with the 5th (inception) fixture

## Context

T-192 added a 5th fixture (`tests/fixtures/aef-bpmn/inception-gonogo.bpmn`) which
`tests/test_forward_fixtures.py` already guards (it globs `*.bpmn`), but the 832-side support spec
`docs/standards/aef-bpmn-forward-compile-v1.md` §5 still reads **"Four authentic editor-emitted diagrams"**
and its table lists only 4. This is a spec-vs-reality drift. The fix must be *accurate*: the inception
fixture is **hand-authored** (not an editor export) and embodies the **provisional G-3 inception marker**
(mapping-v1 Part II, ratified AEF-side but not yet graduated to frozen v1.1 by Dimitri). It must be listed
as a distinct category, not folded into the "authentic editor-emitted" count, and not presented as frozen.
Non-normative inventory edit only — §2 input contract and §3 mapping rules are NOT touched.

## Acceptance Criteria

### Agent
- [x] §5 corpus intro no longer claims "Four authentic editor-emitted diagrams" as the whole corpus; it states the corpus is **5 fixtures = 4 authentic editor exports + 1 hand-authored inception fixture** — verified (`grep -c "Four authentic..."` = 0)
- [x] `inception-gonogo.bpmn` added as a 5th row in the §5 table with an accurate "Exercises" cell: collapsed `subProcess` + `aef:meta workflowType="inception"`, sovereignty-lane owner-derivation, `aef:constituents`, implied (gateway-less) go/no-go boundary — added, with a new **Source** column distinguishing editor-emitted vs hand-authored
- [x] The row/intro explicitly flags it as **hand-authored** and embodying the **provisional G-3 marker** (mapping-v1 Part II, pending Dimitri's v1.1 graduation) — NOT editor-emitted, NOT frozen — verified (`grep hand-authored`, `grep provisional`)
- [x] No change to §2 (input contract) or §3 (forward-compile mapping) — verified unchanged; single diff hunk at §5 only (14+/10-)
- [x] `tests/test_forward_fixtures.py` still green — `OK: 5 fixture(s) ... conformant`

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

# The 5th fixture is now named in §5, and the stale "Four ... diagrams" whole-corpus claim is gone.
grep -q "inception-gonogo.bpmn" docs/standards/aef-bpmn-forward-compile-v1.md
out=$(grep -c "Four authentic editor-emitted diagrams" docs/standards/aef-bpmn-forward-compile-v1.md); test "$out" = "0"
grep -qi "hand-authored" docs/standards/aef-bpmn-forward-compile-v1.md
grep -qi "provisional" docs/standards/aef-bpmn-forward-compile-v1.md
# The guarded corpus the spec describes is still conformant (5 fixtures).
python3 tests/test_forward_fixtures.py

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

### 2026-07-12 — List the inception fixture as a distinct hand-authored/provisional category
- **Chose:** Add a **Source** column and a 5th row marking `inception-gonogo.bpmn` as hand-authored + provisional-G-3, and reword the intro to "4 editor-emitted + 1 hand-authored" — rather than simply bumping "Four" → "Five".
- **Why:** The 5th fixture is genuinely different in kind: it is not an editor export, and it embodies the G-3 marker which is still mapping-v1 **Part II provisional** (ratified AEF-side, not yet graduated to frozen v1.1 by Dimitri). Folding it into the "authentic editor-emitted" count would misstate both its provenance and its normative status. Inventory-only edit — the frozen contract (§2/§3) is untouched, so no version bump is warranted.
- **Rejected:** (a) "Four"→"Five" one-word edit (loses the provenance + provisional distinctions); (b) leaving the drift (test guards 5, spec says 4 — a reader of the support spec would be misled); (c) waiting for v1.1 graduation to document it (the fixture already exists and is guarded now — the inventory must match reality now, with status flagged).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-12T19:31:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-194-sync-forward-compile-spec-5-corpus-inven.md
- **Context:** Initial task creation

### 2026-07-12T19:34:30Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
