---
id: T-243
name: "release designer 0.3.2 hotfix: T-240 uuid auto-resolve + T-242 dual-form contract"
description: >
  Operator-authorized hotfix cut (AEF ask 1, rail 168; go given 2026-07-23). Content since designer-v0.3.1: T-240 (uuid workflowRef auto-resolves jump target at load) + T-242 (dual-form alias preserved on emit, workflowRef authoritative when resolvable). Protocol per docs/aef-designer-integration-protocol.md: full bridge suite, VERSION bump 0.3.2, deterministic dist cut + MANIFEST, render gate, immutability guard (0.3.1/0.3.0 untouched), annotated tag designer-v0.3.2, push, file_send delivery to aef, rail announce (triggers their re-pin + resolves_workflow_ref flag flip + alias drop).

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
created: 2026-07-23T07:35:07Z
last_update: 2026-07-23T07:40:53Z
date_finished: 2026-07-23T07:40:53Z
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

# T-243: release designer 0.3.2 hotfix: T-240 uuid auto-resolve + T-242 dual-form contract

## Context

Operator-authorized ("go", 2026-07-23) hotfix release. AEF escalated T-240 to a live
regression class at rail 168 (their T-2612: corpus-wide dead handoff jumps on pinned
0.3.1 after their uuid-form migration) and requested a hotfix cut. Content since
designer-v0.3.1 = exactly T-240 (7e11f0e) + T-242 (4e46115); src delta is those two
tasks only. On announce, AEF re-pins, flips their `resolves_workflow_ref` capability
flag, and drops the dual-form compat aliases.

## Acceptance Criteria

### Agent
- [x] Full bridge test suite green before the cut (includes the G-010 editor-behavior
      suite with the 5 T-240/T-242 probes).
      *(run pre-cut: 37/37 round-trip, geometry sweep 24 clean, editor-behavior legs green,
      pins green, exit 0)*
- [x] Release cut is deterministic and gated: VERSION → 0.3.2, `dist/aef-workflow-designer-0.3.2.html`
      byte-identical to `src/aef-workflow-designer.html`, MANIFEST.yaml updated with
      content-derived sha256+bytes, render gate green.
      *(sha 983e0e304a3dc12e41ed9ea7270ba6edd032453c72c9ee423f466aa9d9e8d38a, 866701 B;
      cmp src↔artifact identical; render gate PASS on 0.3.2)*
- [x] Immutability: 0.3.1 (d99a42da…, 862852 B) and 0.3.0 (36be033d…, 826643 B) bytes
      untouched; immutability test green.
      *(shas re-verified post-cut; standalone guard test: 5/5 paths pass, "no tests ran"
      under pytest is expected — it is a standalone script, same as T-239's run)*
- [x] Both hotfix markers provably in the released bundle: the T-240 auto-resolved
      readout marker and the T-242 dual-form emit comment.
      *(grep counts: "auto-resolved from workflow ref (uuid)" ×1, "T-242 (AEF rail 168,
      contract-v0 dual-form)" ×1 in dist/aef-workflow-designer-0.3.2.html)*
- [x] Annotated tag `designer-v0.3.2` created on the release commit and pushed to origin
      along with the release commit(s).
      *(release commit 99431de + tag pushed together to origin)*
- [x] Artifact delivered to AEF via termlink file_send (sender sha == MANIFEST sha) and
      the release announced on the rail with sha/bytes/tag + re-pin trigger.
      *(transfer xfer-mcp-888946-1784792300564-0, 18 chunks, 866701 B, sha match;
      announced at rail offset 171 with their re-pin flow spelled out)*

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

## Recommendation

**Recommendation:** GO
**Rationale:** Full gated release executed per protocol, identical to the 0.3.1 flow;
every gate green pre-tag; delivery sha-matched; prior releases byte-untouched. Awaiting
only AEF's sha-confirm + re-pin verdict on the rail.
**Evidence:** see checked Agent ACs — each carries its measured result.

## Verification

MAN=$(cat dist/MANIFEST.yaml); echo "$MAN" | grep -q 'latest: "0.3.2"'
MAN=$(cat dist/MANIFEST.yaml); echo "$MAN" | grep -q '983e0e304a3dc12e41ed9ea7270ba6edd032453c72c9ee423f466aa9d9e8d38a'
cmp src/aef-workflow-designer.html dist/aef-workflow-designer-0.3.2.html
grep -q "auto-resolved from workflow ref (uuid)" dist/aef-workflow-designer-0.3.2.html
grep -q "T-242 (AEF rail 168, contract-v0 dual-form)" dist/aef-workflow-designer-0.3.2.html
SHA1=$(sha256sum dist/aef-workflow-designer-0.3.1.html | cut -d' ' -f1); test "$SHA1" = "d99a42da304fc9377e580a1e34e54467431727058026ded7a8ee85fd464fd05c"
SHA0=$(sha256sum dist/aef-workflow-designer-0.3.0.html | cut -d' ' -f1); test "$SHA0" = "36be033d66aa1c159a9e75df674f02032eb9f308882af288fad909e6d754a4bb"
python3 tests/test_release_immutability.py
TAGS=$(git tag -l 'designer-v*'); echo "$TAGS" | grep -q "designer-v0.3.2"

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

## RCA

**Symptom:** AEF operators hit corpus-wide dead handoff jumps on pinned 0.3.1 (their
T-2612): every uuid-form link showed "Target workflow — none —" with a disabled jump.
**Root cause:** Producer/consumer sequencing inversion across the seam — AEF migrated
their whole corpus to uuid `workflowRef` form (their T-2605/T-2609 recreates) while the
pinned editor (0.3.1) only bound jumps via the legacy slug; the uuid-binding capability
(T-240) was known and filed but sat at horizon `next` while the corpus format moved
ahead of it. Per-node code RCAs live in T-242 (either/or emit, precedence).
**Why structurally allowed:** Nothing on either side tied "corpus emit format" to
"pinned-editor capability" — the seam pinned BYTES (sha) but not BEHAVIORAL capability,
so a format migration could outrun the consumer with no gate firing. Severity was also
mis-triaged at intake (rail 166: "one picker step" — it was a dead affordance for
operators).
**Prevention:** AEF-side (already live): `editor-unbindable` corpus lint keyed off a
`resolves_workflow_ref` capability flag in their designer pin — a served map the pinned
editor cannot bind now FAILS their lint. 832-side: the G-010 suite's 5 permanent
binding probes lock consumer behavior per attr-form. The capability-flag-in-pin pattern
is the structural fix: pins now carry capability, not just bytes.

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

### 2026-07-23T07:35:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-243-release-designer-032-hotfix-t-240-uuid-a.md
- **Context:** Initial task creation

### 2026-07-23T07:40:53Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
