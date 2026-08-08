---
id: T-399
name: "Bridge red: T-361 trailer check treats an AEF-authored fixture as one of our exports (prefix collision)"
description: >
  Bridge red: T-361 trailer check treats an AEF-authored fixture as one of our exports (prefix collision)

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
created: 2026-08-08T21:03:58Z
last_update: 2026-08-08T21:03:58Z
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

# T-399: Bridge red: T-361 trailer check treats an AEF-authored fixture as one of our exports (prefix collision)

## Context

**The bridge suite is RED on master: 70 passed, 1 failed** (`tests/run-bridge-tests.sh`,
exit 1). Geometry sweep is clean, 24/24. Found while pre-running P-011 for T-398's census;
it is what blocks T-041 and T-101 from closing.

    [FAIL] tests/test_emitted_comment_claims.py (T-361)
           FAIL every exported document carries the approved trailer or is a pinned legacy record
                tests/fixtures/third-party/aef-draft-inception-readiness-v2.bpmn
           documents: 1 current, 106 legacy-exempt, 1 unaccounted

### It is a PREFIX COLLISION, not a missing trailer

    ours   (src:9432-9433)  BPMN DI (visual layout) omitted; node geometry travels as aef:position
    AEF's  (the fixture)    BPMN DI (visual layout) omitted in this demo; AEF generates it from node coordinates
                            └──────── shared prefix ─────────┘└──── diverges here ────┘

`test_emitted_comment_claims.py:165` scopes the walk with `if prefix not in body: continue`
— using **"contains our trailer PREFIX"** as a proxy for **"we exported this document"**.
Line 167 then requires the FULL current trailer, and line 171 allows a pinned-sha legacy
exemption. AEF's file satisfies the entry condition and neither exit, so it lands in
`offenders`.

The document has never been through our emitter. AEF wrote a comment that happens to open
with the same eight words — which is not a coincidence worth designing around so much as an
inevitability: it describes the same fact, in the same domain vocabulary, and AEF is the one
peer that shares it.

### Why the proxy was sound and then was not

`prefix in body` was a correct identity test for a corpus containing only our own output.
The T-347/T-356/T-372 third-party intake changed the population. **The check did not become
wrong; the world it was measuring did.**

This is the third instance of one shape from the same intake:

| task | check | complete for | wrong once |
|---|---|---|---|
| T-359 | validator's non-flow-node exclusion set | children *our* emitters produce | Bizagi's `<documentation>` arrived |
| T-337 | importer's node-tag allowlist | tags *we* emit | a foreign tag arrived |
| **T-399** | trailer check's "is this ours" proxy | documents *we* exported | a peer's prose collided |

**It fails in the unsafe direction.** It does not miss one of our documents that lost its
trailer; it reports a foreign document as one of ours. A reader trusting the message would
go looking for an emitter bug that does not exist.

### The fix is a judgement call — do NOT reach for the obvious two

- **Do not add it to the legacy ledger.** The ledger pins sha→path to say *"this document
  legitimately carries an OLD trailer"*. This one carries **no** trailer of ours, ever. A
  ledger entry would be a false statement, and the ledger's whole value is that its entries
  are true.
- **Do not exclude `tests/fixtures/third-party/`.** That is an allowlist-shaped patch to an
  allowlist-shaped defect — the exact move T-337's `## Decisions` warns about. It also fails
  the moment a peer document is vendored anywhere else.

The real question is **what positively identifies a document as our export**, given that the
current answer is prose and prose collides. Whatever is chosen needs mutation teeth in the
T-359 style: prove the check still goes RED on a genuine one of our documents with a stale
trailer, or the fix has removed the check rather than repaired it.

### Provenance is already documented — the ledger just was not told

`tests/fixtures/third-party/PROVENANCE.md:200` already carries a section titled *"foreign,
but NOT by this directory's test (T-372)"*, recording that this file fails the directory's
provably-foreign fingerprint because AEF legitimately uses the `aef:` namespace they define.
So T-372 identified that **one** identity test misfires on this file and documented it — and
a **second** identity test, in a different suite, misfires on the same file for a closely
related reason and went unnoticed. Worth carrying into the fix: the question is not "is this
file foreign" but "how many checks in this tree infer authorship from a string".

Landed 2026-08-08 in `ee2d8217` (T-372). The suite has been red since.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] Bridge suite green: `tests/run-bridge-tests.sh` reports `0 failed` and exits 0.
- [ ] The repair identifies our exports by something a peer's PROSE cannot collide with, and
      the choice is recorded in `## Decisions` with the two rejected shapes named (ledger
      entry — states a falsehood; directory exclusion — an allowlist patch on an allowlist
      defect, and it moves the moment a peer file is vendored elsewhere).
- [ ] **Mutation teeth, T-359 style.** Take a genuine document of ours, give it a STALE
      trailer, and prove the repaired check still reports it. A fix that silences the one
      false positive by narrowing the net until nothing is caught has removed the check, not
      repaired it — and would look identical in the suite output.
- [ ] The reciprocal control: with the repair in place, AEF's fixture is NOT reported, and
      the reason it is not reported is the new identity mechanism rather than a path skip.
- [ ] Census of the same shape: how many other checks in the tree infer authorship or
      provenance from a string match? Reported (not necessarily fixed) — T-372 found one such
      misfire on this exact file and this is a second, so a third is the working assumption
      until counted.
- [ ] T-041 and T-101 re-run: their bridge-suite verification lines pass.

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

# --- T-399 commands (added at filing; the task is NOT yet fixed) ---
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "passed, 0 failed"
# The collision itself, asserted directly: the fixture must NOT be named as an offender.
out=$(python3 tests/test_emitted_comment_claims.py 2>&1); ! echo "$out" | grep -q "aef-draft-inception-readiness-v2"
# Anti-vacuity: the check must still be CAPABLE of reporting. If the repair narrowed the
# net to nothing, the line above passes and means nothing — same failure the fix must avoid.
out=$(python3 tests/test_emitted_comment_claims.py 2>&1); echo "$out" | grep -q "documents:"

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

### 2026-08-08T21:03:58Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-399-bridge-red-t-361-trailer-check-treats-an.md
- **Context:** Initial task creation
