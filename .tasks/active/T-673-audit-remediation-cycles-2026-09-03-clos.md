---
id: T-673
name: "audit remediation cycles 2026-09-03: close the recurring fabric coverage warns with real cards, not stub registrations"
description: >
  audit remediation cycles 2026-09-03: close the recurring fabric coverage warns with real cards, not stub registrations

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
created: 2026-09-03T19:51:17Z
last_update: 2026-09-03T19:51:17Z
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

# T-673: audit remediation cycles 2026-09-03: close the recurring fabric coverage warns with real cards, not stub registrations

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Every card this task creates carries a purpose SOURCED FROM THE FILE ITSELF** —
      its docstring, header comment, or `<title>` — and never the string `TODO`. A card
      whose purpose is a placeholder is a registration, not topology (T-671). Asserted by
      a check that greps the created set for `TODO`, not by inspection.

- [x] **Coverage does not rise by manufacturing stubs.** `fw fabric scan` would register
      256 empty cards and move `registered` 105 → 361 while every one of them landed in
      the *separate* "cards have no edges" warn. That is the aggregate moving the wrong
      way under the obvious fix, which is the exact defect T-671's three-word fence was
      built to expose. Required evidence: the **edgeless proportion does not worsen**
      across the cycles (46/105 = 43.8% baseline), reported per cycle.

- [x] **Edges are DERIVED from source bytes, not asserted.** Reuse
      `tools/_t671-arc0-edge-derive.py`, whose comment-stripping follows the referring
      file's own language (T-669: mention is not invocation). A file that genuinely
      nothing references gets an honest edgeless card and is counted as such — not given
      a decorative edge to clear a warn.

- [x] **Regeneration is idempotent** — running the generator twice leaves
      `git diff --quiet .fabric/components/`. Without this the card set silently drifts
      from the tree it claims to describe.

- [x] **Each cycle reports the audit delta (Pass/Warn/Fail) before and after**, and names
      which warns moved and which did not. A cycle that changes nothing is reported as
      changing nothing.

- [x] **Operator-owned findings are SURFACED, not executed.** Specifically not run:
      `fw inception sweep` (ticks Human ACs), `fw task archive-eligible` and any
      completion of an `owner: human` task (D2 FAIL, CTL-029 stuck-partial), release cut
      (G-007), and `tools/verification-hygiene-baseline.json --tighten`.

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
         1. Run `bin/fw reviewer T-673`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-673 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Cycle log

| cycle | action | Pass | Warn | Fail | fabric coverage | edgeless |
|---|---|---|---|---|---|---|
| 0 baseline | — | 160 | 32 | 1 | 105/358 (29%) | 46/105 = **43.8%** |
| 1 | card whole watch set, sourced purpose + derived edges | — | — | — | **362/359 (100%)** | 104/362 = 28.7% |
| 2 | refresh the 43 code stubs (TODO purpose AND edgeless) | — | — | — | 100% | **67/362 = 18.5%** |
| 3 | T-671 regression check + fence footer correction | 164 | 27 | 1 | 100% | 18.5% |

**Two warns with 13-audit streaks are now PASS:** `Fabric: N registered, M unregistered`
and `Fabric drift: N source files have no card`. Both had appeared in every audit's trend
analysis for two weeks.

## Findings

### The audit's own mitigation was the wrong fix, and would have scored as progress

The audit prints `Run: fw fabric scan` against the coverage warn. That registers a stub
per file: `registered` 105 → 361, and all 256 new stubs land in the **separate** edgeless
warn. One number improves and another degrades by the same act. T-671 built its three-word
fence to make exactly that visible on 28 files; this applied the same discipline to 359.

Measured instead: 257 cards written, **257 with a purpose sourced from the file's own
docstring/header, 0 unsourced, 0 containing `TODO`**.

### "Registered was counting stubs" is a tree-wide condition, not an Arc-0 one

