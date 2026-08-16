---
id: T-425
name: "Every exported .bpmn ships an unverified claim about AEF's behaviour"
description: >
  WITHDRAWN AS A DUPLICATE — no work to do. Filed 2026-08-10 against T-357 spike 1,
  which quotes a DI_TRAILER reading 'BPMN DI (visual layout) omitted in this demo;
  AEF generates it from node coordinates'. That string was repaired seven days earlier
  by T-361 (2026-08-03): src now reads 'BPMN DI (visual layout) omitted; node geometry
  travels as aef:position', naming no third party, and T-399 subsequently fixed a
  defect in T-361's guard. A-020 was likewise already answered NO at rail 417 and
  recorded in T-357's own IW-1b; the assumption register was stale and has been corrected
  to invalidated. Kept rather than deleted because the filing error is the finding:
  a research artifact was read as current fact without re-running the measurement
  it rested on — PL-142 applied to my own prior output. See RCA. Residue filed as
  OBS-018 (register/task-file divergence, 16 candidates, 1 confirmed).

status: work-completed
workflow_type: build
owner: claude-code
horizon:
tags: []
components: []
related_tasks: [T-357, T-423]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-10T20:23:50Z
last_update: '2026-08-16T12:33:57Z'
date_finished: 2026-08-10T20:29:40Z
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
  - ts: '2026-08-16T12:33:57Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-425: Every exported .bpmn ships an unverified claim about AEF's behaviour

## Context

**WITHDRAWN AS A DUPLICATE. The defect was real and was repaired seven days before I filed
this — by T-361, on 2026-08-03.** Nothing to build. Closed with the evidence rather than
deleted, because the way I came to file it is the finding.

What I filed against: `docs/reports/T-357-di-adoption.md` §Spike 1, which quotes
`src:9406-9407`:

    const DI_TRAILER = `${DI_TRAILER_PREFIX} in this demo; AEF generates it from node coordinates`

What `src` actually contains **today** (`src/aef-workflow-designer.html:9432-9433`):

    const DI_TRAILER_PREFIX = 'BPMN DI (visual layout) omitted';
    const DI_TRAILER = `${DI_TRAILER_PREFIX}; node geometry travels as aef:position`;

The claim about a third party is gone; so is "in this demo". `src:9407-9431` carries
T-361's comment recording why, and `src:9710` notes the hardcoded duplicate emit site was
collapsed onto the constant. T-399 then fixed a defect in the guard T-361 added.

**A-020 is likewise not "untested".** It was answered **NO** at rail 417 on 2026-08-03, and
is recorded as answered in this very inception's `## Open Questions` under IW-1b: AEF
measured their own source and found `bpmndi` occurring exactly once — a namespace
declaration with no reader or writer behind it. They never parsed DI, never emitted it, and
hold no record of agreeing to. The assumption register still says `untested`. That
divergence is real, and it is the one live item this task leaves behind.

## Acceptance Criteria

### Agent
- [x] Re-measured `src` rather than trusting the research artifact: the current
      `DI_TRAILER` names no third party and contains no "in this demo". Evidence in
      `## Verification` — one grep asserting the repaired string is present, one asserting
      the false claim survives only inside comments, not in any live code path.
- [x] Confirmed the repair has an owning task with its own reasoning trail (T-361,
      completed; guard defect subsequently found and fixed by T-399), establishing this as
      a duplicate rather than a regression that happens to look like one.
- [x] The one genuine residue is filed rather than folded in here: A-020 read `untested`
      in the assumption register while IW-1b in T-357 recorded it answered NO. Corrected to
      **invalidated** (not `validated` — the measured answer is that the assumption is
      FALSE; `validated` would have asserted its opposite, and it was briefly mis-set that
      way before being corrected the same minute). Registered as **OBS-018**.
- [x] Scope of OBS-018 measured rather than asserted, **and the measurement's limits
      stated**: 16 of 20 assumptions read `untested`, the oldest (`A-001`, `T-020`) since
      2026-07-02 — five weeks. Every one of those 16 belongs to a task whose Open Questions
      carry at least one answered/deferred disposition.
      **That is a proxy, not a proof.** `disposition:` lines belong to `IW-x` open
      questions, not to `A-xxx` assumptions; a task can have answered IWs and a genuinely
      still-open assumption. So the honest reading is **16 candidates and exactly one
      confirmed instance (A-020)** — not 16 confirmed divergences. Resolving the other 15
      needs a per-assumption read, which is its own task and not this one.
      Recorded because the tempting version of this line ("16/16 divergent") is the same
      over-claim from a proxy measurement that this task's RCA is about.

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

grep -q "node geometry travels as aef:position" src/aef-workflow-designer.html
python3 -c "import sys; live=[l for l in open('src/aef-workflow-designer.html') if 'AEF generates it from node' in l and not l.strip().startswith('//')]; sys.exit(1 if live else 0)"
test -f .tasks/completed/T-361-exported-bytes-assert-aef-generates-di-f.md

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

## RCA

**Symptom:** I created a build task for a defect that had been fixed seven days earlier,
and wrote its description asserting the defect was live "across ten releases".

**Root cause:** I read a **research artifact** as a statement of current fact. Spike 1 of
`docs/reports/T-357-di-adoption.md` was written 2026-08-03 and was accurate that day.
T-361 repaired the string later the same day. I quoted the spike verbatim into a new task
without re-running the grep it rested on.

**Why structurally allowed:** nothing marks a research artifact as *dated evidence* rather
than standing truth — it reads like documentation and ages like a measurement. Worse, the
inception's own `## Open Questions` carried the corrected answer (IW-1b, "answered — NO,
rail 417") a few lines from the material I was decomposing. I read past it because I was
reading the *artifact*, not the *task*.

**Prevention:** this is **PL-142** — *a rule and the FACT it rests on are different
artifacts with different lifetimes* — which I applied deliberately three times last session
(T-209's coverage table re-run rather than re-read, T-420's declared producer list dated,
T-421's disposition computed at runtime) and then failed to apply the first time the stale
fact was in a document **I had written myself**. The prevention is not a new rule; it is
the qualifier that the rule's hardest case is your own prior output, because that is the
source you feel least need to re-measure. Every AC above is therefore a re-measurement
rather than a citation, which is the only form of this task that could have caught itself.

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

### 2026-08-10 — the task was wrong before it was written
- **What changed:** everything. At filing I believed a false claim about AEF was live in
  every export across ten releases. It had been repaired seven days earlier by T-361, and
  the assumption I said was untested (A-020) had been answered NO at rail 417 on the same
  day as the repair. The task had no subject.
- **Plan impact:** T-425 is not a build. It converts to a closed record: three
  re-measurements, a corrected register entry, and an RCA. It is deliberately **not**
  deleted — a deleted task leaves no trace of why it was filed, and the filing is the only
  thing here worth keeping.
- **What I would have missed by deleting it:** the register/task-file divergence. Chasing
  down *why* my premise was stale is what surfaced A-020 sitting `untested` next to an
  IW-1b that read "answered — NO". That is a second carrier for one fact with nothing
  reconciling them — the same shape PL-114 names for geometry, one layer up.
- **Triggered:** OBS-018; A-020 corrected `untested` → `invalidated` (via a wrong turn
  through `validated`, which would have asserted the opposite of the measurement); PL-142
  extended with the qualifier that its hardest case is your own prior output.

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

### 2026-08-10T20:23:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-425-every-exported-bpmn-ships-an-unverified-.md
- **Context:** Initial task creation

### 2026-08-10T20:26:17Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2b9bd2f9
- **Timestamp:** 2026-08-10T20:29:41Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-10T20:29:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
