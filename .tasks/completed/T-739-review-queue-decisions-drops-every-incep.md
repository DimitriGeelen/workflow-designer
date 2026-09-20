---
id: T-739
name: "review-queue DECISIONS drops every inception with a recorded DEFER — T-155
  invisible since 2026-07-29"
description: >
  fw:5748 DECISION_RE matches **Decision**: (GO|NO-GO|DEFER) and fw:5768 excludes
  any inception it matches from the DECISIONS queue. DEFER is not a made decision
  — it is a deferred one — so recording a DEFER permanently removes the task from
  the surface that exists to surface pending decisions. T-155 recorded DEFER on 2026-07-29
  and has never appeared since, through a full NO-GO rewrite. The framework already
  concedes DEFER needs revisiting: T-1451 added revisit_at/revisit_evidence_needed
  and a G-053 daily scan solely to recover this class.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [audit-remediation, review-queue, inception, vendored]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-20T19:50:36Z
last_update: 2026-09-20T20:53:57Z
date_finished:
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
  - ts: '2026-09-20T19:52:00Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 4
      D3: 0
      D4: 2
      F-RECALL: 2
      F2: 1
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=4 (body:fw-audit-or-doctor); D3=0
      (no-signal); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=1 
      (body/components:component-fabric-incidental); F4=1 
      (prose:routing/geometry-incidental); F3=4 (prose:seam-fixture-or-pin); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-20T19:52:04Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (paths:.context/inbox.yaml); tier=2 (no-signal); 
      effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-739: review-queue DECISIONS drops every inception with a recorded DEFER — T-155 invisible since 2026-07-29

## Context

`fw review-queue` renders a **DECISIONS — pending inception GO/NO-GO** section whose whole
purpose is to tell the operator which inceptions are waiting on a ruling. Its predicate
(`.agentic-framework/bin/fw:5768`) is:

```python
if workflow_type == "inception" and not DECISION_RE.search(text):
```

and `DECISION_RE` (`:5748`) is:

```python
DECISION_RE = re.compile(r"^\*\*Decision\*\*:\s*(GO|NO-GO|DEFER)\b", re.M)
```

**DEFER is in the alternation.** So recording a deferral — the act of *not* deciding —
permanently removes the task from the queue of things awaiting a decision. The section reads
"has a Decision block" as "is decided", and a DEFER is precisely a decision that has not been
made.

**Live instance, measured 2026-09-20:** T-155 recorded `**Decision**: DEFER` on 2026-07-29 and
has not appeared in DECISIONS on any day since — through a full re-survey that replaced the
DEFER recommendation with a structured NO-GO. 53 days invisible on the one surface built to
show it. The nine rows the section *does* carry (T-184, T-185, T-186, T-277, T-279, T-280,
T-281, T-282, T-498) all lack a recorded `## Decision` block entirely; their DEFER verdict comes
from `extract_recommendation_state()` reading `## Recommendation`. So the section shows
recommendation-DEFER and hides recorded-DEFER — the opposite of the useful ordering, since a
recorded DEFER is the one an operator actually committed to revisiting.

**The framework already concedes the point.** T-1451 added `revisit_at` and
`revisit_evidence_needed` to DEFER decisions and built a G-053 daily revisit scan *solely* to
bring deferred inceptions back. A second scan exists because this queue drops them. The fix is
to stop dropping them, not to keep compensating.

Discovered as a routing finding while working T-155; deliberately not filed to
`.context/inbox.yaml` (T-703 measured that register at 118 pending with no auditable drain, so a
capture there is a write into an archive). One bug = one task.

**SCOPE CORRECTION, 2026-09-20 (same day this task was filed).** The filing above says the surface
that tells the operator what needs deciding "has never shown it". That is true of `fw review-queue`
and **false of Watchtower**. Measured during the T-740 value review:

| Probe | Result |
|---|---|
| `curl $WURL/inception` → `grep -c T-155` | **3** — T-155 IS listed |
| `curl -o /dev/null -w '%{http_code}' $WURL/inception/T-155` | **200** |
| decision vocabulary on that page | `DEFER` ×13, `NO-GO` ×11, `decide` ×4, `pending` ×8 |

