---
id: T-806
name: "Exclude examples/aef-processes/rendered/ from every tool's default sweep"
description: >
  AEF pins against examples/aef-processes/rendered/ as a seam artefact. This session
  a --help invocation of one of our own tools ran its real corpus sweep and rewrote
  24 files under exactly that path; it was caught and reverted byte-identical, but
  only by noticing. AEF's ask at agent-chat-arc @1656: 'keep examples/aef-processes/rendered/
  out of every tool's default sweep' — the topology, not attention, should protect
  the seam. Audit every tool that walks the corpus and make that path opt-in.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: [tools/bake-clean-layout.py, tools/_t806-corpus-sweep-guard-controls.py]
related_tasks: [T-807]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T12:17:14Z
last_update: '2026-09-23T16:50:14Z'
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
  - ts: '2026-09-23T16:49:20Z'
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
  - ts: '2026-09-23T16:50:14Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-806: Exclude examples/aef-processes/rendered/ from every tool's default sweep

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

Audit (T-806): grepped `tools/*.py` and `tools/*.sh` for references to the seam path, then
read each hit to find its walk root and whether it WRITES there by default (not just reads).

| tool | walk root | writes rendered/ by default? |
|---|---|---|
| `tools/bake-clean-layout.py` | `examples/aef-processes/*.workflow.yaml` sources; no args → **all** maps | **yes — the gap.** No argparse; any unrecognized `-`/`--` flag (incl. `--help`) was silently stripped from `names` and fell through to a full bake. This is the exact incident in the task description. |
| `tools/census-dead-legs.py` | none by default — `if not argv: print(__doc__); return 0` | no (read-only tool anyway; requires explicit paths) |
| `tools/gallery-serve.py` | HTTP server; `/api/save` | no — already gated by an existence-or-promotion check (T-138) with its own regression test (`tools/_gallery-save-allowlist-verify.py`, runs against an isolated `tempfile.mkdtemp()` repo, never the real corpus) |
| `tools/mcp-designer-server.py` | MCP `validate`/save tools | no — every write requires a caller-supplied `path`; no default sweep |
| `tools/_corpus-adopt-verify.py`, `tools/_gallery-list-verify.py`, `tools/_t364-x-tie-census.py`, `tools/_t792-mcp-server-probe.py`, `tools/verification-hygiene.py` | various | no — read-only against the real corpus, or (per `_gallery-list-verify.py`) write only inside a temp/sandboxed fixture dir |
| `tools/_t350-*.sh`, `tools/_t353-repair-probe.sh`, `tools/_t408-hygiene-teeth.sh`, `tools/_t440-drive-empty.sh`, `tools/_t809/_t816/_t818/_t836-*-controls.sh`, `tools/serve-gallery.sh` | various | no — every one copies **from** `rendered/` (as a read-only source) into a sandbox/build dir; none writes back into it |

**Conclusion:** of every tool that references the seam path, exactly one — `bake-clean-layout.py`
— writes into it by default, and its unconditional default (baking every map with no flags) is
the tool's own documented, intended contract (`Usage: ... (no map args → every map ...)`); the
actual defect is narrower and sharper than "the whole tool needs an opt-in wall": **any
unrecognized flag, `--help` included, was silently absorbed as a no-op rather than validated**,
so a mistyped or exploratory invocation fell through to the real, intended-only-for-deliberate-
use write path. Fixed by validating flags against a known set (refuse, exit 2, on anything else)
and giving `--help`/`--dry-run` real no-write behaviour — see Decisions.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Every tool under `tools/` that walks the map corpus is enumerated, with the walk root each one uses recorded in the task
- [x] Each such tool either excludes `examples/aef-processes/rendered/` by default, or requires an explicit opt-in flag to touch it
- [x] A `--help` or `--dry-run` invocation of every enumerated tool writes nothing anywhere under `examples/aef-processes/rendered/` (proven by mtime comparison before/after, not by reading the code)
- [x] A regression test asserts the guard, and fails if a tool is added that sweeps the path by default
- [x] The control case is included: the test must fail when the guard is removed, so a passing run means the guard works rather than the test being vacuous

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
         1. Run `bin/fw reviewer T-806`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-806 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

