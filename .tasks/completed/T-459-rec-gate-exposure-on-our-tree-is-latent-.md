---
id: T-459
name: "Rec-gate exposure on our tree is latent not live, and the template remedy is
  upstream — both measured"
description: >
  Rec-gate exposure on our tree is latent not live, and the template remedy is upstream
  — both measured

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
created: 2026-08-12T14:02:38Z
last_update: '2026-08-16T12:34:00Z'
date_finished: 2026-08-12T14:08:29Z
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
  - ts: '2026-08-16T12:34:00Z'
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
---

# T-459: Rec-gate exposure on our tree is latent not live, and the template remedy is upstream — both measured

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The census uses the SHIPPING predicate, not a paraphrase, and both controls are
      stated.** `lib/review.sh:137-168` counts a Human AC only when the line begins
      `- [ ]` / `- [x]` at **column 0**, inside `### Human`, inside `## Acceptance Criteria`.
      Positive control: the four arc blockers (T-340, T-341, T-358, T-209) each return
      `human 0/1` — the counter finds real ACs. Negative control: the shipped template's two
      example ACs sit **indented seven spaces**, so the same counter skips them.
- [x] **The finding is reported with its denominator AND its latency (PL-084).** 21 of 65
      active tasks carry no `## Recommendation` section; **0 of them trip the T-2421
      rec-gate today**, because none has a real Human AC. The exposure is LATENT, not live —
      and it becomes live the moment any of those 21 gains a Human AC, which is exactly what
      happens when an agent replaces the template comment with real criteria at column 0.
- [x] **The template's immunity is identified as ACCIDENTAL, not designed.** review.sh escapes
      the G-036 comment-boundary class only because its glob is whitespace-intolerant and the
      template's examples happen to be indented. De-indenting them — a formatting change no
      reviewer would flag — makes the gate count two phantom Human ACs on every task built
      from the template. Recorded as a fourth site of the G-036 class with an inverted sign:
      the other three mis-strip comments, this one is saved by an unrelated accident.
- [x] **Template ownership answered from the shipping upgrade path, not from T-455's prior
      assertion.** `lib/upgrade.sh:986-991` copies the framework's `.tasks/templates/*.md`
      over the project's whenever `diff -q` reports a difference — unconditionally, with no
      local-modification check. A local fix to `default.md` is therefore reverted by the next
      bump. T-455 declined the local edit on this ground; that ground is now measured rather
      than asserted, and it makes AEF's "remedy is yours" (rail 568 §2) incorrect.
- [x] **My own first census was wrong in the exact class it was measuring, and it is recorded
      rather than quietly replaced.** The first pass used `grep -cE '^[[:space:]]*- \[[ x]\]'`,
      which tolerates leading whitespace, and so counted the two commented template examples
      as real Human ACs — producing 20 false `WOULD BLOCK` rows. That is the T-453 raw-text
      class, committed inside the measurement intended to quantify it, and the second such
      instance in two windows. The controls above exist because of it.
- [x] **The second broken leg generalised into a class, and the class is filed separately.**
      My `grep -q 'diff -q "$tmpl" "$target_tmpl"' …` leg returned 0 while `grep -F` on the
      same pattern and file returned 1. GNU grep treats an unescaped `$` in a BRE **or ERE**
      pattern as an anchor, so any pattern of the form `…$name…` is unsatisfiable and matches
      nothing — measured across all four modes: BRE 0, `-E` 0, `-P` 0, `-F` 1. A sweep of
      `.tasks/**` and `tools/**` found 5 such sites; 3 correctly escape the `$`, and 2 do not:
      `.tasks/completed/T-148:68` (a completed task whose leg can never match) and
      `tools/_t350-teeth.sh:45`, where the unmatchable pattern makes the `guard intact` branch
      of `assert_safe()` **unreachable** — `tools/serve-gallery.sh` contains the literal
      (`-F` 1) and the check reads 0. Filed as its own task per the one-bug-one-task rule.
