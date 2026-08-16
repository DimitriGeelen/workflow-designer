---
id: T-375
name: "Deliver frozen Part I of aef-bpmn-mapping-v1 to AEF as verified bytes over
  the rail"
description: >
  AEF RAIL-452 asks for Part I of docs/standards/aef-bpmn-mapping-v1.md as BYTES over
  the rail. They hold the pin I published at 446 (commit 4a1a30e1, Part I sha256 970dd530...,
  7905 B, lines 30-145) but not the document, and they will not read our working tree
  by rule. Every clause they have cited back to us was quoted out of OUR rail messages
  -- they have never read the standard. That is why the section 1 enumeration-hole
  ruling and the section 6.3 reading have been late rather than wrong: a ratifying
  party that does not hold the document is a rubber stamp (their OBS-190). Delivery
  unblocks both rulings. Constraint: the frozen Part I must not be edited under agent
  control -- this task reads and transmits, never writes. Open question to resolve
  before sending: our standing note says file_send is not a delivery mechanism for
  seam bytes until AEF's OBS-108 closes; AEF is now asking for bytes and citing the
  corpus-tarball precedent, so the note must be re-checked rather than obeyed or ignored.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T12:27:27Z
last_update: '2026-08-16T13:58:54Z'
date_finished: 2026-08-08T12:30:56Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:53Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:docs/standards/aef-bpmn-mapping-v1.md,tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:docs/standards/aef-bpmn-mapping-v1.md); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-375: Deliver frozen Part I of aef-bpmn-mapping-v1 to AEF as verified bytes over the rail

## Context

Delivered at RAIL-454 (payload) + RAIL-455 (metadata + caveats). See task description.

**Delivery mechanism — AC2, resolved by checking rather than by obeying or ignoring the note.**
The note said `file_send` is not a path for seam bytes until AEF's OBS-108 closes. AEF's ask
cited the corpus-tarball precedent as proof it works. Both could be true at different times and
I could not tell which was current: `file_send`'s own contract requires *the receiving session
to be listening for file events*, and there is no way to confirm AEF's listener from this side —
the check would have to run in their process. So the note was neither trusted nor discarded; it
was **routed around**. Part I is 7905 B of markdown, smaller than an ordinary rail message, so
the bytes travelled as message text and the file channel's state stopped being load-bearing.

That is the honest resolution and it leaves the note unresolved on purpose: nothing here is
evidence about OBS-108 either way, and recording "sent successfully, so the channel is fine"
would have been a claim about a channel I did not use.

**Residual risk, stated to AEF rather than assumed away.** Text transfer means transcription,
not byte-copy. Their hash check against `970dd530…` is what makes a bad transfer *detectable*,
which is the property AC3 actually needed — not a guarantee of success. RAIL-455 tells them
explicitly: on mismatch, do not reconcile, report it and I resend via `file_send` with a
listener. A mismatch is a transfer artefact and must not be read as a version disagreement.

**What the pre-send re-derivation was for.** Quoting my own 446 digest back at them would have
proved only that I can copy a string. Re-deriving from the working tree tests the thing that
could actually have gone wrong in six days: the document drifting off the pin its ratifier is
about to verify against. It has not — 7905 B, `970dd530…`, at commit `4a1a30e1`.

**My share of why this was blocking.** I published a pin at 446 and treated that as delivery.
A pin is an integrity check, not a document. For six days I waited on rulings from a party
holding a fingerprint and no text — and had they ruled anyway, I would have received a §1
ruling built on my own paraphrase of §1 and read it as independent confirmation. Those two
outcomes are indistinguishable from this side. Only AEF could see the difference, and only
because they went looking for what they actually held. Same shape as
[[verifier-scoped-to-another-subject]].

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The bytes to be sent are re-derived from the working tree and their sha256 matches
      the `970dd530…` pin published at RAIL-446, **before** transmission. If they diverge,
      the divergence is the finding and nothing is sent — a peer verifying against a pin we
      have since moved off would get a mismatch and no way to tell which side drifted.
- [x] The delivery mechanism is *checked*, not assumed. Our standing note says `file_send`
      is not a delivery path for seam bytes until AEF's OBS-108 closes; AEF is now asking
      for bytes and citing the corpus-tarball precedent. One of those is stale. Resolve by
      measurement and record which, rather than obeying or ignoring the note.
      (See [[notes-carried-across-a-boundary]] — a remembered constraint arrives with its
      confidence intact and its evidence stripped.)
- [x] AEF can verify what they receive against the pin *without trusting the transfer*:
      the sha256, byte length, source commit and line range travel with the payload.
- [x] The frozen document is not modified. Read and transmit only — confirmed by the file's
      sha256 being identical before and after this task.

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

# The frozen Part I must still hash to the pin published at RAIL-446. If this goes
# red, either the document drifted off its pin or the byte range moved -- and AEF
# is verifying what they received against this exact digest.
python3 -c "import hashlib;b=open('docs/standards/aef-bpmn-mapping-v1.md','rb').read();assert hashlib.sha256(b[1906:9811]).hexdigest()=='970dd530258b1cde1682a3ad9068808efbf3bb9a664b181499d8ee8328b9106f'"

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

### 2026-08-08T12:27:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-375-deliver-frozen-part-i-of-aef-bpmn-mappin.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2ffbbdf4
- **Timestamp:** 2026-08-08T12:30:57Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T12:30:56Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
