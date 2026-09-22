---
id: T-824
name: "Cut designer 0.13.0 (operator-instructed release)"
description: >
  Cut designer 0.13.0 (operator-instructed release)

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [src/aef-workflow-designer.html]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T18:17:11Z
last_update: 2026-09-22T18:21:31Z
date_finished: 2026-09-22T18:21:31Z
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

# T-824: Cut designer 0.13.0 (operator-instructed release)

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `VERSION` reads `0.13.0` and `APP_VERSION` in `src/` reads the same. The T-808 parity gate passes — it runs BEFORE any write to `dist/`, and a drifted version is refused rather than shipped
- [x] `scripts/release-designer.sh` runs to completion with NO bypass env var set: no `RELEASE_ALLOW_OVERWRITE`, no `RELEASE_SKIP_RENDER_CHECK`, no `RELEASE_SKIP_ANNOUNCE`. Each exists for a real situation; none of those situations is this one
- [x] `dist/aef-workflow-designer-0.13.0.html` is byte-identical to `src/aef-workflow-designer.html`, and `dist/MANIFEST.yaml` names it with a sha256 that matches the file on disk
- [x] NO already-released artefact changed. `dist/aef-workflow-designer-0.12.0.html` and every earlier one are byte-identical to before — a version denotes fixed bytes or it denotes nothing (G-007)
- [x] `supersedes` in the manifest reads `0.12.0`, derived from what is actually present in `dist/`
- [x] The release commit exists BEFORE the tag is applied. Tagging first would name a commit carrying neither this VERSION nor this artefact — a tag that looks right and resolves to the wrong tree
- [x] Tag `designer-v0.13.0` exists, is annotated, names the sha256, resolves to the release commit, and is pushed to `origin`
- [x] `master` is fast-forwarded to carry the release, and the tag is an ancestor of `master` — a branch tip is not a release, and AEF fetch the artefact by tag (rail 483)
- [x] The rail announcement either SUCCEEDED, or its failure is reported and the announcement is made through the MCP surface instead — a rail that still advertises 0.12.0 tells a consumer they are current when they are not, which is the false-green direction AEF called unacceptable
- [x] `python3 tools/_t382-release-lag.py` reports **BUILD LAG 0** — src carries nothing the release does not. ~~and the peer pin is in step~~ **THIS AC WAS WRONG AS WRITTEN and is corrected rather than ticked.** It demanded the gauge pass overall, but leg 2 measures ADOPTION lag — whether AEF has re-pinned — and they cannot have, seconds after the announce that tells them to. The gauge correctly reports WARN (exit 1), `peer pin behind: 0.12.0 -> 0.13.0, our release is 0 days old`. Demanding green here would have meant either faking a peer action or bypassing a gauge that is right. Same class as T-823's leg 2: an assertion of a momentary alignment that the act it describes makes impossible
- [x] Release authority is recorded — bumping VERSION and writing `dist/` are a sovereignty promise over immutable bytes and are NOT delegated under agent initiative. The operator's instruction is quoted in Decisions

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
         1. Run `bin/fw reviewer T-824`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-824 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
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

