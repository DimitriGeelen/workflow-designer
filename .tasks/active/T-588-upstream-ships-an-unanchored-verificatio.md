---
id: T-588
name: "upstream ships an unanchored verification extractor that can silently drop a leg — rule NO-UPDATE and send our anchored one upstream"
description: >
  upstream ships an unanchored verification extractor that can silently drop a leg — rule NO-UPDATE and send our anchored one upstream

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
created: 2026-08-25T21:46:47Z
last_update: 2026-08-26T09:56:05Z
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

# T-588: upstream ships an unanchored verification extractor that can silently drop a leg — rule NO-UPDATE and send our anchored one upstream

## Context

`fw update` re-vendors `.agentic-framework/` from upstream. The operator ruled: do not
update; send the fix upstream instead. This task is the second half of that ruling —
because the honest form of "we are not taking your code" is "here is the defect, here is
the reproduction, here is our fix", not a decision recorded privately in our own tree.

**The ruling's third supporting reason turned out to be wrong, and the conclusion moved
with it.** It read "VERSION goes backwards 1.6.354 -> 1.6.29, so this is a downgrade". The
version string is a resetting counter and cannot order the two trees. Measured by content,
upstream has 824 code files to our 328 and we lack 499 of them — our tree is the older one.
See the CORRECTION entry in `## Decisions`. The corrected recommendation is a **selective
merge**, not a refusal; it has NOT been acted on, because it is a materially different
recommendation from the one the operator ruled on.

What survives the correction unchanged is the defect report, which stands on its own
reproduction against upstream's current HEAD.

**The claim in this task's own title is not yet proven.** "Can silently drop a leg" is a
third defect I suspect from reading line 177, beyond the two (prefix-matching, range
restart) already measured. AC 1 requires it to be reproduced or retracted IN WRITING.
Reporting a defect upstream on reasoning alone is the same error as a verification leg that
asserts without running.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Each suspected defect in upstream `lib/verification-port.sh:177` is individually
      REPRODUCED against a fixture, or RETRACTED in writing in `## Measurements`. No defect
      is reported upstream on reasoning alone. A retraction is a valid outcome for this AC
      and does not count as failure.
- [x] A differential harness in `tools/` runs upstream's extractor BYTES and ours over one
      shared fixture set and reports where the two disagree. It reads the upstream line from
      the cloned upstream file rather than a hand-copy, or, if it must inline the bytes,
      asserts byte-equality against the upstream source and ABORTS when that fails —
      a copy agrees today and drifts silently tomorrow (PL-259).
- [x] The harness is proven able to FAIL: a mutation that blinds the comparison is caught,
      and the mutation rewrites a line the interpreter REACHES (T-499: appending garbage to
      a script tests a tail no early-exiting interpreter parses).
- [x] Our tree is confirmed not vulnerable BY MEASUREMENT over every task file in
      `.tasks/` — not by asserting it from the shape of our extractor. The count of files
      scanned is printed, so a scan that silently matched nothing is distinguishable from a
      scan that found nothing.
- [x] The findings are posted to AEF over termlink with `from_project` attribution, and
      every number in that post is produced by a command run in this session
      (PL-260: never cite a queue you have not fetched).
- [x] The NO-UPDATE ruling is recorded in `## Decisions` with its three measured reasons
      and with what would REVERSE it, so it is a decision with an expiry condition rather
      than a permanent refusal.

### Human

- [ ] [REVIEW] **Rule on the CORRECTED recommendation: selective merge, keep refusing, or
      update as-is.** The earlier NO-UPDATE ruling was given on three reasons, one of which
      was wrong (see the CORRECTION in `## Decisions`). Our tree is the OLDER one. This is a
      materially different question from the one already answered, so it is asked again
      rather than assumed.

      **Steps:**
      1. Read the measurement — upstream 824 code files vs our 328; 499 we lack; 3 they
         lack; 93 of 325 shared files differ. Confirm it yourself in one line:
         `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw doctor 2>&1 | head -5; find .agentic-framework -type f \( -name '*.py' -o -name '*.sh' \) | wc -l`
      2. Choose one:
         - **A · Selective merge (recommended)** — take upstream where newer, keep ours
           where ours is a superset, do NOT adopt the unanchored extractor. Costs a scoped
           task that measures the 93 differing files and 28 divergences before touching
           anything.
         - **B · Keep refusing** — costs ~500 files, including
           `check-worktree-governance-write.sh` and `worktree-corpus-guard.sh`, the worktree
           governance T-586 hand-built this session.
         - **C · Run `fw update` as-is and repair after** — fastest, and the repair happens
           with the gate that detects verification damage inside the blast radius.
      3. Reply with A, B or C.

      **Expected:** one letter. A creates a scoped merge task; B closes the question with a
      revisit trigger; C is executed and reported precisely.

      **If not:** if none of the three fit, say what is missing — the options were derived
      from measurement, not preference, and a fourth is entirely possible.

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

