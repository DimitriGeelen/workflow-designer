---
id: T-353
name: "Prepare the corpus for the P-011 errexit gate change (4 latent patterns + 19
  DIVERGENT lines)"
description: >
  T-352 measured the blast radius of the proposed P-011 errexit fix and it inverts
  the case for applying it today: 0 currently-manifesting false greens, 4 latent instances
  (all 'grep -q VALID' against validate-workflow.py, all in ARCHIVED tasks so they
  never re-run), and 19 CORRECT verification lines the remedy would break (validator
  exits non-zero on an invalid fixture by design; 'grep -c' exits 1 when it counts
  zero matches). The gate change is right in principle and must not land before the
  corpus is ready. This task does the readying: tighten the 4 patterns so they cannot
  match their own denial, and convert the 19 so their intended failure is expressed
  as success. Blocked on an operator ruling for the completed-task edits (same class
  as G-015 leg 1: a convention change across other owners' tasks). See docs/reports/T-352-remedy.md
  sections 6 and 7.

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
created: 2026-08-03T10:35:08Z
last_update: '2026-08-16T13:58:45Z'
date_finished: 2026-08-03T11:09:29Z
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
  - ts: '2026-08-16T12:33:28Z'
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:docs/reports/T-353-corpus-readiness.md,tools/_t352-member-scan.py,tools/_t352-p011-errexit-probe.sh,tools/_t353-classify.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:45Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/reports/T-353-corpus-readiness.md,tools/_t352-member-scan.py,tools/_t353-classify.py,tools/_t353-convert.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-353: Prepare the corpus for the P-011 errexit gate change (4 latent patterns + 19 DIVERGENT lines)

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **AC1 — the 4 latent patterns are tightened, and the tightening is proven to
      discriminate.** Each `grep -q "VALID"` becomes a pattern that cannot match `INVALID`.
      Proof is not "it still passes": run each repaired line against a document the validator
      *rejects* and require FAIL, and against the real document and require PASS. A repair
      verified only in the passing direction is the untested-direction defect this task exists
      to remove.
      **AMENDED BEFORE TICKING —** the clause "and against the real document and require PASS"
      presupposed all four documents are valid. Measured, T-299's is not: it validates to
      `WARN … 0 error(s), 3 warning(s)` and the string `VALID` does not appear in its output at
      all, so that line is RED today rather than latent. The requirement is unsatisfiable for
      it, and forcing it green would have buried the finding. For T-299 the probe instead
      asserts the two things that are true and falsifiable: the ORIGINAL line already fails
      (correcting T-352's classification) and the repair does not change that, because a
      tightened pattern cannot fix a stale document.
      Evidence: `tools/_t353-repair-probe.sh` — 16/16, gate construct extracted at runtime,
      leg 1 (original + rejected doc must PASS) proving the repair is not a no-op.
- [x] **AC2 — each of the 19 DIVERGENT lines is classified by hand before anything changes.**
      Two causes are mixed in that bucket — a correct failure-path test, and a genuine false
      green — and only a read of each line's *intent* separates them. The classification is
      recorded per line with its reason. No line is converted before it is classified.
      Evidence: `tools/_t353-classify.py` — **19/19 FAILURE-PATH-CORRECT, zero genuine false
      greens**, classified by RUNNING each line under the remedy with an `ERR` trap so
      `$BASH_COMMAND` names the diverging command (the subject's own report, not my parse of
      it). 4 controls in 4 distinct buckets gate every verdict; they caught three defects in
      the classifier before it was allowed to speak — see the report §1.
- [x] **AC3 — converted lines express the intended failure as success.** A line asserting "the
      validator rejects this fixture" must not rely on the gate discarding a non-zero exit; it
      states the expectation directly (capture the status, or invert with `!`). Each conversion
      runs under BOTH the current gate construct and the remedy construct and must pass under
      both — that is what makes the corpus *ready* rather than merely *changed*.
      Evidence: `tools/_t353-convert.py` — **19/19 at 3/3 legs**. Leg 1 runs the ORIGINAL under
      the remedy and requires FAIL, which is what proves each conversion is not a no-op; without
      it a conversion that changed nothing scores 2/2.
- [x] **AC4 — the readiness claim is mechanical, not asserted.** `tools/_t352-member-scan.py`
      is re-run at the end and DIVERGENT must be 0 for the lines in scope. If it is not, the
      remaining members are listed with the reason each was left.
      Evidence: `tools/_t353-convert.py` reports **DIVERGENT remaining after conversion: 0**,
      measured through the extracted gate constructs rather than re-asserted. Zero members left,
      so the "reason each was left" list is empty by measurement, not by omission.
- [x] **AC5 — the scope boundary is respected and recorded.** All 4 latent instances and most
      of the 19 live in COMPLETED tasks owned by others. Editing archived verification blocks is
      a convention change across other owners' tasks — the same class as G-015 leg 1 — so it is
      proposed here and NOT applied without an operator ruling. What was changed and what was
      left is stated explicitly.
      **Measured, it is not "most" — it is ALL of them.** All 19 DIVERGENT and all 4 latent
      lines live in `.tasks/completed/`; zero are in `active/`. So **nothing was applied**: this
      task delivers a proven, ready-to-apply patch set and the ruling request, and changed not
      one archived file. The one live consequence found along the way (T-178) is likewise NOT
      repaired here — it is another owner's active task — and is filed as **T-354**.

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

- [ ] [REVIEW] Ruling: may an agent edit `## Verification` blocks inside `.tasks/completed/`?

  This is a convention question about other owners' archived records, not a technical one —
  the patch set is already built and proven, and no part of it has been applied.

  **Steps:**
  1. `cd /opt/832-Workflow-designer && bash tools/_t353-repair-probe.sh` — 16/16, the 4 latent
     pattern repairs proven to discriminate.
  2. `cd /opt/832-Workflow-designer && python3 tools/_t353-convert.py` — 19/19, DIVERGENT
     remaining 0, every conversion proven under both the current and the remedy construct.
  3. Read `docs/reports/T-353-corpus-readiness.md` §3 and §4 — the two corrections.
  4. Answer one question: may the agent apply these edits to files in `.tasks/completed/`?

  **Expected:** a yes or no recorded here.
  - **Yes** → the patch set is applied to the 23 archived lines, and the P-011 gate change
    becomes unblocked (still a separate operator decision, G-008 upstream).
  - **No** → the archived lines stay as they are, this task closes as a proven proposal, and
    the gate change stays parked. Nothing breaks either way.

  **If not:** if the question is not the right one to be asking, say so — the alternative is
  that the archived corpus is simply never made ready and the gate change is abandoned rather
  than parked, which is also a legitimate answer.

## Recommendation

**Recommendation:** DEFER — do not bulk-apply the patch set to the archived corpus.

**Rationale:** the readying work is complete and proven, but every line it targets is inert.
Applying it would change 23 verification blocks inside other owners' completed tasks for zero
live benefit, and that is a convention change an agent should not make on tidiness grounds.
The one live consequence found while measuring has been split out as T-354, where it can be
fixed on its own merits without any ruling at all. Deferring is cheap and reversible: the
patch set is regenerable from `tools/_t353-convert.py` and does not decay.

**Evidence:**

- `tools/_t353-classify.py` — 19/19 DIVERGENT lines are FAILURE-PATH-CORRECT; **zero genuine
  false greens**. 4 controls in 4 distinct buckets gate every verdict.
- `tools/_t353-convert.py` — 19/19 conversions at 3/3 legs; **DIVERGENT remaining: 0**.
- `tools/_t353-repair-probe.sh` — 16/16; the 4 latent repairs proven to discriminate against a
  document the validator rejects.
- Location census — **all 23 lines in scope are in `.tasks/completed/`; zero in `active/`.**
- `docs/reports/T-353-corpus-readiness.md` §3b — 30 of the corpus's 189 "LATENT" lines are red
  right now; **29 of the 30 are archived and inert.**
- The 30th is `T-178`, active and queued at `/review/T-178` → filed as **T-354**.

The measurements do not support applying it now, and they are the same measurements that would
have supported it if it were warranted:

- **All 23 lines in scope are in `.tasks/completed/`.** Archived verification blocks do not
  re-run. Repairing them buys tidiness, not safety, and touches other owners' records to get it.
- **The scariest number is inert too.** 30 corpus verification lines are RED right now — but
  29 are archived. Their redness has no consequence until someone re-completes those tasks,
  which does not happen.
- **The one thing that IS live has been split out.** T-178 is active, queued for review, and
  will be refused by P-011 when the operator finalises it. That is filed as **T-354** and is
  worth doing on its own merits regardless of how this ruling goes.
- **Deferring costs nothing that cannot be recovered.** The patch set is proven and reproducible
  from `tools/_t353-convert.py`; it does not decay. If the gate change is ever wanted, the
  readying work is already done and re-runnable.

The argument on the other side, stated fairly: leaving 30 red lines in the corpus means the
next person to measure it will rediscover them, and `grep -q "VALID"` remains in the tree as a
copyable example. The second half is already addressed — the template fix in T-352 stops new
instances at the point of teaching, which is where the leverage was.

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
#
# EVERY LINE BELOW IS A SINGLE COMMAND, DELIBERATELY. A task whose subject is
# "`a; b` is judged on `b` alone" must not contain an instance of that shape in
# its own gate. Same discipline as T-351/T-352.

bash tools/_t353-repair-probe.sh
python3 tools/_t353-classify.py
python3 tools/_t353-convert.py
bash -n tools/_t353-repair-probe.sh
python3 -c "import ast; ast.parse(open('tools/_t353-classify.py').read())"
python3 -c "import ast; ast.parse(open('tools/_t353-convert.py').read())"
test -f docs/reports/T-353-corpus-readiness.md

## RCA

**Symptom:** T-352 reported "4 latent instances, all `grep -q "VALID"`, all in archived
tasks — they pass honestly today because their documents are valid." One of the four does
not pass. Its document validates to `WARN`, the string `VALID` never appears in its output,
and the line is red. Separately, 30 of the 189 lines filed under "LATENT — ran, both
constructs agreed" had not agreed about anything: they failed under the current gate and the
second measurement was skipped.

**Root cause:** `LATENT` was defined by the predicate *"the two constructs did not differ"*.
That predicate is true both when both constructs PASS and when the first construct FAILS and
the second is never run — two opposite states. The bucket's recorded verdict pairs preserved
the difference (`(PASS/PASS)` vs `(FAIL/n/a)`), but the prose describing the bucket asserted
the first state of all 189 members. `n/a` is the ABSENCE of a second measurement, and it was
read as a matching one.

**Why structurally allowed:** a bucket name is written once, when the predicate is designed,
and is then carried by every downstream sentence. Nothing re-checks that the name still
describes the members after the population is filled — and the members were right there,
correctly labelled, in the same file as the wrong sentence.

**Prevention:** the pattern is now recorded twice on this arc under its general form (a
bucket named by a predicate, then described as one of the two opposite states that predicate
spans — T-343, T-341, T-352 DIVERGENT, and now T-352 LATENT). The mechanical prevention is
narrower and cheap: **any bucket whose members carry a per-member verdict must report the
distribution of those verdicts, not just its cardinality.** A count of 189 hides a 159/30
split; a distribution cannot.

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

### 2026-08-03 — the task's own premise was wrong in two places

- **What changed:** the filing said "4 latent patterns + 19 DIVERGENT lines" and treated
  both numbers as established. Measurement moved both. The 19 are all
  FAILURE-PATH-CORRECT — zero genuine false greens — which confirms T-352's inversion rather
  than qualifying it. The 4 are **3 + 1**: T-299's line is not latent, it is already red.
- **Plan impact:** AC1's "require PASS on the real document" became unsatisfiable for one of
  its four targets. Amended in place with the reason rather than re-scoped quietly.
- **Triggered:** nothing new for this task; the finding about T-299 generalised into the RCA.

### 2026-08-03 — the finding was in the denominator, not the subject

- **What changed:** the interesting result came from tallying a bucket I was not asked to
  look at. `LATENT` (189) splits 159 `(PASS/PASS)` + 30 `(FAIL/n/a)`, and 30 verification
  lines in this corpus are RED right now. The section describing them says "the first command
  simply succeeds today".
- **Plan impact:** the readiness question is larger than the 19+4 this task scoped. It is not
  larger in a way that changes the recommendation — 29 of the 30 are archived and inert.
- **Triggered:** **T-354** — the 30th is live. T-178 is active, `work-completed`, `owner:
  human`, queued at `/review/T-178`, and its verification pins `0.2.0` against MANIFEST's
  `sha256:` field, which always names the latest release (now `0.8.0`, verified internally
  correct). Completing T-178 will be refused by P-011 for a reason unrelated to its
  deliverable. G-015 shape, third carrier.

### 2026-08-03 — three defects in the instrument, caught by its own controls

- **What changed:** the classifier's first run put all three controls in ONE bucket. The head
  of every member is an assignment (`out=$(cmd)`), whose own stdout is empty by construction —
  I was inspecting that emptiness and calling it "pattern absent". Then the error vocabulary
  turned out to list imagined text (`No such file or directory`) and miss what
  `validate-workflow.py` actually prints (`ERROR [E-LOAD] …: file not found`). Then three
  real lines read `ASSERTION-UNMET` because I substring-tested grep BREs (`\[E-XML-AUTHORITY\]`)
  in Python instead of asking grep.
- **Plan impact:** none to the deliverable; the controls are the reason none of those three
  reached a published number.
- **Triggered:** a fourth control, added specifically to prove `ASSERTION-UNMET` is still
  REACHABLE after the matcher changed — a bucket that can never fill and a bucket that
  legitimately came up empty are indistinguishable, and that bucket had just been filling
  wrongly.

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

### 2026-08-03T10:35:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-353-prepare-the-corpus-for-the-p-011-errexit.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-7bba2d16
- **Timestamp:** 2026-08-03T11:09:55Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#4 (Agent)** — **AC4 — the readiness claim is mechanical, not asserted.** `tools/_t352-member-scan.py`
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_t352-member-scan.py in: **AC4 — the readiness claim is mechanical, not asserted.** `tools/_t352-member-scan.py``

### 2026-08-03T11:09:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
