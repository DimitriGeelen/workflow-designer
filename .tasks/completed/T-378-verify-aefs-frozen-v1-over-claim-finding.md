---
id: T-378
name: "Verify AEF's Frozen-v1 over-claim finding against the frozen text itself"
description: >
  AEF read the standard cold and previews a NO ruling on my section-7 flag, with the evidence inside section 2 rather than section 7: they report that my own frozen governance-meta-key table carries a struck-through row annotated 'in v1.1', i.e. the section defining what frozen MEANS contains a v1.1 edit, so the Frozen-v1 heading over-claims. That is a claim about MY artifact, arrived at from a copy I transmitted, and I must not accept it the way they accepted my paraphrase. Locate the row in the frozen byte range [1906,9811) and quote it with offsets, or report it absent. Establish whether it falls INSIDE the frozen extent — the finding only bites if it does. Confirm the file still hashes to the delivered pin so the reading is against the bytes they hold. The standard must NOT be edited under agent control; the remedy is an operator decision and this task prepares it.

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T14:52:02Z
last_update: 2026-08-08T14:55:49Z
date_finished: 2026-08-08T14:55:49Z
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

# T-378: Verify AEF's Frozen-v1 over-claim finding against the frozen text itself

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The file still hashes to the delivered pin (whole-file `fbada7b3`, Part I `970dd530`
      over bytes [1906,9811)), so the reading is against the same bytes AEF holds — a
      verification against a drifted copy answers a different question
- [x] The struck-through row and its `v1.1` annotation are located and quoted with byte
      offsets, **or** reported ABSENT — absent would mean their ruling rests on something
      my copy does not carry, which is the more serious outcome and must not be smoothed
- [x] Whether the annotation falls INSIDE the frozen extent [1906,9811) is decided by
      offset arithmetic, not by eye — the finding only bites if it does
- [x] The over-claim question is answered from the text on its own terms, stating what the
      heading claims and what the body does, independent of AEF's argument for it
- [x] The whole frozen extent is swept for the same construct, not just the one row they
      named — a single cited instance is a sample, and the remedy differs if there are more
- [x] Operator decision prepared with remedy options, consequences, and the expected pin
      break stated as expected
- [x] The standard itself is NOT edited: `git diff --exit-code docs/standards/aef-bpmn-mapping-v1.md` is clean at completion

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

## Measurements

**Integrity first.** Whole file 10790 B / `fbada7b3`; Part I bytes [1906,9811) = 7905 B /
`970dd530258b1cde…`. Unchanged since delivery — this reading is against the same bytes AEF
holds, so the two of us are arguing about one artifact.

**Their citation is accurate.** Byte 3985, inside the frozen extent:

> `| ~~`owner`~~ *(derived — see §3)* | `owner` | `human` \| `agent` | **derived from the
> node's lane (Axis 1); no node-level override.** `owner` remains in task-YAML output but
> has no node-level BPMN carrier in v1.1. |`

A struck-through row annotated `v1.1` (byte 4195), inside a table introduced at byte 3342 as
*"The **frozen v1** governance meta-keys"*. Both inside [1906,9811).

**But they named one instance, and the population is nine.** Every version token inside the
frozen extent:

| offset | token | construct | stale? |
|---|---|---|---|
| 1927 | `v1` | `# Part I — Frozen (v1)` — the heading | **yes** — the one they cited |
| 3342 | `v1` | "the **frozen v1** governance meta-keys" — introduces the edited table | **yes** |
| 4195 | `v1.1` | the struck `owner` row's annotation | correct |
| 4584 | `v1` | "not part of the **frozen v1** governance-scalar contract" | **yes** |
| 6330 | `v1.1` | "**owner is the lane (IW-9, v1.1)**" | correct |
| 7040 | `v1` | "out of scope for v1" — a scope statement, not a label | ambiguous |
| 8278 | `v1` | "An implementation is **v1-conformant** iff" — §6 | **yes, and worst** |
| 8904 | `v1.1` | "## 7. Inception marker (G-3) — ratified v1.1" | correct |
| 9189 | `v1.1` | "machine-checked at compile time (O-3, v1.1)" | correct |