# Leg 1 runs OFFLINE and asserts the differential REFUSES rather than passing vacuously
# when it has no upstream to compare against. This is the leg that stays honest when the
# clone is gone: without it, a missing clone and a clean comparison look identical.
sh -c 'unset T588_UPSTREAM; out=$(tools/_t588-verification-extractor-differential.sh 2>&1); rc=$?; [ "$rc" = "2" ] && echo "$out" | grep -q "Nothing was compared"'

# Leg 2 is the real comparison. It clones upstream into a cache if absent — a network
# failure here means "could not verify against upstream", which is a red we want to see
# rather than a green we cannot justify.
sh -c 'C=/tmp/.t588-aef-cache; [ -d "$C/.git" ] || git clone --depth 1 --quiet https://github.com/DimitriGeelen/agentic-engineering-framework.git "$C"; T588_UPSTREAM="$C" tools/_t588-verification-extractor-differential.sh > /tmp/.t588-diff.out 2>&1 && grep -q "still defective in all three directions" /tmp/.t588-diff.out'

# Leg 3: the differential can reach a conclusion other than "all well".
sh -c 'C=/tmp/.t588-aef-cache; [ -d "$C/.git" ] || git clone --depth 1 --quiet https://github.com/DimitriGeelen/agentic-engineering-framework.git "$C"; T588_UPSTREAM="$C" tools/_t588-differential-teeth.sh > /tmp/.t588-teeth.out 2>&1 && grep -q "3 passed, 0 failed" /tmp/.t588-teeth.out'

# Leg 4: our own tree still carries zero exposure to the defect we are reporting. The
# count is printed so a scan that silently matched nothing is distinguishable from a scan
# that found nothing.
sh -c 'n=$(find .tasks -name "*.md" -type f | wc -l); [ "$n" -gt 500 ] && bad=$(for f in $(find .tasks -name "*.md" -type f); do e=$(grep -n "^## Verification[[:space:]]*$" "$f" | head -1 | cut -d: -f1); p=$(grep -n "^## Verification" "$f" | head -1 | cut -d: -f1); [ -n "$e" ] && [ -n "$p" ] && [ "$e" != "$p" ] && echo x; done | wc -l); echo "scanned $n task files, prefix-shadowed: $bad"; [ "$bad" = "0" ]'

## Measurements

All numbers below were produced by commands run in this session, against upstream
commit `67aeacc` (dated 2026-08-25 10:17, `VERSION` = 1.6.29) cloned fresh.

### The one line under discussion

`lib/verification-port.sh:177`, verbatim — a file we do not have at all:

```sh
sed -n '/^## Verification/,/^## /p' "$file" 2>/dev/null | sed '$d' | tail -n +2 | ...
```

### Three separable defects, each reproduced against a fixture

| # | Mechanism | Fixture | Upstream emits | Ours emits |
|---|-----------|---------|----------------|------------|
| D1 | Verification is the LAST section, so no `## ` closes the range; sed runs to EOF and `sed '$d'` deletes the final line — **a leg, not a heading** | A | `LEG-ONE`, `LEG-TWO` — **`LEG-THREE-LAST` silently gone** | all three |
| D2 | sed ranges RESTART on a second `^## Verification` prefix match | B | `REAL-LEG` **and `SHOULD-NOT-RUN`** | `REAL-LEG` only |
| D3 | `/^## Verification/` is a PREFIX match, so `## Verification Notes` opens the range and the REAL heading CLOSES it | C | **prose**, and **not** `REAL-LEG` | gate REFUSES |

D1 was a suspicion when this task was filed, not a measurement. It is now reproduced.
D3 is the worst of the three: one prefix match causes prose to be executed *and* the real
block to be skipped — two failures in opposite directions.

### Exposure, measured over both task trees

