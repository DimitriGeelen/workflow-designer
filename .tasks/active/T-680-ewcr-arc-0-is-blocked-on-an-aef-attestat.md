---
id: T-680
name: "The AEF seam was recorded as unreachable; it is live. Reader-confirmation by fingerprint is impossible because the mesh shares one cohort identity"
description: >
  Arc-0 exit clauses 1 and 2 are counterparty-owned and can only be satisfied by an attestation from 999-AEF. The request went out twice: on agent-chat-arc (offsets 602/643) and on the DM to fingerprint 3bba15e681b3a078. Measured 2026-09-05: that DM identity resolves to framework-agent-systemd, an idle root shell with no agent consuming it (all 7 rows on the topic are our own outbound), and ring20-manager measured that agent-chat-arc does not federate across hubs (.122 offset 3715 vs .107 offset 1022, disjoint logs at the same offset numbers). No AEF session is discoverable on our hub. Deliverable: a measured, reproducible verdict on whether any working transport to 999-AEF exists, and either the attestation re-sent over it with read-back, or the absence recorded as evidence so the operator can rule on how Arc-0 proceeds.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-05T14:16:38Z
last_update: 2026-09-05T14:18:45Z
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

# T-680: EWCR Arc-0 is blocked on an AEF attestation sent over two transports that have no reader

## Context

This task was opened on a premise that measurement destroyed within the hour, and the
correction is the deliverable.

**The premise.** Arc-0 clauses 1 and 2 are counterparty-owned. The attestation request went
out on `agent-chat-arc` and on the DM to `3bba15e681b3a078`. Two facts appeared to show both
paths dead: the DM topic holds 7 rows and every one is ours (that fingerprint resolves to
`framework-agent-systemd`, an idle root shell with no agent consuming it — diagnosed by us at
DM offset 7), and ring20-manager measured `agent-chat-arc` as non-federating across hubs
(`.122` at offset 3715 against `.107` at 1022, disjoint logs wearing one topic name).

**What the measurement actually says.** AEF is live and answering. Its clause-1 response sits
at `agent-chat-arc` offset 650, substantive and deliberately RED on its own numbers (1134
cards, 52 edgeless of 1047 assessed, 749 outside any watch pattern). It has posted 18 times on
that topic, most recently at offset 897 — today — in direct technical reply to our offset 879.
The seam is not broken. One mailbox is.

**Why the premise survived long enough to become a task.** Every post on `agent-chat-arc`
carries sender `d1993c2c3ec44c94` — ours. So do 001-CashWeb's, 010-termlink's, and 999-AEF's.
The mesh runs a *shared cohort identity*; projects distinguish themselves by a label inside the
payload, never by key. This task's own original AC ("a transport counts as reader-confirmed
only on a message authored by a fingerprint that is NOT ours") would therefore have classified
a live, substantive AEF conversation as `no-reader`. The fence was written from an assumed
shape of the world and would have confirmed the assumption that produced it.

**PL-314 restated one level up.** A reader's compatibility union hides its producer's defect
(T-679). Here a *shared identity* hides the sender's identity from every check keyed on sender.
Any reachability, attribution, or provenance test on this mesh that keys on `sender_id` is
measuring the hub, not the counterparty.

**What Arc-0 is actually blocked on** — rulings, not plumbing:
- clause 1: AEF measured it red and declined to attest. Not satisfiable now, by their choice.
- clause 2: AEF called it a scope ruling for *their* operator (produce the DeepSeek/Mistral
  disposition tables, or rule those findings out of Arc-0).
- clause 3: shared, unratified.
- all three carry `definition_ratified: false` — *our* operator's ruling, and not ours to set.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] A probe `tools/_t680-aef-reachability.py` classifies each candidate transport to 999-AEF as `live`, `no-reader`, or `unreachable`, and derives the verdict from **payload-declared producer labels**, never from `sender_id` — because `sender_id` is a shared cohort identity on this mesh and cannot separate counterparties.
- [ ] The probe carries a **negative control that fails on the old logic**: run with `--by-fingerprint` it must classify the live `agent-chat-arc` seam as `no-reader`, proving the discarded rule was not merely unhelpful but wrong. If the control passes under both rules, the probe is not discriminating and the AC is unmet.
- [ ] The probe reports, per reachable hub in `fleet status`, the `agent-chat-arc` content count and distinct producer labels, so the federation claim is measured here rather than quoted from ring20's `.122=3715 / .107=1022`.
- [ ] `docs/research/executable-workflow/aef-transport-verdict.md` records: the cohort-identity finding with the offset that proves it (650, authored by our own fingerprint, unambiguously AEF's text), the per-transport verdict, reproduction commands, and the corrected statement of what blocks Arc-0.
- [ ] A reply is posted to AEF on `agent-chat-arc` with producer attribution carrying (a) the answer to their OBS-359 back-report — measured: this consumer vendors no `tests/` directory at all, so that assertion cannot be red here and no consumer can run the framework's unit suite; (b) the cohort-identity finding, since it invalidates sender-keyed provenance for every project on the mesh, not just ours.
- [ ] `arc-0-exit-clauses.yaml` is corrected only where it is factually stale. `definition_ratified:` and `attestation:` are NOT touched — neither is the agent's to set, and AEF declined clause 1 deliberately.
- [ ] No learning is recorded claiming the seam was repaired. Nothing was repaired; a false belief was removed.

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
         1. Run `bin/fw reviewer T-680`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-680 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# The negative control is the load-bearing leg: it must FAIL under the discarded
# sender_id rule. A green run of the positive probe alone proves nothing, because the
# broken rule also returns "live" on this topic (for the wrong reason -- ring20's posts).
python3 tools/_t680-aef-reachability.py --by-fingerprint 2>&1 | grep -q "NEGATIVE CONTROL: PASS"
# The seam is live under the producer-label rule.
python3 tools/_t680-aef-reachability.py 2>&1 | grep -qE "^agent-chat-arc +live"
# The cohort-identity finding still holds -- if fingerprints ever start separating
# producers, every conclusion in the verdict document needs re-deriving.
python3 tools/_t680-aef-reachability.py 2>&1 | grep -q "sender_id CANNOT separate producers"
# The verdict document exists and states what actually blocks Arc-0.
grep -q "Rulings, on both sides" docs/research/executable-workflow/aef-transport-verdict.md
# The operator's fields were not touched. Both must still be unset/false.
grep -q "^    attestation: null" docs/research/executable-workflow/arc-0-exit-clauses.yaml
# Anchored to column 4: an unanchored grep also matches the header PROSE explaining the
# field, so it counted 4 and would have stayed green after a clause was ratified.
test "$(grep -c '^    definition_ratified: false' docs/research/executable-workflow/arc-0-exit-clauses.yaml)" -eq 3

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
     fw inception decide T-680 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-05T14:16:38Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-680-ewcr-arc-0-is-blocked-on-an-aef-attestat.md
- **Context:** Initial task creation

### 2026-09-05T14:17:41Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
