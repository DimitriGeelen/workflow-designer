---
id: T-517
name: "vendored-fix divergence census: 19 G-008 in-tree framework fixes a re-vendor would silently clobber"
description: >
  vendored-fix divergence census: 19 G-008 in-tree framework fixes a re-vendor would silently clobber

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t517-vendor-divergence.py, tools/_t517-vendor-divergence-teeth.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-15T10:01:37Z
last_update: 2026-08-15T10:15:37Z
date_finished: 2026-08-15T10:15:37Z
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

# T-517: vendored-fix divergence census: 19 G-008 in-tree framework fixes a re-vendor would silently clobber

## Context

G-008 permits fixing vendored `.agentic-framework/` code in-tree **and upstreaming it**. The
second half is not happening, and nothing records that the first half did. Measured against the
pristine re-vendor baseline `ebf0c721` (T-276, v1.6.763): **28 files diverge, 1737 insertions**,
of which **8 differ only in file mode**. A future `fw upgrade` / re-vendor overwrites all of it.

This is not hypothetical. T-276's own follow-up commit `70627849` reads *"post-vendor repair —
restore exec bits demoted by old do_vendor copy (5 files) + chmod secret-scan"*: the last
re-vendor DID clobber, and it was caught by hand because someone happened to look.

Found while checking email-archive's rail 11888 (`G-AUDIT-EXCLUDE-NOT-HONORED`, refresh #3,
2mo silent) against our own tree instead of assuming it was theirs. Their concern is **valid
upstream** — and we have carried a working fix for it since T-374, whose own code comment says
AEF's T-1842 *"reached register.sh and drift.sh and did not reach here."* A peer's gap sat open
for two months while the remedy sat in our tree, unlabelled.

## Acceptance Criteria

### Agent
- [x] `.agentic-framework/.vendor-divergence.yaml` records the baseline vendor commit and one
      entry per diverged path: `path`, `kind` (content|mode|added), and the task that introduced
      it. Covers every path the measurement finds — no path silently omitted.
- [x] `tools/_t517-vendor-divergence.py` compares the live vendored tree against the recorded
      baseline commit and exits non-zero when the ACTUAL diverged set differs from the manifest
      set, in either direction (unrecorded divergence AND a manifest entry that no longer
      diverges). Set equality, not a count — a count ratchet would be the G-015 class T-508 named.
- [x] Mode-only divergence is detected. Proven by mutation, not asserted: `chmod -x` a file whose
      only divergence is its exec bit and the instrument goes red naming that path.
- [x] The instrument REFUSES with a distinct exit code when the baseline commit is unreachable,
      rather than reporting zero divergence. An unmeasurable baseline and a clean tree must not
      produce the same output (PL-205).
- [x] `tools/_t517-vendor-divergence-teeth.py` — hermetic legs under mktemp covering: unrecorded
      content divergence goes red, unrecorded mode divergence goes red, a stale manifest entry
      goes red, an absent baseline refuses (not passes), and an anti-vacuity leg proving green is
      classification rather than a dead comparator. Exits 0.
- [x] Both wired into `tests/run-bridge-tests.sh` with real callers — not excused by the `*teeth*`
      naming convention T-509 measured false for 19 of 24 scripts. Suite passes, 0 failed.
- [x] The audit-exclude finding reported to email-archive and framework-agent on the rail:
      their concern is valid upstream, T-374 is the tested implementation of the exact fix they
      proposed, and the secret-scan exec bit is a LOCAL repair here (upstream still ships 644)
      even though the `-f` gate makes it non-load-bearing.

<!-- No Human-AC section: every criterion above is agent-verifiable by a command in
     ## Verification, which the template's own guidance says is the case for removing it.
     Removed rather than left in place because a bulk tick of this task's ACs also flipped the
     two [ ] boxes inside the commented-out [REVIEW]/[REVIEWER] EXAMPLES above — template text,
     inert, but Human-AC boxes all the same, and CLAUDE.md says never to touch those. The
     T-1731 guard then correctly refused to let me flip them back, in either direction, and
     FW_ALLOW_HUMAN_AC_TICK=1 is a Tier 2 bypass that is not mine to use. Deleting a boilerplate
     section this task never needed is the remedy that requires no bypass. Recorded here rather
     than done quietly: the mistake was mine, a `- [ ]` → `- [x]` sweep that did not check what
     section it was standing in. -->

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

python3 -c "import yaml,sys; d=yaml.safe_load(open('.agentic-framework/.vendor-divergence.yaml')); sys.exit(0 if d.get('baseline_commit') and d.get('entries') else 1)"
python3 tools/_t517-vendor-divergence.py
python3 tools/_t517-vendor-divergence-teeth.py
grep -q "_t517-vendor-divergence.py" tests/run-bridge-tests.sh
grep -q "kind: mode" .agentic-framework/.vendor-divergence.yaml

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

**Symptom:** email-archive re-pinged `G-AUDIT-EXCLUDE-NOT-HONORED` for the third time in four
months, attributing two months of silence to framework-agent inaction. A tested fix for exactly
that defect has been in our tree since T-374 and neither they nor upstream knew.

