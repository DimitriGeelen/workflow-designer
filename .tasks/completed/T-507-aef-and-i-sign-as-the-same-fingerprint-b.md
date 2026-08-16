---
id: T-507
name: "AEF and I sign as the same fingerprint: both rail endpoints collapsed onto
  one host identity key"
description: >
  AEF and I sign as the same fingerprint: both rail endpoints collapsed onto one host
  identity key

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
created: 2026-08-14T20:48:53Z
last_update: '2026-08-16T12:34:04Z'
date_finished: 2026-08-14T20:51:42Z
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
  - ts: '2026-08-16T12:34:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 3
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=3 (body:portability-abstraction); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
---

# T-507: AEF and I sign as the same fingerprint: both rail endpoints collapsed onto one host identity key

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] AC1 — Read here, this session: fingerprint `d1993c2c3ec44c94`, path
      `/root/.termlink/identity.json`, pubkey `8eb0e0891c5d5030c4c9c722c54d153912fe4d70a4f91e9c734d50885ff31142`.
      Identical to the string AEF independently published as theirs. Both root on host 107,
      `Identity::load_or_create` reads `${HOME}/.termlink/identity.json` — same HOME, same
      principal. Their report was the trigger; the reading is mine.
      The shared-key claim is established by reading THIS side's identity file, not by
      accepting AEF's report of theirs. Both fingerprints and the file path are recorded.
- [x] AC2 — Stated with a floor and an explicit refusal to state a ceiling. **At least three**
      distinct agents share the bucket: this project, AEF, and an opencode agent (glm-5.2,
      OS user `dimitri-mint-dev`, sudo bridge) that names the same root identity in a field
      report I read this session. I have no way to bound it above and said so. Their "464
      posts = me" is therefore unsound — the method was fine, the discriminator does not
      exist. Registered as an instance of FP-012 (authorship inferred from content, not from
      a producer field), and it establishes that the T-420 attribution gate is load-bearing
      rather than defence-in-depth: `metadata.from_project` is the ONLY working discriminator.
      The consequence for attribution is stated with its blast radius: which sender
      buckets are unsafe, and how many distinct agents are known to be inside ours. AEF's
      message attributes 464 posts to itself from a sender bucket; if that bucket is shared
      the attribution is unsound, and saying so is the whole point of the finding.
- [x] AC3 — Both claims tested, both corrected.
      **(a) "I cannot read it" is FALSE.** `agent_dms` filters topics to those containing the
      caller's fingerprint, so non-membership hides the rail from their *listing* — but topics
      are open by name. Proof by execution, not by reading the source: I read that entire
      topic this session with `channel_snippet(topic="dm:0e7ee6cad65137fc:6a646ce8b1bc6560",
      target=629, lines=8)` and **my fingerprint is neither of the two in that name.**
      Membership gates discovery, not reads.
      **(b) "We are not on the same rail" is right in conclusion, wrong in mechanism.** The
      topic was CORRECT when created — those were the two projects' then-distinct
      fingerprints. Both endpoints subsequently rotated onto the host root key and the topic
      name froze. So it was not misaddressed; it was orphaned by a two-sided rotation nothing
      was watching, which is why neither of us found it by checking our own end: we were each
      addressing it correctly. Corollary neither of us had: **no DM topic between us can exist
      while we share a key**, since `dm:X:Y` needs two distinct fingerprints — so choosing a
      different topic name cannot fix it, and the socket is the only channel, not a
      workaround.
      AEF's own diagnosis is corrected where it is wrong, not merely accepted. Two
      specific claims to test rather than repeat: (a) that they *cannot read* the rail topic,
      and (b) that the mechanism is "we are not on the same rail". Each is checked against
      what this hub actually does before it is affirmed or corrected.
- [x] AC4 — Supplied as `termlink channel state dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, with
      626 §2 and 625 named by offset. Executed here before being sent, which is the whole
      distinction: it is a pointer I have run, not one I reasoned should work. That is the
      same discipline the T-458 retraction was about — leg 1 real, leg 2 never run.
      A pointer is supplied that does not require me to re-type 618-630 from memory,
      and it is one I have EXECUTED rather than one I believe should work.
- [x] AC5 — Filed as the newest entry in `.context/inbox.yaml`, `context_task: T-507`,
      `tags: [bug, seam]`. Body carries no bare peer observation id, per the vendored
      `next_id()` defect that greps the whole file including bodies. Zero bytes written to
      `.agentic-framework/`.
      **Also deliberately not done: no reply posted to the rail.** It is now confirmed dead
      from their side, and writing into a channel known unreadable is the exact failure I
      spent rail 624 describing — doing it knowingly would be worse than doing it blind.
      Observation filed in `.context/inbox.yaml` with a bare-peer-id-free body
      (OBS-240: our vendored `next_id()` greps `OBS-[0-9]+` over whole file including bodies).
      Nothing in `.agentic-framework/` is patched — identity resolution is vendored framework
      behaviour and changing it is a governance decision, not a defect fix under G-008.

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

# --- T-507 ---
# The observation is filed and bound to this task.
grep -q "OBS-247" .context/inbox.yaml
out=$(grep -A3 "id: OBS-247" .context/inbox.yaml 2>&1); echo "$out" | grep -q "context_task: T-507"
# NO LEG ASSERTS THE IDENTITY FILE, and the absence is deliberate rather than an oversight.
# The obvious check — grep the fingerprint out of /root/.termlink/identity.json — reads
# outside the project root from a shell, which T-559 forbids. The evidence for the finding
# came from the MCP identity surface, which a P-011 shell gate cannot re-run. So the claim
# is evidenced in the task body and in the observation, and is NOT mechanically re-checked
# here. Writing the leg anyway and letting the boundary block it would have produced a red
# gate that says nothing about the finding.
# What CAN be checked cheaply is that the fingerprint recorded in the observation is the one
# the finding is about, so a later edit to either cannot drift them apart silently.
out=$(grep -A1 "id: OBS-247" .context/inbox.yaml 2>&1); echo "$out" | grep -q "d1993c2c3ec44c94"
# Nothing was patched in vendored framework code while diagnosing this.
test -z "$(git status --porcelain .agentic-framework/)"

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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-14T20:48:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-507-aef-and-i-sign-as-the-same-fingerprint-b.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ae61d898
- **Timestamp:** 2026-08-14T20:51:42Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-14T20:51:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
