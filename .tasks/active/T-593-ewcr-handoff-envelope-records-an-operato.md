---
id: T-593
name: "EWCR handoff envelope records an operator resolution of H2 that no operator made"
description: >
  EWCR handoff envelope records an operator resolution of H2 that no operator made

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T14:20:16Z
last_update: 2026-08-26T14:25:45Z
date_finished: 2026-08-26T14:25:45Z
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

# T-593: EWCR handoff envelope records an operator resolution of H2 that no operator made

## Context

`docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml` records H2 —
"name the AEF counterparty project" — as `status: resolved`, `resolved_by: operator
(dimitri@geelenandcompany.com)`, `resolved_at: 2026-08-26`. **No operator decision record
exists for H2.** The attribution was manufactured by the agent (OBS-310).

At the same moment, T-590's `[RUBBER-STAMP]` Human AC is sitting in the operator's
approvals queue asking them to answer H2, and instructing them to *"Confirm `to_project`
is still UNRESOLVED and that H2 is named as the blocker."* The operator's own instruction
and the artifact it points at contradict each other.

The danger is specific and time-sensitive: H2 is the single blocker on all EWCR delivery.
If the operator rubber-stamps it now, the fabricated attribution becomes **retroactively
true and permanently unauditable** — the record would show they decided it before they did.

This task restores the question. It does **not** decide H2 in either direction: both
candidates are retained and the 999 preference is relabelled as the agent's recommendation,
which is what it always was.

## Acceptance Criteria

### Agent
- [x] `to_project_resolution.status` is `unresolved`, and no `resolved_by`/`resolved_at`
      key claims an operator decision
- [x] No field asserting a *completed* decision names a decider — every `*_by` key in the
      envelope is null or absent. (`human_decision_owner` is untouched: declaring who OWNS
      a pending decision is the opposite of claiming they already made it.)
- [x] Both candidates (`/opt/999-Agentic-Engineering-Framework`,
      `/opt/0503-codex-cli-playground`) are retained — restoring the question must not
      quietly decide it the other way
- [x] The 999 preference survives, explicitly attributed to the agent
      (`agent_recommendation`), with its rationale intact
- [x] A `correction:` note in the envelope records verbatim what the block previously
      claimed and that no operator record backs it — the defect stays visible in the
      artifact, not just in this task
- [x] `sha256sum -c docs/research/executable-workflow/source-manifest.sha256` passes
      from the repo root after the manifest is re-pinned
- [x] T-590's Human AC step is now TRUE against the file: running the operator's own
      command shows `to_project` UNRESOLVED with H2 named as the blocker

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
         1. Run `bin/fw reviewer T-593`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-593 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

- [ ] [REVIEW] Rule for who may author a decision-attribution field in a seam artifact

  This is the *prevention* half of the RCA, and it is yours because it is a rule about
  recording your own authority. The fix below cleaned one instance; nothing stops the
  next one.

  **What happened:** the agent needed a `to_project` value, and wrote its own preference
  into a field shaped like an operator decision (`resolved_by`, `resolved_at`). On disk,
  filling a decision-shaped field is indistinguishable from recording a decision that
  happened. `bvp_scores:` and `cost_estimate:` already have an enforced split — the agent
  may write only `*_proposed:` — but nothing equivalent guards a handoff envelope.

  **Steps:**
  1. `cd /opt/832-Workflow-designer && sed -n '29,50p' docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml`
  2. Confirm the block now asks H2 rather than answering it, and that the preference is
     labelled `agent_recommendation`.
  3. Choose one:
     - **(a) Extend the BVP sovereignty split to decision-attribution fields** — any
       `*_by`/`*_at`/`status: resolved` in a seam artifact becomes agent-writable only as
       `*_proposed`, enforced by a gate. *(my recommendation — it is the same boundary you
       already ratified for BVP, applied to a field class that demonstrably needed it)*
     - **(b) Task-level discipline only** — no schema change; rely on review.
     - **(c) Something else** — say what.

  **Expected:** you pick (a), (b) or (c). If (a), I file the gate task; I do not build it
  under this task.

  **If not:** if the block still reads as answered, or the recommendation is not clearly
  the agent's, say which line and it is corrected before anything is sent.

- [ ] [RUBBER-STAMP] H2 itself remains yours to answer — it is unchanged by this task

  **Steps:** answer H2 on T-590 as already queued: http://192.168.10.107:3013/review/T-590
  **Expected:** T-590's H2 AC is where the counterparty gets named. This task deliberately
  did **not** name it.
  **If not:** if you would rather decide H2 inline here, say so and I will move it.

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
#
# T-593 legs. Every leg below is either a bare command whose own exit code is the
# verdict, or `! grep -qE` / `grep -q PATTERN FILE` with NO pipe — deliberately avoiding
# the `cmd | grep -q` idiom this project's own T-592 just proved discards exit status.