| tree | task files | with a Verification block | D1 | D2 | D3 |
|------|-----------|---------------------------|----|----|----|
| positive control (fixtures) | 3 | 3 | 1 | 2 | 1 |
| 832 (ours) | 590 | 590 | 0 | 0 | 0 |
| AEF upstream | 3123 | 2990 | 0 | **14** (3 in `active/`) | **1** (in `active/`) |

The fixture row is the positive control: a detector reporting 0 on the live trees is only
meaningful because the same detector reports non-zero on inputs built to trigger it.

### The live instance: AEF's own T-3130

`.tasks/active/T-3130-episodic-mining-runs-before-the-completi.md` has two headings that
begin `## Verification` — line 168 and line 191. Line 168 is **inside the task template's
own HTML comment**, where the wrap happens to place the literal text at column 0:

```
## Verification` instead of a Human AC here. Only keep [REVIEW] if
```

Upstream's extractor therefore opens at 168, closes at 191, and hands **21 lines of
template documentation** to the eval loop — `**Steps:**`, `1. Open https://... in browser`,
`-->` — while the real verification block at 191 is never reached.

Our gate, run against that same file, refuses and names the cause:

> Why: a heading at line 168 begins with '## Verification' but is not the real heading
> (which is at line 191). This is the T-542 shape: a prefix match opens the range EARLY
> and feeds prose to the shell.
> Headings seen: exact='## Verification' x1 | starting-with x2 | mid-line x1

**The difference between the two trees is one line wrap.** The identical sentence in our
template reads `     command in \`## Verification\` instead of a Human AC here.` — indented,
so it never matches at column 0. That is the whole reason our D3 count is 0 and theirs is
1. It is luck, not design, and it is why our gate refuses instead of relying on it.

### Control on the file-count claim: the gap is real, not a git artifact

010-termlink warned 832 directly (agent-chat-arc offset 415) that our `.gitignore`
allowlist was probably dropping framework code our own `bin/fw` executes. If true, the
824-vs-328 comparison would be measuring our `.gitignore` rather than our tree. Checked:

| | on disk | tracked by git | ignored |
|---|---|---|---|
| `.agentic-framework/**` `*.py`+`*.sh` | 328 | 328 | **0** |
| `.agentic-framework/**` all files | 2249 | 2165 | 84 |

**832 is NOT affected.** All 84 ignored paths are `__pycache__` (76), `.pytest_cache` (7)
and one `.context/working` file — bytecode and caches, no framework source. The 328 figure
is the tree, so the ~500-file gap is genuinely missing code.

*Control honesty:* the probe file written to test whether `git check-ignore` fires here
came back NOT ignored, so that control demonstrated nothing. The evidence the check works
is the run itself returning 84 non-zero results; the probe was redundant and is recorded as
a dud rather than quietly dropped.

### A third-party data point on the same tool class, arrived while this was pending

001-CashWeb reported (their G-047) that `fw upgrade` **silently reverted their designer pin
from 0.11.0 back to 0.8.0**, after a correct intake, and the route went back to serving
903600 bytes **with no sha complaint** — because the 0.8.0 artifact was still on disk. The
check that should have caught it was satisfied by a stale file.

Relevance to the A/B/C ruling below: it is an independent observation of the same class this
task is about — a vendoring tool reverting a deliberate local decision without saying so.
It does not decide the ruling, and it is a different verb (`fw upgrade`, not `fw update`) on
a different project, so it is recorded as a data point rather than folded into the reasons.
It cuts toward "measure before and after, whichever option is chosen" rather than toward any
one option.

### Upstream confirmed the defect on their own tree, twice, within the hour (rail 457)

999-AEF replied to our report and did not merely accept it — they found the same shape in
their own tooling and gave it a home:

- The shape is **six sites** in their tree, **four of them gate-bearing**, filed as their
  **T-3148**. `sed -n '/^## X/,/^## /p' | sed '$d'` is not one line, it is a pattern they
  had reproduced by copy.
- **It fired on them while they were reading our report.** Their own task file carried a
  template stub `## Recommendation` above the real 40-line one; the gate refused with
  *"## Recommendation is empty"* while the recommendation sat 300 lines below. Then it
  happened **again the same day, in T-3149 — the very inception documenting the class.**
- Their diagnosis is sharper than ours and is the part worth keeping: the extractor takes
  the **FIRST** range. For `## Verification` that is correct — a second block supersedes.
  For `## Recommendation` it is wrong. **First-wins vs last-wins is a per-section semantic
  decision, and it had been made once, globally, by accident.** Our D2 says "ranges restart";
  theirs says why that is sometimes right and sometimes catastrophic.

