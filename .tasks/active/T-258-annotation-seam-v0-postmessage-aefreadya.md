---
id: T-258
name: "Annotation seam v0: postMessage aef:ready/aef:annotate read-only badge layer + MANIFEST capabilities flag (T-250 GO)"
description: >
  Build the T-250 GO-ratified annotation seam, shape A (operator decision 2026-07-27): (1) designer emits postMessage {type:'aef:ready', uid list} to parent after EVERY render including initial load (renderAll rebuilds SVG so annotations wipe per render — re-handshake is the contract); (2) accept {type:'aef:annotate', annotations keyed by node uid} and render a read-only badge layer on g[data-id=uid] — never serialized into BPMN, dropped on document switch, unknown uids ignored silently; (3) add MANIFEST capabilities flag (annotation_seam) — T-246 second-consumer promotion trigger, AEF conditional-emit guard self-configures at re-pin; (4) suite leg + origin-policy decision (IW-3 deferred from T-250). Consumer contract fixed both sides: AEF feed = single Watchtower aggregation endpoint emitting aef:annotate verbatim (rail 210); their overlay v0 build is unblocked by this ratification (announced at rail 216).

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
created: 2026-07-27T17:54:59Z
last_update: 2026-07-27T19:00:30Z
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

# T-258: Annotation seam v0: postMessage aef:ready/aef:annotate read-only badge layer + MANIFEST capabilities flag (T-250 GO)

## Context

Build ratified by T-250 GO (operator, 2026-07-27, shape A postMessage). Contract
announced to AEF at rail 216; their overlay v0 consumes it (feed = single
Watchtower aggregation endpoint emitting the aef:annotate payload verbatim,
rail 210). DOM key: `g[data-id]` IS the node uid (node.id = node.uid, src :1986).

## Acceptance Criteria

### Agent
- [x] `aef:ready` handshake: when embedded (window.parent !== window), the designer
      posts `{type:'aef:ready', uids:[...], workflow:<meta id>}` to the parent after
      EVERY renderAll() — including initial load, edits, doc open — because renderAll
      rebuilds the SVG wholesale (re-handshake per render is the ratified contract).
      Never posts when not embedded.
- [x] `aef:annotate` intake: accepts `{type:'aef:annotate', annotations:[{uid, badge,
      tone?, title?}]}` ONLY from the embedding parent (event.source === window.parent);
      renders a read-only badge layer anchored to `g[data-id=uid]`; unknown uids
      silently ignored; malformed messages ignored without console errors; badge text
      rendered via text nodes only (no HTML injection path).
- [x] Never serialized + lifecycle: annotations exist only in the DOM overlay
      (buildBpmnXml output byte-free of them); wiped by the next render (parent
      re-annotates after the re-handshake); dropped on document switch/open;
      excluded from captureThumbnail output.
- [x] MANIFEST capabilities flag: release manifest gains a structured
      `capabilities:` block including `annotation_seam: 1` (T-246 promotion trigger;
      AEF's conditional-emit guard self-configures at re-pin) — generated
      deterministically by scripts/release-designer.sh.
- [x] Suite leg: new CDP harness embeds the real designer in an iframe host page and
      proves the full loop — ready received on load with correct uid list; annotate
      renders badges for known uids, ignores unknown; re-render re-emits ready and
      wipes badges; doc switch drops; emitted BPMN clean; BITE (no badge without
      annotate). Existing suite stays green.
- [x] Visual verification: element-level screenshot(s) of rendered badges READ and
      confirmed (badge legible, not colliding with node chrome).

### Human
- [ ] [REVIEW] Badge look-and-feel reads right
  **Steps:**
  1. Open the review page: http://192.168.10.107:3000/review/T-258
  2. Look at the badge screenshot referenced under Visual Verification
     (`.playwright-mcp/t258-annotation-badges.png`) — a green "running" pill above
     a start event and a red "blocked" pill above a task node
  **Expected:** Pills legible, tones distinct, placement doesn't obscure node names
  **If not:** Note what reads wrong (size/placement/color) — pill geometry is one
  function (`aefApplyAnnotations`), trivially adjustable before the release cut

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

# Exit codes are the verdict (wrappers return non-zero on failure, loud SKIP on missing toolchain)
python3 tests/test_t258_annotation_seam.py
python3 tests/test_t259_eventdef_preservation.py
python3 tests/test_roundtrip_serialization.py
grep -q "annotation_seam: 1" scripts/release-designer.sh

## Visual Verification

- `.playwright-mcp/t258-annotation-badges.png` — element-level capture from the
  isolated harness browser (G-006): green tone-ok "running" pill above the seed
  startEvent, red tone-err "blocked" pill above the "Load context bundle" task.
  READ and confirmed 2026-07-27: pills legible (mono 9px on soft-tone fill),
  tones distinct, placement at node top-right clears node names and lane chrome.
  Dark theme only — the badge layer uses the same theme vars as node chrome, and
  annotations never appear outside an embedding parent, so mode sweep = the
  embedded (served) context the harness reproduces.

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

### 2026-07-27 — Origin policy v0 (T-250 IW-3, deferred to this build)
- **Chose:** Emit `aef:ready` with targetOrigin `*`; accept `aef:annotate` only when
  `event.source === window.parent`. No allowlist yet.
- **Why:** The uid list is map structure, not a secret (LAN-scoped tool); the intake
  is read-only display with text-node-only rendering (no HTML injection path); and
  parent-source gating already rejects sibling/self spoofing (harness proves it).
  An allowlist would need configuration surface with exactly one embedder in existence.
- **Rejected:** (a) same-origin check — AEF serves the vendored copy from their own
  host so it would pass today, but it hard-couples the seam to their serving topology;
  (b) `?aefOrigin=` query-param allowlist — configuration surface without a second
  embedder class to justify it. Documented in the protocol doc as the designated
  tightening path.

### 2026-07-27 — Annotate payload shape (contract owner: 832)
- **Chose:** `{uid, badge (≤48 chars), tone: info|ok|warn|err (default info),
  title? (≤200, native SVG tooltip)}` — array form.
- **Why:** Minimal display vocabulary covering AEF's overlay v0 need (live state on
  nodes); tones map to existing theme vars so badges render coherently in the
  designer's chrome; clamps bound layout damage from a runaway feed.
- **Rejected:** free-form styling fields (arbitrary color/size) — display-only seam
  should not expose a styling API; state-name passthrough with designer-side mapping
  (aef:meta state vocabulary) — their feed already aggregates, verbatim is simpler.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-27T17:54:59Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-258-annotation-seam-v0-postmessage-aefreadya.md
- **Context:** Initial task creation

### 2026-07-27T19:00:30Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
