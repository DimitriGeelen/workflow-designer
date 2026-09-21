---
id: T-770
name: "Standing instruction: an external reviewer verdict may stand in for human verification, with named exceptions"
description: >
  The operator delegated Human-AC verification to the external reviewer agent, except for high-risk, Tier 0 and genuine UX/taste judgement. Record it as policy AND make it a gate, not a note.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t770-delegation-boundary.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-21T12:00:17Z
last_update: 2026-09-21T12:23:46Z
date_finished: 2026-09-21T12:23:46Z
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

# T-770: Standing instruction: an external reviewer verdict may stand in for human verification, with named exceptions

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The reviewer's written standard is located — and it is not where the instruction
      assumes.** There is **no `agents/reviewer/` directory and no reviewer AGENT.md** in
      this vendored tree (`.agentic-framework/agents/` holds 24 agents; reviewer is not one
      of them). The standard exists in two other places instead:

      1. `.agentic-framework/docs/reports/T-1443-independent-reviewer-agent.md` — **GO
         2026-04-25**, with three locked decisions quoted verbatim in T-1950:
         > 36. Reviewer authority = **mechanical tick on Agent ACs only** (NOT Human ACs).
         > 113. Reviewer NEVER auto-ticks a `### Human` AC. **Original classification is inviolable.**
         > 213. Sovereignty preservation: reviewer NEVER ticks `### Human` ACs — structurally enforced.
      2. `.agentic-framework/lib/reviewer/static_scan.py:7` — the same rule as a docstring:
         *"Sovereignty: NEVER modifies AC checkboxes for Human ACs or non-[REVIEWER] Agent ACs."*

      T-1443's sketch proposed `agents/reviewer/` as a profile directory. It was never
      created; the implementation landed as a Python library. **So "always use the agent
      file" cannot be followed literally here — there is no file to load.** That is a
      finding for AEF, not a local defect.

- [x] **Whether the implementation applies the standard: measured, and it does — more
      strictly than the instruction as spoken.** `_should_auto_tick` is `[REVIEWER]`-prefix
      only (`static_scan.py:2157`), idempotent by digest against the feedback stream
      (`:166-173`), and gated by an override register with TTL. Auto-tick **shipped** — my
      first read of T-1950 said *"only the write is missing"*, which was true when that
      inception was written and is false now. Checked rather than quoted.

      **The `--dispatch` worker is NOT handed the standard, and that is correct here.** Its
      entire prompt is *"Execute this shell script using the Bash tool … Do not do anything
      else"* (`dispatch_cli.py:105-110`). The reviewer is a **deterministic scanner**, not a
      judging LLM, so isolation buys process separation and recursion safety
      (`FW_REVIEWER_IN_DISPATCH=1`), not independent opinion. Worth stating plainly so
      nobody reads "external reviewer" as "second mind".

- [x] **The delegation boundary is written down as a mechanical predicate, not a judgement
      call.** `tools/_t770-delegation-boundary.py`. `classify(task, ac)` puts every
      acceptance criterion in the live queue into exactly one bucket and returns the rule
      that put it there:

      | bucket | rule |
      |---|---|
      | `REVIEWER-CLOSEABLE` | `### Agent` + `[REVIEWER]` prefix, no carve-out fired. This is the entire delegated surface. |
      | `AGENT-SELF` | `### Agent`, no `[REVIEWER]` prefix — the agent closes it under P-011; the reviewer may not tick it either (`static_scan.py:7`). |
      | `OPERATOR-ONLY` | `### Human` section (AEF decision 113 — original classification is inviolable), or a carve-out fired. |

      Carve-outs, in evaluation order — the criterion's own properties before the task's,
      so the reason returned is the most specific one rather than the first one that
      happens to be true: `taste` (`[REVIEW]`) · `act-in-the-world` (`[RUBBER-STAMP]`) ·
      `tier0-or-bypass` (body names a gate-bypass or destructive token) ·
      `sovereignty-field` · `release-surface` · `inception-decision` · `owner-human`.

      Every input is a heading, a literal prefix token, a frontmatter field, or one of
      three fixed token lists. There is no score, no threshold and no heuristic, which is
      the point: **nowhere in the file does an agent decide what counts as "high risk".**
      That was this criterion's actual test — a boundary the agent evaluates per case is
      not a delegated boundary, it is a moved one.

      `--self-test`: 12 legs green, each with a negative control in the set — prefix
      removed must NOT be closeable; `cost_estimate_proposed:` must NOT demote where
      `cost_estimate:` does; `[REVIEW]` must NOT be flagged convertible where `[REVIEWER]`
      is. PL-178: a leg that cannot fail is asserting nothing.

