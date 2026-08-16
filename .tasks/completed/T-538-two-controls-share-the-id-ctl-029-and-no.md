---
id: T-538
name: "two controls share the id CTL-029 and nothing checks control-id uniqueness"
description: >
  two controls share the id CTL-029 and nothing checks control-id uniqueness

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
created: 2026-08-16T11:18:09Z
last_update: 2026-08-16T11:35:48Z
date_finished: 2026-08-16T11:35:48Z
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

# T-538: two controls share the id CTL-029 and nothing checks control-id uniqueness

## Context

`audit.sh` defines two DIFFERENT controls under the single id `CTL-029`:

| site | origin | section gate | predicate | remedy it prints |
|---|---|---|---|---|
| `audit.sh:3639` | T-1903, L-403 | `oe-daily` only | in `active/`, `status == work-completed`, ACs exist and **zero unchecked** | `bin/fw task archive-eligible` |
| `audit.sh:3772` | T-2055 | `compliance \|\| oe-daily` | in `active/`, `status in (started-work, issues)`, all **Agent** ACs ticked | `bin/fw task update T-XXX --status work-completed` |

Their status predicates happen to be disjoint, so they never disagree about a
single task — this is not a correctness bug in either control. It is a
**register-integrity** bug: the id is used as a key by readers (operators
scanning a report, `.context/audits/*.yaml` consumers, gap
`closure_check_command`s, the T-535 trend aggregator) and the key does not
resolve to one thing.

Measured witness, one real `--section oe-daily` run on this tree: **21 warn
lines all labelled `CTL-029`**, from both controls, carrying two different
remedies — the T-1903 control's single line ("2 stuck partial-complete task(s)")
buried among 20 lines from the T-2055 control.

Nothing anywhere checks that a control id maps to one control.

### Not the finding I expected

T-536's closing commit recorded "CTL-029 is firing on 12 tasks in `active/`
carrying `status=work-completed`". That is wrong and is corrected here: the
T-2055 control filters `status in (started-work, issues)` and fires on a
**disjoint** population (20 tasks, all `started-work`). The 12 were my own
measurement of the task corpus, not the control's output. Of those 12, **10 are
the framework's designed `partial-complete` state** (agent ACs done, human ACs
genuinely open, parked in `active/` with `owner: human` exactly as CLAUDE.md
specifies) — not drift of any kind. Only T-093 and T-178 have zero open human
ACs, and those are the 2 the T-1903 control correctly names.

## Acceptance Criteria

### Agent
- [x] `tools/_t538-control-id-collision.py` detects an id whose emission sites are
      **interleaved** with another id's — a threshold-free structural test, not a
      line-distance heuristic
- [x] It names `CTL-029` on the real `audit.sh` and does NOT name the nine
      controls that merely emit several `pass` lines from adjacent if/elif arms
- [x] A mutation leg plants a second block for an existing id in a COPY of
      `audit.sh` and the detector finds it (proves the detector can see)
- [x] A mutation leg removes the second `CTL-029` block in a COPY and the
      detector reports it resolved (proves the answer is read from structure,
      not hardcoded)
- [x] Ratchet: red when a collision appears that is not in the pinned baseline;
      a resolved baseline entry prints loudly but does NOT go red
- [x] The real `audit.sh` is byte-identical (sha256) before and after the run
- [x] Wired into `tests/run-bridge-tests.sh`; suite green
- [x] The collision is registered in `concerns.yaml` with a closure condition
      that names the operator/AEF decision, since renumbering is AEF's namespace

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
#
# NOTE: no pinned sha256 of audit.sh appears below on purpose. That file is vendored and
# AEF revises it; pinning its hash here would assert a global always-moving property
# (G-015) and go red for an unrelated upstream change. The detector checks its own
# non-mutation of audit.sh internally (leg 6), which is the property that matters.
python3 tools/_t538-control-id-collision.py
grep -q '_t538-control-id-collision.py' tests/run-bridge-tests.sh
grep -q 'A control id names exactly one control (T-538)' tests/run-bridge-tests.sh
python3 -c "import yaml,subprocess,sys; c=[x for x in yaml.safe_load(open('.context/project/concerns.yaml'))['concerns'] if x['id']=='G-039'][0]; r=subprocess.run(['bash','-c',c['closure_check_command']],capture_output=True,text=True); sys.exit(0 if r.returncode==0 and 'CTL-029 collision=' in r.stdout else 1)"
python3 -c "import importlib.util as u,io,contextlib,sys;s=u.spec_from_file_location('t','tools/_t538-control-id-collision.py');m=u.module_from_spec(s);s.loader.exec_module(m);m.BASELINE={};b=io.StringIO();c=contextlib.redirect_stdout(b);c.__enter__();rc=m.main();c.__exit__(None,None,None);sys.exit(0 if rc==1 else 1)"

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

