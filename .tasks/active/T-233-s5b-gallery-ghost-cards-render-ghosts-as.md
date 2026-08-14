---
id: T-233
name: "S5b gallery ghost cards render ghosts as visually-distinct GHOST entries"
description: >
  S5b: render /api/list ghosts[] as visually-distinct GHOST cards in the gallery index. UI slice — needs visual verification; assess build-vs-inception scope before starting. Split from S5 (sibling S5a=T-232). Depends on S3 ghosts[] + S4 claim.

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
created: 2026-07-22T06:26:46Z
last_update: 2026-08-14T17:05:07Z
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

# T-233: S5b gallery ghost cards render ghosts as visually-distinct GHOST entries

## Context

An off-page connector may point at a `workflowRef` uuid with no live map yet. The gallery
server surfaces those as `ghosts[]` on `/api/list`. Today **only** the separate "Pending
refs…" modal (T-228 / S4a) shows them; the Open-project browser reads `d.maps` and throws
`d.ghosts` away, so the one surface an operator actually opens to see "what is in this
project" is silently missing every pending reference. This slice renders them there, as
entries that cannot be mistaken for a real map.

**Preconditions, checked before starting rather than assumed (the T-424 lesson):** the
`description` names two — *S3 ghosts[]* and *S4 claim*. Both are materially met:

- **S3** — `/api/list` returns one live ghost (verified at runtime under T-500).
- **S4** — T-228 is still `started-work`/`owner: human`, but its deliverable is already in
  the source: `createFromPendingRef()` at `src:9064`, the picker modal at `src:8948`, the
  button wired at `src:9212`. The task is open awaiting the operator's verification, not
  awaiting the code. Same shape as T-241, where the deliverable had shipped under another
  task and the park never noticed.

**Scope assessment the description asked for (build vs inception):** build. One UI element
in one file, reusing `createFromPendingRef` and `makeThumbPlaceholder` that already exist.
No new claim logic, no new endpoint, no new state.

## Acceptance Criteria

### Agent
- [x] `openProjectModal` reads `d.ghosts` from the same `/api/list` response it already
      fetches, and renders each ghost as a card in the Open-project browser
- [x] Ghost cards are visually distinct from map cards by more than one signal — dashed
      border, amber accent, a `◌` tile instead of a thumbnail, and a `pending ref` badge —
      so the distinction survives a colourblind reader and a greyscale screenshot
- [x] A ghost card never issues an `/api/thumb` request (there is no tile to fetch; a map
      card's 404→▦ fallback would misrepresent it as a map whose thumbnail is merely missing)
- [x] Clicking a ghost card closes the modal and calls `createFromPendingRef(ghost)` — the
      identical S4a claim path as the Pending-refs modal, with no second implementation
- [x] Ghost cards are excluded when `opts.pick` is set (pick mode chooses an off-page
      *target*; returning a uuid with no live map would write an unresolvable ref)
- [x] Ghost cards participate in the filter box and carry no 🗑 delete affordance
- [x] The empty state says "No project maps found." only when maps **and** ghosts are both
      empty; a project with nothing but pending refs is not an empty project
- [x] `bash tests/run-bridge-tests.sh` passes with 0 failures

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

- [ ] [REVIEW] A ghost entry reads as "not a map yet" at a glance, without reading the badge

  **Steps:**
  1. `cd /opt/832-Workflow-designer && python3 tools/gallery-serve.py 3099 --docroot src --repo .`
  2. Open `http://localhost:3099/aef-workflow-designer.html` in your browser
  3. Click **📂 Open** in the toolbar
  4. Look at the grid without reading any text — then read the badges

  **Expected:** The pending-ref entries are obviously a different kind of thing from the
  map tiles before you read a single word. Clicking one seeds a new map that adopts the
  ghost's uuid and toasts "Save to project to claim it."

  **If not:** Say which signal failed (border / colour / tile glyph / position). This is a
  taste call on visual weight — I can make it louder or quieter, but I should not be the
  one deciding it is loud enough.

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

bash tests/run-bridge-tests.sh
node tools/_t233-ghost-cards-cdp.mjs

## Visual Verification

Served surface, not `file://` (PL-045): `tools/gallery-serve.py 3099 --docroot src --repo .`,
driven with a real Playwright click on `#btn-open-project`. The repo's one live ghost
(`future-map`, uuid `4300eae7…`, referenced by `claim-smoke-legacy`) rendered among the 33
map cards — 34 children in the grid where there were 33.

- `.playwright-mcp/t233-ghost-card-open-project.png` — the ghost card beside three real map
  tiles. Dashed amber border, `◌` tile where the others carry a thumbnail, `◌ pending ref ·
  referenced by 1` badge, uuid prefix in place of a map id.
- `.playwright-mcp/t233-ghost-card-greyscale.png` — **the same frame desaturated.** The code
  comment and AC-2 both claim the distinction survives a colourblind reader; a claim about
  what colour does is not verified by looking at the colour version. Desaturated, the dashed
  border and the empty `◌` tile against the dense map thumbnails still carry the whole
  distinction, and the badge text is legible. The claim holds — checked, not asserted.

### The guard was green on nothing, twice, before it was green on anything

`tools/_t233-ghost-cards-cdp.mjs` is hermetic on purpose — it injects an `/api/list`
payload of 2 maps and 3 ghosts rather than reading the corpus, because the corpus holds
exactly one ghost and will hold zero the moment somebody claims it. A guard whose
denominator can fall to zero passes loudest when it has stopped measuring.

Having written that reasoning into the file's header, I then shipped the same defect inside
it. Run against the pre-change source as a negative control, three legs reported **PASS**
while rendering zero ghost cards: `every()` over an empty array is true, and "no ghost
requested a thumbnail" is trivially satisfied when there are no ghosts. Only the two legs
that count something failed. Each leg now asserts its own denominator, and the control
went from 3 FAIL to 8 FAIL of 10 — the two that still pass do so honestly (the old code
really did suppress the empty state when maps exist, and really did offer no ghosts in
pick mode, having none anywhere).

One earlier leg was also measuring the wrong thing: it counted surviving `<img>` elements
and read 0 where it expected 2. Under `file://` every thumb URL fails, `img.onerror` fires,
and `src:8882` replaces the `<img>` with the `▦` placeholder — so it was counting whether
T-149's fallback had swept the evidence away, not whether the request was made. It now
intercepts the `src` setter, which measures the request itself.

Neither of these was caught by suspicion. The first was caught because the control was run
at all, and the second because a number contradicted one already on screen.

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

### 2026-07-22T06:26:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-233-s5b-gallery-ghost-cards-render-ghosts-as.md
- **Context:** Initial task creation

### 2026-08-14T17:05:07Z — status-update [task-update-agent]
- **Change:** horizon: later → now

### 2026-08-14T17:05:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
