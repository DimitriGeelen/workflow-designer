---
id: T-456
name: "P-011 strips HTML comments from the Verification COMMAND text, mangling any
  command containing the markers"
description: >
  update-task.sh:981 runs re.sub(r'<!--.*?-->', '', text, flags=DOTALL) over the Verification
  block before executing each line. That is correct for stripping commented guidance,
  but it also rewrites EXECUTABLE commands: any verification line containing both
  markers has everything between them deleted. Discovered live 2026-08-12 while completing
  T-453, whose leg 2 was a comment-stripping assertion. The gate echoed what it actually
  ran: sed -E 's///g' file | sed '//d' | grep -c - the regex body removed. The leg
  passes standalone and FAILS under P-011, so the failure is invisible to anyone testing
  their verification commands before filing them, which is the recommended practice.
  Worse than a false red: a line of the form cmd-A ; cmd-B judged on B alone (T-352)
  could be mangled into something that still exits 0, producing a false GREEN over
  a check that no longer checks anything. Workaround in T-453 builds the markers from
  chr(60)+chr(33) so the extractor has nothing to match. Vendored AEF tooling, fix
  is theirs under G-008. Note the irony this was found by: a task about a gate that
  fails to strip HTML comments, blocked by a gate that strips them too aggressively.

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
created: 2026-08-12T12:26:03Z
last_update: '2026-08-16T14:33:38Z'
date_finished: 2026-08-12T12:36:20Z
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
  - ts: '2026-08-16T12:33:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:38Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/task-create/update-task.sh,tools/_t352-p011-errexit-probe.sh,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:56Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 
      (paths:.agentic-framework/agents/task-create/update-task.sh); tier=2 
      (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-456: P-011 strips HTML comments from the Verification COMMAND text, mangling any command containing the markers

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Both the CAUSE and the EFFECT are asserted, separately.** The cause — a DOTALL
      comment-strip applied to the Verification text in the vendored `update-task.sh` — is
      asserted against the shipping file. The effect — that the strip rewrites a real
      command into a harmless one — is demonstrated by reproducing the exact transformation
      observed on T-453's leg. A defect report that shows only the cause leaves the reader
      to believe the consequence; one that shows only the effect can be dismissed as a
      quoting mistake in my own command.
- [x] **The verification legs survive the defect they describe.** Every leg builds the
      comment markers from `chr()` codes so no literal marker pair appears in a command
      handed to `eval`. This is the recursive trap: the obvious way to test the mangling is
      a command containing the markers, which the gate mangles before judging it. Legs that
      quietly get eaten and still report PASS are the failure mode of this very ticket.
- [x] **The false-GREEN direction is reported as a MECHANISM, not a sighting.** Rail 566:
      *"I have not found an instance in my tree — I am reporting the mechanism, not a
      sighting, and I want to be explicit about which of those two this is."* Composed
      with the T-352 errexit swallow (`a ; b` is judged on `b` alone), a mangled leg can
      still exit 0 over a check that no longer checks anything. No instance was found in
      this tree, and the report says so — claiming a sighting I do not have would be the
      same overreach as the caller-side count in T-451.
- [x] **Reported upstream with a remedy shape; no local patch.** AEF rail offset **566**,
      remedy named: strip comments only from lines being discarded as guidance, not from
      lines handed to `eval` — the section already distinguishes them by the `#` prefix. Vendored under
      `.agentic-framework/`, so the disposition ruled for T-402/T-422/T-345/T-453/T-455
      applies. Verified by an empty `git diff` over `update-task.sh`.

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

# EVERY leg below builds the HTML comment markers from chr() codes. That is not style —
# a leg containing the literal marker pair is rewritten by the very extractor these legs
# assert against, before it is judged. See T-453, where the sed form of a comment-strip
# assertion ran as `sed -E 's///g'` and failed while passing standalone.
#
# LEG A — the CAUSE, read off the shipping vendored file: a DOTALL comment-strip is
# applied to the Verification text (update-task.sh:981).
test 1 -le "$(python3 -c "print(sum(1 for l in open('.agentic-framework/agents/task-create/update-task.sh') if 're.sub' in l and 'DOTALL' in l and chr(60)+chr(33) in l))")"
# LEG B — the EFFECT, reproducing the exact transformation observed on T-453's leg 2:
# a real sed command containing the markers is rewritten into `sed -E 's///g'`, which
# succeeds and asserts nothing.
#
# WHAT LEG B IS NOT. It applies the regex ITSELF, so it demonstrates the semantics and
# will pass forever no matter what the vendored file does. It is a worked example, not a
# gauge, and it must not be read as one — I first wrote a comment here claiming it "goes
# red when the upstream fix lands", which is false and is exactly the caller-side
# reasoning T-451 was about (asserting a property of a thing by testing something that
# merely resembles it). LEG A is the one bound to the shipping file, and LEG A is what
# goes red when this is fixed upstream.
python3 -c "import re,sys; O=chr(60)+chr(33)+'--'; C='--'+chr(62); q=chr(39); cmd='sed -E '+q+'s/'+O+'([^-]|-[^-]|--[^>])*'+C+'//g'+q; out=re.sub(O+'.*?'+C,'',cmd,flags=re.S); sys.exit(0 if out=='sed -E '+q+'s///g'+q else 1)"
# LEG C — NO local patch to the vendored file. Empty diff is the deliverable.
test -z "$(git diff --name-only -- .agentic-framework/agents/task-create/update-task.sh)"

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

### 2026-08-12T12:26:03Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-456-p-011-strips-html-comments-from-the-veri.md
- **Context:** Initial task creation

### 2026-08-12T12:36:18Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-8ad0b066
- **Timestamp:** 2026-08-12T12:36:21Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T12:36:20Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
