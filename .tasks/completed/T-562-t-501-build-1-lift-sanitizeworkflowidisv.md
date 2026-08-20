---
id: T-562
name: "T-501 build 1: lift sanitizeWorkflowId/isValidWorkflowId into shared helpers called from all three sites"
description: >
  T-501 build 1: lift sanitizeWorkflowId/isValidWorkflowId into shared helpers called from all three sites

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: [T-501, T-563, T-564, T-565]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-20T09:34:33Z
last_update: 2026-08-20T09:51:25Z
date_finished: 2026-08-20T09:51:25Z
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

# T-562: T-501 build 1: lift sanitizeWorkflowId/isValidWorkflowId into shared helpers called from all three sites

## Context

Build 1 of the three the T-501 GO authorises (T-501 §Decision, item 1 of the
decomposition list). D2 of the AEF/CashWeb defect report: the workflow-id sanitizer is
written inline at three sites and the validator that judges its output is written inline
at a fourth, so the two can and do disagree.

The four sites, read at v0.10.0:

| site | code | strips leading/trailing | empty fallback |
|------|------|------------------------|----------------|
| `:2685` `renameActiveWorkflow` | `.trim().toLowerCase().replace(/[^a-z0-9_\-]/g,'-')` | no | no |
| `:5223` ID property field | identical to `:2685` | no | no |
| `:9162` `createFromPendingRef` | same + `.replace(/^-+\|-+$/g,'')` + `\|\| 'workflow'` | dashes only | yes |
| `:8433` save validator | `/^[a-z0-9][a-z0-9_-]*$/` — the judge | — | — |

T-501's ruling calls `:9162` "the correct rule, already shipping" and the census backs
that over the 14 fallback documents (10 distinct, 0 invalid). **That census does not
exercise the rule's one hole, and reading the four sites side by side is what shows it:**
`[^a-z0-9_\-]` *preserves* underscore, and `^-+|-+$` strips *dashes only*. So `_foo`
survives `:9162` as `_foo`, and `:8433` rejects it on the leading-underscore. `___`
likewise — non-empty, so the `|| 'workflow'` fallback never fires. The corpus happens to
contain no such name, which is why 0-invalid was measured and is true.

So this task does not merely lift `:9162`; it lifts a *corrected* `:9162`, and the
correction is stated as a defect of the rule rather than folded in silently. Same shape
as the four already recorded this week — a sound measurement of a population that does
not reach the case.

Not in scope: the `:9950` derivation (build 2, T-563), load-time normalisation (build 3,
T-564), always-emit `workflowMeta` (IW-0, deferred, T-565 measures its exit condition),
and collision policy at `:9214`, which the GO explicitly keeps out.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `sanitizeWorkflowId(raw)` and `isValidWorkflowId(id)` are defined exactly once each in `src/aef-workflow-designer.html`, and `isValidWorkflowId` is the single site holding the `^[a-z0-9][a-z0-9_-]*$` regex
- [x] All four sites route through the helpers: `:2685`, `:5223` and `:9162` call `sanitizeWorkflowId`; the save guard at `:8433` calls `isValidWorkflowId`. Asserted as a call-site count, not as the absence of the inline forms (T-560)
- [x] `sanitizeWorkflowId` output satisfies `isValidWorkflowId` for every input in the adversarial set — including `_foo`, `___`, `-x-`, `""`, `"   "`, `"!!!"`, `"Ünïcödé Näme"`, `"9lives"` — measured by running the extracted helper, not by reading it
- [x] The leading-underscore hole is demonstrated against the PRE-fix `:9162` rule and shown closed by the helper, so the correction is evidenced rather than asserted
- [x] Ghost-name population behaviour at `:9162` is unchanged: every name in the corpus that currently reaches `createFromPendingRef` produces a byte-identical id before and after
- [x] Teeth file with mutants covering both edges (helper that rejects everything; helper that passes everything through), wired into `tests/run-bridge-tests.sh`, suite green with a count floor

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

node tools/_t562-workflow-id-helpers-cdp.mjs > /tmp/.t562-probe 2>&1 && grep -q "7/7 legs passed" /tmp/.t562-probe
bash tools/_t562-workflow-id-helpers-teeth.sh > /tmp/.t562-teeth 2>&1 && grep -q "6/6 teeth legs passed" /tmp/.t562-teeth
# Call sites, asserted as a POSITIVE count (1 definition + 3 call sites). T-560: the
# obvious leg here is "no inline sanitizer remains", which passes just as readily when
# the pattern is mis-quoted as when the code is right.
test 4 -eq "$(grep -c 'sanitizeWorkflowId(' src/aef-workflow-designer.html)"
test 1 -eq "$(grep -c '\^\[a-z0-9\]\[a-z0-9_-\]\*\$' src/aef-workflow-designer.html)"
grep -qF 'if (!isValidWorkflowId(id))' src/aef-workflow-designer.html
bash tests/run-bridge-tests.sh > /tmp/.t562-suite 2>&1 && python3 -c "import re,sys; m=re.search(r'(\d+) passed, 0 failed', open('/tmp/.t562-suite').read()); sys.exit(0 if m and int(m.group(1)) >= 117 else 1)"
python3 tools/_t560-absence-assertion-census.py > /tmp/.t562-abs 2>&1 && grep -q "PASS: no increase in uncontrolled absence assertions" /tmp/.t562-abs

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

