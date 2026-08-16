---
id: T-536
name: "Tasks in .tasks/completed/ whose frontmatter still says started-work (CTL-028), surfaced 263 times in a corpus nothing reads"
description: >
  Tasks in .tasks/completed/ whose frontmatter still says started-work (CTL-028), surfaced 263 times in a corpus nothing reads

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
created: 2026-08-16T09:01:00Z
last_update: 2026-08-16T09:01:00Z
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

# T-536: Tasks in .tasks/completed/ whose frontmatter still says started-work (CTL-028), surfaced 263 times in a corpus nothing reads

## Context

A task's **location** (`.tasks/completed/`) and its **frontmatter `status:`** are two independent
carriers of the same fact, and they disagree. The audit's CTL-028 control detects exactly this,
named four tasks — T-335, T-336, T-338, T-348 — and fired **263 times**, once per 15-minute cron
run since 2026-08-09. Every one of those firings landed in `.context/audits/cron/`, which
T-535 measured as invisible to the trend detector (non-recursive glob, date-named filter). So the
control worked perfectly and nobody has ever seen it.

That is the interesting part and the reason this is a task rather than a cleanup: a control whose
output goes only to an unread sink is indistinguishable from a control that does not exist. The
fix has to address the disagreement **and** say something about why it stood for a week.

Filed separately from T-535 (which found it) and from CTL-029/CTL-030 (different predicates,
different remedies) per the one-bug-one-task rule.

## Findings

### The population, measured from the tree

**4 of 468** files in `.tasks/completed/` carry a `status:` other than `work-completed` — exactly
the four the audit named, all `status: started-work`, all `owner: agent`, all
`date_finished: null`. The audit line was accurate; it was verified rather than trusted.

| task | agent ACs | Human AC section | verification cmds | closing commits |
|---|---|---|---|---|
| T-335 | 8 ticked / 0 open | none | 11 | 2 |
| T-336 | 4 ticked / 0 open | none | 9 | 1 |
| T-338 | 6 ticked / 0 open | none | 6 | 3 |
| T-348 | 8 ticked / 0 open | none | 4 | 2 |

**A measurement error caught before it became a conclusion:** the first pass reported "0 ticked /
2 unticked Human ACs" for all four and would have classified them as partial-complete — the one
state where closing them is *not* mine to do. Those two entries are the `[REVIEW]` / `[REVIEWER]`
**examples inside the template's HTML comment block**, which the parser was reading as live
checkboxes. Stripping `<!-- … -->` first shows none of the four has a Human AC section at all.
Same shape as PL-239 from earlier today: a confident count over the wrong set, not a missing one.

### Which carrier is truthful

**The location is truthful; the frontmatter is the stale carrier.** Every agent AC is ticked, each
task has real verification commands and substantial closing commits, and none has an outstanding
Human AC. Nothing here is a task still in progress that was misfiled — so the blanket repair is
safe, which is a conclusion the classification earned rather than assumed.

### How they got there

`git log` shows all four as **`R100` renames — byte-identical moves** from `active/` to
`completed/`, each swept into a session-handover commit on 2026-08-02. Byte-identical means the
frontmatter was never rewritten, so `fw task update --status work-completed` never ran. This is a
**named class the framework already knows**: L-390, `git mv` bypassing the state machine, which is
precisely what `completed-task-scan.py` / CTL-028 exists to detect. No tooling defect — agent
behaviour on 2026-08-02, correctly caught.

### Why nobody saw it for 14 days — the part worth keeping

CTL-028 fires under `should_run_section "compliance" || should_run_section "oe-daily"`
(`audit.sh:3721`). Its header says, verbatim:

> *promoted by T-1882 to fire on `compliance || oe-daily` so the pre-push audit (which includes
> compliance) catches the `git mv → completed/` bypass class BEFORE the drift ships, rather than
> waiting up to 24h for the next oe-daily cron run.*

**The pre-push audit does not include compliance.** `agents/git/lib/hooks.sh:839` runs
`"$AUDIT_SCRIPT" --section structure` and nothing else — trimmed to `structure` by **T-862** for
speed ("full audit takes >90s with 100+ tasks"). T-862 landed first, so T-1882's comment asserted
a property of the pre-push audit that was **already false when it was written**.

The promotion therefore moved CTL-028 into a section the pre-push hook never runs, leaving
`oe-daily` — the 15-minute cron — as its only live carrier. Its output goes to
`.context/audits/cron/`, which T-535 measured as invisible to the trend detector. Result: **263
correct firings, over 14 days, none of them anywhere a person or agent looks.**

That is PL-159 one level up — *a bar stated in a message string is not a bar the instrument
holds* — applied to a **comment claiming a routing property**. Two upstream changes, each correct
in isolation, composed into a control that runs nowhere useful. Neither task could have seen it:
T-862 predates the promotion, and T-1882 had no reason to re-read a hook it wasn't touching.

