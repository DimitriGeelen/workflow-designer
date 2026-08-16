---
id: T-512
name: "Cut designer release 0.10.0: AEF is pinned to 0.9.0 and blocked on six unreleased
  src commits including the T-340 DI import repair"
description: >
  Cut designer release 0.10.0: AEF is pinned to 0.9.0 and blocked on six unreleased
  src commits including the T-340 DI import repair

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
created: 2026-08-15T08:38:33Z
last_update: '2026-08-16T14:33:43Z'
date_finished: 2026-08-15T08:42:03Z
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
  - ts: '2026-08-16T12:34:04Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:43Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 5
      F1: 5
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=5 
      (prose:seam-contract); F1=5 (prose:process-composition)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:dist/MANIFEST.yaml,dist/aef-workflow-designer-0.10.0.html,dist/aef-workflow-designer-0.9.0.html,scripts/release-designer.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:57Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:dist/MANIFEST.yaml,dist/aef-workflow-designer-0.10.0.html,dist/aef-workflow-designer-0.9.0.html,scripts/release-designer.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-512: Cut designer release 0.10.0: AEF is pinned to 0.9.0 and blocked on six unreleased src commits including the T-340 DI import repair

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] VERSION bumped 0.9.0 → 0.10.0 and `scripts/release-designer.sh` run clean. Minor, not
      patch: the six unreleased commits include a behavioural repair (T-340, DI read on
      import) and a change to every exported byte (T-399, producer identity). Neither is a
      patch.
- [x] Artifact `dist/aef-workflow-designer-0.10.0.html` exists and its sha256 matches the sha
      recorded in `dist/MANIFEST.yaml`, with byte count recorded.
- [x] Render gate PASS — the script's own gate. A failed gate aborts the cut; it is never
      worked around.
- [x] **Determinism: re-running the release script yields a byte-identical artifact.** A
      release nobody can reproduce is a pin AEF cannot verify.
- [x] **Immutability: every previously released artifact is still byte-identical to its
      released sha.** A new cut must never disturb a pinned one — this is what protects AEF's
      existing 0.9.0 pin while 0.10.0 lands beside it. Asserted over ALL prior artifacts
      present, not one hand-picked.
- [x] **The content of the cut is stated by commit, not by adjective** — the six src commits
      since the 0.9.0 pin named individually, so AEF can see that T-340's DI import repair
      (the arc's step 1) is the thing they have been waiting on.
- [x] Release ANNOUNCED on the rail with `from_project` attribution — **offset 11880**,
      `metadata.from_project=832-Workflow-designer`, `event_type=designer-release`. Carries
      version, tag, sha256 and byte count inline; names the six commits; flags T-399's +51
      bytes/export as notice-not-re-pin; and asks them to confirm their actual pin, because
      `_t382-release-lag.py` reports 0.8.0 from a VENDORED copy of their policy and that can
      only under-report. The script's own announcement went to the DM topic (offset 631,
      cv_key=designer-release); this AC is about the attributed rail post and was left
      unticked until this post existed. Release ANNOUNCED on the rail carrying version, sha256
      and byte count inline so AEF can verify a pull without a second round-trip. **Announce
      only — no `file_send`:** seam bytes are refs-only until AEF's OBS-108 closes, so the
      announcement carries the digest and they fetch, which is the protocol's fetchable-URL
      path.



**Evidence, measured 2026-08-15:**

| check | result |
|---|---|
| artifact | `dist/aef-workflow-designer-0.10.0.html` |
| sha256 | `76bf20fb4a3ababc7540e33f801908213d4b361c9194e0cb8ff4a1fbacd39534` |
| bytes | 953047 |
| render gate | PASS — render, T-177 markers, inspector dropdowns, console all OK |
| determinism | re-ran the script; artifact **byte-identical** |
| immutability | **12/12** prior artifacts still match their pre-cut sha256 |
| manifest | `latest: 0.10.0`, sha256 and bytes agree with the artifact |
| src parity | artifact sha == `src/aef-workflow-designer.html` sha |

**The six commits in this cut** (`designer-v0.9.0..HEAD -- src/`):

- `4c40414c` **T-399** — producer identity on every export (`exporter="aef-workflow-designer"`)
- `c99f49f8` **T-406** — `readDocComment` no longer infers boilerplate ownership from text
- `fd68c432` **T-414** — DI-trailer suppression narrowed to comments that are only the trailer
- `fc7f7263` **T-340** — **the DI import repair: standard BPMN DI is no longer silently discarded.** This is the arc's step 1 and the thing AEF's T-2977 has been waiting on
- `b9074180` **T-233** — pending off-page refs appear where an operator looks
- `46378578` **T-355** — a `callActivity` was drawn as a `serviceTask`; preservation shipped

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


# ── T-512's legs. NOT `bash tests/run-bridge-tests.sh` (G-015/PL-200: global moving state).
# These are properties of THIS release and stay true regardless of later work.
test "$(cat VERSION)" = "0.10.0"
test -f dist/aef-workflow-designer-0.10.0.html
# The manifest must agree with the artifact it names — a manifest naming a sha the file does
# not have is the one failure mode that breaks AEF's verify step rather than ours.
python3 -c "import yaml,hashlib,sys; m=yaml.safe_load(open('dist/MANIFEST.yaml')); a=m['artifact']; h=hashlib.sha256(open(a,'rb').read()).hexdigest(); sys.exit(0 if h==m['sha256'] and m['latest']=='0.10.0' else 1)"
# Immutability of the pin AEF currently holds. Named explicitly: if this line ever goes red,
# a consumer's verified pin has been mutated underneath them.
python3 -c "import hashlib,sys; h=hashlib.sha256(open('dist/aef-workflow-designer-0.9.0.html','rb').read()).hexdigest(); sys.exit(0 if h=='9ccd2c584e073bcd3702eb7efac5b0e5ec734b9ecabb572a3cff012083ff801a' else 1)"
# The artifact is the source, not a stale copy of it.
python3 -c "import hashlib,sys; a=hashlib.sha256(open('dist/aef-workflow-designer-0.10.0.html','rb').read()).hexdigest(); b=hashlib.sha256(open('src/aef-workflow-designer.html','rb').read()).hexdigest(); sys.exit(0 if a==b else 1)"

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

### 2026-08-15T08:38:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-512-cut-designer-release-0100-aef-is-pinned-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-727db415
- **Timestamp:** 2026-08-15T08:42:04Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#1 (Agent)** — VERSION bumped 0.9.0 → 0.10.0 and `scripts/release-designer.sh` run clean. Minor, not
  - **AC-verify-mismatch** (narrow, heuristic) — `path=scripts/release-designer.sh in: VERSION bumped 0.9.0 → 0.10.0 and `scripts/release-designer.sh` run clean. Minor, not`

### 2026-08-15T08:42:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
