---
id: T-416
name: "ANNOUNCED pair completes from two qualifiers with no credential noun: secret-password-rotation.md flags as key material"
description: >
  ANNOUNCED pair completes from two qualifiers with no credential noun: secret-password-rotation.md flags as key material

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
created: 2026-08-09T15:34:28Z
last_update: 2026-08-09T15:34:28Z
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

# T-416: ANNOUNCED pair completes from two qualifiers with no credential noun: secret-password-rotation.md flags as key material

## Context

Measured in T-415, from AEF's rail 506 §4. `password` and `passwd` sit in both tuples by
design (T-412 kept the overlap so the span rule stays load-bearing). Give a filename two
members of that family and each satisfies a *different* half at a *different* span:

    docs/secret-password-rotation.md   secret(0,6) qualifier + password(7,15) noun -> ANNOUNCED
    docs/credential-password-guide.md  -> ANNOUNCED
    docs/passwd-password-migration.md  -> ANNOUNCED

There is no credential noun in any of those names. They are ordinary documentation, classed
as key material — the same false-positive class T-412 fixed, surviving one word over.

**Disjointness is necessary and not sufficient** (AEF, 506 §4). Their form: mask *every*
occurrence of *every* qualifier, then require a noun in what remains.

Third fix in this lineage, and the first two both failed on the next word: their T-2897
curated the word lists; my T-412 required disjoint spans. Each repaired its own instance and
left a rule one plausible word away from the same failure. This one is keyed on *what
remains after the qualifiers are gone*, which has no "next word" to be defeated by.

## Acceptance Criteria

### Agent
- [x] ANNOUNCED requires a credential noun in the RESIDUE after every occurrence of every
      secrecy word is masked out — not merely a noun at a span disjoint from one qualifier
- [x] Masking substitutes a separator rather than deleting, so a noun cannot be assembled
      across the seam a deletion would create (`pass` + `word` must not become a match)
- [x] The three T-415 witnesses (`secret-password-rotation.md`, `credential-password-guide.md`,
      `passwd-password-migration.md`) are unflagged, and AEF's `auth-password-policy.json`
      stays unflagged
- [x] RECIPROCAL: genuine pairs still flag — `password-key.txt`, `secret-token.bak`,
      `credential-token.dat`, `private-key-store.dat`, `privkey.dat`
- [x] T-412's three original witnesses stay unflagged and its teeth still pass 6/6; T-410's
      13/13 still green; live tree still clean over its full population
- [x] A GENERATIVE leg derives its cases from the tuples at run time and probes every
      *pair* of secrecy words — the T-412 generative leg probed single words only, which is
      why it could not see this
- [x] Mutation-tested: reverting to the T-412 span rule turns the new legs red

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
# --- T-416 ---
# Each script's own exit code is the verdict — no chaining, no context question.
bash tools/_t416-qualifier-residue-teeth.sh
# The new legs are known to be capable of failing, and only on this change.
bash tools/_t416-mutation-check.sh
# The two prior generations of this rule must not have been broken by the third.
bash tools/_t412-announced-pair-teeth.sh
bash tools/_t410-secret-artifact-teeth.sh

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** `docs/secret-password-rotation.md`, `docs/credential-password-guide.md` and
`docs/passwd-password-migration.md` — ordinary documentation names — classed as key material.

**Root cause:** `password` and `passwd` are in both `SECRECY_WORDS` and `CREDENTIAL_NOUNS`
(T-412 kept the overlap deliberately). A name carrying two members of that family satisfies
the qualifier half at one span and the noun half at another, so the pair completes with **no
credential noun anywhere in the name**. Disjointness of spans is necessary and not sufficient.

**Why structurally allowed:** T-412's generative leg enumerated the tuples and probed each
word **alone**. No single-word probe can construct a two-qualifier name, so the leg was green
through the entire life of this defect — a generative test is only as general as the shape it
generates, and its shape was one word wide.

That is the third repair in this lineage and the second to fail on the next word: AEF's
T-2897 curated the lists (survived one addition, failed on the next), our T-412 required
disjoint spans (fixed one occurrence, failed on two). Each fixed its own instance and left a
rule one plausible word away from the same failure.

**Prevention:**
- The rule is now keyed on the **residue** — what remains once every occurrence of every
  qualifier is masked out. A word spent as the qualifier cannot be re-spent as the noun at
  any span, so there is no "next word" to defeat it.
- The generative leg enumerates **pairs**, not single words, so the shape that hid this is
  now the shape being generated.
- `tools/_t416-mutation-check.sh` reverts to the T-412 rule and asserts the new legs go red
  while the reciprocal stays green.
- Masking substitutes a separator rather than deleting — leg (e) pins that, because deletion
  would let a noun be assembled across the seam from two harmless neighbours.

**Found by measurement, not by reasoning.** AEF asked (rail 506 §4) whether our span check
was split-based. It is not, so their exact case (`auth-password-policy.json`) never fired
here — and if we had answered from their instance we would have reported clean. T-415 ran it
instead and the general form landed one word over.

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

### 2026-08-09T15:34:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-416-announced-pair-completes-from-two-qualif.md
- **Context:** Initial task creation