So the operator has had a reachable decision page for T-155 the whole time, and `/inception/<id>/decide`
is a live route (`.agentic-framework/web/blueprints/inception.py`). The defect is real and the fix is
unchanged — `DECISION_RE` still encodes "a DEFER was recorded" as "the decision was made" — but its
blast radius is **one CLI surface, not the operator's whole view**. AC4 already demands the fix be
verified against live `fw review-queue` output, so no AC changes.

The 53-day stall is therefore NOT "no surface showed it". It is: the CLI queue dropped it, and the
web page that did show it was not where the decision got made. Recorded here rather than silently
narrowed. Evidence: `docs/reports/VALUE-REVIEW-aef-seam-2026-09-20/06-operator-surface.md` §3.

**Vendored-path note:** the defect is in `.agentic-framework/bin/fw`, which G-008 permits fixing
in-tree and upstreaming. The audit's `Vendor divergence: all N diverged path(s) declared` check
must stay PASS, so the divergence is declared as part of this task. Whether to upstream to AEF is
a separate act and out of scope here.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Gap registered in `concerns.yaml`/`gaps.yaml` BEFORE the fix lands (CLAUDE.md "register first, fix second"), with a closure condition that renders.
- [x] `tools/_t739-defer-is-not-a-decision.py` reproduces the defect from the live tree: it applies the shipped `DECISION_RE` to every active inception and names each one a recorded DEFER makes invisible. Exits non-zero while any such task is hidden, zero when none is.
- [x] `DECISION_RE` no longer treats DEFER as terminal, and the change is scoped to the DECISIONS predicate — `extract_recommendation_state()` and the VERDICT pass are untouched.
- [x] `fw review-queue` lists **T-155** under DECISIONS carrying its current verdict (NO-GO, not the stale DEFER), verified against live command output rather than asserted.
- [x] The three decided inceptions **T-309, T-357, T-681** (`**Decision**: GO`) remain excluded — the fix must not turn the section into "every inception".
- [x] The nine recommendation-only rows (T-184/185/186/277/279/280/281/282/498) are still listed: count goes 9 → 10, not 9 → something unrelated.
- [x] Vendor divergence declared for `.agentic-framework/bin/fw` so `fw audit --section structure` still reports `Vendor divergence: all N diverged path(s) declared` as PASS.
- [x] `tools/_t739-defer-is-not-a-decision.py` registered in the Component Fabric.