Bearing on the ruling: this is the strongest available evidence that the defect is real,
live, and upstream-acknowledged — but it also shows upstream **fixing it**, which is exactly
the condition our own differential is written to detect (leg 1 goes RED if line 177 is
repaired). It argues for a **timed** re-check rather than for any of A/B/C directly.

### 010-termlink carries the same pre-fix extractor and is not patching it (rail 437)

They vendored `67aeacc` this week and their `lib/verification-port.sh:177` is the old form,
plus all four gate-bearing AC sites. Their measured consequence over **2569** task files:
D3 **0**, D2 **22** (`## Verification`) and **1** (`## Acceptance Criteria`), D1 **1**. They
explicitly decline to patch — G-062, vendored code is never patched locally there.

Two independent trees now report **D3 = 0 and call it luck**, for the same stated reason:
the task template puts `## Verification` at column 0 inside a comment block. Three projects
agreeing that a zero is contingent rather than earned is worth more than any one of the
zeros.

### AEF's operator ruled that `fw upgrade` owns CLAUDE.md and settings.json wholesale (rail 458)

Their T-3149 IW-1 was decided **GO**: the upgrade owns those files outright, and they will
pay the resulting debt rather than build a merge engine. Slices filed as T-3150–T-3153.

**Direct bearing on the A/B/C ruling in front of you, and I am recording it rather than
weighting it.** If taking upstream's tooling means upstream's upgrade path owns our
`CLAUDE.md` and `.claude/settings.json` wholesale, then option **C** (run it as-is and repair
after) has a cost this task had not priced: the repair target includes the two files that
carry our governance and our enforcement config. Note the interaction with **T-586**, whose
whole deliverable is three deny rules in `.claude/settings.json`.

It is upstream's operator's ruling about upstream's tool, not a ruling about our tree, and I
am not treating it as one. But it is the single most decision-relevant thing that arrived on
the rail since this task was filed.

### Version direction

`fw update` re-vendors from that commit. `VERSION` goes 1.6.354 -> 1.6.29 while the tool
calls it an upgrade. AEF's numbering is not orderable from here, which is itself a reason
not to let a tool decide the direction.

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

**Symptom:** `fw update` presents itself as an upgrade. Measured, it would replace a
working verification gate with one that can hand task prose to a shell, skip the real
verification block, or silently drop the final leg — and would move `VERSION` backwards
while doing it.

**Root cause:** one unanchored `sed` range. `/^## Verification/` is a prefix match, `sed`
ranges restart, and an unmatched closing address runs to EOF where `sed '$d'` then deletes
a command instead of a heading. Three distinct failures from one line because the line
makes three separate assumptions it never checks.

**Why structurally allowed:** the verification gate is the instrument that would report a
verification problem. When the instrument is the defect, every leg it runs is suspect and
none of them say so — a green P-011 run over a block the extractor mangled looks exactly
like a green run over the block the author wrote. Neither tree could have detected this
from the inside; it took comparing two implementations that were supposed to agree.

**Prevention:** `tools/_t588-verification-extractor-differential.sh` compares the two
extractors' real bytes on fixtures isolating each defect, with a control that aborts when
it cannot tell them apart. It fails in BOTH directions — if ours regresses, and if
upstream's line changes — so it is the trigger that re-opens the update question rather
than a one-time argument for closing it.

**Not prevention:** our own D3 count being 0. That is a line-wrap accident in our copy of
the shared template, not a property of our code. Recorded in `## Measurements` precisely so
nobody later mistakes the luck for the design.

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

### 2026-08-25 — `fw update`: NO, with an expiry condition

- **Chose:** Do not run `fw update`. Send the finding and our extractor upstream instead.
- **Operator input:** the operator selected this option from a numbered list where it was
  presented as the recommendation. Recorded as their ruling; the agent did not decide it.
- **Why (three measured reasons, not one):**
  1. It would **import a live defect into a tree that is immune to it.** Upstream ships
     `lib/verification-port.sh:177`; we do not have that file, and our extractor anchors
     exactly, takes `head -1`, and refuses on ambiguity. Their own `active/` tree has a
     task (T-3130) the defect fires on today.
  2. It would **revert 28 `.vendor-divergence.yaml` entries**, including live enforcement
     gates — `context/budget-gate.sh`, `context/lib/safe-commands.sh`,
     `context/check-active-task.sh`, `observe/observe.sh`, `task-create/update-task.sh`
     (P-011 multi-line + the anchored extractor), `policy/designer-pin.yaml`.
     0 of our content fixes have landed upstream.
  3. ~~**VERSION moves backwards** (1.6.354 -> 1.6.29) while the command calls it an
     upgrade.~~ **RETRACTED — see the correction below. This reason was wrong.**
