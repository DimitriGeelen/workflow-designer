---
id: T-513
name: "does identity survive a third-party import with no aef-uid"
description: >
  does identity survive a third-party import with no aef-uid

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: [T-511, T-364, T-340, T-423]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T09:14:42Z
last_update: 2026-08-15T09:27:11Z
date_finished: 2026-08-15T09:27:11Z
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

# T-513: does identity survive a third-party import with no aef-uid

## Context

AEF asked this directly on the rail at 11882, closing out the element-`id` question
we raised at 11879:

> "If you have a case where identity has to survive a third-party import (no `aef:uid`
> on arrival), that is the one I would want to hear about — that is where derived-from-uid
> stops being stable."

It is the gap `_t511`'s own `does_not_cover` line already named and excluded:
*"third-party documents arriving without aef:uid."* So this is not a new question — it is
the one we told AEF we had not measured, asked back at us by the party who would be
harmed if the answer is bad.

The READ of the source says identity survives: `parseBpmnXml` derives a uid from the BPMN
element id via FNV-1a when `aef:uid` is absent (T-364, :9898-9925), and `buildBpmnXml`
emits `aef:uid` unconditionally (:9363). But T-511's first run proved a read of this
exact area can produce a confident wrong answer — the answer here is MEASURED by running
the real path, and the read is used only to say what the probe is expected to find.

Arc: `designer-authoring-surface`. Third-party import is the T-340 surface (step 1).

## Acceptance Criteria

### Agent
- [x] A probe drives the real save path — `buildBpmnXml(parseBpmnXml(x))` in the loaded
      designer, not a re-implementation — over a fixture that is genuinely third-party
      shaped: the `aef` namespace does not appear in it at all, geometry arrives as BPMN
      DI `dc:Bounds`, and element ids are bpmn.io-shaped (`Activity_1a2b3c4`).
      → `tools/_t513-thirdparty-identity-roundtrip.mjs`, exit 0.
- [x] Anti-vacuity: the probe REFUSES (non-zero, named reason) if the fixture contains any
      `aef:uid` before the round-trip. A "third-party import" test on a document that
      already carries our identity attribute answers a different question and would pass
      for the wrong reason.
      → two independent checks: a static one on `FIXTURE` before anything spawns (rc 2),
        and `IN.uids.length !== 0` after the page's own parser has read it.
- [x] The question is answered on both halves and they are reported separately, because
      they can differ: (a) does an identity exist on the way OUT — is `aef:uid` injected
      into a document that arrived without one; (b) does that identity SURVIVE a second
      import, i.e. `uids(parse(export(parse(fixture))))` equals `uids(parse(fixture))`.
      → (a) 0 uids in, 7 out — minted. (b) identical sets across the second import.
- [x] Negative control, cutting on the SAME identity the comparator reads (PL-205): one
      `aef:uid` is deleted from the exported document and the comparator MUST report it.
      A dead comparator and a clean round-trip are byte-identical outputs otherwise.
      → victim `n_6ccd26d5`, `fired: true`.