# ---- T-824 legs -------------------------------------------------------------
# 1. Parity holds: the header names the release it IS.
bash tools/_t808-version-parity.sh > /tmp/.t824-parity.out 2>&1
# 2. The released artefact IS src, byte for byte. This is release-designer.sh's contract
#    and the thing AEF's sha256 pin depends on.
cmp -s src/aef-workflow-designer.html dist/aef-workflow-designer-0.13.0.html
# 3. The manifest's sha256 matches the file on disk — read from both, not trusted from the
#    script's own echo.
test "$(grep -oP '(?<=^sha256: ")[a-f0-9]+' dist/MANIFEST.yaml)" = "$(sha256sum dist/aef-workflow-designer-0.13.0.html | awk '{print $1}')"
# 4. IMMUTABILITY. Every previously-released artefact still hashes to what it did before
#    this cut. A version denotes fixed bytes or it denotes nothing (G-007). The checksums
#    were taken BEFORE the release and are pinned here as a file in the tree, so this leg
#    keeps meaning something on every future run, not just today.
sha256sum -c tools/_t824-dist-immutability.sha256 > /tmp/.t824-immut.out 2>&1
# 5. The tag exists, is annotated, and resolves to a commit on master. A branch tip is not
#    a release; AEF fetch the artefact by tag (rail 483).
git rev-parse -q --verify refs/tags/designer-v0.13.0 > /dev/null
test "$(git cat-file -t designer-v0.13.0)" = "tag"
git merge-base --is-ancestor designer-v0.13.0 master
# 6. BUILD LAG ZERO — src carries nothing the release does not. NOT the whole gauge: its
#    second leg measures whether AEF has re-pinned, which they cannot have done seconds
#    after the announce telling them to. See the corrected AC for why demanding overall
#    green there would have meant faking a peer action or bypassing a gauge that is right.
python3 tools/_t382-release-lag.py > /tmp/.t824-lag.out 2>&1; grep -q "unshipped product commits since designer-v0.13.0: 0" /tmp/.t824-lag.out
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

### 2026-09-22 — release authority: instructed, and recorded as such

- **Standing rule:** bumping `VERSION`, writing `dist/`, or updating `dist/MANIFEST.yaml`
  **under agent initiative** is forbidden — a release is a sovereignty promise over
  immutable bytes (G-007).
- **The instruction, verbatim:** *"go"* — in direct answer to "Cutting 0.13.0 is the remedy
  whenever you want it — say the word and I'll walk it through `scripts/release-designer.sh`."
  That is instruction, not initiative, which is the precise thing the rule turns on.
- **Earlier in this same session** the operator said *"I run a release in the proper way, so
  tell me the proper way and that's what we're going to do"*, and then chose not to cut.
  The proper way is this script; this is that.

### 2026-09-22 — no bypass, on a script that offers three

- **Chose:** run with `RELEASE_ALLOW_OVERWRITE`, `RELEASE_SKIP_RENDER_CHECK` and
  `RELEASE_SKIP_ANNOUNCE` all unset.
- **Why:** each exists for a real situation — a deliberate re-cut, a browser-less host, an
  unreachable hub — and none of those was this one. Reaching for a bypass because it is
  there is how a gate becomes decoration. The script's own comment makes the point about
  the one flag it deliberately does NOT offer: there is no situation where shipping a
  knowingly mislabelled version is right, so there is no flag for it.

### 2026-09-22 — immutability is now checked by something other than the releasing script

- **Chose:** pin every released artefact's sha256 in `tools/_t824-dist-immutability.sha256`
  and verify it as a standing leg.
- **Why:** `release-designer.sh`'s immutability guard fires only when IT is the thing doing
  the writing. It says nothing about a stray edit, a bad merge, or a well-meant reformat
  touching a shipped artefact — and that is exactly the case with no local signal, because
  AEF's pin breaks on their side, not ours. I took the checksums BEFORE the cut and verified
  all 15 prior artefacts unchanged after; pinning them in the tree is what makes that a
  repeatable check rather than a thing I happened to do once.

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
     fw inception decide T-824 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T18:17:11Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-824-cut-designer-0130-operator-instructed-re.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-6d66b486
- **Timestamp:** 2026-09-22T18:21:32Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Per-AC findings:**

- **AC#2 (Agent)** — `scripts/release-designer.sh` runs to completion with NO bypass env var set: no `RELEASE_ALLOW_OVERWRITE`, no `RELEASE_SKIP_RENDER_CHECK`, no `RELEASE_SKIP_ANNOUNCE`. Each exists for a real situation;
  - **AC-verify-mismatch** (narrow, heuristic) — `path=scripts/release-designer.sh in: `scripts/release-designer.sh` runs to completion with NO bypass env var set: no `RELEASE_ALLOW_OVERWRITE`, no `RELEASE_SKIP_RENDER_CHECK`, no `RELEASE`

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 26
     - evidence: `git rev-parse -q --verify refs/tags/designer-v0.13.0 > /dev/null`

### 2026-09-22T18:21:31Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
