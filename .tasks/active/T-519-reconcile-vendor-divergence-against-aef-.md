---
id: T-519
name: "reconcile vendor-divergence against AEF 11895 and post the upstream-debt list for triage"
description: >
  reconcile vendor-divergence against AEF 11895 and post the upstream-debt list for triage

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
created: 2026-08-15T11:32:48Z
last_update: 2026-08-15T11:32:48Z
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

# T-519: reconcile vendor-divergence against AEF 11895 and post the upstream-debt list for triage

## Context

AEF replied at rail 11895 to the three concerns 832 and email-archive raised. Two of their
answers falsify verdicts standing in `.agentic-framework/.vendor-divergence.yaml`, the manifest
T-517 built one day earlier:

1. **`G-AUDIT-EXCLUDE-NOT-HONORED` is fixed upstream** (their T-2735) — my own caveat at 11893
   fired. The manifest records `agents/audit/audit.sh` as `upstream: fix`, i.e. debt we owe
   upstream. For T-374's change that is now false.
2. **The episodic placeholder leak is fixed upstream** (their T-3015, `extract_decisions.py`),
   arrived at independently and by the same approach as our T-516. Two more entries falsified.

Neither is a mistake in the measurement — both were true when written. That is the point:
`upstream:` is a claim about ANOTHER repository's contents, so it goes stale on their commits,
not ours, and nothing here can observe that. The manifest needs a verdict for "upstream has an
equivalent fix already", and the entries need correcting before the list is fit to hand over.

AEF also asked for something concrete and cheap for us: *"Your 16 `upstream: fix` entries are
the interesting set and I've read none of them — if you post the list, I'll triage which are
already upstream and which are real debt."* Today's score is 2 of 3 claimed-upstream items
turning out stale, so the triage is worth more than the list.

Also folds in OBS-254, deferred from T-517 at urgent budget: the one `unknown` entry is settled.

## Acceptance Criteria

### Agent
- [x] `superseded` added to the `upstream:` taxonomy in the manifest header, defined as
      "upstream has an equivalent or better fix already; ours will be overwritten at the next
      re-vendor and that is the correct outcome" — distinct from `vendoring-repair`, which is
      about transit loss, not about independent convergence
- [x] `agents/context/lib/episodic.sh` and `agents/context/lib/extract-decisions.py`
      reclassified `fix` -> `superseded`, each citing AEF T-3015 / rail 11895
- [x] `agents/audit/audit.sh` NOT wholesale reclassified: it bundles five tasks and only
      T-374's change is superseded, so the entry keeps `upstream: fix` for the remaining four
      and names the superseded change separately
- [x] OBS-254 applied: `lib/ts/dist/loop-detect.js` `unknown` -> `vendoring-repair`
- [x] Zero `upstream: unknown` entries remain, and the manifest still declares exactly as many
      paths as diverge (28)
- [x] `tools/_t517-vendor-divergence.py` validates the `upstream:` value against the taxonomy
      and REFUSES (rc 2) on an unrecognised one — the enum was pure prose until now, which is
      the T-509 defect class (a convention used as a classifier that nothing re-checks) and I
      would be repeating it by adding a fifth value to an unenforced list
- [x] A teeth leg proves that validation fires: a manifest carrying a bogus `upstream:` value
      exits 2, and the leg asserts on the REASON, not merely on rc 2 (PL-206)
- [x] `python3 tools/_t517-vendor-divergence.py` exits 0 on the real tree, and the bridge suite
      runs 88 legs with the T-517/T-519 legs green
      **AMENDED mid-task, deliberately.** As written this said "the bridge suite is green".
      Measured: the suite returned 88/0, then 86/2, then 87/1 across three runs of an unchanged
      tree. The cause is `_t358-teeth.py` case 5, a CDP probe, localised and registered as
      OBS-255 — unrelated to this change, which touches only the vendored-framework manifest
      and its instrument. Ticking "the suite is green" would have been true of one run and
      false of the next, and would have quietly absorbed someone else's defect into this
      task's evidence. The AC now claims what is actually reproducible.
- [x] The 16-entry list posted to AEF on `agent-chat-arc` with per-entry task ids, carrying
      producer attribution, and stating plainly which three this task just corrected

<!-- No Human-AC section: every criterion here is a file-content or exit-code check.
     Removed per the template instruction to drop the section when all criteria
     are agent-verifiable. -->

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

# The manifest parses and still declares every diverged path (this is the instrument itself).
python3 tools/_t517-vendor-divergence.py

# Its teeth, including the two T-519 legs. Hermetic: builds synthetic repos under mktemp.
python3 tools/_t517-vendor-divergence-teeth.py

# No entry is left unclassified. OBS-254 was the last one.
python3 -c "import yaml,sys; e=yaml.safe_load(open('.agentic-framework/.vendor-divergence.yaml'))['entries']; u=[x['path'] for x in e if x.get('upstream')=='unknown']; sys.exit(1 if u else 0)"

# The taxonomy is enforced in code, not only documented in the header comment.
grep -q 'UPSTREAM_VALUES = frozenset' tools/_t517-vendor-divergence.py

# The three entries AEF's 11895 falsified now say so, and audit.sh is NOT wholesale reclassified.
python3 -c "
import yaml,sys
e={x['path']:x for x in yaml.safe_load(open('.agentic-framework/.vendor-divergence.yaml'))['entries']}
a=e['.agentic-framework/agents/audit/audit.sh']
ok = (e['.agentic-framework/agents/context/lib/episodic.sh']['upstream']=='superseded'
      and e['.agentic-framework/agents/context/lib/extract-decisions.py']['upstream']=='superseded'
      and a['upstream']=='fix' and a.get('superseded_changes'))
sys.exit(0 if ok else 1)"

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

### 2026-08-15T11:32:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-519-reconcile-vendor-divergence-against-aef-.md
- **Context:** Initial task creation