- [x] **The policy is recorded as a decision AND the gap between policy and enforcement is
      named.** Decision recorded in `.context/project/decisions.yaml` (T-770). Gap
      **G-052** registered `watching` in `.context/project/concerns.yaml` with a renderable
      closure condition.

      **What is NOT enforced, stated rather than implied:** the predicate is a reporter.
      Nothing calls it. `fw task update --status work-completed` does not consult it, and
      `fw reviewer` carries its own independent encoding of the same rule in
      `static_scan.py:_should_auto_tick`. Two implementations of one boundary, neither
      checking the other — exactly the drift shape this AC was written to avoid. Today they
      agree; nothing makes them keep agreeing. G-052 holds that open, and names the check
      that closes it: the predicate and the scanner must be shown to return the same
      verdict over the live tree, by a test, not by inspection.

- [x] **No Human AC is ticked by the agent under this task, and no ownership is changed.**
      The standing instruction authorises a future mechanism; it is not retroactive
      permission to close the queue that exists today.

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
         1. Run `bin/fw reviewer T-770`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-770 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Findings

### The mechanism exists, matches the ruling, and is idle by mis-filing

Measured 2026-09-21 across `.tasks/active/`:

| | count |
|---|---|
| `[REVIEWER]` ACs total | 107 |
| `[REVIEW]` ACs (operator's, taste/accountability) | 190 |
| `[RUBBER-STAMP]` ACs | 6 |
| **unticked `[REVIEWER]` under `### Agent`** — auto-tick may fire | **3** |
| **unticked `[REVIEWER]` under `### Human`** — reviewer structurally forbidden | **104** |

**104 acceptance criteria are marked `[REVIEWER]` — meaning their Expected clause is
deterministic and a scanner can settle them — and filed in the section where the reviewer
is forbidden to act.** They sit across 104 separate tasks. That is the review queue.

The framework is not missing a capability. The capability is wired, shipped, bounded and
idle, because the ACs it is allowed to touch were filed one heading too far down.

`.tasks/templates/default.md:51-56` already states the rule that would have prevented it:
*"default to `[REVIEWER]` if Expected is grep-able … that AC should be an Agent AC with the
reviewer command in `## Verification` instead of a Human AC here."*

### Correction, 2026-09-21 — the 104 does not exist

The table above was produced by a file-level grep for the `[REVIEWER]` token, and what it
counted was the task template's own comment block. `.tasks/templates/default.md` ships a
worked `[REVIEWER] example` *inside* the `### Human` HTML comment, and that comment is
copied into every task file at creation. 108 of the active task files contain the token;
**0 of them carry it on an acceptance-criterion line.**

Measured again, this time restricted to AC lines (`^- \[[ xX]\] *\**\[PREFIX\]`):

| | reported earlier | actually |
|---|---|---|
| `[REVIEWER]` on an AC line | 107 | **0** |
| `[REVIEW]` on an AC line | 190 | **86** |
| `[RUBBER-STAMP]` on an AC line | 6 | 6 |

The finding survives the correction and gets sharper, pointing the other way. There is no
queue of 104 mis-filed criteria waiting on a reclassification, and no reclassification to
authorise. **The reviewer's delegated surface is empty — `REVIEWER-CLOSEABLE` = 0.** Nobody
has ever written a `[REVIEWER]`-prefixed acceptance criterion in this project.

L-302 one level up: I shipped the detector and read its output as the measurement without
first asking what the generator puts into every file. The boilerplate *was* the signal.

### What the predicate reports, 2026-09-21

319 open acceptance criteria across `.tasks/active/`:

| bucket | count |
|---|---|
| `REVIEWER-CLOSEABLE` | **0** |
| `AGENT-SELF` | 115 |
| `OPERATOR-ONLY` | 204 |

`OPERATOR-ONLY` by rule: `owner-human` 92 · `taste` 76 · `inception-decision` 29 ·
`act-in-the-world` 6 · `tier0-or-bypass` 1.

The operator's own queue is **82 open `### Human` criteria** — 76 `[REVIEW]` and 6
`[RUBBER-STAMP]`, none unprefixed. So the prefix-routing rule *is* being applied wherever a
Human AC gets written. What nobody writes is the Agent-side `[REVIEWER]` AC, which is the
only shape the reviewer is allowed to close.

### What this means for the standing instruction

The operator's instruction — *reviewer says good, then it may close, except high risk,
Tier 0 and real UX judgement* — **is already AEF policy**, decisions 36/113/213, GO'd
2026-04-25. It needs no new authority. What it needs is for the 104 to be reclassified so
the reviewer can reach them.

**Superseded by the correction above.** The population this paragraph proposed to
reclassify is empty, so there is nothing to ask the operator to authorise. The
conversion rule (T-1811/T-1878, Human→Agent for the deterministic mis-prefix class)
stands unchanged and unused. What the standing instruction needs is not a reclassification
but a supply: tasks written with `[REVIEWER]` Agent ACs in the first place.

## Verification

./tools/_t770-delegation-boundary.py --self-test
test $(grep -rlE '^- \[[ xX]\] *\**\[REVIEWER\]' .tasks/active/ | wc -l) -eq 0
./tools/_t770-delegation-boundary.py --json > /tmp/.t770-boundary.json && python3 -c "import json,sys; d=json.load(open('/tmp/.t770-boundary.json')); sys.exit(0 if len(d) > 100 and all(r['rule'] and r['bucket'] for r in d) else 1)"
grep -q 'G-052' .context/project/concerns.yaml
grep -q 'T-770' .context/project/decisions.yaml

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

### 2026-09-21 — the population the task was built for evaporated mid-build

- **What changed:** the task was filed to make a delegation boundary reachable for 104
  mis-filed `[REVIEWER]` criteria. Building the predicate that would classify them showed
  there are none. The original count came from a file-level grep that matched the task
  template's own worked example inside the `### Human` comment block — boilerplate present
  in 108 of 109 active task files, and on zero acceptance-criterion lines.
- **Plan impact:** the reclassification I had drafted for the operator was withdrawn before
  it was offered. The deliverable is unchanged and the conclusion inverts: the boundary is
  not blocked by mis-filing, it is unused because nothing in this project has ever been
  written with a `[REVIEWER]` Agent AC. The delegated surface is empty, not obstructed.
- **Triggered:** correction recorded in `## Findings` alongside the superseded table rather
  than in place of it; G-052 registered for the unreconciled second encoding. No new task —
  the supply question (why no task ever gets a `[REVIEWER]` AC) belongs to whoever next
  edits the template, and is stated in the Findings rather than pre-empted here.

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

### 2026-09-21 — the standing instruction is encoded as a predicate, not as prose

- **Chose:** express the operator's delegation as `tools/_t770-delegation-boundary.py`, a
  pure classifier over heading + prefix token + frontmatter field + fixed token lists, and
  record the policy as a decision with its enforcement gap named (G-052).
- **Why:** the instruction as spoken — *"except high risk, Tier 0 and large UX reviews"* —
  names an exception the agent would have to adjudicate case by case. An exception the
  agent adjudicates is not delegated authority; it is relocated authority. Encoding it so a
  script returns the bucket removes the agent from the decision entirely, which is what
  makes it safe to honour.
- **Rejected:** writing the boundary as guidance in CLAUDE.md. It would read as governance
  and enforce nothing — the T-624 shape, a correct notice that changes no number. Also
  rejected: wiring the predicate into the completion gate in this task. That is a gate
  change on the operator's queue and belongs to its own task under its own scrutiny; G-052
  holds it open rather than letting it land as a side effect.
- **Rejected:** proposing the 104-item reclassification I had drafted. The population was a
  measurement artefact (see Findings). Acting on it would have edited 104 of the operator's
  task files on the strength of a grep that counted template boilerplate.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-770 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T12:00:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-770-standing-instruction-an-external-reviewe.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-3398d9e7
- **Timestamp:** 2026-09-21T12:23:47Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-21T12:23:46Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
