---
id: T-611
name: "EWCR Arc 4 diagram-Fabric navigation: prove the built link path end to end, hand the operator a one-click review, answer CashWeb's parked question"
description: >
  EWCR Arc 4 diagram-Fabric navigation: prove the built link path end to end, hand the operator a one-click review, answer CashWeb's parked question

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:designer-authoring-surface]
components: []
related_tasks: [T-589, T-570, T-609, T-200]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-27T07:45:08Z
last_update: 2026-08-27T07:51:23Z
date_finished: 2026-08-27T07:51:23Z
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

# T-611: EWCR Arc 4 diagram-Fabric navigation: prove the built link path end to end, hand the operator a one-click review, answer CashWeb's parked question

## Context

Roadmap §2.1, Arc 4 row, Designer column names three deliverables. One of them is
**"diagram↔Fabric navigation"**. This task is about that phrase and nothing else.

Three facts arrived from different directions and turn out to be the same fact:

1. **T-589 built the door.** `fabricRef` and `links` are authorable on the four task-like
   node types, render as real anchors, and survive a round trip. `fabricRef` emits a
   root-relative href of the shape `/fabric/component/<value>`. Status is
   work-completed / owner: human, parked on two `[REVIEW]` ticks since 2026-08-26.

2. **001-CashWeb built the destination** and said so at rail offset 603 — one page per
   workflow step at `/fabric/component/<aef_uid>`, carrying the endpoint, the call, the
   directives, the implementing code and the bench call that proves it. 21 of 21 nodes of
   `cash-ecwid-stock-sync` v12 covered.

3. **Neither side knew about the other.** They asked at rail 577 whether a per-node link
   could render as navigable, measured our 0.11.0 bundle (linkify 0, window.open 0,
   `<a>` 0) and reasonably concluded no. That measurement was correct *for 0.11.0* and is
   stale for `src/`. Their route shape and our emitted href shape are the same string,
   reached independently, with no coordination between the two projects.

### What is genuinely built, and what is not

The honest split matters more than the good news, because the good news is easy to
overstate:

| surface | state |
|---|---|
| properties panel renders authored URLs as real anchors | **built** (T-589, `src/`) |
| `fabricRef` → `/fabric/component/<uid>` click-through | **built** (T-589, `src/`) |
| canvas / diagram click-through from a node glyph | **NOT built** — no navigation on the canvas at all |
| any of the above in a *released* artifact a consumer can pin | **NOT released** — `dist/` tops out at 0.11.0 |

CashWeb's rail-577 wording contrasts "navigable" with "text in the panel". T-589 makes the
panel navigable, which is not the same as making the canvas navigable. Answering "yes" flat
would be answering a question they did not ask.

### Why this task is not "release the designer"

A VERSION bump is outward-facing and is T-200's scope, not this one. This task proves the
path works, makes the operator's two-tick review one click instead of a five-line shell
incantation, and puts an accurate answer in front of the consumer who is parked. If the
operator then wants a release, that is a separate and better-informed decision.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The T-589 CDP gate passes against current `src/` — a verifier that DRIVES the page,
      not one that restates the rule it checks. Record the leg count and the baseline arm's
      verdict (the arm loads the pre-change build and requires ZERO anchors; if the baseline
      already links, no leg below evidences anything).
      <br>**Evidence:** `node tools/_t589-panel-links-cdp.mjs` → **10 passed, 0 failed**,
      exit 0. Baseline arm `control-baseline-cannot-navigate` **PASSES**: the pre-change
      build renders 0 anchors anywhere in the panel and shows both keys only as read-only
      "Other extensions" rows — disclosed, not authorable, not clickable. The gate also
      carries its own refusal (`:203`): a baseline that already contains `fabricLink` is
      rejected as "not a pre-change build" rather than silently passing.
- [x] A live server is serving the `src/` build, and the SERVED bytes contain both new field
      keys. Measured against the served response, never against `src/` on disk and never
      against an HTTP 200 — a page that 200s and a page that carries the fields are
      different claims (rail 588).
      <br>**Evidence:** `tools/gallery-serve.py` on a free port, docroot in scratchpad.
      HTTP 200, 993,710 bytes. Counted **in the fetched response**: `fabricRef` ×6,
      `Fabric component` ×1, `linkList` ×2. `cmp` of served-vs-disk is identical, i.e. the
      server is not transforming — which is the thing that makes the disk file admissible
      as a proxy *afterwards*, not before.
      <br>Note: `target="_blank"` counts **0** in the served HTML and that is correct, not a
      miss — `linkRow` sets it programmatically. The rendered-DOM proof is the gate's
      `fabric-anchor-root-relative` leg, which reads it off the live anchor.
- [x] The href shape T-589 emits and the route shape CashWeb built are compared as literal
      strings and the result recorded whichever way it comes out. Asserting that they match
      without putting the two literals side by side is the failure this project repeats.
      <br>**Evidence:** the expression at `src/aef-workflow-designer.html:5997` is
      `'/fabric/component/' + encodeURIComponent(refVal)`. Run against CashWeb's five stated
      uids — `cesync_write_ecwid`, `cesync_abort_run`, `cesync_backoff_read`,
      `cesync_backoff_write`, `ecwid` — **all five MATCH byte-for-byte**. Arm: a uid of
      `a b/c` yields `/fabric/component/a%20b%2Fc` and is reported DIFFER, so the comparison
      is not blind. Underscores survive `encodeURIComponent`; their 21 aef_uids drop into
      `fabricRef` unchanged.
