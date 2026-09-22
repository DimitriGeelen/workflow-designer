---
id: T-814
name: "Delete refreshLibraryUI: inert body, ten no-op call sites (F-17)"
description: >
  Value review T-742 F-17, the ONLY item of 93 inventoried that cleared the DELETE evidence bar. refreshLibraryUI's first statement is 'const picker = $("workflow-picker"); if (!picker) return;' and no element with that id exists in the file — measured: 0 occurrences. Every statement after the guard operates on picker alone, so the function is a pure no-op that is called and returns immediately every time. T-154 records the dropdown's removal as deliberate ('one unified full-corpus entry point, no half-populated dropdown'), but that comment addresses the ELEMENT; the surviving call sites are residue it does not mention. Review said 8 call sites; measured 10.

status: started-work
workflow_type: refactor
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T13:41:06Z
last_update: 2026-09-22T13:46:55Z
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

# T-814: Delete refreshLibraryUI: inert body, ten no-op call sites (F-17)

## Context

Value review T-742 **F-17** — the **only** item of 93 inventoried that cleared the DELETE
evidence bar. The review is explicit about why so few did: *"DELETE requires positive evidence
— broken when exercised, or a recorded reason the need is gone. Across 93 inventoried items …
exactly one item cleared that bar. Everything else that looks deletable is D UNMEASURED, and D
means INVESTIGATE."*

`refreshLibraryUI` opened with
`const picker = $('workflow-picker'); if (!picker) return;` and **no element with that id
exists** — measured 0 occurrences. Every statement after the guard touched `picker` alone. So
it was called and returned immediately, every time, reading nothing and writing nothing.

What cleared the bar is not disuse: **T-154 records a positive decision** to replace the
dropdown with the brand-area "Open project" button — *"one unified full-corpus entry point, no
half-populated dropdown."* That comment addresses the **element**; the function and its call
sites are residue it never mentions.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Inertness proven BEFORE deletion, not assumed: `id="workflow-picker"` occurs 0 times, and every statement after the guard touches only `picker`
- [x] The function definition and all ten call sites are removed; zero references remain
- [x] A tombstone records why it went, so the next reader does not re-derive it — this file's established convention (see `DI_TRAILER`, T-158)
- [x] The editor still loads with no console error and round-trips the corpus byte-identically: a no-op removal must be observably a no-op
- [x] Visual verification: the app renders and a map opens after the deletion
- [x] The review's call-site count is corrected where measurement disagrees (it said 8; there are 10)


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-814 legs. Each line's exit code is its own verdict; no chaining. ---
# No CALLABLE reference may remain. Matches `refreshLibraryUI(` so the tombstone's prose
# mention of the name does not satisfy the assertion — and the file must exist, so a path
# typo cannot read as absence (grep exit 2 vs 1).
test -f src/aef-workflow-designer.html
bash -c 'test "$(grep -cE "refreshLibraryUI[[:space:]]*\(" src/aef-workflow-designer.html)" = "0"'
# CONTROL for the leg above: the pattern must be capable of matching. Proven against a
# throwaway copy with one call re-inserted — otherwise a broken regex reads as success.
bash -c 'd=$(mktemp -d); sed "s/^var _x;/var _x; refreshLibraryUI();/" src/aef-workflow-designer.html > "$d/c.html"; printf "refreshLibraryUI();\n" >> "$d/c.html"; n=$(grep -cE "refreshLibraryUI[[:space:]]*\(" "$d/c.html"); rm -rf "$d"; test "$n" -ge 1'
# The tombstone must survive, or the next reader re-derives all of this.
grep -q 'T-814 (value review F-17)' src/aef-workflow-designer.html
# The element really is absent — the premise the whole deletion rests on.
#
# JS COMMENT LINES ARE EXCLUDED, and the reason is a mistake this leg made on its first run:
# the tombstone written six lines above QUOTES the old markup (`<select id="workflow-picker">`)
# to explain what went, and a naive count matched its own documentation and failed. The
# assertion is about an ELEMENT, not about the string appearing anywhere in the file. That is
# the T-560 family exactly — an absence assertion satisfied, or in this case defeated, by
# something other than the condition it names — landing in the leg written to avoid it.
bash -c 'test "$(grep -vE "^[[:space:]]*//" src/aef-workflow-designer.html | grep -c "id=\"workflow-picker\"")" = "0"'
# CONTROL for the leg above: append a REAL element to a throwaway copy and require the count
# to rise. Without it, a pattern that excludes too much would report absence unconditionally.
bash -c 'd=$(mktemp -d); cp src/aef-workflow-designer.html "$d/c.html"; printf "<select id=\"workflow-picker\"></select>\n" >> "$d/c.html"; n=$(grep -vE "^[[:space:]]*//" "$d/c.html" | grep -c "id=\"workflow-picker\""); rm -rf "$d"; test "$n" -ge 1'
# A no-op removal must be observably a no-op.
python3 tests/test_roundtrip_serialization.py
python3 tests/test_bridge_seam_roundtrip.py
git diff --quiet HEAD -- examples/aef-processes/rendered/
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

