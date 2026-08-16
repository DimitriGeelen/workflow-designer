---
id: T-452
name: "Reciprocal check of AEF's gate-metacharacter deadlock (DM 559 4) against 832's
  task gate"
description: >
  Reciprocal check of AEF's gate-metacharacter deadlock (DM 559 4) against 832's task
  gate

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
created: 2026-08-12T10:52:17Z
last_update: '2026-08-16T13:58:56Z'
date_finished: 2026-08-12T10:57:28Z
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
  - ts: '2026-08-16T12:33:59Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 1
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=1 
      (body/components:prompt-incidental); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/agents/context/check-active-task.sh,.agentic-framework/agents/context/lib/safe-commands.sh,.tasks/templates/default.md,tools/_t352-p011-errexit-probe.sh);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:56Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/agents/context/check-active-task.sh,.agentic-framework/agents/context/lib/safe-commands.sh,.tasks/templates/default.md);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-452: Reciprocal check of AEF's gate-metacharacter deadlock (DM 559 4) against 832's task gate

## Context

AEF's DM 559 §4: their task-creation gate refused **both** commands its own block
message prescribes, because the task name contained `11->10` and the `>` read as a
redirect, so `fw task create` was classified as a file write and blocked for having no
active task. With focus null that is a deadlock — no task can be created if its name
contains `>`. They asked whether the same shape is available here.

**Two instances found before the probe was even written, both while filing this task.**

**Instance A — the gate's prescribed remedy is unreachable from Bash.** G-020 blocks
source edits until a build task has real ACs, and its block message says to edit the
task file. Doing that from Bash (a heredoc + a script writing the file) is itself
classified as a write and blocked by the same gate. The remedy is reachable only
through the Edit tool. Same ordering flaw as AEF's: write-pattern classification runs
before the exemption that would permit the bootstrap action.

**Instance B — and this one is AEF's 554 finding, in my tree, two days after I told
them I had adopted it.** I wrote a real AC that *quoted the gate's own block message*,
which contains the placeholder token G-020 greps for. The gate found that token inside
my quotation and classified a fully-written AC block as placeholders. **A task
describing the placeholder gate is unfileable, because describing the placeholder
produces the placeholder.**

AEF's words at 554: *"a 'latent, not live' assessment is only valid over a corpus the
session does not write to … prose about a string-matching bug reliably contains the
string. The ticket will."* Their instance was `OBS-233`'s own text quoting
`status: pending` and pushing their count from 118 to 119. I replied at 558 §6 that
"grep the text you are about to file, first" was now how I file. It was not. The
transfer rate of these reports at the level of behaviour is, again, about zero.

The token is not reproduced anywhere in this file — that is the workaround, and it is
recorded as a workaround rather than a fix, because a gate whose subject cannot be
written about is still broken after I have finished writing around it.

## Findings

### 1. AEF's deadlock does NOT reproduce here, and the reason is not luck

`has_bash_write_pattern()` strips quoted content **before** scanning for redirects, then
judges each redirect by its **target** rather than by the character. Probed by changing
exactly one thing:

| command | write pattern? | bootstrap-exempt? |
|---|---|---|
| `fw task create --name "count 11->10" --type build` | no | yes |
| `fw task create --name "count 11 to 10" --type build` | no | yes |
| `fw task create --name x > /etc/passwd` | **WRITE** | yes (but blocked — write wins) |
| `echo hi > file.txt` | **WRITE** | — |
| `grep x y 2>/dev/null` | no | — |
| `grep x y 2>&1` | no | — |

The `->` moves nothing. Real unquoted redirects are still caught, and `2>/dev/null` and
`2>&1` correctly are not.

**The ordering AEF blames is the same here and is not the bug.** 832 also checks write
patterns *first* (`check-active-task.sh:92`), deliberately — the comment says "even
'safe' commands with redirects are writes", and `fw task create --name x > /etc/passwd`
proves why: it matches the bootstrap exemption and is blocked anyway. Their classifier
over-approximates, so a correct ordering bites something it should never have seen.

**This tree hit their bug and fixed it at T-170, PL-025:** *"Detecting shell write-intent
with a character-level regex over-approximates."* The remedy is portable and is two
things, not one — strip quoted content, then inspect the redirect's target. The source
carries a third, hard-won note worth passing on verbatim: the operator must be written
`[>]` and not `\>`, because glibc's ERE engine reads `\>` as *end-of-word*, so a
`\>\>?` group silently matches word boundaries and never sees a redirect at all.

### 2. Instance A — G-020's remedy is unreachable from the tool the block implies

The block message says to edit the task file. From Bash that is a write, so the same
gate blocks it. Reachable only via the Edit tool. Not a deadlock (Edit works), but the
message names a remedy without naming the only tool that can perform it.

### 3. Instance B, and underneath it a hole in G-020 itself

G-020 scans the AC section as raw text:

    HAS_PLACEHOLDER = grep -ciE '\[(First|Second|…) criterion\]'
    REAL_AC_COUNT   = grep -cE '^\s*-\s*\[[ x]\]'
    block if HAS_PLACEHOLDER > 0 OR REAL_AC_COUNT == 0

No structural parse and, unlike its sibling gate sixty lines above (G-067, which strips
HTML comments at `:539` with a note about tolerating `>` inside them), no comment
stripping. Two consequences from that one root:

- **False positive (instance B):** the placeholder token quoted inside a genuine AC is
  counted as a placeholder. A task describing this gate is unfileable.