- [x] `/review/T-589` renders BOTH `[REVIEW]` criteria with Steps / Expected / If-not blocks
      intact — counted, not eyeballed. Regression control against the T-609 class, where a
      card returned 200 and rendered AC titles with zero Steps because the ACs were ticked.
      <br>**Evidence:** `tools/_t611-review-card-steps.py` (new). Live: T-589 → 2 unchecked
      `[REVIEW]`, 2 Steps blocks rendered, exit 0.
      <br>**The invariant is a relation, not a count**, and that was a correction made during
      build: "expect 2 Steps" would go green on a card that ticked one criterion and
      duplicated another's block, and would go **red when the operator does their job**. What
      is asserted is `rendered Steps == unchecked [REVIEW] criteria`, both sides measured —
      left from the card's bytes, right from the task file.
      <br>**Arm:** running it against T-597 passed too, which proved nothing (T-609 already
      reverted those ticks). Ticking a `### Human` AC to manufacture a red is not available
      to me — it is the operator's verdict to assert. So `--self-test` drives 5 synthetic
      cases plus 2 guards: 7/7, including the literal T-609 shape (2 unchecked / 1 Steps →
      VIOLATED) and its mirror (instructions rendered for an already-met criterion →
      VIOLATED). A `[REVIEW]` token inside the template's own HTML comment is counted as a
      **mention, not a use** (the T-608 lesson), and a task with zero `[REVIEW]` criteria
      exits 2 rather than passing `0 == 0` vacuously.
- [x] The rail answer to 001-CashWeb is posted with `from_project` attribution and states
      the panel/canvas split and the unreleased status EXPLICITLY. An answer that lets them
      infer canvas navigation exists is worse than the stale "no" they have now.
      <br>**Evidence:** `agent-chat-arc` **offset 604**, thread `EWCR-ARC4-NAV-832`,
      `in_reply_to: 603`, `metadata.from_project=832-Workflow-designer`. Part 2 is headed
      "WHAT IS NOT BUILT" and states "no navigation on the canvas at all"; Part 3 is headed
      "THE PART THAT ACTUALLY BLOCKS YOU" and states that `dist/` tops out at 0.11.0 and
      there is nothing for them to consume today. Their 0.11.0 measurement is confirmed as
      correct rather than corrected. Rail acked to 604.
- [x] No file under `src/` is modified by this task. This is a proving-and-delivering task;
      if it starts editing the designer it has become a different task and must be split.
      <br>**Evidence:** `git diff --quiet HEAD -- src/` exits 0; `git status --short -- src/`
      is empty. The only new file is `tools/_t611-review-card-steps.py`.

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

# --- T-611 ---
# The two keys are present in src (the thing the whole task rests on).
python3 -c "import pathlib,sys; t=pathlib.Path('src/aef-workflow-designer.html').read_text(); sys.exit(0 if ('fabricRef' in t and 'links' in t) else 1)"
# AC 6: this task must not have touched the designer. Its own exit code is the verdict.
git diff --quiet HEAD -- src/
# AC 4: both [REVIEW] criteria still render their Steps blocks on the live card.
# Single command whose own exit code is the verdict (T-352): no chained `;`.
python3 tools/_t611-review-card-steps.py 589
# ...and the guard must be able to go red, or its green means nothing.
python3 tools/_t611-review-card-steps.py --self-test
# The T-589 gate itself, driven against src, baseline arm included.
node tools/_t589-panel-links-cdp.mjs

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

### 2026-08-27 — the guard I wrote first would have gone red when the operator did their job

- **What changed:** the T-609 regression control started life as "assert 2 Steps blocks
  render on `/review/T-589`". That is an adjacent measurement. It passes on a card that
  ticked one criterion and duplicated another's Steps block, and it turns **red the moment
  the operator ticks a criterion** — punishing exactly the action the card exists to invite.
  The invariant that actually encodes T-609 is a relation between two measured quantities:
  `rendered Steps == unchecked [REVIEW] criteria`.
- **Plan impact:** the AC was rewritten mid-build from a count to a relation, and the
  verifier reads the task file as the right-hand side rather than carrying a literal 2.
- **Triggered:** `tools/_t611-review-card-steps.py --self-test`, because the live arm was
  unavailable — the only way to make the live card go red is to tick a `### Human` AC, which
  is the operator's verdict and never mine to assert.

### 2026-08-27 — the answer to a peer question changed shape once I checked the release, not the source

- **What changed:** I was one step from telling 001-CashWeb "yes, it's built" on the strength
  of `src/`. `dist/` tops out at 0.11.0 and their pin is 0.11.0, so the true answer to
  "can I have it" is **no, not yet** — their original measurement was right and is merely
  stale for a tree they cannot see. Confirming their measurement rather than correcting it
  is the difference between a useful answer and a misleading one.
- **Plan impact:** the rail post grew a third part ("THE PART THAT ACTUALLY BLOCKS YOU")
  naming the release gap as the real blocker, and explicitly declines to bump VERSION on a
  peer's behalf — a peer message is not authorisation (G-020).
- **Triggered:** nothing filed. T-200 already carries the release; this task deliberately
  does not fold it in, and the operator now has consumer evidence attached to that decision.

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

### 2026-08-27T07:45:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-611-ewcr-arc-4-diagram-fabric-navigation-pro.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2a8f4803
- **Timestamp:** 2026-08-27T07:51:28Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-27T07:51:23Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
