---
id: T-193
name: "Re-deliver canonical inception fixture + corpus to AEF via rail artifact_ref
  (unblock T-2535)"
description: >
  AEF's termlink file_send transfers (offsets 31/34) never arrived — deprecated replay
  path. AEF asked for re-send via rail artifact_ref. Re-post inception-gonogo.bpmn
  (and 24-map corpus) byte-exact via termlink_channel_post payload_b64 on the DM rail,
  with sha256 in metadata for their T-2535 byte/behaviour cross-validation.

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
created: 2026-07-12T17:47:54Z
last_update: '2026-08-16T12:33:42Z'
date_finished: 2026-07-12T20:02:29Z
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
  - ts: '2026-08-16T12:33:42Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 3
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=3 
      (body:component-silent-failure); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-193: Re-deliver canonical inception fixture + corpus to AEF via rail artifact_ref (unblock T-2535)

## Context

AEF's T-2535 (byte/behaviour cross-validation against 832's canonical `inception-gonogo.bpmn` + the 24-map
corpus) is blocked: my two `termlink_file_send` transfers (rail offsets 31 and 34) never arrived — the
`file_send` path is a deprecated replay path on AEF's side. AEF built against a "faithful AEF twin" fixture
and explicitly asked me to **re-send via rail `artifact_ref`**. Fix: re-post the canonical bytes *inside* the
rail envelope via `termlink_channel_post payload_b64` (byte-exact, boundary-safe, durable — it's read back by
`channel_state`), with sha256 in `metadata` so AEF can decode and cross-validate deterministically. This
bypasses `file_send` entirely.

Canonical artifacts (832 HEAD, git-tracked):
- `tests/fixtures/aef-bpmn/inception-gonogo.bpmn` — sha256 `093858400716a0c5dd4e6676ad96b1564e47980527a15028fd08242df1c7041e`
- 24-map rendered corpus tarball (as delivered at offset 31) — sha256 `cbb318ff19e1ee7f094a5f8dae0c66a531f59dff12236e97f3cb69a42d73eb6c`

## Acceptance Criteria

### Agent
- [x] `inception-gonogo.bpmn` re-posted to the DM rail (`dm:0e7ee6cad65137fc:6a646ce8b1bc6560`) via `termlink_channel_post` with `payload_b64` = base64 of the byte-exact HEAD file, `msg_type="artifact"`, and `metadata` carrying `filename`, `sha256`, `in_reply_to` — **offset 41**
- [x] Round-trip proven: base64-decoding the posted rail envelope's `payload_b64` reproduces the file byte-for-byte (decoded sha256 == `093858400716a0c5dd4e6676ad96b1564e47980527a15028fd08242df1c7041e`, 4314 B) — verified `ROUND-TRIP: BYTE-EXACT ✓`
- [x] Corpus byte-validation re-delivered — **AEF descoped the full-24 tarball** (their offset 44, cid t2399-auto-063412: canonical inception fixture arrived byte-exact and caught a real AEF-side bug T-2536; namespace-agnostic parsing now proven against real bytes, so the 24-file smoke is non-blocking breadth). Their scoped ask = the **one negative fixture** `resume-status.bpmn` (`frw_7_gather` = subProcess + constituents WITHOUT `workflowType`, the inception-detector negative). Delivered byte-exact via `payload_b64` at **offset 45** (sha256 `7b15f3e0f78587c25d8b448f30dc6d57ffa8b283396f55caf875fa10e4b2c03f`, 10530 B; matches offset-42 manifest line), round-trip proven both ways (local `base64 -d` + rail `channel_state` read-back = `7b15f3e0`). Corpus validation closes on **manifest (offset 42) + this negative fixture**; no tarball. Confirm note posted at offset 46.
- [x] A human-readable rail note posted pointing AEF at the artifact-envelope offset(s) + the decode-and-verify recipe (`base64 -d` → `sha256sum` compare) — **offset 43**
- [x] Local canonical bytes confirmed identical to git HEAD before sending (no working-tree drift) — `HEAD-identity: MATCH` for the fixture; corpus manifest built from `git archive HEAD`

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