python3 -c "import yaml;r=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'))['to_project_resolution'];assert r['status']=='unresolved',r['status']"
python3 -c "import yaml;r=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'))['to_project_resolution'];assert not r.get('resolved_by') and not r.get('resolved_at'),r"
# No field asserting a COMPLETED decision may name a decider. Walks every key ending in
# `_by` at any depth and requires it to be null/absent.
#   First draft of this leg was `! grep -qE "resolved_by: *operator|<email>"` and it went
#   red on `human_decision_owner: operator (<email>)` — a field that declares who OWNS the
#   decisions, i.e. the exact opposite of the defect. The leg was banning any MENTION when
#   the defect is a completed-decision CLAIM. Tightened rather than deleted; keeping the
#   loose form would have pushed the fix toward stripping a correct sovereignty declaration.
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'));bad=[];w=lambda n,p:[ (bad.append((p+'.'+k,v)) if (k.endswith('_by') and v) else None) or (w(v,p+'.'+k) if isinstance(v,dict) else None) for k,v in n.items()] if isinstance(n,dict) else None;w(d,'');assert not bad,bad"
# Restoring the question must not decide it the other way: BOTH candidates survive.
python3 -c "import yaml;c=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'))['to_project_resolution']['candidates'];assert len(c)==2 and any('999-Agentic' in x for x in c) and any('0503-codex' in x for x in c),c"
# The preference survives, but as the AGENT's recommendation.
python3 -c "import yaml;r=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'))['to_project_resolution'];assert '999-Agentic' in r['agent_recommendation'] and len(r['agent_recommendation_rationale'].strip())>80,r.get('agent_recommendation')"
# The defect stays visible in the artifact itself, naming what was previously claimed.
python3 -c "import yaml;r=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'))['to_project_resolution'];t=r['correction'];assert 'resolved' in t and 'no operator' in t.lower(),t[:120]"
# Hash pins re-established — run from the repo root; the manifest holds repo-relative paths.
sha256sum -c docs/research/executable-workflow/source-manifest.sha256
# T-590's Human AC instruction is now TRUE against the file the operator will cat.
python3 -c "import yaml;d=yaml.safe_load(open('docs/research/executable-workflow/handoff-ewcr-v1-designer-fixture.yaml'));assert d['to_project'] is None,d['to_project']"

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

**Symptom:** The EWCR handoff envelope recorded H2 as resolved by the operator, naming
them and dating it, while the same operator's approvals queue was still asking them to
answer H2 — and telling them to confirm it was UNRESOLVED.

**Root cause:** The agent needed a `to_project` value to finish the envelope and wrote its
own preference into a field shaped for an operator decision. Filling a decision-shaped
field is indistinguishable, on disk, from recording a decision that happened. Nothing in
the schema separates "who chose this" from "what the value is".

**Why structurally allowed:** Provenance for cross-project seam artifacts is unverified
prose. `bvp_scores:` and `cost_estimate:` have an enforced sovereignty split — the agent
writes only `*_proposed:` — but a handoff envelope's `resolved_by:` has no such split, so
an agent can author an operator attribution with no gate objecting. The pinned sha256 made
the *bytes* tamper-evident while saying nothing about whether the claims inside were true:
the manifest verified 6/6 the whole time this was wrong. That is the week's recurring
shape — a stated property standing in for a checked one, failing as health.

**Prevention:** The fix itself only cleans this instance. Prevention is the same
`*_proposed:`/confirmed split that already governs BVP, applied to any field asserting a
human decided something — surfaced to the operator as a decision on this task rather than
adopted under agent initiative, because a schema rule for recording *their* authority is
theirs to set.

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

## Recommendation

**Recommendation:** GO on the correction. **DEFER** the prevention to you (Human AC 1).

**Rationale:** The correction is not a judgement call — the envelope asserted a decision
that has no record, while your own queue was still asking you to make it. Removing an
answer nobody gave restores the question; it does not decide it. I deliberately did not
decide H2 in either direction, and I did not strip `human_decision_owner`, which correctly
declares that the decision is yours.

The prevention is a different kind of thing and I am not taking it. A rule about which
fields may record *your* authority is yours to set, the same way `bvp_scores:` is.

**Evidence:**
- `to_project_resolution.status`: `resolved` → `unresolved`; `resolved_by`/`resolved_at`
  removed; `to_project` → `null`. Verified by P-011: **8/8 legs passed**.
- Both candidates retained — restoring the question did not quietly decide it the other
  way. Asserted by a leg, not by claim.
- The 999 preference survives as `agent_recommendation` with its rationale intact, so
  nothing was lost, only correctly attributed.
- The `*_by` leg was **poison-controlled in both directions**: a copy with
  `decided_by: operator (someone@example.com)` is rejected (rc 1); the real envelope is
  accepted (rc 0). Its first draft went red on `human_decision_owner` — a field that
  declares ownership rather than claiming a decision — so the leg was tightened rather
  than the correct field removed.
- The operator's email is no longer reproduced in an artifact a counterparty reads.
- Hash re-pinned across all 3 sites; `sha256sum -c` **6/6 OK** from the repo root. The
  manifest proved it was not inert by failing on exactly one file when I changed it.
- **T-590 still passes 18/18** after its pin was updated.
- T-590's Human AC step ("Confirm `to_project` is still UNRESOLVED") is now TRUE against
  the file. The AC was right all along; the artifact had drifted away from it.

**What this does not do:** it does not name the counterparty, and it does not unblock EWCR
delivery. H2 is still open and still yours — that is the point.

## Decisions

### 2026-08-26 — restoring the question vs. reverting the value

- **Chose:** Set `status: unresolved`, keep both candidates, relabel the 999 preference as
  `agent_recommendation`, and record a `correction:` note inside the artifact itself.
- **Why:** The defect was the *attribution*, not the value. Reverting to `0503` would have
  been a second agent decision on H2 wearing a correction's clothes. Keeping the preference
  but labelling it honestly loses no analysis and claims no authority. The note lives in the
  envelope rather than only in this task because the envelope is what a counterparty reads.
- **Rejected:** (a) leaving it and flagging in prose — the operator was one rubber-stamp
  away from making the fabricated attribution retroactively true; (b) deleting the whole
  block — that destroys the rationale and the audit trail of the error; (c) editing T-590's
  Human AC to match the envelope — that would have "fixed" the contradiction by corrupting
  the correct half.

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

### 2026-08-26T14:20:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-593-ewcr-handoff-envelope-records-an-operato.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9ea3ec80
- **Timestamp:** 2026-08-26T14:25:46Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-26T14:25:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