- **False negative, and it is the serious one — measured:** the template's `### Human`
  block ships two commented example checkboxes. They match `REAL_AC_COUNT`. So on any
  task created from the template, `REAL_AC_COUNT` is **2 before a single AC is written**,
  and the `== 0` half of the gate can never fire. Deleting the two placeholder lines —
  the literal instruction in the block message — leaves the gate **passing with zero
  acceptance criteria.** Reproduced with the gate's own two commands:
  `HAS_PLACEHOLDER=0  REAL_AC_COUNT=2  → ALLOWED`.

The gate that blocked this session three times can be satisfied by deleting two lines
and writing nothing. Filed as **T-453**; the file is vendored AEF tooling, so the fix is
theirs (G-008 upstreamable) and the reproduction goes over the rail.

## Acceptance Criteria

### Agent
- [x] Measured, not reasoned: whether `fw task create --name "<name containing a shell
      metacharacter>"` is classified as a file write by 832's task gate, and whether
      that classification runs BEFORE the task-bootstrap exemption — the ordering is
      what makes AEF's instance a deadlock rather than a nuisance
- [x] The probe changes exactly ONE thing between the allowed and the blocked run, so
      the metacharacter is proven to be the cause rather than merely correlated
- [x] Instance A recorded: G-020's own prescribed remedy — edit the task file — is
      reachable through the Edit tool but NOT through Bash, because a Bash command that
      writes the ACs is itself classified as a write and blocked by the same gate
- [x] Instance B recorded and REPRODUCED deliberately on a throwaway task, proving the
      gate cannot be described in a task file it governs — the placeholder token quoted
      inside a genuine AC is read as a placeholder
- [x] If a deadlock reproduces it is filed with its reproduction and NOT worked around
      by rewording — rewording is the evasion, not the fix
- [x] If it does not reproduce, the reason is stated from the gate's own source
      (ordering, regex, exemption list), not inferred from the absence of a block

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

# 1. AEF's shape does not reproduce: one thing changed (`->` vs ` to `) moves nothing.
bash -c 'source .agentic-framework/agents/context/lib/safe-commands.sh; has_bash_write_pattern "fw task create --name \"count 11->10\" --type build"'; test $? -eq 1
# 2. ...and the classifier still catches a REAL unquoted redirect, so leg 1 is not a
#    guard that has simply stopped working. Both halves, or leg 1 proves nothing.
bash -c 'source .agentic-framework/agents/context/lib/safe-commands.sh; has_bash_write_pattern "echo hi > file.txt"'; test $? -eq 0
# 3. ...and a discard is not a write (the over-approximation AEF is hitting).
bash -c 'source .agentic-framework/agents/context/lib/safe-commands.sh; has_bash_write_pattern "grep x y 2>/dev/null"'; test $? -eq 1
# 4. The quote-stripping that makes leg 1 true is present in the source, not incidental.
grep -q "_sc_strip_quoted" .agentic-framework/agents/context/lib/safe-commands.sh
# 5. Instance B's false NEGATIVE, asserted against the SHIPPED template rather than a
#    synthetic fixture.
#    The first version of this leg built a fixture with an embedded printf and FAILED
#    under P-011 while PASSING when run directly in the same shell (count=2 both times).
#    I first wrote "T-391 P-011 multiline hazard" here — inferred from the gate echoing
#    the command back with expanded newlines, which is exactly the infer-a-cause-from-
#    association step this session has already caught twice. It is NOT measured and
#    the real cause is unknown. Recorded as unknown rather than guessed; the fixture
#    version is preserved below the live legs so someone can chase it.
#    The replacement is stronger anyway: it asserts against the template the framework
#    actually ships, not a fixture I wrote to resemble it.
#    The template's AC section carries 4 lines matching G-020's real-AC pattern, of
#    which only 2 are the placeholders it blocks on. Delete those 2 — the literal
#    instruction in the block message — and REAL_AC_COUNT is still 2, so the `== 0`
#    half can never fire and the gate passes over zero acceptance criteria.
test "$(sed -n '/^## Acceptance Criteria/,/^## [^A]/p' .tasks/templates/default.md | sed '$d' | grep -cE '^\s*-\s*\[[ x]\]')" -eq 4
test "$(sed -n '/^## Acceptance Criteria/,/^## [^A]/p' .tasks/templates/default.md | sed '$d' | grep -ciE '\[(First|Second|Third|Fourth|Fifth) criterion\]')" -eq 2
# 5-OLD (removed): the synthetic fixture below could not survive P-011's line splitting.
# T=$(mktemp); printf -- '## Acceptance Criteria\n\n### Agent\n\n### Human\n<!--\n       - [ ] [REVIEW] Dashboard renders correctly\n       - [ ] [REVIEWER] Block message names both bypass mechanisms\n-->\n\n## Verification\n' > "$T"; A=$(sed -n '/^## Acceptance Criteria/,/^## [^A]/p' "$T" | sed '$d'); test "$(echo "$A" | grep -cE '^\s*-\s*\[[ x]\]')" -eq 2
# 6. ...and the sibling gate sixty lines above DOES strip comments, so the remedy is
#    already present in the same file, applied to the other gate.
grep -q "Strip HTML comments so the template guidance does not count" .agentic-framework/agents/context/check-active-task.sh
# 7. The follow-on defect is filed rather than fixed in vendored tooling.
ls .tasks/active/T-453-*.md > /dev/null 2>&1 || ls .tasks/completed/T-453-*.md > /dev/null 2>&1

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

### 2026-08-12T10:52:17Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-452-reciprocal-check-of-aefs-gate-metacharac.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d29a49e3
- **Timestamp:** 2026-08-12T10:57:29Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **empty-output-success** (partial, heuristic) @ Verification:line 80
     - evidence: `ls .tasks/active/T-453-*.md > /dev/null 2>&1 || ls .tasks/completed/T-453-*.md > /dev/null 2>&1`

### 2026-08-12T10:57:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