**Symptom:** one `fw audit --section oe-daily` run emits 21 warn lines all labelled
`CTL-029`, from two different controls, carrying two different remedies. An operator
cannot tell which control is speaking, and the T-1903 control's single line is buried
under twenty from the T-2055 control.

**Root cause:** T-2055 minted a new control and reused an id already held by T-1903.
Control ids are written by hand into comment headers and into `pass`/`warn`/`fail`
message strings. There is no allocator, no register file, and no uniqueness check —
so reuse is invisible at author time and stays invisible afterwards.

**Why structurally allowed:** `audit.sh` audits the project. Nothing audits `audit.sh`'s
own register. Every consumer treats the id as a key — an operator scanning a report,
`.context/audits/*.yaml` recording it, a gap `closure_check_command` grepping it, and
the T-535 trend aggregator, which goes to deliberate trouble to protect identifier
tokens from being folded together *precisely so CTL-028 and CTL-029 stay distinct*.
That protection is doing careful work on a key that was never unique to begin with.

**Prevention:** `tools/_t538-control-id-collision.py`, wired into the bridge suite. It
splits emission sites into maximal same-id runs and flags any id with two or more —
structural, threshold-free, and separate from the renumbering, which is upstream's.
G-039 tracks the renumbering itself and explicitly refuses this detector as its closure.

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

### 2026-08-16 — the collision is reported, not renumbered

- **Chose:** leave both controls holding `CTL-029`; ship the detector, the gap, and an
  upstream report with the witness.
- **Why:** the id namespace is AEF's. Renumbering in our vendored copy diverges it from
  upstream and will conflict on the next `fw upgrade` — and AEF stated plainly at DM 536
  §1 that the bump is the operator's call. A register-allocation decision made silently
  by an agent inside a vendor copy is exactly the kind of change that is invisible until
  it collides.
- **Rejected:** renaming the T-2055 control to `CTL-031` in-tree. The edit itself is
  trivial and *is already proven to work* — leg 4 applies precisely that rename to a
  throwaway copy and confirms the collision disappears without a new one appearing. So
  the remedy is ready and tested the moment a ruling arrives; what is missing is the
  authority, not the change. Also rejected: renaming and "just telling AEF after".

### 2026-08-16 — the ratchet is one-directional on purpose

- **Chose:** a NEW collision is red; a baselined collision that becomes RESOLVED prints
  a loud notice and exits 0.
- **Why:** the fix belongs upstream. A guard that turned red the moment AEF renumbered
  the control would be a guard telling them not to.
- **Rejected:** the symmetric both-directions ratchet used for the T-509 census. That one
  is right when the movement is ours to make; here it is not.

### 2026-08-16 — interleaving, not line distance

- **Chose:** two emission sites belong to different controls iff another id's emissions
  lie between them.
- **Why:** nine ids legitimately emit several `pass` lines, one per if/elif arm. A
  distance rule separates those from a real collision only by a threshold nobody can
  justify, and the threshold is the part that would rot. Interleaving is structural: no
  single if/elif chain can have another control's output inside it. On the real file the
  spans differ by an order of magnitude (2–15 lines for the look-alikes, 185 for
  CTL-029), so a threshold would have worked *today* — which is exactly how it would have
  passed review and then failed later.
- **Rejected:** matching the `# CTL-NNN` header comments instead of the emission sites.
  Those include banner lines (`# CTL-002, CTL-005, CTL-006, ...`) that list many ids for
  one section, so the naive version reports six collisions of which five are section
  headers. My first grep did exactly that and had to be thrown away.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-16T11:18:09Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-538-two-controls-share-the-id-ctl-029-and-no.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d291a648
- **Timestamp:** 2026-08-16T11:35:50Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-16T11:35:48Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
