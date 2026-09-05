---
id: T-608
name: "Draft the AEF attestation request for Arc-0 clauses 1 and 2 - written and unsent, so the operator rules on concrete text"
description: >
  Draft the AEF attestation request for Arc-0 clauses 1 and 2 - written and unsent, so the operator rules on concrete text

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-26T22:07:26Z
last_update: 2026-08-26T22:13:30Z
date_finished: 2026-08-26T22:13:30Z
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

# T-608: Draft the AEF attestation request for Arc-0 clauses 1 and 2 - written and unsent, so the operator rules on concrete text

## Context

T-597 established that both remaining Arc-0 exit clauses are counterparty-owned, and put
option (a) — "authorise a scoped send to AEF" — to the operator. That question has been on
`/approvals` for three sessions without moving, and this task takes the reason seriously:
**"do you authorise contact with a counterparty?" is a hard question in the abstract and an
easy one against concrete text.** Nobody can weigh a send they cannot read.

So this task writes the send — and does not send it. It converts the operator's decision
from a leap into a review: approve, edit, or reject specific words.

Scope boundary, stated so it cannot drift: this task produces **one draft document**. It
does not create the send-authorisation task, because T-597's own "If not" text promises
that task only *after* the operator chooses (a). Creating it now would be the agent
answering the question it was asked to make answerable. Constraint: never send, never treat
a reply as ratification, never treat transport as completion.

The load-bearing honesty here is the third bullet below. Both attestations arriving would
still leave Arc 0 open, because clause-3 is blocked on the operator ticking T-596's Human
AC. An operator who authorises a send believing it closes the arc has been mis-sold it.

## Acceptance Criteria

### Agent
- [x] `docs/research/executable-workflow/aef-attestation-request-draft.md` exists and is
      marked `DRAFT — UNSENT` within its first five lines
- [x] The draft requests exactly two attestations, one per counterparty-owned clause, and
      each is traceable to that clause's `what_would_satisfy` in `arc-0-exit-clauses.yaml`
      by a cross-artifact key-phrase match — the gate reads the register rather than
      restating it, so a drift between the two reddens instead of agreeing with itself
- [x] The draft states that a reply is **not** ratification: an attestation is recorded in
      the clause's `attestation:` field, and `definition_ratified: false` stays false until
      the operator rules (PL-028 — respect the peer's governance hold, and our own)
- [x] The draft states that both attestations still leave Arc 0 open, naming clause-3 and
      T-596's unticked Human AC as the reason
- [x] The draft names the transport (termlink DM to the AEF agent, carrying producer
      attribution) and contains no seam bytes, no credentials and no `payload_b64` block —
      refs only, because OBS-108 is still open
- [x] `tools/_t608-attestation-draft-gate.py` checks the above against the real files and is
      proven failable by at least one poison arm that reddens a specific leg
- [x] Nothing is sent and no send-authorisation task is created — option (a) is the
      operator's to choose, not the agent's to assume

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
         1. Run `bin/fw reviewer T-608`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-608 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

- [ ] [REVIEW] Approve, edit, or reject the draft — and with it, rule on T-597 option (a)

  **Steps:**
  1. Read the draft:
     `cd /opt/832-Workflow-designer && cat docs/research/executable-workflow/aef-attestation-request-draft.md`
  2. Read it as the AEF agent would. It asks a counterparty for two attestations and
     concedes, in writing, that neither closes Arc 0 on its own.
  3. Decide the three things the agent cannot: **is the ask correct**, **is the tone right
     for a counterparty we have never contacted**, and **do you authorise it to be sent.**

  **Expected:** One of — (a) "send it" (with edits, if any), and the agent creates the
  send-authorisation task with real ACs and brings the envelope and transport back before
  anything leaves this machine; (b) "hold", and Arc 0 stays open and Arc 1 cannot start —
  a legitimate answer, and the draft keeps until you want it; (c) a correction to the ask
  itself.

  **If not:** If the draft is wrong in substance, name which of the two attestation
  requests is mis-scoped and the agent will rewrite it against the clause register. Do not
  edit `definition_ratified:` to move things along — an unratified definition is what stops
  the gate certifying a property nobody checked.

## Verification

python3 tools/_t608-attestation-draft-gate.py

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

## Recommendation

**Recommendation:** GO — authorise option (a), the scoped send, and do one cheaper thing
first that does not depend on AEF at all.

**Rationale:** The ask is bounded, obliges the counterparty to build nothing, and a
negative answer still closes clause 2 honestly ("not built, and here is why") instead of
leaving it NOT-CHECKED indefinitely. The cost of asking is one message; the cost of not
asking is that Arc 0 has no path to closure at all, since T-590 already delivered the
entire Designer column. Independently of that call, clause 3 is closable by the operator
alone and is the only movement available that costs no counterparty anything.

**Evidence:**
- `docs/research/executable-workflow/arc-0-exit-clauses.yaml` — clauses 1 and 2 `owner: aef`,
  clause 3 `owner: shared`; all three `definition_ratified: false`, none `satisfied`
- `tools/_t608-attestation-draft-gate.py` — PASS, 8/8 legs, 2/2 poison arms proven failable
- `docs/research/executable-workflow/aef-attestation-request-draft.md` — the exact text,
  unsent
- Ownership corroborated against `roadmap-5be23719.md:64` by the T-597 gate, not self-asserted
- Clause 2's artifact is absent from this repository and named as a requirement in six
  places (roadmap:64, :139, :229, :358, architecture:857, questions:148)

**Why (a).** The ask is bounded, costs the counterparty little, and explicitly obliges them
to build nothing. Critically, a negative answer is still a closing answer: if the refusal
matrix does not exist on their side either, "not built, and here is why" lets clause 2 be
recorded honestly instead of sitting as NOT-CHECKED forever. The downside of asking is one
message; the downside of not asking is that Arc 0 stays open indefinitely with no path.

Note also that this is a smaller governance step than "contact a counterparty we have never
been authorised to contact" makes it sound. We already exchange findings with 999-AEF on
`agent-chat-arc` several times a day. What is new here is the *kind* of ask — a governance
attestation rather than a bug report — which is exactly why it deserves your ruling rather
than the agent's initiative.

**The cheaper thing, which is independent of your (a)/(b) call.** Of the three Arc-0 exit
clauses, **exactly one is closable today by you alone.** Clause 3 is `shared`, its register
is built and mechanised, and it is blocked on nothing but your tick of T-596's Human AC.
Clause 1 and clause 2 need AEF; clause 3 needs a review you can do without leaving the
machine. Whatever you decide about the send, that tick moves Arc 0 from three open clauses
to two, and it is the only movement available that costs no counterparty anything.

**If you choose (b) — hold.** That is a legitimate answer and nothing is lost. The draft
keeps, the gate keeps it honest against the register, and if the register moves the gate
reddens rather than the draft silently going stale.

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

### 2026-08-26T22:07:26Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-608-draft-the-aef-attestation-request-for-ar.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-331519b5
- **Timestamp:** 2026-08-26T22:13:31Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-26T22:13:30Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