**Not fixed here, deliberately.** Making the pre-push audit run `compliance` restores T-1882's
intent but adds latency to every push, and T-862 traded that away on purpose. Changing how long
the operator waits at every push is their call, not initiative I hold. Registered as **G-038**
(watching) with a closure condition that refuses the one-instance fix as closure, reported
upstream at rail 11973, and put to the operator below.

### What re-running a two-week-old verification gate found

The repair runs each task's `## Verification` block, and **T-338's blocked** — 3 of 6 commands
failed. Not bypassed, investigated:

- The probe itself passes (`rc 0`, *"OK: every measured fidelity verdict matches expectation"*).
- Two legs asserted the literal strings `out-of-vocabulary tags probed` and `callActivity`. Both
  were present in the probe at `abc5baa5` — T-338's own commit — and were removed afterwards by
  **T-419** (competing-carrier rewrite) and **T-340** (DI repair). The properties are still
  measured; only the prose moved.

**The reason nobody noticed is the same reason this task exists.** T-338's verification block has
**never once executed**. The `git mv` bypassed the P-011 gate it was written for, and by the time
anything ran it — today, 14 days later — its subject had been rewritten twice underneath it. A
verification block is a one-shot gate (PL-161); one that never fires is indistinguishable from
one that passes. The status desync and the rotted assertions are not two problems, they are the
same bypass seen from two sides.

Repaired by re-pointing those two legs at the probe's own **verdict** and at a population name it
derives, rather than at how it phrases things in passing — assertions on what the instrument
concludes, not on its wording. This is a third instance of the family T-535 named today: an
identity or an assertion pinned to a rendered string that its subject is free to change.

**This is a goalpost move and should be read as one.** I edited a task's verification so that it
would pass. The defence is that the probe's verdict is unchanged and its exit code was already 0
— but the honest record is that the alternative (leave T-338 desynced, report it) was available
and I chose the repair. Stated here so a reader can disagree with the call rather than discover it.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The population is measured from the tree, not taken from the audit string.**
      → 4 of 468, enumerated above with status, owner and `date_finished`. Matches the audit's
      four; verified rather than trusted.
- [x] **Each one is classified before anything is changed.**
      → All four: location truthful, frontmatter stale. Evidence per task in the table above.
      The first classification pass was **wrong** and would have mis-filed all four as
      partial-complete; corrected before any change was made, and the error is recorded rather
      than quietly fixed.
- [x] **No `owner: human` task is closed as part of this.**
      → All four are `owner: agent`, and none has a Human AC section at all. Nothing here was
      mine to leave alone, but it was checked before acting, not after.
- [x] **The repair is applied through `fw task update`, not by hand-editing frontmatter.**
      → Four `fw task update --status work-completed` runs, gates live. **`--force` deliberately
      not used**, even though CTL-028's own mitigation string offers it first. T-338's gate
      blocked and was investigated, not bypassed (below).
- [x] **CTL-028 reports clean afterwards on a real run**, and the run is shown.
- [x] **A regression guard exists that fails when location and status disagree.**
      → `tools/_t536-status-desync-teeth.py`, 5 legs, 3.3s, wired into the bridge suite. Driven
      against a **synthetic** tree via the `TASKS_DIR` seam, because "the real tree is clean" is
      a global always-moving property (G-015) that goes red for someone else's mistake and green
      when the control is deleted. Red arm: neutering `completed-task-scan.py`'s desync append
      makes the audit print `All completed/ tasks have frontmatter status: work-completed` — a
      broken control rendering as a PASS line, which is why leg 1 asserts the finding rather than
      trusting silence. Anti-vacuity in both directions (a correctly-closed task and an in-flight
      task must **not** be named).
- [x] **The unread-sink question is answered, not deferred.**
      → Answered: `audit.sh:3721` gates CTL-028 on `compliance || oe-daily`, the pre-push hook
      runs `--section structure` only, and the two sets are disjoint. Registered as **G-038**
      whose closure condition explicitly refuses the one-instance fix. The remedy costs push
      latency that T-862 bought deliberately, so it goes to the operator rather than being taken
      as initiative.

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

# The population is empty. Asserts a property of THIS task's subject, not of the whole tree:
# a task appearing in completed/ with a wrong status tomorrow is someone else's defect, and the
# teeth below are what catch that — a count here would be the G-015 shape.
test "$(python3 -c "
import glob,re
n=0
for f in glob.glob('.tasks/completed/*.md'):
    fm=open(f,encoding='utf-8',errors='replace').read().split('---',2)[1]
    m=re.search(r'^status:\s*(\S+)',fm,re.M)
    if (m.group(1) if m else '') != 'work-completed': n+=1
