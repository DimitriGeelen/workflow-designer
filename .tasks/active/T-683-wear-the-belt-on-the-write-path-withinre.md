---
id: T-683
name: "Wear the belt on the write path: _within_repo guards delete but not save, so one regex is the whole fence"
description: >
  tools/gallery-serve.py:109 _within_repo documents itself as belt-and-braces over ID_RE, but is referenced only at :120 on the delete path. The /api/save write path has no containment check at all. T-681 S2 demonstrated behaviorally that widening ID_RE alone puts a write outside the version store (HTTP 200, escaped=True). Apply the guard on the save path so containment does not rest on a single regex.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [ewcr, arc-2, isolation]
components: []
related_tasks: []
arc_id: ewcr-governed-delivery
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-05T17:25:56Z
last_update: 2026-09-07T21:08:31Z
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

# T-683: Wear the belt on the write path: _within_repo guards delete but not save, so one regex is the whole fence

## Context

`/api/save` writes five targets — version snapshot, thumbnail, version index, canonical
corpus copy, served copy — every one of them derived from the request's `id`, and none of
them containment-checked. The only fence is `ID_RE`. T-681 S2 demonstrated behaviourally
that widening `ID_RE` alone puts a write outside the version store (HTTP 200, `escaped=True`).

**The task description proposed applying `_within_repo` to the save path. That is the wrong
guard, and building it would have reproduced PL-318 one level up.** `_within_repo` asserts
containment in REPO. The save path's targets live in *specific roots inside* REPO, so an id
of the shape `../.claude/settings` resolves **inside** REPO — passing `_within_repo` — while
escaping the version store entirely and landing on enforcement config that B-005 protects.
A guard that admits the write it exists to refuse is decoration.

The fence therefore has to be per-target containment against each target's **own** intended
root, not against the repo. `DOCROOT` is operator-overridable (`--docroot`, :69), so the
served copy's root is `DOCROOT/rendered` and not a repo path at all — a blanket repo check
would also produce a *false refusal* on a legitimate configuration.

## Acceptance Criteria

### Agent
- [x] A single containment primitive `_within(path, root)` exists, and `_within_repo` is
      expressed in terms of it — one implementation of containment, not two.
      *(gallery-serve.py:109 `_within`, :119 `_within_repo` returns `_within(path, REPO)`.)*
- [x] Every `/api/save` write target is containment-checked against its own intended root:
      version snapshot, thumbnail and `index.json` against `.editor-versions/<id>`; corpus
      copy against `examples/aef-processes/rendered`; served copy against `<DOCROOT>/rendered`.
      *(`_save_targets()` pairs each path with its root; the version dir covers snapshot,
      thumbnail and index since all three are written inside it under fixed `vN.*` names.)*
- [x] Containment is checked **before any bytes are written**, and a failure refuses the
      whole save (HTTP 400) leaving no partial write — the arc's "refused rather than run".
      *(Guard sits after the bpmn check and before `ts = …`; the first write is the
      `os.makedirs(vdir)` that follows it. Live case `no-write-escaped-the-version-store`
      asserts nothing landed.)*
- [x] Regression test proves the discriminating case: an id that resolves **inside REPO but
      outside the version store** is REFUSED. This is precisely the write `_within_repo`
      would have allowed, so the test distinguishes the real fix from the proposed one.
      *(`escaping-id-refused-by-per-target-guard` + `within-repo-would-have-allowed-it`:
      the second asserts every target for `../.claude/settings` passes `_within_repo`.)*
- [x] Regression test proves the control is not always-red: an ordinary save still returns
      200 and writes every target. *(`ordinary-id-not-refused-by-guard`,
      `ordinary-save-still-succeeds` — the latter on the widened server, so the green is
      not an artefact of ID_RE rejecting everything.)*
- [x] Regression test proves no false refusal when `DOCROOT` is set outside REPO.
      *(`docroot-outside-repo-no-false-refusal`: docroot in a separate tmpdir, 200 + file.)*
- [x] `ID_RE` is unchanged — the containment fix must not rest on tightening the regex it is
      supposed to be redundant with. *(`id-re-unchanged` greps the original literal.)*

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
         1. Run `bin/fw reviewer T-683`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-683 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

python3 tools/_t683-save-containment-verify.py
python3 tools/_gallery-save-allowlist-verify.py
python3 tools/_serve-gallery-verify.py
python3 tools/_gallery-list-verify.py
# the guard is WIRED on the save path, not merely defined — that WAS the defect
grep -q "escape = _escaping_save_target" tools/gallery-serve.py
# negative leg: containment must not be re-implemented a second time
test 1 -eq "$(grep -c 'rp.startswith' tools/gallery-serve.py)"

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