# Canonical fixture bytes match git HEAD (no working-tree drift) and the known sha256.
test "$(git hash-object tests/fixtures/aef-bpmn/inception-gonogo.bpmn)" = "$(git rev-parse HEAD:tests/fixtures/aef-bpmn/inception-gonogo.bpmn)"
test "$(sha256sum tests/fixtures/aef-bpmn/inception-gonogo.bpmn | cut -d' ' -f1)" = "093858400716a0c5dd4e6676ad96b1564e47980527a15028fd08242df1c7041e"
# Fixture still passes the forward-fixtures conformance guard.
python3 tests/test_forward_fixtures.py

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

### 2026-07-12 — Re-delivery mechanism: inline `payload_b64` on the rail, not `file_send`
- **Chose:** Re-post canonical bytes INSIDE the rail envelope via `termlink_channel_post` `payload_b64`, with `sha256` in `metadata`. Proven byte-exact by decode-and-hash round-trip before claiming delivery.
- **Why:** AEF's two `file_send` transfers (offsets 31/34) never arrived — `file_send` rode a deprecated replay path. The `channel_post` envelope is durable (read back verbatim by `channel_state`) and boundary-safe (bytes travel in the envelope, no cross-host path resolution that T-559 would block).
- **Rejected:** Retrying `file_send` (same broken path); an opaque `artifact_ref`-only pointer with no inline bytes (cross-host blob store resolution is the same boundary problem).

### 2026-07-12 — Corpus tarball: deliver the per-file manifest, hold the tarball bytes
- **Chose:** Deliver `MANIFEST.sha256` (24 per-file sha256 at HEAD, offset 42) as the byte-validation anchor; hold the raw tarball pending AEF's transport pick (offset 43).
- **Why:** A 36 KB gzip → ~48 KB base64 cannot be materialised as a single tool parameter on my side, so I can't verify it end-to-end — sending unverifiable bytes violates "no silent failures." The manifest fully enables T-2535's byte cross-validation: AEF runs `sha256sum -c MANIFEST.sha256` against their "faithful twin" and any mismatch names the exact drifted file. Pre-streaming 24 files would likely be wasted work (manifest check probably shows zero drift).
- **Rejected:** Forcing a 48 KB single-envelope post I can't verify; pre-streaming all 24 files unprompted (contradicts the cheaper manifest-check-first path AEF was offered).

### 2026-07-12 — AEF ruling resolves the transport question: manifest + one negative fixture, no tarball
- **Chose:** Close corpus byte-validation on the offset-42 manifest + the single negative fixture `resume-status.bpmn` (offset 45), per AEF's offset-44 ruling. No full-24 stream.
- **Why:** AEF confirmed the canonical `inception-gonogo.bpmn` arrived byte-exact and it *immediately* caught a real AEF-side bug (T-2536 / L-501): their compiler read `aef:uid` as element text, but 832 serializes it as an attribute `<aef:uid value="…"/>`, so it was silently falling back to node-id for every node — the IW-1 stable-identity contract was broken against real bytes, invisible because their self-authored twin used the wrong form. With namespace-agnostic parsing now proven against real bytes + my file vendored with a sha guard, AEF descoped the 24-file smoke as non-blocking breadth and asked only for the negative case (`frw_7_gather`: subProcess + constituents WITHOUT `workflowType`) to close their last independent test. The manifest-check-first path I'd offered (Decision above) is exactly what let AEF make this call cheaply — zero wasted streaming.
- **Rejected:** Streaming the remaining 22 files anyway (AEF explicitly descoped it; matches the "don't manufacture" stance). The peer's scoping ruling on *their* test coverage is theirs to make (PL-028: respect a peer agent's stated scope).
- **Cross-agent validation:** The whole exchange is the case study for L-501 — a self-authored twin proves only mock-vs-mock; byte-validation against a peer's real canonical bytes is what surfaces serialization-contract drift.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-12T17:47:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-193-re-deliver-canonical-inception-fixture--.md
- **Context:** Initial task creation

### 2026-07-12T20:02:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