## Decisions

### 2026-09-22 — delete, with a tombstone rather than silently

- **Chose:** remove the function and all ten call sites, and leave a comment where the
  function was.
- **Why a tombstone:** this file's established convention, and for a reason it demonstrates
  itself — `DI_TRAILER` is *kept, not deleted*, precisely so the guard that depends on it has
  something to compare against and the next person does not retype it by hand. A deletion
  with no trace invites someone to re-derive the same analysis, or worse, to re-add the
  function when a picker returns. The note says: build a new function against the new
  element, do not resurrect this one.
- **Rejected — leaving it:** it is the one item with positive evidence. Keeping it would mean
  the review's single DELETE produced no deletion at all.
- **Rejected — deleting the other candidates too:** nine other zero-reference functions, five
  zero-use schema constructs, four zero-use io types and five never-instantiated node types
  are all **D UNMEASURED**. D never justifies DELETE, and the review says so in terms. They
  stay.

### 2026-09-22 — the review said 8 call sites; there are 10

- Measured: 2506, 2823, 2858, 5569, 5578, 7420, 8676, 9658, 9694, 11295. All ten removed.
- Small, but it is the third count in this review that measurement moved (after F-06's
  per-node totals and F-11's 47-vs-24). Recorded rather than quietly absorbed.

### 2026-09-22 — my own tombstone defeated my own absence leg

- **What happened:** the leg asserting `id="workflow-picker"` occurs 0 times **failed** — the
  tombstone I had just written quotes `<select id="workflow-picker">` to explain what was
  removed, and the naive count matched its own documentation.
- **The element was absent the whole time.** The condition was right; the pattern was wrong.
  That is the **T-560 family** — an absence assertion answering to something other than the
  condition it names — arriving inside the leg written to guard this deletion.
- **Fix:** exclude JS comment lines, plus a control that appends a *real* element to a
  throwaway copy and requires the count to rise. Without that control, a pattern that
  excluded too much would report absence unconditionally and look identical to success.
- **Worth the words:** this is the second time today a control caught my own instrument
  rather than the code (T-813's double-record was the first). Both were found by running the
  thing, not by reading it.

## Visual Verification

Screenshot: `.playwright-mcp/t814-after-deletion.png`, read with the Read tool.

`context-memory.bpmn` imported and rendered after the deletion — 12 nodes, 12 edges, lanes
drawn, properties panel bound to `context-memory_v2`, `v0.12.0` still in the header. Console
carries two errors, both the pre-existing environmental class: `/api/health` and `/api/list`
404 on a static preview server with no gallery backend. **No `refreshLibraryUI is not
defined`** — and `typeof refreshLibraryUI` evaluates to `undefined` in the live page,
confirming the symbol is genuinely gone rather than merely unreferenced.

The extracted script block also passes `node --check`.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-814 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T13:41:06Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-814-delete-refreshlibraryui-inert-body-ten-n.md
- **Context:** Initial task creation