python3 -c "import ast; ast.parse(open('tools/bake-clean-layout.py').read())"
python3 tools/_t806-corpus-sweep-guard-controls.py
before=$(find examples/aef-processes/rendered -name '*.bpmn' -exec stat -c '%Y %n' {} \; | sort); python3 tools/bake-clean-layout.py --help > /dev/null 2>&1; python3 tools/bake-clean-layout.py --nonexistent-flag > /dev/null 2>&1; after=$(find examples/aef-processes/rendered -name '*.bpmn' -exec stat -c '%Y %n' {} \; | sort) && test "$before" = "$after"

## RCA

**Symptom:** an invocation of `tools/bake-clean-layout.py` intended to show usage (`--help`)
instead ran a full bake and rewrote all 24 files under `examples/aef-processes/rendered/` — the
seam artefact AEF pins against by sha256. Caught by noticing the diff, reverted byte-identical;
no corruption shipped, but nothing structural would have caught it if it had gone unnoticed.

**Root cause:** `main()`'s argument parsing built `names` by filtering OUT anything starting
with `--` (`names = [a for a in argv if not a.startswith("--")]`) and only special-cased
`--check`. Every other flag — typo'd, exploratory, or `--help` — was silently dropped rather
than validated, leaving `names == []`, which is the documented shorthand for "bake everything."
There was no code path that could refuse an unrecognized flag; the only two outcomes were
"recognized flag" and "silently treated as no flags at all."

**Why structurally allowed:** the tool had no `--help`/usage flag of its own (the docstring
existed but nothing dispatched to it), and no closed set of valid flags — so there was no
concept of an "unrecognized" argument to refuse on. A hand-rolled `.startswith("--")` filter
reads as argument parsing but only implements argument *stripping*.

**Prevention:** `FLAGS = ("--check", "--dry-run", "--help", "-h")`; anything `-`/`--`-prefixed
outside that set now calls `refuse()` (exit 2, the project's existing "examined nothing, not a
pass" convention — see `refuse()`'s own docstring). `--help` and `-h` now genuinely print the
docstring and return 0. `tools/_t806-corpus-sweep-guard-controls.py` regression-tests this with
a control case: the same harness against the pre-fix source (`git show HEAD:...`) shows
`--help` DID call `write_back` there, proving the guard is load-bearing rather than redundant.

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

### 2026-09-24 — guard scope: validate flags, don't wall off the default bake
- **Chose:** treat the gap as "unrecognized flags are silently swallowed," not "the tool's
  documented default (no args → bake everything) is itself unsafe." Fixed by validating argv
  against a closed flag set (refuse on anything else) and giving `--help`/`--dry-run` real
  no-write behaviour, while leaving the no-args-bakes-everything contract untouched.
- **Why:** the actual incident was a `--help` invocation being absorbed as a no-op and falling
  through to a full bake — not a deliberate, intentional `tools/bake-clean-layout.py` (no args)
  invocation gone wrong. The tool's whole purpose is to write into `rendered/`; the topology
  fix AEF asked for ("the topology, not attention, should protect the seam") is best aimed at
  the accidental-invocation path, not at adding friction to the tool's one legitimate job.
- **Rejected:** requiring an explicit `--write`/opt-in flag even for a bare, argument-free
  invocation — this would satisfy AC2's literal wording more strongly but changes the tool's
  long-standing documented contract (`Usage: ... (no map args → every map ...)`, unchanged since
  T-101) for every legitimate caller, on the strength of an incident that was never about
  deliberate no-args use. Left as a follow-up for a human to decide if wanted; not done here.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-806 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T12:17:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-806-exclude-examplesaef-processesrendered-fr.md
- **Context:** Initial task creation

### 2026-09-22T12:17:57Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
