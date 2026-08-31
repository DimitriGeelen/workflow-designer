---
id: T-647
name: "T-640's fetcher write-guard over-blocks the stdout idioms: curl -o - and wget -O - are refused"
description: >
  Found by 999-AEF at rail @841, confirmed against our tree by measurement. Our T-640 guard treats any -o/-O argument as a file write. Two of them are not: 'curl -o -' and 'wget -O -' write to STDOUT, so they are readers and the pre-T-640 behaviour admitted them. Measured 2026-08-30 with a null-focus sandbox against the live hook: curl -o - -> BLOCKED (should be ADMITTED); wget -O - -> BLOCKED (should be ADMITTED); curl -s -o /dev/null -w '%{http_code}' -> ADMITTED (correct, already covered); curl -o out.txt -> BLOCKED (correct); wget URL -> BLOCKED (correct). So the guard is right about writers and wrong about the two stdout spellings. AEF carries a no-widening leg asserting their fix blocks nothing the pre-fix version allowed; ours has no such leg, which is why this got through - the prober asserted that writers are refused and that five readers are admitted, but never that the fix refuses NOTHING the unguarded version allowed. That missing leg is the more valuable half of this task. Their commit d6cfc31b1.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-30T18:28:29Z
last_update: 2026-08-31T11:20:11Z
date_finished: 2026-08-31T11:20:11Z
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

# T-647: T-640's fetcher write-guard over-blocks the stdout idioms: curl -o - and wget -O - are refused

## Context

999-AEF found this at rail @841 and it is real. Confirmed by measurement against our live
hook on 2026-08-30 (null-focus sandbox, so the task gate admits nothing on its own):

| command                                   | now      | should be | writes a file? |
|-------------------------------------------|----------|-----------|----------------|
| `curl -o - URL`                           | BLOCKED  | ADMITTED  | no — stdout    |
| `wget -O - URL`                           | BLOCKED  | ADMITTED  | no — stdout    |
| `curl -s -o /dev/null -w '%{http_code}'`  | ADMITTED | ADMITTED  | no             |
| `curl -o out.txt URL`                     | BLOCKED  | BLOCKED   | yes            |
| `wget URL`                                | BLOCKED  | BLOCKED   | yes            |