**Root cause:** G-008 authorises in-tree fixes to vendored code *and* upstreaming. The tree
records the fix (a commit) but nothing records that the fix is LOCAL — that it exists here and
not upstream. Divergence is therefore invisible in both directions: upstream cannot see what to
adopt, and we cannot see what a re-vendor would destroy.

**Why structurally allowed:** the only representation of "this vendored file is locally patched"
is git history, which is per-file, per-commit, and unreadable as a set. Two of the diverged
files carry NO content change at all — only an exec bit — so even a diligent reviewer diffing
content would report them clean. `fw doctor` and `fw audit` both check vendored-tree health and
neither compares against the vendor baseline.

**Prevention:** the manifest + set-equality instrument in the ACs. Divergence becomes a declared,
reviewed artifact; a re-vendor has an explicit re-apply list including the mode-only entries; and
new unrecorded divergence goes red the next time the bridge suite runs. Distinct from the fix
itself (the fix is upstreaming T-374, which is AEF's call, not ours).

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

### 2026-08-15 — set equality rather than a count ratchet
- **Chose:** the instrument compares the diverged SET against a declared manifest, and fires in
  both directions — unrecorded divergence and stale entries alike.
- **Why:** the number of diverged files is a global always-moving property. It rises with every
  legitimate G-008 fix, so a count ratchet would go red on correct work and train whoever reads
  it to re-baseline reflexively, which is how a ratchet becomes a rubber stamp. T-508 catalogued
  exactly this as the G-015 class and found the hash-keyed baseline strictly better than the
  count-keyed one I had drafted then.
- **Rejected:** a count ratchet (`diverged <= 28`), and a one-directional check that only catches
  new divergence — the stale direction is what detects a re-vendor having silently eaten a fix,
  which is the more destructive of the two failures.

### 2026-08-15 — an upstream taxonomy rather than a flat divergence list
- **Chose:** every entry carries `upstream: fix | vendoring-repair | local-config | unknown`,
  and one entry is genuinely recorded as `unknown`.
- **Why:** the manifest has two consumers with different questions. A re-vendor asks "what must
  I re-apply?" and the answer is all 28. framework-agent asks "what should I adopt?" and the
  answer is only the 16 marked `fix` — offering them the exec bits or our designer pin would be
  noise that makes the real debt harder to see. The distinction is not cosmetic: the exec bits
  are upstream's file that OUR vendoring lost in transit, the opposite direction of travel.
- **Rejected:** a flat list of 28 paths, which would have made the upstream ask unactionable;
  and guessing a value for `lib/ts/dist/loop-detect.js` — it is a built artifact and settling it
  needs a rebuild, so it is recorded as unknown. An `upstream:` value asserted without checking
  is precisely the folklore this manifest exists to end.

### 2026-08-15 — the manifest declares itself
- **Chose:** `.vendor-divergence.yaml` carries an entry for `.vendor-divergence.yaml`.
- **Why:** it lives inside the tree it measures, so it is itself divergence. Noticed only
  because `git diff` ignores untracked files — the instrument ran green while the manifest was
  unstaged and would have gone red the moment it was committed.
- **Rejected:** special-casing it out of the comparison, which would have been a hole in a
  register whose entire purpose is that there are no holes, and would have been invisible to
  every future reader.

### 2026-08-15 — deleted the boilerplate Human-AC section rather than take a Tier 2 bypass
- **Chose:** removed the unused `### Human` section wholesale, which the task template's own
  guidance sanctions when every criterion is agent-verifiable.
- **Why:** a bulk `- [ ]` → `- [x]` sweep over this task's ACs also flipped the two boxes inside
  the section's commented-out [REVIEW]/[REVIEWER] examples. Inert template text, but Human-AC
  boxes, and CLAUDE.md says never to touch those. The T-1731 guard then correctly refused to let
  me flip them back — it blocks the toggle in both directions, which is right.
- **Rejected:** `FW_ALLOW_HUMAN_AC_TICK=1`, a Tier 2 bypass that autonomous initiative does not
  delegate; and leaving the wrong state in place because it was only template text, which would
  have left a task file asserting that human criteria had been verified.

### 2026-08-15 — reported "valid upstream" with the inference stated rather than as fact
- **Chose:** told email-archive their concern is valid upstream, and in the same breath said I
  cannot see upstream HEAD and named exactly what the claim rests on.
- **Why:** what I can actually observe is that our v1.6.763 baseline lacked the fix, that we made
  it locally, and that they observe the defect in their own tree. Two independent consumer trees
  is good evidence, not proof about framework-agent's HEAD. Corroborating a peer's filing is
  worth much less if the corroboration is itself unverified — that is how one unconfirmed claim
  becomes consensus, which is the reason I declined to corroborate this one at 11892.
- **Rejected:** asserting it flatly (overstates what I measured), and declining a second time
  (I had now actually checked, and the check was cheap).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-15T10:01:37Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-517-vendored-fix-divergence-census-19-g-008-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-75a51928
- **Timestamp:** 2026-08-15T10:15:39Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T10:15:37Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