**8278 is the one that is not a label.** `v1-conformant` is a *defined term*, and §6 defines
it by a list that now includes the v1.1-edited §2 table and the v1.1-ratified §7 marker. So
the bar the word names moved while the word did not. An implementation certified
"v1-conformant" against the original v1 text and one certified against this document are not
being held to the same requirements — and both our conformance rail and
`tests/test_mapping_standard_conformance.py` key on that term. AEF's recommended remedy
("retitle plus a changelog") was scoped from the single instance they cited and leaves 3342,
4584 and 8278 standing.

**The governance process was NOT violated — say this plainly so it is not misread.** Byte
105 declares `**Version:** 1.1`, a changelog block at byte 296 records exactly what moved
into Part I and why, and "Versioning & change control" requires a bump for frozen changes.
The bump happened and is documented. What failed is labelling, not control.

**The defect that is mine, and it is a property of the extent I chose to transmit.** The
only correct statement of this document's version — `**Version:** 1.1` — lives at byte 105,
**outside [1906,9811)**. I sent AEF the frozen extent alone as the citable unit. That unit
contains three internal claims that it is v1, four annotations that it is v1.1, and no
correct statement of its own version. **A party holding only Part I cannot determine what
version of Part I it holds.** In a two-party ratification process the unit of citation is
exactly the thing that must be self-describing, and I stripped it of its identity in the act
of making it citable.

**Answering the over-claim question from the text on its own terms:** the heading claims the
section is Frozen (v1). The section is the frozen content *as amended by v1.1*. The heading
is therefore wrong in the direction AEF says — but the sharper statement is that the frozen
extent asserts its version three times and is wrong all three, while the four places that
name v1.1 are annotations on individual changes rather than a version declaration.

## Operator decision — remedy for the version labelling

The standard must not be edited under agent control, so this is prepared, not applied.

| | Remedy | Leaves standing | Pin |
|---|---|---|---|
| **A** | Retitle the §heading only (AEF's remedy as written) | 3342, 4584, **8278** | breaks |
| **B** | **Recommended.** Retitle; correct 3342/4584; resolve 8278 explicitly; add a version declaration *inside* the frozen extent; changelog entry | nothing | breaks |
| **C** | Split Part I into its own versioned file | nothing, but heavier; AEF recommends against | breaks |

All three break the pin. **That is the pin working** — AEF's sidecar forbids silently
updating the expected hash, so this becomes a deliberate, recorded re-pin on both sides
rather than a drift. Sequence matters: agree the remedy with AEF *before* editing, so we
re-pin once against one agreed artifact instead of twice.

`8278` needs a decision rather than a substitution: renaming the term to `v1.1-conformant`
changes what every existing conformance claim means, whereas leaving it means the term is
version-free by intent. Either is defensible; picking silently is not.

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

# The standard was NOT edited under agent control. This is the AC, not a courtesy check.
git diff --exit-code docs/standards/aef-bpmn-mapping-v1.md

# The bytes this task reasoned over are still the bytes AEF holds. Literal sha is
# deliberate and legitimate here for the same reason as T-377's: a frozen document at a
# fixed byte range. If this goes red the artifact moved — which after the operator applies
# a remedy it WILL, and at that moment this line must be updated together with the rail
# re-pin, not quietly refreshed to whatever the file then hashes to.
python3 -c "import hashlib,sys; b=open('docs/standards/aef-bpmn-mapping-v1.md','rb').read()[1906:9811]; sys.exit(0 if hashlib.sha256(b).hexdigest()=='970dd530258b1cde1682a3ad9068808efbf3bb9a664b181499d8ee8328b9106f' else 1)"

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

### 2026-08-08T14:52:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-378-verify-aefs-frozen-v1-over-claim-finding.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ccf0df7a
- **Timestamp:** 2026-08-08T14:55:50Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T14:55:49Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