T-671 found all 6 pre-existing Arc-0 cards were `TODO` stubs. Tree-wide the same
measurement: **46 of the 47 TODO-purpose cards were exactly the 46 edgeless cards** — one
population, two symptoms, reported by the audit as two independent warns. Refreshing the
43 that are code files gave **37 of them real derived edges**; 6 are honestly edgeless and
3 are `.xml` fixtures the extractor cannot read and which were deliberately left alone.

### The remaining edgeless warn is now honest, and that is the point

67/362 remain edgeless: 58 newly-carded files nothing references and which reference
nothing, 6 refreshed stubs in the same position, 3 XML fixtures. **None can be reduced
without inventing an edge**, which is the false green in the other direction. The warn is
no longer an artifact of stub registration; it is a true statement about leaf files.

### Scope bound this task does NOT clear

New cards carry both directions from one forward pass over all 359 files. Pre-existing
cards that were *not* stubs were left untouched, so where such a card is now referenced by
a newly-carded file, its own `depended_by` does not say so. The graph is complete for the
300 cards this task wrote and unchanged for the rest. Not repaired here because rewriting
authored cards wholesale is how generated trees eat hand work.

### Surfaced, not executed

- **13× CTL-029** "all Agent ACs ticked but `started-work`" (T-041, T-101, T-102, T-105,
  T-189, T-209, T-286, T-293, T-309, T-344, T-345, T-357, T-402) — **every one is
  `owner: human`.** Completing them is not delegated.
- **4 inceptions with no research artifact** (T-015, T-103, T-250, T-587) — checked
  whether they were misfiled rather than missing, as T-600's `## Updates` turned out to be
  this morning. **They are genuinely absent.** Writing them now would fabricate a thinking
  trail that never happened, which is worse than the warn.
- **D13 inception limbo** (T-309, T-357) — `fw inception sweep` ticks Human ACs.
- **D2 FAIL**, release lag (G-007), gate-bypass log review — operator's.

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


# No card this task wrote carries a placeholder purpose. Positive assertion on the
# created set, so a change to the audit's phrasing cannot make it pass by accident.
python3 -c "import os,yaml,sys; D='.fabric/components'; bad=[f for f in os.listdir(D) if f.endswith('.yaml') and (lambda c: c.get('created_by')=='T-673' and 'TODO' in str(c.get('purpose') or ''))(yaml.safe_load(open(os.path.join(D,f))) or {})]; sys.exit(1 if bad else 0)"

# Every watched file has a card. This is the coverage warn, asserted directly.
python3 -c "import os,subprocess,sys,yaml; w=set(subprocess.run([sys.executable,'.agentic-framework/agents/fabric/lib/expand_patterns.py','.fabric/watch-patterns.yaml','.'],capture_output=True,text=True).stdout.split()); D='.fabric/components'; c={(yaml.safe_load(open(os.path.join(D,f))) or {}).get('location') for f in os.listdir(D) if f.endswith('.yaml')}; sys.exit(0 if not (w-c) else 1)"

# The edgeless PROPORTION stays below the 43.8% baseline. A ratchet, not a snapshot:
# this is the leg that a stub-registration "fix" would fail while raising coverage.
python3 -c "import os,yaml,sys; D='.fabric/components'; cs=[yaml.safe_load(open(os.path.join(D,f))) or {} for f in os.listdir(D) if f.endswith('.yaml')]; e=sum(1 for c in cs if not (c.get('depends_on') or []) and not (c.get('depended_by') or [])); sys.exit(0 if cs and e/len(cs) < 0.438 else 1)"

# Regenerating the cards changes nothing. Without this the set drifts from the tree.
python3 tools/_t673-fabric-cards.py --refresh-stubs >/dev/null 2>&1 && git diff --quiet .fabric/components/

# T-671's Arc-0 fence still passes and its red arms still fire — this task rewrote 300
# cards in the directory that fence ranges over, so it is a regression guard, not decor.
python3 tools/_t671-arc0-fabric-fence.py
python3 tools/_t671-arc0-fabric-fence.py --self-test

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
     fw inception decide T-673 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-03T19:51:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-673-audit-remediation-cycles-2026-09-03-clos.md
- **Context:** Initial task creation
