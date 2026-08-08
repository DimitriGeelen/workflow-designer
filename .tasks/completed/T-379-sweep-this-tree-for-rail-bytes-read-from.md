---
id: T-379
name: "Sweep this tree for rail bytes read from a rendered view instead of payload_b64"
description: >
  AEF's T-2872 root cause: they extracted a delivered artifact by slicing a human-rendered subscribe view, which prefixes a display header per record and terminates each with a newline. Their send, the hub, and their client read were all byte-faithful; the only lossy step was the choice of source. Their rule — seam bytes are read from payload_b64 and hashed before touching a file, rendered output is never a wire format — is a class check I owe on my own tree, symmetric to the G-008 upstreams. Enumerate every site here that reads termlink message CONTENT and classify each: decodes payload_b64, or consumes rendered output. A zero is only meaningful with its denominator stated: if nothing in the tree reads rail content at all, that is unmeasured rather than clean, which is the empty-denominator failure T-344 already cost this project.

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-08T14:56:27Z
last_update: 2026-08-08T15:01:47Z
date_finished: 2026-08-08T15:01:47Z
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

# T-379: Sweep this tree for rail bytes read from a rendered view instead of payload_b64

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Every site in the tree that invokes termlink (CLI or MCP) is enumerated, with the
      search terms and file scope recorded so the denominator is auditable rather than
      asserted
- [x] Each site is classified: **decodes `payload_b64`**, **consumes rendered output**, or
      **does not read message content** — a three-way partition, because "not a defect" and
      "not examined" are different states and a two-way split hides the second
- [x] The verdict states the denominator alongside the count. A zero over an empty
      population is UNMEASURED, not clean — the exact failure T-344 already paid for here
- [x] If any rendered-output reader exists it is fixed or filed; if none exists, that is
      reported as a measured zero with its population size, not as an absence of concern
- [x] The classifier is shown to discriminate — it must produce a non-`payload_b64` verdict
      on a constructed rendered-reader, or a clean sweep is a comparator that says clean

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

## Measurements

`tools/_t379-rendered-as-wire-sweep.py` — **14 teeth legs, 0 failures**.

**Result: 492 tracked code files, 50 mention termlink, 9 read message content, 0 read it
from a rendered view.** All nine decode `payload_b64` or pass `--json`. Seven are in the
vendored framework (`lib/templates/scripts/agent-{send,respond,listeners,conversation-*}.sh`,
`subscribe-learnings-from-bus.sh`, `peer.py`), one is `tools/_t377`. AEF's T-2872 class does
not reproduce here.

**The number reached zero by three corrections, all in the same direction, and that is the
part worth recording.** First run: **5 RENDERED**. Every one was noise.

| run | count | what was actually wrong |
|---|---|---|
| 1 | 5 | 3 × array-built invocations (`sub_args=(… --json)` sat 4–6 lines above the call, outside the window); 2 × module **docstrings** quoting a command — one of them `rail-sweep.py`, whose docstring quotes the very commands it exists to distrust |
| 2 | 1 | an **error string**: `echo "…channel subscribe failed…"`. Two of my own defects cancelled into a finding — the verb matched without the tool, *and* the array assignment sat one line outside the window |
| 3 | 0 | correct, but over a denominator of **7** |
| 4 | 0 | over **9** — the matcher could not see Python argv-list form `["termlink","channel","subscribe",…]`, and the file it was blind to was **my own probe** |

Three corrections that each *removed* findings is the shape of an instrument being quietly
disarmed — a broken matcher moves the count toward zero too. So the controls are not
imagined failure modes: they are **the two that actually occurred**, the one the **repair
could have introduced** (array resolution blanketing everything into PAYLOAD), and a final
leg requiring the classifier to still report a plain rendered read after all three. Without
that last leg a zero here would be indistinguishable from a matcher that had stopped
matching.

Run 4 is the one that strengthened the claim rather than shrinking it: fixing the matcher
**raised** the denominator from 7 to 9. A zero over a population that grows when you look
harder is worth more than a zero over one that shrinks.

**Scope.** Static classification of call sites in tracked `.sh`/`.py`/`.mjs`/`.js`, excluding
`dist/` and `vendor/` (built copies of `src/`, named rather than silently filtered). It reads
what the code *asks for*, not what any process did at runtime. `.mcp.json`, prose docs and
built HTML are excluded by extension and carry no call sites.

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

# Exit code IS the verdict: 0 rendered readers, over a non-empty population, with a
# classifier that failed its own controls loudly at three earlier revisions. No literal
# counts here — the population moves whenever a call site is added, and pinning it would
# be the same G-015 shape this project keeps re-finding.
python3 tools/_t379-rendered-as-wire-sweep.py

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

### 2026-08-08T14:56:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-379-sweep-this-tree-for-rail-bytes-read-from.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5c2a3ed1
- **Timestamp:** 2026-08-08T15:01:48Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-08T15:01:47Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
