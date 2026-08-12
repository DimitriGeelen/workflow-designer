---
id: T-460
name: "grep with an unescaped $name pattern is unsatisfiable: _t350-teeth assert_safe guard-intact branch is unreachable"
description: >
  grep with an unescaped $name pattern is unsatisfiable: _t350-teeth assert_safe guard-intact branch is unreachable

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T14:08:42Z
last_update: 2026-08-12T14:08:42Z
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

# T-460: grep with an unescaped $name pattern is unsatisfiable: _t350-teeth assert_safe guard-intact branch is unreachable

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The branch is proven dead on the shipping file BEFORE the fix.**
      `tools/_t350-teeth.sh:45` reads `[ "$guard" -ge 1 ] && grep -q 'case "${OUT%/}" in' "$f"`.
      On `tools/serve-gallery.sh` that pattern returns **0** while `grep -F` on the identical
      pattern and file returns **1** — the literal is present and the check cannot see it.
      The `&&` therefore never holds, so `assert_safe()`'s `return 0  # guard intact` line is
      unreachable for every input, including the correct one.
- [x] **The fix is at the pattern, not at the guard.** Only `-q` becomes `-qF` on that line.
      `tools/serve-gallery.sh` is not touched, the recursive-delete guard is not touched, and
      the harness's logic is not restructured — a dead branch is revived, nothing is loosened.
- [x] **Reachability is proven through the RIGHT return path, not just by exit code.**
      `assert_safe()` returns 0 from two places: `guard intact`, and a fallback `delete
      stubbed — nothing to authorise` when no live recursive delete is found. An rc-0 that
      cannot tell those apart is the G-034 zero-population reading in miniature. The proof
      therefore asserts BOTH that a live recursive delete exists in `serve-gallery.sh` (so the
      fallback is not the path taken) AND that the guard-intact condition now evaluates true.
- [x] **The sweep is re-run and reported with its denominator.** After the fix, the count of
      `grep` sites under `tools/` carrying an unescaped `$name` in a non-`-F`, non-`-P` pattern
      is **0**. The one remaining *code* site repo-wide is `.tasks/completed/T-148:68`,
      deliberately left in place: editing a completed task's Verification block rewrites a
      record of a gate run without re-running it, which is worse than an inert line in an
      archived file.
- [x] **The one adjacent site that LOOKS like the defect is verified safe rather than assumed
      safe.** `tools/_t350-build-only-probe.sh:210` is the dangerous direction — `! grep -q`,
      where an unmatchable pattern is a false GREEN — but it escapes the dollar (`\${GALLERY_DIR:-`),
      and escaping works: measured `BRE 1 / -F 1` against `tools/serve-gallery.sh`. It matches,
      so its `fail` arm is live. Recorded because a sweep that only *classifies* sites would
      have left this one resting on the claim that `\$` behaves — which is the assumption that
      produced the bug next door.
- [x] **My own sweep reproduces the boundary defect it was written to chase, and it is stated
      rather than filtered away.** The refined scan reports 3 repo-wide hits; **2 of them are
      PROSE** — the sentences in T-459 and T-460 that quote the broken pattern in order to
      describe it. The scanner has no notion of code-to-run versus text-about-code, which is
      exactly G-036's mechanism appearing inside the instrument built to find a different bug.
      It is not worth a filter here (the population is three and the two are self-evident);
      it is worth recording that the class reached one level further than the report did.
- [x] **The direction of failure is recorded, because it decides severity.** As a positive
      assertion the unmatchable pattern is a false RED — noisy, self-announcing. Negated
      (`! grep -q`) or inside an `&&` guard it is a false GREEN — and `_t350-teeth.sh:45` is
      the `&&` form. The class belongs with G-034/G-035 as a third way an instrument reports
      something other than what it means: not blind to zero, not uncalled, but **unsatisfiable
      by construction while reading as a correct quotation of the line it targets**.

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
# LEG A binds to the SHIPPING file — it goes red if anyone drops the -F from _t350-teeth.sh.
# LEG B is a WORKED EXAMPLE (T-456's distinction): it re-executes assert_safe()'s condition
# rather than calling the function, because sourcing the harness runs its main. It proves the
# semantics and the exclusion of the fallback path; it does NOT gauge the shipping file. Leg A
# is the gauge. Saying which is which is the whole point of the distinction.
test 1 -eq "$(grep -cF -e "-qF 'case" tools/_t350-teeth.sh)"
test -n "$(grep -nE '^[[:space:]]*rm[[:space:]]+-[a-zA-Z]*r' tools/serve-gallery.sh | grep -v '^[0-9]*:[[:space:]]*#')" && test "$(grep -c 'refusing to recursively delete' tools/serve-gallery.sh)" -ge 1 && grep -qF 'case "${OUT%/}" in' tools/serve-gallery.sh
test 0 -eq "$(grep -c 'case "${OUT%/}" in' tools/serve-gallery.sh)" && test 1 -eq "$(grep -cF 'case "${OUT%/}" in' tools/serve-gallery.sh)"
test 1 -eq "$(grep -c 'OUT="\${GALLERY_DIR:-' tools/serve-gallery.sh)"
python3 -c 'import glob,re,os,sys; q=chr(39); pat=re.compile(r"grep\s+(-[A-Za-z]+\s+)*"+q+r"[^"+q+r"]*(?<!\\)\$[A-Za-z_{][^"+q+r"]*"+q); h=[(p,i) for p in sorted(glob.glob("tools/*")) if os.path.isfile(p) for i,l in enumerate(open(p,errors="replace").read().splitlines(),1) if pat.search(l) and "F" not in pat.search(l).group(0).split(q)[0] and "P" not in pat.search(l).group(0).split(q)[0]]; print("tools/ unescaped-dollar grep sites: %d %s" % (len(h), h)); sys.exit(0 if len(h)==0 else 1)'

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

**Symptom:** `tools/_t350-teeth.sh` reports `SAFETY PRECONDITION FAILED — guard removed AND a
live recursive delete remains` against `tools/serve-gallery.sh` in its correct, unmutated state.
The guard was not removed; the harness could not see it.

**Root cause:** `grep -q 'case "${OUT%/}" in'` — the pattern is a faithful single-quoted copy of
the target line, so the shell does not interpolate it and it reads as correct. GNU grep treats
the unescaped `$` as an anchor in BRE, ERE and PCRE alike, making the pattern unsatisfiable.
Measured on the same pattern and file: BRE 0, `-E` 0, `-P` 0, `-F` 1.

**Why structurally allowed:** the failure is invisible at every point a reader looks. It is not
a typo — the pattern is character-for-character the line it targets. It is not a shell-quoting
mistake — single quotes are the *correct* choice for a literal containing `$`; switching to
double quotes would have made it obviously wrong, so the safe-looking form is the one that
hides it. And the harness's output blames the target file rather than the check, so the report
points away from the defect.

**Prevention:** the `-F` now carries an inline comment naming the measurement and saying not to
drop it, so the evidence sits at the call site rather than in a task file. The repo-wide sweep
lives in `## Verification` and goes red if a new unescaped-`$` pattern lands under `tools/`.
Directionality is recorded on the ACs because it decides severity — positive assertions fail
loud (false RED), negated and `&&`-guarded ones fail silent (false GREEN), and this was the
`&&` form. The class belongs beside G-034 (verdict computed from zero) and G-035 (instrument
with no live caller) as a third way an instrument reports something other than what it means:
unsatisfiable by construction, while reading as a correct quotation of its target.

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

### 2026-08-12T14:08:42Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-460-grep-with-an-unescaped-name-pattern-is-u.md
- **Context:** Initial task creation