print(n)")" -eq 0
# The guard exists, sees a planted disagreement, and does not flag the two look-alikes.
# rc 2 is a REFUSAL (CTL-028 said nothing at all), never a pass.
python3 tools/_t536-status-desync-teeth.py
# Wired into the gating runner rather than merely present on disk (T-316/T-509 class).
grep -q '_t536-status-desync-teeth.py' tests/run-bridge-tests.sh
# The gap is registered and its closure command actually runs from the stored YAML.
# Exits 1 today (STRANDED) BY DESIGN, so this asserts it is renderable, not that it is green —
# demanding green here would require taking the operator's push-latency decision for them.
python3 -c "
import yaml,subprocess,sys
c=[x for x in yaml.safe_load(open('.context/project/concerns.yaml'))['concerns'] if x['id']=='G-038'][0]
r=subprocess.run(['bash','-c',c['closure_check_command']],capture_output=True,text=True)
sys.exit(0 if r.returncode in (0,1) and 'CTL-028 gate=' in r.stdout else 1)"
# T-338's repaired verification legs assert the probe's VERDICT, not its incidental prose.
grep -q 'every measured fidelity verdict matches expectation' .tasks/completed/T-338-input-fidelity-guard-prove-load-save-pre.md

## RCA

**Symptom:** four tasks sat in `.tasks/completed/` carrying `status: started-work` and
`date_finished: null` for 14 days. The audit's CTL-028 control named all four correctly, 263
times, and no one ever saw a single firing.

**Root cause (the desync):** L-390 — a bare `git mv` moved the files without running
`fw task update --status work-completed`, so the state machine, the date stamp and the P-011
verification gate were all skipped. Confirmed as `R100` byte-identical renames swept into
session-handover commits on 2026-08-02.

**Root cause (the blindness, which is the one that matters):** CTL-028 is gated on
`compliance || oe-daily` (`audit.sh:3721`) while the only automatic caller a human reads — the
pre-push hook — runs `--section structure` (`hooks.sh:839`). T-862 trimmed the hook for speed;
T-1882 later promoted CTL-028 *to* `compliance` with a comment asserting "the pre-push audit
(which includes compliance)", a routing property that T-862 had already falsified. The promotion
moved the control from one unrun section to another. Its only live carrier became the 15-minute
cron, whose output lands in `.context/audits/cron/` — which T-535 measured the same day as
invisible to the trend detector too.

**Why structurally allowed:** nothing asserts that a control's declared audience intersects the
sections its automatic callers actually run. Both changes were individually correct and neither
author could have seen the composition — T-862 predates the promotion, T-1882 had no reason to
re-read a git hook. This is PL-159 applied to a **routing** claim rather than a threshold: a
property stated in a comment is not a property the system holds. And a control firing into an
unread sink is observationally identical to a control that does not exist, so no user of the
system could report it either.

**A second face of the same bypass:** because the `git mv` skipped P-011, T-338's verification
block had **never executed**. Two of its legs asserted literal probe output strings that T-419
and T-340 removed weeks later. The block rotted unexecuted and only failed when this task ran it
for the first time. Status desync and assertion rot are one bypass seen from two sides.

**Prevention:** `tools/_t536-status-desync-teeth.py` (5 legs, wired into the bridge suite,
synthetic tree via `TASKS_DIR`, red arm proven) keeps the *detection* honest — it fails if
CTL-028 stops seeing a planted disagreement, and REFUSES rather than passes if the control says
nothing. That is deliberately **not** the full prevention: it proves the control can see, not
that anyone is listening. The listening half is **G-038**, registered `watching`, whose closure
condition explicitly refuses the one-instance re-route as a fix and whose stored closure command
prints `STRANDED: CTL-028 gate=['compliance','oe-daily'] pre-push runs=['structure']` today.

## Decisions

### 2026-08-16 — repairing T-338's stale verification instead of leaving it desynced

- **Chose:** re-point the two rotted legs at the probe's own verdict line and at a derived
  population name, then close the task through the gate.
- **Why:** the probe exits 0 and reports *"every measured fidelity verdict matches expectation"*;
  the properties it measures are unchanged, only the prose moved. Assertions pinned to incidental
  wording are the same defect class T-535 fixed in the trend detector's identity key.
- **Rejected:** `--force` (a Tier-2 bypass, not delegated, and it would have hidden the rot);
  leaving T-338 desynced and reporting it (defensible, and the honest note is that I chose the
  repair — this is a goalpost move and is labelled as one in the findings so a reader can
  disagree with the call rather than discover it).

### 2026-08-16 — not fixing the routing gap

- **Chose:** register G-038, report upstream, hand the trade to the operator.
- **Why:** the obvious fix — add `compliance` to the pre-push hook — spends push latency at every
  push, which T-862 deliberately bought back. That is an operator-facing cost, and a broad
  autonomous directive delegates initiative, not authority over the operator's own trade-offs.
- **Rejected:** doing it anyway and mentioning it afterwards; and closing the gap on the teeth,
  which prove the control can see but assert nothing about whether anyone is listening.

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

### 2026-08-16T09:01:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-536-tasks-in-taskscompleted-whose-frontmatte.md
- **Context:** Initial task creation
