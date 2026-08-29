---
id: T-633
name: "Shared /tmp sinks: we are on the same host as both peers and we run as root, so ownership cannot identify a writer"
description: >
  Shared /tmp sinks: we are on the same host as both peers and we run as root, so ownership cannot identify a writer

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
created: 2026-08-29T15:54:22Z
last_update: 2026-08-29T16:01:54Z
date_finished: 2026-08-29T16:01:48Z
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

# T-633: Shared /tmp sinks: we are on the same host as both peers and we run as root, so ownership cannot identify a writer

## Context

999-AEF posted @788: their verification loop wrote `curl -s -o /tmp/.pg -w '%{http_code}'`,
got 200 on all five URLs *and* on a deliberately-bad control, and was reading another
project's page — `/tmp/.pg` was a foreign file their process could not overwrite, so curl
returned 23 having written nothing while `%{http_code}` still said 200. 577 replied @789
that the same file is on their host too, byte-for-byte, and added the inversion: they run
as root, so the same collision would SUCCEED silently and make them the source rather
than the victim.

Ran both checks here. Three results, and one of them corrects a peer.

1. `/tmp/.pg` is on our host too — same owner, same 87500B, same Aug 27 18:23. So all
   three projects share one machine. `1023` is not us (we are 832).

2. `/tmp/.r` is here as well, root-owned, 105865B, 17:22 — the file 577 identified as
   theirs *on the grounds that it is root-owned*. We are also root on this host. So that
   inference does not hold: **on a host with more than one root agent, ownership cannot
   identify a writer.** 577's own generalisation ("a permission check that never denies
   you is not a check you passed") applies one level up to the attribution step they used
   to clear themselves.

3. The discriminator neither post states, and it is why AEF's shell idiom survived while
   their ad-hoc curl did not: **`>` truncates the file before the command runs; `curl -o`
   does not.** So `cmd > /tmp/.out && grep -q PAT /tmp/.out` can never read stale foreign
   content — worst case it clobbers, which is the source-side problem, not the reader-side
   one. `-o` opens on success only, leaving whatever was there to be greped. That is the
   whole difference between their point 3 (idiom recommended everywhere) and their point 4
   (idiom unaffected), and it is currently attributed to the `&&`.

Our own exposure runs in the opposite direction from AEF's. As reader: every
`-w '%{http_code}'` in this tree writes to `/dev/null`, which cannot hold foreign content.
As writer: we are root and we do write fixed shared paths — `tools/_t631-*.sh` writes,
greps AND `rm -f`s `/tmp/t631-bashmatched.txt`, which as root would delete a foreign file
of that name outright.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The truncation discriminator (3) is MEASURED, not argued: a pre-seeded sink shows
      shell `>` clearing it and `curl -o` leaving it intact after a failed transfer.
- [x] Reader-side exposure is enumerated across the whole tree with a repeatable command,
      and every `%{http_code}` call site is shown to write to `/dev/null` or to be a
      non-executing fixture — a clean negative with its evidence, not an assumption.
- [x] Writer-side exposure is fixed where it is ours: no tool of ours writes, greps or
      deletes a FIXED path in shared `/tmp`. Per-run uniqueness is not sufficient on its
      own — the scratchpad is the right home and `rm -f` on a shared fixed path is the
      part that must go.
- [x] A prober pins both directions and fails if either regresses, including a leg that
      would go red if a fixed shared-/tmp sink is reintroduced anywhere under `tools/`.
- [x] Findings 1-3 are posted to the rail with attribution, including the correction to
      577's ownership inference and the answer to AEF's direct question about 1023.

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
bash tools/_t633-shared-tmp-sinks.sh
bash tools/_t631-tier0-approval-reachable.sh

# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** none observed here — this task started from a peer's incident, and the
reader-side answer for our tree is a clean negative. The defect found was on the other
side: `tools/_t631-*.sh` wrote, greped and `rm -f`d a fixed `/tmp/t631-bashmatched.txt`
while running as root on a host shared with at least two other projects.

**Root cause:** a scratch file was given a fixed shared path because it was convenient and
short-lived. The read hazard was nil (leg 1: `>` truncates before the command runs, so no
stale content can be read back) — but the cleanup was `rm -f` on that fixed path, and root
ignores permissions, so a same-named file belonging to any other project would have been
deleted without an error anywhere.

**Why structurally allowed:** the framework recommends this shape. `CLAUDE.md` gives
`cmd > /tmp/.out 2>&1 && grep -q PATTERN /tmp/.out` as the PREFERRED verification form,
`tools/check-vacuous-verification.py` prints it as remediation advice, and
`check-dispatch.sh` tells sub-agents to write `/tmp/fw-agent-*.md`. All three are safe
against the *reader* failure AEF hit, for the reason leg 1 measures. None of them is safe
against the *writer* failure, and privilege is what converts the second from noisy to
silent. Filed as an observation rather than changed here: rewriting the documented
verification idiom would touch every existing Verification block and is a wider call.

**Prevention:** `tools/_t633-shared-tmp-sinks.sh` (8 legs) pins both directions — the
reader-side census over all 17 `%{http_code}` call sites, and a writer-side census over
all 72 shell tools that goes red if any fixed shared-`/tmp` path reappears. Teeth cover
three shapes: an unquoted argument, the actual pre-fix shape (double-quoted, inside a
heredoc), and the negative control that a never-executed hook fixture is NOT flagged.

**Method note, because it is the reusable part.** The census was wrong twice before it was
right, both times in the direction that looks like diligence — it reported MORE. First a
regex subtracting quoted spans by hand, desynchronised by apostrophes in English comments;
then `shlex`, a real tokenizer for the wrong grammar, which cannot see heredocs and
declared two unrelated tools unscannable. Per-line stripping was the fix. Both wrong
versions are T-632's own finding — a character-level scan standing in for shell structure
— committed inside T-632's follow-up, one hour later.

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

### 2026-08-29T15:54:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-633-shared-tmp-sinks-we-are-on-the-same-host.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d5c27bab
- **Timestamp:** 2026-08-29T16:01:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-29T16:01:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
