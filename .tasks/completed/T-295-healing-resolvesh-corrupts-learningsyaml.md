---
id: T-295
name: "healing resolve.sh corrupts learnings.yaml: indented append into column-0 list + max-id grep misses column-0 ids (always mints L-001)"
description: >
  healing resolve.sh corrupts learnings.yaml: indented append into column-0 list + max-id grep misses column-0 ids (always mints L-001)

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-29T06:10:59Z
last_update: 2026-07-29T06:16:14Z
date_finished: 2026-07-29T06:16:14Z
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

# T-295: healing resolve.sh corrupts learnings.yaml: indented append into column-0 list + max-id grep misses column-0 ids (always mints L-001)

## Context

`fw healing resolve` (vendored `.agentic-framework/agents/healing/lib/resolve.sh`)
appends its learnings entry with a 2-space-indented `- id:` block into
`.context/project/learnings.yaml`, whose top-level list sits at column 0 —
producing invalid YAML (caught by the T-1599 pre-push gate on 2026-07-29 while
resolving T-293). Its max-L-id grep also only matches the indented form
(`^  - id: L-`), so it never sees existing column-0 entries and always mints
`L-001` — a duplicate L-001 from T-262 (2026-07-27, same bug, hand-re-indented
but never renumbered) is already in the file. Vendored-tree fix, upstream to
AEF per G-008.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] resolve.sh appends the learnings entry at the file's actual list indent
      (column 0, matching every sibling entry) so the file stays parseable
- [x] The max-id scan sees existing ids regardless of indent (both `- id: L-`
      and `  - id: L-` forms) so minted ids are unique, never a duplicate L-001
- [x] No duplicate learning ids remain in learnings.yaml (today's mis-minted
      L-001 was renamed PL-059 in 792ad87; T-262's L-001 is thereby unique)
- [x] Fix verified by running `fw healing resolve` against a scratch copy:
      output parses as valid YAML and the new id is max+1
- [x] Upstream report queued to AEF on the rail (G-008 — vendored fix must not
      be lost on next re-vendor): posted at rail offset 306 (reply to their 305
      T-2665 exception-handling seed — defect + fix recipe + scratch evidence)

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
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

bash -n .agentic-framework/agents/healing/lib/resolve.sh
grep -q 'T-295' .agentic-framework/agents/healing/lib/resolve.sh
out=$(grep -cE '^\$\{indent\}' .agentic-framework/agents/healing/lib/resolve.sh); [ "$out" -ge 7 ]
python3 -c "import yaml; yaml.safe_load(open('.context/project/learnings.yaml'))"
out=$(grep -c '^- id: L-001' .context/project/learnings.yaml); [ "$out" -eq 1 ]

## RCA

**Symptom:** After `fw healing resolve T-293`, `git push` was blocked by the
pre-push YAML gate: learnings.yaml unparseable ("expected <block end>, but
found '-'"). The appended entry carried id `L-001` although the file already
holds one.

**Root cause:** `resolve.sh` hard-codes a 2-space-indented heredoc (`  - id:`)
while learnings.yaml's top-level sequence is at column 0; mixed indent under a
column-0 list is invalid YAML. Separately, the max-id grep pattern
`^  - id: L-` only matches the indented form, so existing column-0 ids are
invisible and the counter restarts at L-001 every run.

**Why structurally allowed:** healing's writer has no post-write parse check;
the corruption is only caught later, at push time, by the T-1599 pre-push gate
— one full commit after the damage. The same mis-write already happened at
T-262 and was hand-repaired (indent only), leaving no signal that the tool was
the culprit.

**Prevention:** the T-1599 pre-push gate remains the backstop; this fix makes
the writer emit the file's real shape and adds id-scan robustness to both
indent forms. Upstream report to AEF so the fix survives re-vendor (G-008).

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

### 2026-07-29T06:10:59Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-295-healing-resolvesh-corrupts-learningsyaml.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-89553ce4
- **Timestamp:** 2026-07-29T06:16:15Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-29T06:16:14Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