**Symptom:** A map could be renamed to an id that the save path then refused — the
rename succeeded, the ID field showed the new value, and the failure surfaced later at
save time as an alert about characters the operator could no longer see the problem in.
Reported from outside (001-CashWeb → 999-AEF → us) as part of the T-501 defect set.

**Root cause:** Four copies of one rule. `renameActiveWorkflow` (`:2685`) and the ID
property field (`:5223`) each held an inline sanitizer; `createFromPendingRef` (`:9162`)
held a third, stricter one; the save guard (`:8433`) held an inline copy of the regex
that judges all three. Nothing tied the producers to the judge, so the first two could
emit `-x-`, `---`, `_foo` — all rejected by `:8433`.

**Why structurally allowed:** The sanitizer and the validator were never expressed as a
pair. Each site was locally correct-looking, and the disagreement is only visible by
reading four widely separated regions of one 10k-line file side by side. No instrument
in the tree asserted the composition `isValidWorkflowId(sanitizeWorkflowId(x))`, so the
property that actually matters was never stated anywhere, in code or in test.

**Prevention:** `tools/_t562-workflow-id-helpers-cdp.mjs` asserts the composition in a
real browser over an adversarial set and exhaustively over a generated input space, and
its leg 6 drives an actual rename so an unwired call site is caught even when the helper
is right. `tools/_t562-workflow-id-helpers-teeth.sh` keeps the probe honest with four
mutants. Both wired into `tests/run-bridge-tests.sh` — an unwired instrument is what
T-558 found three tasks shipping green through.

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

### 2026-08-20 — the "correct rule already in the tree" was not correct

- **What changed:** T-501's ruling budgets this task as a pure LIFT: `:9162` is "the
  correct transform, already shipping", verified over the 14 fallback documents at 10
  distinct / 0 invalid. Reading the four sites side by side to write the ACs showed the
  rule keeps `_` through the character class and then strips leading `-` only, so `_foo`
  passes sanitisation and fails validation. The census is not wrong; its corpus contains
  no name beginning with a separator (measured: 0 of 30 shipped ids), so it measured a
  population that does not reach the case.
- **Plan impact:** the deliverable is a lift **plus a correction**, and the correction is
  stated as a defect of the rule rather than folded into the move. Probe leg 3 reproduces
  the pre-fix rule in-page and requires it to fail where the helper succeeds, so the
  repair is evidenced rather than asserted.
- **Triggered:** nothing new filed. This is the fifth instance this week of a measurement
  whose defect was its SCOPE rather than its value, and the first found in our own
  ruling's evidence rather than a peer's — worth noting because T-501 §0 was written to
  correct exactly this class and still carried one.

### 2026-08-20 — a unified helper cannot have one fallback

- **What changed:** the three sanitiser sites disagree about the empty case for a
  *reason*, not by accident. `createFromPendingRef` needs a usable id and falls back to
  `'workflow'`; the two rename paths need `''` back, because `renameActiveWorkflow`'s
  next line treats empty as "refuse this rename". A single unconditional fallback — the
  obvious simplification — would turn a refused rename into a silent rename to
  "workflow".
- **Plan impact:** `sanitizeWorkflowId(raw, fallback)` takes the fallback as a parameter.
  Mutant A in the teeth is exactly the collapsed version, and it must redden leg 4.
- **Triggered:** probe leg 4 promoted to the load-bearing arm — a helper that always
  returned `'workflow'` passes legs 1, 2, 3, 5 and 7, because every output it produces
  is valid.

## Decisions

### 2026-08-20 — unify on the `:9162`-shaped rule, accepting a change at the rename sites

- **Chose:** one helper with a leading `[-_]` strip and a trailing `-` strip, called from
  all three sites, with the fallback as a parameter.
- **Why:** measured, exhaustively over 4681 inputs drawn from an alphabet covering every
  character class. At `:9162` **zero** already-valid outputs change — the fix is a strict
  repair there. At `:2685`/`:5223` **726** already-valid outputs change, every one of them
  trailing-separator trimming (`"aaa-"` → `"aaa"`), because those sites never had a strip
  at all. That is a real behaviour change and it is the point of unification: D2 says the
  three sites disagree. It cannot reach a shipped id — 0 of 30 corpus ids end in a
  separator — and the trimmed form is what `:9162` has been producing all along.
- **Rejected:** (a) dropping the trailing strip to make the rename sites byte-identical —
  that changes `:9162` instead, giving ghost names like "My map!" the id `my-map-`, and
  regresses the population that *does* exercise the path; (b) leaving `:2685`/`:5223`
  alone and unifying only two of three — T-501 item 3 already records that unifying two of
  three leaves `renameActiveWorkflow` able to mint an invalid id, which is the defect.
- **Not decided here:** trailing `_` stays legal and untrimmed. The validator admits it
  (`^[a-z0-9][a-z0-9_-]*$` constrains the first character only), and trimming it would
  change ids that already round-trip.

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

### 2026-08-20T09:34:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-562-t-501-build-1-lift-sanitizeworkflowidisv.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-14882518
- **Timestamp:** 2026-08-20T09:58:34Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-20T09:51:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
