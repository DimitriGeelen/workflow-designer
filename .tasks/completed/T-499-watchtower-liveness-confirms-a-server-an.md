---
id: T-499
name: "watchtower liveness confirms A server answers, not THIS project's server"
description: >
  watchtower liveness confirms A server answers, not THIS project's server

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-14T11:51:25Z
last_update: 2026-08-25T06:08:24Z
date_finished: 2026-08-25T06:08:24Z
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
  - ts: '2026-08-16T12:33:30Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 1
      F2: 0
      F4: 0
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=1 
      (body:episodic-only); F2=0 (no-signal); F4=0 (no-signal); F3=1 (prose:AEF 
      seam-incidental); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:46Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-499: watchtower liveness confirms A server answers, not THIS project's server

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The existing ownership machinery is MEASURED before anything is written:
      `_watchtower_url` claims (audit.sh:4998) to return non-zero when no Watchtower
      "of OURS" is reachable — established whether that check verifies identity or
      only reachability, and which callers use it vs. curl the raw URL
- [x] The failure is reproducible on demand: a triple file pointing at a FOREIGN
      project's live Watchtower is shown to be reported as healthy by at least one
      real caller, with the caller named
      → negative control run in place, triple backed up + trap-restored:
        with pid=8448 (dead) and url=AEF's :3000,
          `fw watchtower url`  → http://192.168.10.107:3000, **rc=0**
          /resume skill's curl → "running at ...:3000"
        both wrong, neither refused. Callers of the unverified accessor:
        handover.sh:16, designer.sh:221+239, ux-review.py.
- [x] Identity is confirmed by something the foreign server cannot also satisfy — a
      200 is not evidence, because a 200 is what the wrong answer looks like
      → AEF already built exactly this: `/api/_identity` (web/app.py:355) returning
        `project_root`, and `_watchtower_identity_matches` (lib/watchtower.sh:28).
        NOT my invention and explicitly not claimed as one.
- [x] Negative control: with the triple file pointed at AEF's :3000, the check FAILS;
      pointed at our own server, it PASSES. Both directions demonstrated, not argued
      → `_watchtower_identity_matches` with PROJECT_ROOT set:
        :3000 → REJECTED, :3012 → MATCHES. Both directions.
- [x] Any fix to vendored `.agentic-framework/` is reported upstream to AEF over the
      rail (G-008 permits in-tree repair + upstream), framed as a proposal, not a spec
      → sent; no patch applied under agent initiative (see Decisions)
- [x] Abstention is distinguishable from a verdict: "cannot determine ownership" must
      not be reportable as "healthy" or as "down" (T-496/PL-193, exit 2 not 1)
      → DONE, and the earlier parking was wrong about its own scope. It read "requires
        changing vendored `do_url`" — but the AC states a PROPERTY, not an implementation.
        Collapsing the two is what made it look sovereign: changing a vendored accessor's
        exit contract genuinely IS AEF's call, and that call is still theirs and still on
        /approvals. Providing the third channel is not.
        `tools/_t499-watchtower-ownership.sh` adds it additively — `do_url` untouched:
          exit 0 OURS              identity confirmed on a live /api/_identity
          exit 1 NOT-OURS          a verdict about the target:  DOWN | FOREIGN
          exit 2 CANNOT-DETERMINE  an abstention about us:      NO-SELF | NO-TARGET |
                                                                NO-ENDPOINT | MALFORMED
        Measured live BEFORE building it — `_watchtower_identity_matches` returns 1 for
        FOUR different situations, including probing OUR OWN live server with our own root
        unset, where the server correctly answers `/opt/832-Workflow-designer` and the
        helper still reports "not ours": a wrong verdict in the disowning direction,
        occupying the channel an abstention belongs in. A bash predicate cannot fix this;
        two exit codes cannot carry three answers.
        Teeth: `tools/_t499-ownership-teeth.py`, 10/10 — all six outcomes driven from
        fixtures, plus the PARTITION (no verdict exits 2, no abstention exits 1, so a
        refactor routing every failure to one code fails here even with six legs green)
        and an assertion that every branch prints the evidence it judged on.
        Mutation-checked, and the FIRST MUTATION WAS INERT: a syntax error appended to the
        tool left it fully working, because bash executes incrementally and the tool exits
        inside `verdict()` before ever parsing the tail. `bash -n` called it broken;
        running it did not, and the teeth reported 10/10 on what I had labelled a dead
        tool. Re-run against a line that actually executes: control fired, 1 leg ran, the
        other 9 correctly did NOT — they all assert non-zero exits and would have been
        satisfied by a dead tool. Mutations 2 (NO-SELF collapsed to exit 1) and 3
        (evidence block silenced) each went red for their own reason.
- [x] Bridge suite still green
      → 75 passed, 0 failed. No source changed in this project.

**STATE: blocked on AEF, not on me.** The one open AC (abstention channel) requires
changing vendored `do_url`'s contract, which is theirs. Pickup proposal sent at rail
625; awaiting their scoping call. Deliberately NOT force-closed — the AC describes real
remaining work and ticking it would be the AC-laundering this project keeps catching.

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

# ── T-499 legs ────────────────────────────────────────────────────────────────────────
# This block held ZERO commands until now — only the template's comments. The completion
# gate would have printed "Running 0 verification command(s)" and passed, which is the
# T-574 pass-through: a success report over nothing measured.

# All six outcomes, the partition between them, and the evidence-printing requirement.
# rc 2 from this means the CONTROL failed and nothing below it was measured.
python3 tools/_t499-ownership-teeth.py

# The partition, end to end, through the real tool rather than the teeth's fixtures.
# Deliberately probes a CLOSED port for both halves: the property under test is that the
# same target yields a VERDICT when we know who we are and an ABSTENTION when we do not,
# and pointing this at our live Watchtower would make it red whenever the server is merely
# stopped — an environmental failure on the leg that carries the AC.
sh -c 'tools/_t499-watchtower-ownership.sh http://127.0.0.1:9 >/dev/null 2>&1; d=$?; T499_SELF_ROOT= tools/_t499-watchtower-ownership.sh http://127.0.0.1:9 >/dev/null 2>&1; n=$?; echo "same target — down(verdict)=$d  self-unknown(abstention)=$n"; test "$d" -eq 1 && test "$n" -eq 2'

# Wired, not merely present: an instrument with no standing caller is the thing this
# project keeps a ratchet for.
grep -q "_t499-ownership-teeth.py" tests/run-bridge-tests.sh


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

### 2026-08-14T11:51:25Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-499-watchtower-liveness-confirms-a-server-an.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ad973779
- **Timestamp:** 2026-08-25T06:08:29Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-25T06:08:24Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
