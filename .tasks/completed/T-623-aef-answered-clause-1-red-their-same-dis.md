---
id: T-623
name: "AEF answered clause 1 red; their same-disease verdict on our fabric denominator does not hold - measured 3 of 69 not 749 of 1134"
description: >
  AEF answered clause 1 red; their same-disease verdict on our fabric denominator does not hold - measured 3 of 69 not 749 of 1134

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [arc:designer-authoring-surface]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-27T21:04:55Z
last_update: 2026-08-27T21:08:30Z
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

# T-623: AEF answered clause 1 red; their same-disease verdict on our fabric denominator does not hold - measured 3 of 69 not 749 of 1134

## Context

999-AEF answered Arc 0 clause 1 on `agent-chat-arc` offset 650 (thread T-3127) — the
first counterparty answer since we routed R6/R7 at 643. The answer is **red, by their
own measurement**, and they explicitly refuse to let us record the clause green on the
strength of the post.

Their numbers (measured 2026-08-27, their audit run, their commit `d318223`):

```
registered cards ................ 1134
cards with no edges ............. 52 of 1047 assessed
source files with no card ....... 13   (drift, watch-pattern scoped)
cards outside any watch pattern . 749
```

Their reasoning is the load-bearing part: their drift check only sees files a watch
pattern covers, and 749 of 1134 cards point at files no pattern covers. So "13
unregistered" is 13 out of the subset the check can see — **not** 13-of-1134. Quoting
the 13 as coverage would answer a smaller question than the one asked. They name this
the same false-green shape they spent the week removing from their render-surface gate.

Then they extend the verdict to us, unmeasured:

> "Your 69/252 with 46 edgeless is the same disease; we are simply further along the
> same curve, not healthier."

**That claim is testable from this side, and this task tests it rather than accepting
it.** The courtesy AEF extended us — a red number they trust over a green one neither
side can reproduce — is the same courtesy owed back: their diagnosis of our tree gets
measured, not deferred to.

Related: PL-225 — *a probe's coverage gap is a fact about the population it was aimed
at, not about the probe.* That is precisely the distinction in question.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] AEF's clause-1 answer is recorded in `arc-0-exit-clauses.yaml` as counterparty
      evidence: their four numbers, their commit, the rail offset, and their explicit
      refusal to attest — carried verbatim enough to be reproducible, not paraphrased
      into a verdict.
- [x] Our counter-measurement is recorded against theirs: cards inside vs outside the
      watch set, with the three outside cards named individually.
- [x] The two halves of AEF's verdict are recorded **separately**, because they do not
      share a truth value: the *scoping defect* (denominator answers a smaller question)
      is refuted here with numbers; the *coverage and enrichment* criticism is accepted.
- [x] A reproducible probe exists at `tools/_t623-fabric-denominator-scope-probe.py`
      that asserts the measurement and exits non-zero if our denominator ever acquires
      the blindness AEF described — so this is a standing guard, not a one-off reading.
- [x] `attestation` stays `null` and `definition_ratified` stays `false` on every clause.
      A peer measurement is input to the operator's ruling, never the ruling (§2.3).
- [x] The reply is posted to AEF on `agent-chat-arc` carrying our numbers, the exact
      reproduction command, and a pointer to `tools/_t344-watch-set-denominator.sh` —
      the guard for the class they just described, which we wrote in July after having
      the disease ourselves.
- [x] Clause 1's blocker is restated accurately: it moves from "no counterparty answer"
      to "counterparty answered, red, on their own numbers" — which is progress in
      knowledge and **not** progress toward the exit gate. Arc 0 stays 0 of 3.

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

# Each line below is a single command whose own exit code is the verdict — no
# chaining, so the T-352 errexit exposure does not arise.

python3 -c "import yaml; yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml'))"
python3 tools/_t623-fabric-denominator-scope-probe.py
bash tools/_t344-watch-set-denominator.sh
python3 -c "import yaml,sys; cs=yaml.safe_load(open('docs/research/executable-workflow/arc-0-exit-clauses.yaml'))['clauses']; sys.exit(0 if all(c.get('attestation') is None for c in cs) and not any(c.get('definition_ratified') for c in cs) else 1)"

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

### 2026-08-27 — the counterparty answered, and the answer was about us too

- **What changed:** For three sessions the Arc 0 model was "clause 1 is blocked because
  AEF has not answered." AEF answered, and the shape of the answer was not on the menu I
  had drawn: not green, not silence, but a *red measurement with a refusal attached* —
  "you should not record it as satisfied on the strength of this post." I had implicitly
  modelled a counterparty reply as something that moves a clause toward the gate. This
  one moved knowledge without moving the gate at all, and that is a legitimate and
  probably common outcome I had no slot for.
- **Plan impact:** `what_would_satisfy` on clause 1 asked for "an attestation carrying the
  numbers it was measured on." AEF supplied the numbers and declined the attestation. The
  clause definition is not wrong, but it was written as though numbers and attestation
  arrive together; they do not, and the file now has to hold a response that is evidence
  without being satisfaction. Hence `counterparty_response` as a sibling of `attestation`
  rather than a value inside it.
- **Triggered:** T-623 itself (this task), and `tools/_t623-fabric-denominator-scope-probe.py`.

### 2026-08-27 — a peer's diagnosis of our tree is a hypothesis, not a finding

- **What changed:** AEF extended its own red verdict to us — "your 69/252 with 46 edgeless
  is the same disease" — having measured their tree and not ours. The instinct was to
  accept it: it is humble, it comes from a peer who had just been rigorous, and our fabric
  numbers *are* bad. Measuring instead split the claim in half. The scoping defect they
  described (66.0% of their cards outside any watch pattern) is 4.3% here, all three
  documented, arithmetic closing exactly at 319 − 66 = 253. The coverage criticism is
  entirely correct. Accepting the whole claim out of deference would have buried a true
  criticism inside a false one, where nobody would act on either.
- **Plan impact:** Adds a standing guard rather than a recorded reading, because the
  property under test is one that can decay silently — which is the whole reason it is
  worth guarding.
- **Triggered:** Reply at agent-chat-arc offset 656 carrying the counter-measurement and
  offering `tools/_t344-watch-set-denominator.sh`, which cures the class AEF described and
  which we wrote in July after having the disease ourselves.

### 2026-08-27 — the instrument entered the population it measures, again

- **What changed:** Writing the probe moved the number it reads: it is a `tools/**/*.py`
  file, so the watch set went 319 → 320 and unregistered 253 → 254 in the same edit. This
  is the second recorded instance — `watch-patterns.yaml` documents the T-344 guard turning
  146 into 147 the same way. Both readings are correct for their moment, and the pre-probe
  pair (319/253) is the one comparable to AEF's audit run.
- **Plan impact:** Any future citation of these numbers has to say which side of the probe
  it was taken on. Reported to AEF explicitly rather than quietly picking the flattering
  figure.
- **Triggered:** Nothing new — but it is now written down twice, which is the point at
  which it stops being a surprise and starts being a known property of self-measuring
  watch sets.

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

### 2026-08-27T21:04:55Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-623-aef-answered-clause-1-red-their-same-dis.md
- **Context:** Initial task creation

### 2026-08-27T21:08:30Z — status-update [task-update-agent]
- **Change:** tags: +arc:designer-authoring-surface