- **What REVERSES this:** any one of — (a) `tools/_t588-verification-extractor-differential.sh`
  starts exiting 1 with an "upstream may have FIXED it" leg, meaning line 177 changed;
  (b) our divergence entries land upstream so re-vendoring stops reverting them;
  (c) the operator decides the version question separately. This is a decision with a
  trigger, not a standing refusal to ever update.
- **Rejected — run it and repair afterwards:** the repair would be re-applying 28 entries
  by hand against a tree whose VERSION now reads lower than before, with the gate that
  detects verification-block damage among the things being replaced. The tool that would
  tell us it went wrong is inside the blast radius.
- **Rejected — patch upstream's file in our vendored copy:** we do not have the file, and
  creating it would manufacture a divergence entry for code we do not run.

### 2026-08-26 — CORRECTION: reason 3 was wrong, and the recommendation changes with it

Read `agent-chat-arc` offset 424 after recording the decision above. 010-termlink had
publicly retracted the exact claim I had just written down, then I measured it here and
they are right.

- **Retracted:** "VERSION moves backwards, so this is a downgrade." The version string is a
  **resetting counter**, not an ordering. 010's own register records
  1.6.260 -> 1.6.160 -> 1.6.7 -> 1.6.295 -> 1.6.145 across five vendor events. A string
  comparison cannot decide direction in either direction, and I used it as if it could —
  while separately holding the evidence that upstream's HEAD commit date (2026-08-25 10:17)
  is **current**. I had the disproof in the same paragraph as the claim.
- **Measured here, by content rather than by string:**

  | | upstream | ours (`.agentic-framework/`) |
  |---|---|---|
  | `*.py` + `*.sh` code files | **824** | **328** |
  | files the other side does not have | 499 | 3 |
  | shared files differing in content | 93 of 325 | — |

  Our tree is behind by roughly 500 files. `1.6.354` is a **stale higher number on an older
  tree.** Among the 499 we lack: `agents/context/check-worktree-governance-write.sh` and
  `agents/git/lib/worktree-corpus-guard.sh` — worktree governance, which is the exact
  capability T-586 built from scratch this session because nothing here provided it.

- **So the recommendation changes.** "Do not update" is no longer the right shape. Reason 1
  is narrow (one file's extractor, which is already ours by divergence) and reason 2 is a
  **merge** problem, not an argument for refusal. 010-termlink's account of the same trap is
  the precedent: *"Last session I reverted the vendored tree wholesale, which threw away
  five months of upstream work to protect one local patch that upstream had already fixed
  better."* Refusing wholesale to protect 28 divergences would be that same move.
- **Corrected recommendation:** a **selective merge** — take upstream where it is newer,
  keep ours where ours is a superset, and specifically do NOT adopt
  `lib/verification-port.sh`'s extractor without the anchoring fix. Not a blind `fw update`,
  and not a refusal.
- **NOT ACTED ON.** The operator ruled on the previous, wrongly-supported recommendation.
  A materially changed recommendation needs a fresh ruling, so nothing was updated, merged
  or re-vendored. Surfaced instead.
- **What this cost:** one reason out of three, and the shape of the conclusion. What it did
  not cost: the defect report, which stands entirely on D1/D2/D3 and reproduces against
  upstream's current HEAD.

### 2026-08-25 — report the defect with a runnable reproduction, not a description

- **Chose:** build a differential that executes both extractors' real bytes over shared
  fixtures, and send that alongside the prose.
- **Why:** we are declining someone's code. The honest form of that is a reproduction they
  can run, not an assertion they have to take on trust. It also inverts on us: if upstream
  fixes line 177, leg "upstream DROPS the final leg" goes red and tells us to re-open the
  update question. The tool argues against `fw update` today and will argue for it later.
- **Rejected — file an observation and move on:** that is what happened with OBS-343. The
  finding existed, the fix existed in our tree, and it did not travel.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-25T21:46:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-588-upstream-ships-an-unanchored-verificatio.md
- **Context:** Initial task creation
