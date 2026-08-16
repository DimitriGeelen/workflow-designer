---
id: T-516
name: "episodic decisions extractor is line-oriented over a block document"
description: >
  episodic decisions extractor is line-oriented over a block document

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
created: 2026-08-15T09:45:17Z
last_update: '2026-08-16T12:34:05Z'
date_finished: 2026-08-15T09:52:41Z
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
  - ts: '2026-08-16T12:34:05Z'
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
---

# T-516: episodic decisions extractor is line-oriented over a block document

## Context

Found by checking a peer's filing against our own tree rather than assuming it was theirs.
email-archive re-pinged `G-EPISODIC-PLACEHOLDER-LEAK` at rail 11890 (their third refresh,
2mo+ silent). Measured here: **363 of 448 episodics (81%)** carry template placeholder text,
including **T-513, T-514 and T-515 — the three tasks closed today.**

`.agentic-framework/agents/context/lib/episodic.sh` extracts the Decisions section
line-by-line from a block-structured markdown document. Three symptoms, one root cause:

1. **Phantom decisions.** Line 131 filters lines matching `^<!--` and `^-->`, but not the
   *interior* lines of a multi-line HTML comment. The task template's Decisions block is
   exactly such a comment, so `### [date] — [topic]` / `- **Chose:** [what was decided]`
   survive the filter and are emitted as a real decision. This fires on **every** task
   close, which is why the rate is 81% and rising rather than stable archive cruft.
2. **Truncated real decisions.** Line 330 takes `sed 's/.*\*\*Chose:\*\* *//'` on ONE line.
   T-513's genuine decision came out as `chose: 'count duplicate element ids over
   BPMN-namespace elements only, and report the'` — cut mid-clause. This is the worse
   half and email-archive's filing does not mention it: a phantom entry is obviously
   junk, whereas a truncated rationale reads as a complete one.
3. **Silent cap.** `head -20` on line 131 drops everything past 20 lines of the section
   with no note, so a task with several decisions loses the tail.

email-archive's proposed fix (a placeholder regex filter) addresses symptom 1 only, and
would leave 2 and 3 in place while making the result *look* clean.

G-008 permits fixing vendored `.agentic-framework/` in-tree and upstreaming.

## Acceptance Criteria

### Agent
- [x] HTML comment BODIES are stripped, not just their delimiter lines, so a task whose
      Decisions section is only the template emits `decisions: []` (or the no-decisions
      note) rather than a phantom entry.
      → `strip_html_comments()` in `extract-decisions.py`, non-greedy + DOTALL; an
        unterminated comment consumes to end-of-section, the safe direction.
- [x] A `**Chose:**` / `**Why:**` / `**Rejected:**` value that wraps across continuation
      lines is captured whole. Verified against T-513's real decision specifically, since
      that is the one measured truncated.
      → T-513's `chose` went from `…and report the` to the full sentence; its `rationale`
        now carries the whole `xsd:any processContents="lax"` argument.
- [x] The 20-line cap no longer silently discards: either removed, or retained with the
      drop reported. A cap that loses data without saying so is the defect class this
      repo keeps cataloguing.
      → removed; teeth leg proves 12 decisions all survive.
- [x] Teeth: a mutation script proves each of the three symptoms is actually caught —
      green on correct input, red on a document exhibiting each symptom. Per PL-206 the
      stimulus must be shown to contain the thing the control looks for, not merely to
      differ from the control input.
      → `tools/_t516-episodic-decisions-teeth.py`, **8 passed / 0 failed**, hermetic under
        mktemp. Includes a PL-205 leg: the same text UNCOMMENTED must be extracted, so
        "empty" cannot mean "the parser is dead". That leg failed on first run — my
        stimulus kept the template's 5-space indent so `### …` never matched `^###` — and
        it failed RED rather than green, which is the direction a malformed stimulus
        should fail in. Fixed and recorded in the file.
- [x] Regenerating T-513's episodic yields its real decision untruncated and NO phantom
      entry. Measured on the actual artifact, not on a synthetic fixture.
      → 2 entries → 1; the survivor is the real one. Pinned in Verification against the
        parsed YAML.
- [x] The 363 historical episodics are NOT rewritten. Fix-forward only — bulk-rewriting
      stored memory is a data decision for the operator, not an agent's to take, and the
      pre-fix records are evidence of the defect's reach.
      → 360 still carry the leak (363 minus this session's own three, regenerated because
        they are this session's records rather than history). Verification asserts the
        historical leak is still VISIBLE, so a later bulk rewrite fails this task's gate
        rather than passing quietly.
- [x] Reported to framework-agent on the rail with producer attribution, carrying the
      working patch and the two symptoms their filing missed, so the fourth re-ping is a
      diff rather than a count.
      → `agent-chat-arc` offset **11892**, `metadata.from_project=832-Workflow-designer`,
        `in_reply_to=11890`. Carries the root cause, the patch itself rather than a
        description of it, and the warning that their proposed placeholder-regex remedy
        closes symptom 1 while making symptoms 2 and 3 invisible. Also reports that their
        G-FW-SECRET-SCAN re-ping is already fixed upstream (T-2061 gates on -f not -x,
        T-2647 made the miss loud) so they are chasing a stale payload — and explicitly
        declines to corroborate G-AUDIT-EXCLUDE, which I did not check here.
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

# All three symptoms plus the two controls. The teeth's own exit code is the verdict.
python3 tools/_t516-episodic-decisions-teeth.py > /dev/null

# Wired — T-509 measured that the "*teeth* is one-shot by design" convention was false for
# 19 of 24 scripts, so a teeth script excused by its own name is not scheduled at all.
grep -q '_t516-episodic-decisions-teeth.py' tests/run-bridge-tests.sh

# End-to-end on the real artifact, not a fixture: T-513's episodic must carry its genuine
# decision and NOT the template phantom. Asserted on the parsed YAML so a malformed file
# fails here rather than being counted as clean.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/episodic/T-513.yaml')); dec=d.get('decisions') or []; sys.exit(0 if len(dec)==1 and 'xsd:ID' in str(dec[0].get('rationale','')) and '[what was decided]' not in str(dec) else 1)"

# The historical episodics must NOT have been bulk-rewritten. Rewriting stored memory is an
# operator decision; the pre-fix records are also the evidence of the defect's reach. This
# asserts the leak is still visible in history rather than quietly erased.
python3 -c "import glob,re,sys; n=sum(1 for f in glob.glob('.context/episodic/*.yaml') if re.search(r'\[date\]|\[what was decided\]', open(f).read())); sys.exit(0 if n > 300 else 1)"

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

### 2026-08-15T09:45:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-516-episodic-decisions-extractor-is-line-ori.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e3a14d65
- **Timestamp:** 2026-08-15T09:52:42Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 49
     - evidence: `python3 tools/_t516-episodic-decisions-teeth.py > /dev/null`

### 2026-08-15T09:52:41Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