- [x] Anti-overfit leg: a benign edit (renaming a node's `name`) must leave the verdict
      GREEN. A probe that goes red on any change is not measuring identity.
      → `quiet: true`; uid set unchanged under the rename.
- [x] The boundary is measured rather than asserted: re-mint every element id in the
      fixture (what a third-party editor does on its own re-export) and REPORT whether the
      derived uids change. This is expected to be a boundary, not a defect — but it is
      reported as a number, not as a claim.
      → 0 of 7 uids survive a full re-mint; `overlap: []`.
        Recorded because I got this wrong first: the leg originally suffixed only the four
        NODE ids and reported 3 surviving edge uids. That was an artifact of the three
        `Flow_` ids I had left untouched, not a property of the designer — a partial
        re-mint models a re-export nobody performs. Fixed to re-mint every id the fixture
        defines, and the survivors went to zero.
- [x] The probe is wired into `tests/run-bridge-tests.sh`. A property asserted to a peer
      project over the rail with nothing re-checking it is the exact class this repo has
      been cataloguing (T-451 ratchet, T-509).
      → suite 83 passed / 0 failed; T-451 census FINDINGS unchanged at 67.
- [x] The answer is posted to AEF on the rail with producer attribution, stating the
      boundary in the same breath as the answer so it cannot be read wider than measured.
      → `agent-chat-arc` offset **11885**, `metadata.from_project=832-Workflow-designer`,
        `in_reply_to=11882`. Carries the answer, the 0-of-7 re-mint boundary, the
        `does_not_cover` scope, the correction to the too-narrow `id` warning I gave them
        at 11879, and the near-miss disclosure on the fabricated duplicate-id defect.

<!-- No ### Human section: every criterion above is a deterministic command or a
     grep-able structural fact, so under the T-1811/T-1878 routing rule they all belong
     here as Agent ACs. Nothing in this task turns on taste. -->

<!-- Human-AC template guidance retained below, commented, for the next author.
### Human
     Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
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

# The probe's own exit code IS the verdict: 0 only when the fixture was genuinely
# aef-free, the round-trip preserved identity, the negative control FIRED, and the
# anti-overfit leg stayed green. Single command, no chaining — per the errexit warning
# above, a chained line would be judged on its last segment alone.
timeout 300 node tools/_t513-thirdparty-identity-roundtrip.mjs > /dev/null

# Wired into the suite, so the claim made to AEF is re-checked by something other than
# my memory of having run it once (T-451 ratchet / T-509).
grep -q '_t513-thirdparty-identity-roundtrip.mjs' tests/run-bridge-tests.sh

# The fixture must not contain the aef namespace. This pins the anti-vacuity property in
# the probe SOURCE, so a later edit that quietly adds aef:uid to the fixture — which would
# make the probe pass for the wrong reason — fails here rather than passing silently.
python3 -c "import sys,re; s=open('tools/_t513-thirdparty-identity-roundtrip.mjs').read(); m=re.search(r'const FIXTURE = String.raw\`(.*?)\`', s, re.S); sys.exit(0 if m and 'aef:' not in m.group(1) and 'anchorpoint.framework' not in m.group(1) else 1)"

# The negative control must cut on aef:uid — the same identity the comparator reads.
# Cutting on something the comparator does not consult proves nothing about it (PL-205).
grep -q 'NEGATIVE CONTROL CUTS ON aef:uid' tools/_t513-thirdparty-identity-roundtrip.mjs

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

### 2026-08-15 — three legs were green for the wrong reason before they were green for the right one

- **What changed:** every one of the three passed on the first run, and two of them were
  worthless. (1) The anti-overfit rename appended `(renamed)` to "Review request"; the
  emitted id slug is built from the leading word, so both names slug to `review` and
  `id_survived_a_rename: true` was true without the leg ever exercising a rename. (2) The
  boundary leg re-minted only the four node ids and reported three surviving edge uids —
  an artifact of the three `Flow_` ids left untouched. (3) The duplicate-id counter ran
  over every namespace and reported `Process_t513` twice, which reads as a schema
  violation.
- **Plan impact:** none to the answer — it was YES before and after. The impact is on what
  I would have SENT: a fabricated defect report and two numbers that describe the fixture
  rather than the designer.
- **Triggered:** no new task. The class is already PL-205 ("a probe reporting an absence is
  indistinguishable from a dead comparator") and AEF's 11876 form of it ("a control that
  cannot fail is not a control"). What is new here is the third variant — a control that
  CAN fail but whose *input* was built so it never would — so the check is not only "does
  the control fire?" but "does the stimulus actually contain the thing the control looks
  for?". Both the rename and the re-mint failed the second question while passing the first.

### 2026-08-15 — the warning we already sent AEF was too narrow

- **What changed:** at 11879 I told AEF the element `id` is "re-minted on import". Measured
  here, it is a function of lane + x-order + the node's NAME: `hum_2_review` becomes
  `hum_2_escalate` under a plain rename, with the uid unchanged. The id therefore churns
  during ordinary authoring, not only across an import.
- **Plan impact:** the rail post must carry the sharper form, because AEF closed the id
  question on their side on the strength of the narrower one.
- **Triggered:** the correction is in the T-513 rail post rather than a new task — same
  fact, better measured, and splitting it into its own ticket would separate it from the
  measurement that produced it.

## Decisions

### 2026-08-15 — reported the duplicate-id finding as an observation, not a defect

- **Chose:** count duplicate element ids over BPMN-namespace elements only, and report the
  cross-namespace collision (`bpmn:participant/@id` == `aef:workflowMeta/@id`) as a named
  observation rather than as a defect.
- **Why:** BPMN's `@id` is `xsd:ID`, but `aef:workflowMeta` is a foreign element inside
  `bpmn:extensionElements`, which BPMN20.xsd admits via
  `<xsd:any namespace="##other" processContents="lax"/>`. With no AEF schema available, lax
  means it is not validated, so that attribute is never typed as `xsd:ID` and carries no
  uniqueness constraint. The document is valid.
- **Rejected:** filing it as a bug and telling AEF — which is what the naive counter's
  output invited. It would have been a fabricated defect report to a peer, from us, in the
  same week we asked them to trust our measurements.
- **Also rejected:** gating the probe on duplicate ids. This probe answers the identity
  question; widening it into a validity gate would make one green mean two different
  things, and a future reader could not tell which property a red was about.

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

### 2026-08-15T09:14:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-513-does-identity-survive-a-third-party-impo.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0306e3ea
- **Timestamp:** 2026-08-15T09:27:14Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 52
     - evidence: `timeout 300 node tools/_t513-thirdparty-identity-roundtrip.mjs > /dev/null`

### 2026-08-15T09:27:11Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
