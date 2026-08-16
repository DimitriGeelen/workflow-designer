---
id: T-400
name: "Gap register entries can be silently unreadable: G-027 used a closure field
  name no check reads"
description: >
  Gap register entries can be silently unreadable: G-027 used a closure field name
  no check reads

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
created: 2026-08-08T21:08:12Z
last_update: '2026-08-16T14:33:34Z'
date_finished: 2026-08-09T11:05:42Z
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
  - ts: '2026-08-16T12:33:56Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:34Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=0 (no-signal); F3=0 
      (no-signal); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:22Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.context/project/concerns.yaml,tools/_t352-p011-errexit-probe.sh,tools/_t400-schema-teeth.sh,tools/concerns-schema.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.context/project/concerns.yaml,tools/_t400-schema-teeth.sh,tools/concerns-schema.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-400: Gap register entries can be silently unreadable: G-027 used a closure field name no check reads

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] G-027 uses `decision_trigger`, the field the audit's closure check actually reads.
      Audit back to 19 pass / 3 warn / 0 fail (was 18/4/0).
- [x] `concerns.yaml` still parses.
- [x] **The register cannot silently accept an unreadable entry.** `tools/concerns-schema.py`
      refuses any field name that is neither read by code nor documented as prose, and names
      the remedy INLINE (including `decision_trigger`) rather than sending the reader to
      another command — G-027's whole cost was a message that misdirected. Teeth leg (a)
      uses the literal field name G-027 used, and proves the audit's existing heuristic
      would still miss it. **On "at write time":** the check runs standing (this task's
      `## Verification`; available to pre-commit or audit wiring). It is deliberately NOT
      wired as a new PreToolUse hook — that edits `.claude/settings.json` and moves the
      enforcement baseline, which is an operator-facing enforcement change rather than
      agent initiative. Surfaced in `## Operator decision needed` below.
- [x] Census the other 23 entries for fields that no check reads — done, and it found more
      than the two pairs named at filing. See `## Census`; `--census` reproduces it live.

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
# NOTE: carries neither G-015 shape — no serve-root diff, no port literal (T-350 AC8).
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"
python3 tools/concerns-schema.py
bash tools/_t400-schema-teeth.sh
# The specific G-027 miss, asserted by name so this cannot pass on another leg's green.
out=$(bash tools/_t400-schema-teeth.sh 2>&1); echo "$out" | grep -q "(a) closure_condition refused by name"
# G-027 itself still uses the field the audit reads.
out=$(python3 tools/concerns-schema.py --census 2>&1); echo "$out" | grep -q "decision_trigger"

## Census

25 entries, 20 distinct field names. Reproduce with
`python3 tools/concerns-schema.py --census`.

**Read by code — 6 of 20.** `id`, `status`, `title`, `severity`, `type`,
`decision_trigger`. That is the whole load-bearing surface of the register.

**Prose — 14 of 20.** `origin_task`(20), `detected`(18), `related`(14),
`description`(13), `detail`(12), `evidence`(11), `related_tasks`(11),
`registered`(7), `closure_evidence`(4), `resolved`(1), `resolution`(1),
`prevention_partial`(1), `progress`(1), plus the dated-evidence convention.

**The pairs named at filing are both inert, in the same direction.**
`detail`(12) vs `description`(13) — neither is read. `related`(14) vs
`related_tasks`(11) — neither is read. So the question the AC posed ("which member
is load-bearing?") has an answer nobody expected: *neither is*. The pairs are
harmless today precisely because no code depends on either. The risk is that they
LOOK load-bearing, which is the exact perceptual condition that produced G-027.

**A THIRD DIRECTION THE AC DID NOT ANTICIPATE — read-but-absent.** The census also
runs the mirror query, and it is the more interesting half:

| field | read by | entries carrying it |
|---|---|---|
| `closure_check_command` | `lib/gaps.py` one-click closure gauge | **0 / 25** |
| `last_reviewed` | `lib/gaps.py:408` staleness reference | **0 / 25** |
| `created` | `lib/gaps.py:408` staleness fallback | **0 / 25** |

The register carries `detected`(18) and `registered`(7); `gaps.py` reads
`created`/`last_reviewed`. **This is a second live instance of the G-027 shape,
running the other way** — the machinery is correct, its input never arrives, and
the staleness reference silently resolves to `""` for all 25 entries. Likewise the
one-click closure gauge has no users at all. Reported as a NOTE, never a failure:
an optional feature may legitimately have no users yet, and this task must not
smuggle in an argument that it should.

**Why the existing audit detector would not have caught G-027.** `audit.sh`
(~line 2107) flags an alternate key only when its name contains the substring
`trigger`. `closure_condition` does not contain `trigger`, so the very entry that
motivated this task would still have been classified `missing` rather than
`unread`. Near-synonyms do not reliably share a substring with the field they
shadow — that is what makes them near-synonyms. Teeth leg (a) pins this.

## Operator decision needed — NOT taken here

The AC asks for refusal **at write time**. The check exists and passes standing, but
making it a genuine write-time gate means adding a PreToolUse hook, which edits
`.claude/settings.json` and moves the enforcement baseline (L-398). Adding
enforcement is an operator-facing change to how the framework constrains everyone,
not agent initiative, so it is surfaced rather than done:

1. Leave standing-only (today's state) — caught at verification/audit, not at write.
2. Wire as a PreToolUse hook on Write|Edit matching `concerns.yaml` — true write-time
   refusal; requires `bin/fw enforcement baseline` after.
3. Wire into the audit as a FAIL — catches it a commit later, but with a message that
   no longer misdirects, which was most of G-027's actual cost.

No recommendation is withheld here: **option 3** is the cheapest honest improvement,
since the misdirecting message was the expensive part rather than the timing. Option 2
is the only one that satisfies the AC's literal wording.

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

### 2026-08-08T21:08:12Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-400-gap-register-entries-can-be-silently-unr.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-834e4103
- **Timestamp:** 2026-08-09T11:05:45Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-09T11:05:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