<!-- No ### Human section: every criterion above is a deterministic shell check
     (T-1811/T-1878 routing — Expected is grep-able, so these are Agent ACs with the
     checks in ## Verification, not [REVIEWER] Human ACs). -->


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

# AC2/AC3 — the probe reads the SHIPPED regex out of bin/fw and exits non-zero while any
# active inception is hidden by a recorded non-terminal decision. Its own exit code is the
# verdict, so no chaining and no errexit exposure (T-352).
python3 tools/_t739-defer-is-not-a-decision.py

# AC1 — G-051 registered in the gap register with a closure condition that renders.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.context/project/concerns.yaml')); g=[c for c in d['concerns'] if c['id']=='G-051']; sys.exit(0 if g and g[0].get('decision_trigger','').strip() else 1)"

# AC3 — DEFER is gone from the DECISIONS predicate specifically. Asserted against the
# shipped source, not against a copy.
python3 -c "import re,sys; s=open('.agentic-framework/bin/fw').read(); m=re.search(r'DECISION_RE\s*=\s*re\.compile\(\s*r\"([^\"]*)\"', s); sys.exit(0 if m and 'DEFER' not in m.group(1) and 'NO-GO' in m.group(1) else 1)"

# AC3 (scope) — extract_recommendation_state's vocabulary is UNTOUCHED: it must still carry
# DEFER, which is why the rendered VERDICT column can read DEFER while the predicate cannot.
python3 -c "import re,sys; s=open('.agentic-framework/bin/fw').read(); sys.exit(0 if re.search(r'KEEP-OPEN\|NO\[-_\]GO\|CLOSE\|GO\|DEFER', s) else 1)"

# AC4 — T-155 is listed under DECISIONS carrying its CURRENT verdict (NO-GO), not the stale
# DEFER. Verified against live command output.
.agentic-framework/bin/fw review-queue > /tmp/.t739-rq.txt 2>&1 && python3 -c "import re,sys; t=re.sub(r'\x1b\[[0-9;]*m','',open('/tmp/.t739-rq.txt').read()); b=re.search(r'DECISIONS.*?\n\n',t,re.S); sys.exit(0 if b and re.search(r'NO-GO\s+\S+\s+T-155\b',b.group(0)) else 1)"

# AC5 — the three genuinely DECIDED inceptions stay excluded. The fix must not turn the
# section into "every inception".
.agentic-framework/bin/fw review-queue > /tmp/.t739-rq.txt 2>&1 && python3 -c "import re,sys; t=re.sub(r'\x1b\[[0-9;]*m','',open('/tmp/.t739-rq.txt').read()); b=re.search(r'DECISIONS.*?\n\n',t,re.S).group(0); sys.exit(1 if any(x in b for x in ('T-309','T-357','T-681')) else 0)"

# AC6 — the nine recommendation-only rows survive and the count goes 9 -> 10, not 9 -> something
# unrelated. All nine named explicitly so a coincidental count of 10 cannot pass this leg.
.agentic-framework/bin/fw review-queue > /tmp/.t739-rq.txt 2>&1 && python3 -c "import re,sys; t=re.sub(r'\x1b\[[0-9;]*m','',open('/tmp/.t739-rq.txt').read()); b=re.search(r'DECISIONS.*?\n\n',t,re.S).group(0); nine=['T-184','T-185','T-186','T-277','T-279','T-280','T-281','T-282','T-498']; sys.exit(0 if '(10)' in b and all(x in b for x in nine) else 1)"

# AC7 — vendor divergence for .agentic-framework/bin/fw is declared and names T-739.
python3 tools/_t517-vendor-divergence.py

python3 -c "import yaml,sys; d=yaml.safe_load(open('.agentic-framework/.vendor-divergence.yaml')); e=[x for x in d['entries'] if x['path'].endswith('bin/fw')]; sys.exit(0 if e and 'T-739' in e[0]['task'] else 1)"

# AC8 — the probe is registered in the Component Fabric.
test -f .fabric/components/tools-_t739-defer-is-not-a-decision.yaml


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

**Symptom:** T-155 carried a written inception recommendation — DEFER from 2026-07-29, rewritten
to a structured NO-GO on 2026-09-20 — and never appeared in `fw review-queue`'s "DECISIONS —
pending inception GO/NO-GO" section on any day in between. 53 days of an operator decision
sitting unrouted on the surface built to route it.

**Root cause:** `DECISION_RE` (`.agentic-framework/bin/fw:5748`) includes `DEFER` in its
alternation, and `:5768` uses a match on it as an exclusion. The predicate therefore encodes
"a Decision block exists" as "the decision has been made". For GO and NO-GO that identity holds.
For DEFER it is exactly inverted: a deferral is a recorded statement that the decision is still
outstanding. One token in a regex alternation carries a semantic claim the rest of the framework
does not agree with.

**Why structurally allowed:** the framework already knew DEFER needs to come back — T-1451 added
`revisit_at` and `revisit_evidence_needed` to deferred inceptions and built the G-053 daily
revisit scan for exactly this class. That compensating scan is what kept the omission invisible:
DEFERs *were* being resurfaced, just on a different surface, so nobody asked why the decisions
queue had stopped listing them. **A second mechanism built to recover a class is evidence that a
first mechanism is dropping it** — and it reads as coverage rather than as a defect.

Compounding it: the one live instance was a task whose own `revisit_evidence_needed` said it was
waiting on operator input, so G-053's output looked correct while pointing at evidence that had
already arrived (fixed separately at `7da563ef`).

**Prevention:** distinct from the fix. `tools/_t739-defer-is-not-a-decision.py` applies the
*shipped* `DECISION_RE` to the live tree rather than restating the rule, so it fails if the
alternation ever regrows DEFER — including via an upstream vendor bump that silently reverts the
in-tree fix, which is the realistic recurrence path for a vendored file. The general learning is
the one above: when a compensating scan exists for a class, check what dropped it.

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
     fw inception decide T-739 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-20T19:50:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-739-review-queue-decisions-drops-every-incep.md
- **Context:** Initial task creation

### 2026-09-20T20:53:57Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