- [x] **Reported to AEF on the rail** with the census, both controls, the upgrade.sh file:line,
      and the correction to §2's remedy assignment.

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
#
# NOTE ON LEG 1 (the census). It asserts `live rec-gate blocked == 0`, which is TODAY's
# measured state, not an invariant. If a future task gains a real column-0 Human AC while
# lacking a `## Recommendation` section, this leg goes red — correctly, because that is the
# moment the latent exposure becomes live. It is a gauge, not a worked example (T-456).
#
# Every leg below is single-quoted at the shell level so `$(.*?)` inside the regex is NOT
# read as command substitution, and none of them contains an HTML comment delimiter, so the
# P-011 extractor's DOTALL comment strip (T-456) cannot eat the middle of the command.
python3 -c 'import glob,re,sys; S=lambda p: (re.findall(r"(?ms)^### Human$(.*?)(?=^#{2,3} |\Z)", open(p).read()) or [""])[0]; T=lambda p: [l for l in S(p).splitlines() if l.startswith(("- [ ]","- [x]","- [X]"))]; F=[p for p in glob.glob(".tasks/active/T-*.md") if not re.search(r"^## Recommendation", open(p).read(), re.M) and re.search(r"^workflow_type:\s*(build|refactor|test|decommission)", open(p).read(), re.M)]; B=[p for p in F if len(T(p)) > 0 and sum(1 for l in T(p) if l.startswith(("- [x]","- [X]"))) < len(T(p))]; print("build-class active tasks with no ## Recommendation: %d  ·  of those, live rec-gate blocked (human_checked < human_total): %d" % (len(F), len(B))); sys.exit(0 if len(B)==0 else 1)'
python3 -c 'import re,glob,sys; p=glob.glob(".tasks/active/T-340-*.md")[0]; s=(re.findall(r"(?ms)^### Human$(.*?)(?=^#{2,3} |\Z)", open(p).read()) or [""])[0]; n=sum(1 for l in s.splitlines() if l.startswith(("- [ ]","- [x]","- [X]"))); print("POSITIVE CONTROL — T-340 column-0 Human ACs:", n); sys.exit(0 if n >= 1 else 1)'
python3 -c 'import re,sys; sec=(re.findall(r"(?ms)^### Human$(.*?)(?=^## )", open(".tasks/templates/default.md").read()) or [""])[0]; bad=[l for l in sec.splitlines() if l.startswith(("- [ ]","- [x]"))]; ind=[l for l in sec.splitlines() if l.lstrip().startswith("- [ ]") and l != l.lstrip()]; print("NEGATIVE CONTROL — template Human section: column-0 checkboxes %d, indented example checkboxes %d" % (len(bad), len(ind))); sys.exit(0 if len(bad) == 0 and len(ind) >= 2 else 1)'
grep -qF 'diff -q "$tmpl" "$target_tmpl"' .agentic-framework/lib/upgrade.sh
test 1 -eq "$(grep -c '^## Recommendation' .tasks/templates/inception.md)"
test 0 -eq "$(grep -c '^## Recommendation' .tasks/templates/default.md)"
test -z "$(git diff --name-only -- .tasks/templates/default.md)"

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

### 2026-08-12T14:02:38Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-459-rec-gate-exposure-on-our-tree-is-latent-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6dc72292
- **Timestamp:** 2026-08-12T14:08:31Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T14:08:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

### 2026-08-12 — CORRECTION (T-460): the sixth Agent AC on this task is WRONG

The AC beginning *"The second broken leg generalised into a class"* asserts that GNU grep reads
an unescaped mid-pattern `$` as an anchor, making `grep '…$name…'` unsatisfiable, and cites
`BRE 0, -E 0, -P 0, -F 1`. That is false. GNU grep reads a mid-pattern `$` as a **literal**,
which is the documented and correct behaviour:

    grep -c 'diff -q "$tmpl" "$target_tmpl"' .agentic-framework/lib/upgrade.sh
      through the agent shell   0
      through /usr/bin/grep     1

`grep` in the agent's interactive tool shell is a shell function routing to **ugrep 7.5.0**,
and ugrep anchors on that `$`. Every subshell, hook, script and P-011 leg runs `/usr/bin/grep`.
The leg was never broken; the measurement was taken with the wrong program.

**The AC text and its tick are deliberately left as they were.** Flipping the checkbox would
make this task read as though it had found something true, and the record of a wrong finding is
more useful than a tidy one. What the AC actually established — that the leg failed and that
chasing the failure was worthwhile — still holds; the explanation it reached does not.

The change this task made on the strength of that AC (`grep -q` → `grep -qF` in
`tools/_t350-teeth.sh`) is **kept** but re-justified in T-460: `-F` is the right flag for a
wholly literal pattern and it makes the check agree under both implementations. It was not a
bug fix, and the call-site comment no longer says it was.

Reported to AEF at rail 571, retracting rail 570 §5. Full account in T-460.
