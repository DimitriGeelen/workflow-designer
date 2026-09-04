---
id: T-674
name: "CTL-012 counts ACs inside HTML comment blocks, so preserving superseded ACs is punished as an unchecked-AC violation"
description: >
  MEASURED 2026-09-03 during T-673 audit remediation. CTL-012 reports 'Completed task T-508 has unchecked AC' and quotes '- [ ] The two classes are separated mechanically'. That line and four others sit INSIDE an HTML comment block in .tasks/completed/T-508-verification-legs-pin-corpus-cardinality.md (lines ~189-212), opened with a rationale that is the opposite of a violation: 'ORIGINAL ACs, kept because a rewritten AC set that hides its own supersession is the laundering this project keeps catching.' T-508's live ACs are all ticked and it completed cleanly on 2026-08-15 with no bypass in the log. So the detector reads commented-out history as live criteria, and the warn fires precisely on the practice of preserving superseded ACs rather than silently deleting them - it punishes the honest form and rewards the laundering. Fix: strip <!-- ... --> regions before counting '- [ ]' in the CTL-012 scan. Guard: a task file with a ticked live AC set plus a commented block of unticked ones must NOT trigger CTL-012, and one with a genuinely unticked live AC still must - both arms driven, per PL-308. Framework code under .agentic-framework/ (vendored; G-008 allows in-tree fix plus upstream).

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t674-ctl012-comment-fence.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-03T20:28:17Z
last_update: 2026-09-04T22:01:54Z
date_finished: 2026-09-04T22:01:54Z
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

# T-674: CTL-012 counts ACs inside HTML comment blocks, so preserving superseded ACs is punished as an unchecked-AC violation

## Context

Found while classifying the 27 remaining audit warns (T-673 round 2), not by a
detector. See frontmatter for the measurement.

## Findings

**1. The fence caught a hole in the fix, and a pre-existing one behind it.** The naive
strip leaves `<!-- x --> - [ ] live` as ` - [ ] live`, and the match is `^`-anchored,
so it stopped matching. Measured against HEAD, that case was ALREADY invisible before
this task — a pre-existing false negative that the naive fix would have preserved
while looking like it had done its job. Fixed by lstripping only when a comment was
actually removed, so authored indentation still means what it meant.

**2. Comment-stripping had to move ahead of the section checks, not just the AC
match.** Otherwise a commented-out `### Human` steers section state. (Measured: the
old code happened to survive this because `<!-- ### Human -->` does not
`startswith("### Human")` — so this arm is a regression guard for the new code, not a
bug that was live. Stated precisely because "my change fixed it" would be false.)

**3. I made the same mistake the detector made.** The script I used to tick the ACs
did a blanket `- [ ]` → `- [x]` replace over everything above `## Verification`, and
it rewrote two prose passages that QUOTED `- [ ]` while describing the bug — including
the frontmatter sentence naming the exact line CTL-012 misread. A checkbox and a
mention of a checkbox are not the same token, which is precisely what CTL-012 got
wrong and what T-669 states as "mention is not invocation". Caught by grep, reverted.

**4. Not fixed here, one bug one task:** the `decision_empty` pre-scan in the same
function has its own comment handling that skips lines *starting* with `<!--` or
*ending* with `-->`, but not the interior lines of a block. A multi-line comment inside
a `## Decision` section therefore reads as content, making the section look filled.
That flips `missing-decide` to `drift` — a misclassification, not a false positive,
and a different symptom. Left for a separate task rather than widened into this one.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `completed-task-scan.py` strips `<!-- ... -->` regions before matching an
      unticked-AC line,
      including blocks that span many lines and comments that open or close
      mid-line. Stripping happens BEFORE the section checks, so a commented
      `### Human` or `## Heading` can no longer steer section state either.
- [x] **Both arms driven (PL-308), because this is a false-POSITIVE fix and the
      failure mode of fixing one is silencing the detector.** A fixture whose only
      unticked ACs are inside a comment block must NOT be reported; a fixture with a
      genuinely unticked live AC MUST still be reported. The second arm is the one
      that matters — a scanner that reports nothing would satisfy the first alone.
- [x] The auto-tick / `missing-decide` classification still works, and prose-DEFERRED
      markers are still skipped. Both are existing behaviour in the same loop.
- [x] CTL-012 no longer fires on T-508, measured by running the real audit section —
      not by reasoning about the fixture.
- [x] T-508's commented block is left exactly as it is. It is the artifact that
      exposed the defect and its rationale is the point: *"a rewritten AC set that
      hides its own supersession is the laundering this project keeps catching."*

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
         1. Run `bin/fw reviewer T-674`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-674 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Seven arms. Two fail against HEAD's pre-fix scanner, so the fence DISCRIMINATES
# rather than merely being green. The load-bearing one is "genuinely unticked live AC
# MUST still fire": this is a false-positive fix, and the cheapest way to stop a
# detector reporting something is to stop it reporting anything.
python3 tools/_t674-ctl012-comment-fence.py

python3 -c "import ast; ast.parse(open('.agentic-framework/agents/audit/completed-task-scan.py').read())"

# The real corpus, measured — not reasoned about: zero unchecked ACs across all 578
# completed tasks (T-508 included).
#
# NOT `fw audit --section compliance`. Two such legs HUNG this task's own completion:
# the audit runs from inside the transaction that is completing the task and contends
# with the lock FDs that transition holds (OBS-332). Calling the scanner directly is
# also the better assertion — it is the unit this task changed, it reads the same real
# corpus, and it does not make completion depend on unrelated tree state. 0.36s.
python3 -c "import json,subprocess,sys; d=json.loads(subprocess.run([sys.executable,'.agentic-framework/agents/audit/completed-task-scan.py','.tasks','.context/episodic','docs/reports'],capture_output=True,text=True).stdout); n=len(d.get('unchecked_ac',[])); print('unchecked_ac:',n,'of',d['stats']['total'],'completed'); sys.exit(0 if n==0 else 1)"

# T-508's commented block is the artifact that exposed the defect. Untouched: the
# block still opens with its rationale, and its superseded ACs are still there.
# The rationale is line-WRAPPED in the file ("...supersession is the\n laundering this
# project keeps catching"), so match the fragment that actually occupies one line.
grep -q 'laundering this project keeps catching' .tasks/completed/T-508-verification-legs-pin-corpus-cardinality.md
grep -q 'ORIGINAL ACs, kept because a rewritten AC set that hides its own supersession' .tasks/completed/T-508-verification-legs-pin-corpus-cardinality.md
test -z "$(git status --porcelain .tasks/completed/T-508-verification-legs-pin-corpus-cardinality.md)"

test -f .fabric/components/tools-_t674-ctl012-comment-fence.yaml

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
     fw inception decide T-674 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-03T20:28:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-674-ctl-012-counts-acs-inside-html-comment-b.md
- **Context:** Initial task creation

### 2026-09-04T21:55:55Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5ad41115
- **Timestamp:** 2026-09-04T22:01:57Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-04T22:01:54Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
