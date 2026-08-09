---
id: T-412
name: "ANNOUNCED pair is completed by a single word: password/passwd sit in both halves"
description: >
  ANNOUNCED pair is completed by a single word: password/passwd sit in both halves

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t412-announced-pair-teeth.sh, tools/tracked-secret-artifacts.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-09T14:38:17Z
last_update: 2026-08-09T14:42:04Z
date_finished: 2026-08-09T14:42:04Z
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

# T-412: ANNOUNCED pair is completed by a single word: password/passwd sit in both halves

## Context

`tools/tracked-secret-artifacts.py` (T-410) classes a filename ANNOUNCED when it pairs a
**secrecy word** with a **credential noun**. The pair exists so that `secret-scan.sh` (secrecy
word, no noun) and `context_tokens.py` (noun, no secrecy word) are not mistaken for key
material — the two halves are the false-positive control.

`password` and `passwd` appear in **both** lists. So a single occurrence of one word satisfies
both halves and the pair collapses to a single-word match:

    docs/reset-password.md      -> ANNOUNCED   (documentation about password reset)
    docs/password-policy.md     -> ANNOUNCED   (a policy document)
    lib/password_reset_test.py  -> ANNOUNCED   (a test)

None is key material. This is precisely the class the pair was built to exclude, and a scanner
that reds on a policy document gets uninstalled rather than obeyed — the same survival
property T-410's FP control leg exists to protect.

**Provenance, and a correction to what I told AEF.** AEF hit this shape in their own name-axis
scanner (rail 501) with `credential`/`cred`, and described it as *"a pair one word can complete
is a single-word match wearing a pair's clothes."* I reported at rail 502 §4 that mine had the
identical bug in `credential`/`cred`. **That part was wrong** — those two are genuinely
disjoint here (`credentials.md` is correctly not flagged, verified). The live instance is
`password`/`passwd`. The class transferred; the word did not, and I named the word before
measuring it. Correction owed on the rail.

It has never fired because no tracked filename in this tree happens to contain the word. That
is luck, not design.

**Root shape:** the pair's soundness depends on the two halves being satisfiable only from
*different* spans of the name, and nothing enforced that. Disjoint word LISTS are not disjoint
MATCHES — a word in both lists satisfies both from one span, and set-difference on the lists
would fix this instance while leaving the rule that permits it intact.

## Acceptance Criteria

### Agent
- [x] The ANNOUNCED rule requires the secrecy word and the credential noun to match at
      **non-overlapping spans** of the filename — not merely to come from two different lists
- [x] `docs/reset-password.md`, `docs/password-policy.md` and `lib/password_reset_test.py`
      are no longer flagged
- [x] Reciprocal: `password-key.txt`, `secret-token.bak` and `.fw-secret-key` ARE still
      flagged — the fix must not be satisfied by a rule that stopped flagging things
- [x] The overlap that caused this is asserted structurally: a leg fails if any word can
      satisfy both halves from one span, so a future edit re-adding an overlapping word is
      caught by the harness rather than by luck
- [x] `tools/_t410-secret-artifact-teeth.sh` still passes 13/13 — the T-410 legs are the
      regression surface for this change
- [x] Live tree still scans clean over its full population with an empty allowlist

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

bash tools/_t412-announced-pair-teeth.sh > /tmp/.t412a 2>&1 && grep -q "TEETH PASS" /tmp/.t412a
bash tools/_t410-secret-artifact-teeth.sh > /tmp/.t412b 2>&1 && grep -q "TEETH PASS — 13/13" /tmp/.t412b
python3 tools/tracked-secret-artifacts.py > /tmp/.t412c 2>&1 && grep -qE "scan ok: [0-9]{4,} tracked file" /tmp/.t412c

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

### 2026-08-09T14:38:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-412-announced-pair-is-completed-by-a-single-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b92ee402
- **Timestamp:** 2026-08-09T14:42:08Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#2 (Agent)** — `docs/reset-password.md`, `docs/password-policy.md` and `lib/password_reset_test.py`
  - **AC-verify-mismatch** (narrow, heuristic) — `path=lib/password_reset_test.py in: `docs/reset-password.md`, `docs/password-policy.md` and `lib/password_reset_test.py``

### 2026-08-09T14:42:04Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