**Symptom:** `/api/save` accepted a write whose targets escaped the version store. With
`ID_RE` widened (T-681 S2), a POST with `id: "../.claude/settings"` returned HTTP 200 and
wrote `v1.bpmn` into the repo's `.claude/settings/` — the enforcement-config directory
B-005 exists to protect. Reproduced this session against the pre-fix code.

**Root cause:** containment was implemented once and referenced once. `_within_repo` was
defined at :109 and called only at :120, on the delete path. The write path — five targets,
all id-derived — had no containment check at all, so the entire fence was one regex.

**Why structurally allowed:** the guard's own docstring claimed belt-and-braces, which made
the file *read* as defended on both paths. Nothing asserted that the guard was called, and
a guard that is never called is indistinguishable from a guard that is called and passes.
The delete path's green test covered the only call site that existed, so coverage looked
complete. This is PL-318 exactly: a docstring is not defence-in-depth.

**Prevention:** distinct from the fix — a P-011 leg greps that the guard is *wired* on the
save path (`escape = _escaping_save_target`), and a second leg asserts containment is
implemented once (`rp.startswith` appears exactly once), so a future path cannot quietly
grow a parallel weaker check. The regression suite cuts ID_RE deliberately, so the second
belt is exercised rather than shadowed by the first.

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

## Evolution

### 2026-09-07 — the filed fix was the wrong fix

- **What changed:** the task was filed as "apply `_within_repo` on the save path". Reading
  the code showed that guard does not hold: the save targets live in roots *inside* REPO, so
  an id of `../.claude/settings` passes `_within_repo` while escaping the version store and
  landing on the enforcement-config directory. The filed plan would have shipped a guard
  that admits the write it exists to refuse — and would have tested green doing it.
- **Plan impact:** the deliverable changed from "call an existing function in a second place"
  to "introduce a per-target containment primitive and re-express the existing guard on it".
  Bigger than filed, and the suite grew an assertion whose only job is to prove the filed
  version would have failed (`within-repo-would-have-allowed-it`).
- **Triggered:** no new task. Two facts worth carrying: `DOCROOT` is operator-overridable, so
  repo-relative containment produces false refusals on a legitimate config; and a
  defence-in-depth layer sitting behind a working outer layer cannot be tested through the
  front door — the suite has to break the outer layer on purpose or it verifies nothing.
  The second generalises past this file and is a candidate learning for T-684.

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-09-07 — the guard is per-target, not per-repo

- **Chose:** `_within(path, root)` applied to each save target against its own intended
  root (`.editor-versions`, the corpus dir, `DOCROOT/rendered`).
- **Why:** the task description's own proposal — "apply `_within_repo` on the save path" —
  does not hold. Every target for `../.claude/settings` resolves *inside* REPO, so
  `_within_repo` passes all three while the write escapes the version store and lands on
  enforcement config. Building what was asked would have produced a guard that admits the
  exact write it exists to refuse, and it would have tested green. That is PL-318 repeated
  one level up, by the task written to fix PL-318. The suite now asserts this explicitly
  (`within-repo-would-have-allowed-it`) so the distinction cannot silently regress.
- **Rejected:** *(a)* `_within_repo` on the save path — decorative, above. *(b)* Tightening
  `ID_RE` to forbid dots and slashes — that is bracing the braces; the entire point is that
  containment must survive the regex being wrong, and a P-011 leg now pins ID_RE unchanged.
  *(c)* Checking each of the five write targets individually — snapshot, thumbnail and index
  all live inside the version dir under fixed `vN.*` names, so the directory check covers
  them; enumerating them would imply the filenames were attacker-controlled when they are not.

### 2026-09-07 — the regression test cuts ID_RE deliberately

- **Chose:** run the live cases against a temp copy of the server with `ID_RE` widened.
- **Why:** `ID_RE` rejects the hostile id before the containment guard is reached, so
  through the front door the second belt is unreachable and untestable — it would have
  passed whether or not it was wired. A defence-in-depth layer must be tested with the
  outer layer broken, or it is being asserted rather than verified. Confirmed separately
  that the suite goes red against pre-fix code (status 200, `escaped=True`), so it is a
  control that has actually fired, not one that has only ever been green.
- **Rejected:** monkeypatching `ID_RE` in-process — the save path runs in a subprocess
  server, so an in-process patch would not reach it and would have produced a false green.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-683 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-05T17:25:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-683-wear-the-belt-on-the-write-path-withinre.md
- **Context:** Initial task creation

### 2026-09-07T21:02:37Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