The guard is right about writers and wrong about the two stdout spellings. T-640's own
header calls this out as accepted collateral ("stated rather than hidden because it is a
real cost") — so it was known, priced, and shipped. AEF's contribution is that it did not
have to be priced at all: `-o -` is distinguishable from `-o FILE` by the same regex that
already distinguishes `-o /dev/null`.

THE PATCH IS THE SMALL HALF. The reason it got through is the finding:
`tools/_t640-fetchers-that-write-are-writes.sh` asserts that WRITERS ARE REFUSED and that
five HAND-PICKED READERS ARE ADMITTED. It never asserts that the guard refuses nothing the
unguarded version allowed. **A chosen-set assertion cannot find what you forgot to choose.**
A no-widening sweep can, and AEF's did.

So the deliverable is two things, and the second is the load-bearing one:
1. exempt the stdout spellings;
2. add a no-widening leg whose corpus is GENERATED from the flag space rather than chosen,
   diffing pre-guard against post-guard admission and requiring every newly-blocked command
   to appear in an explicit reviewed manifest. Anything blocked that is not in the manifest
   is a widening nobody signed off on — which is exactly the shape `curl -o -` had.

## Acceptance Criteria

### Agent
- [x] `curl -o -`, `curl --output -`, `curl --output=-` and the bundled `curl -sfo -` are ADMITTED under a null focus
- [x] `wget -O -`, `wget -O-`, `wget -qO-`, `wget --output-document=-` are ADMITTED under a null focus
- [x] Writers still BLOCK: `curl -o out.txt`, `curl -sO`, `curl -O`, `curl --output f`, `curl --remote-name`, bare `wget URL`, `wget -O f`, `wget --output-document f`
- [x] `wget -O - -o log URL` still BLOCKS — the stdout exemption does not swallow wget's LOG-file flag (`-o`/`--output-file`/`--append-output`), which writes a file even when the body goes to stdout
- [x] `curl -s -o /dev/null -w '%{http_code}' URL` is still ADMITTED (the pre-existing status-probe exemption is not regressed)
- [x] `_t640` carries a NO-WIDENING leg: a mechanically generated corpus over the curl/wget output-flag space, run against both a pre-T-640 mutant lib and the live lib, asserting the newly-blocked set is EXACTLY the reviewed manifest — no unexpected blocks, and no stale manifest entries that no longer block
- [x] The no-widening leg has teeth: reverting the T-647 exemption makes it FAIL by naming `curl -o -` / `wget -O -` as unmanifested blocks (demonstrated by a mutant run, not asserted)
- [x] `bash -n` clean on both edited files; the full `_t640` suite and the safe-commands corpus both pass
- [x] SCOPE EXTENDED BEYOND WHAT AEF NAMED: `wget --spider` is admitted too. It was the third form T-640's header priced as collateral, it writes nothing, and fixing its two siblings while leaving it would have parked a known-wrong entry in the reviewed manifest below

**Evidence.**

`bash tools/_t640-fetchers-that-write-are-writes.sh` → **20 passed, 0 failed** (was 18 legs; +2).
`python3 -m pytest .agentic-framework/web/test_safe_commands.py -q` → **132 passed**.
`bash -n` clean on `lib/safe-commands.sh` and on the prober.

Direct predicate sweep over all 21 spellings named in the ACs — every verdict as required:

```
read  | curl -o -            read  | curl --output -       read  | curl --output=-
read  | curl -sfo -          read  | curl -s -o /dev/null -w "%{http_code}"
WRITE | curl -o out.txt      WRITE | curl -sO              WRITE | curl -O
WRITE | curl --output f      WRITE | curl --remote-name    WRITE | curl --output-dir /tmp -O
read  | wget -O -            read  | wget -O-              read  | wget -qO-
read  | wget --output-document=-   read | wget --output-document -   read | wget --spider
WRITE | wget -O - -o log     WRITE | wget --spider -o log
WRITE | wget                 WRITE | wget -O f             WRITE | wget --output-document f
```

The no-widening leg: **18 of 36 generated commands lost admission, and every one is on the
reviewed list.** Teeth: reverting the T-647 exemptions makes the sweep report all ten stdout
and spider spellings as unpriced widening, by name.

**THE LEG FAILED ON ITS AUTHOR WITHIN A MINUTE OF BEING WRITTEN, AND THAT IS THE RESULT.**
Its first run came back `manifest is stale — listed but no longer blocked: curl -sfo -`. I had
hand-written that entry into EXPECTED_NEWLY_BLOCKED while the AC four lines above it says the
same command must be ADMITTED. The guard was right and my manifest was wrong. A chosen-set
assertion would have had nothing to disagree with, because I would simply not have chosen it.
The comment recording this is left in the manifest rather than tidied away.

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
         1. Run `bin/fw reviewer T-647`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-647 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

- [ ] [REVIEW] The manifest is the right governance object
  **Steps:**
  1. `cd /opt/832-Workflow-designer && sed -n '/^EXPECTED_NEWLY_BLOCKED=/,/^)/p' tools/_t640-fetchers-that-write-are-writes.sh`
  **Expected:** A short list of command spellings that T-640 deliberately took away, every one of them a genuine file-writer. It is the list of things you can no longer do without an active task.
  **If not:** Any entry you would NOT have signed off on is a live over-block — name it, and it becomes a task exactly like this one.

## Recommendation

**Recommendation:** GO — the code half needs no ruling; the one Human AC is a review of the
manifest, not of the patch.

**Rationale:** The exemptions are mechanically verified in both directions and the corpus suite
is unchanged at 132 passed. What genuinely wants your eye is the new
`EXPECTED_NEWLY_BLOCKED` list, because it is now the written record of *what this guard costs
you* — nineteen command spellings you can no longer run without an active task. That list was
previously implicit, which is exactly how `curl -o -` survived in it for a week without anyone
being asked. Reading it takes under a minute and the [REVIEW] AC gives the one-line command.

**What I did not do:** I did not widen the guard to other fetchers (`aria2c`, `httpie`, `scp`).
They are not on the safe-list, so they are already refused for a different reason, and adding
them would be a second deliverable.

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
bash tools/_t640-fetchers-that-write-are-writes.sh
bash -n .agentic-framework/agents/context/lib/safe-commands.sh
bash -n tools/_t640-fetchers-that-write-are-writes.sh
python3 -m pytest .agentic-framework/web/test_safe_commands.py -q 2>&1 | tail -1 | grep -qv "failed"
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

### 2026-08-30T18:28:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-647-t-640s-fetcher-write-guard-over-blocks-t.md
- **Context:** Initial task creation

### 2026-08-31T11:10:35Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-20e99d64
- **Timestamp:** 2026-08-31T11:21:51Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 6
     - evidence: `python3 -m pytest .agentic-framework/web/test_safe_commands.py -q 2>&1 | tail -1 | grep -qv "failed"`

### 2026-08-31T11:20:11Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
