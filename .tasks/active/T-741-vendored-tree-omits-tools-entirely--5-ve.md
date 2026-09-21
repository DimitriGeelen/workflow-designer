---
id: T-741
name: "vendored tree omits tools/ entirely — 5 verbs dead including both workflow-to-program
  bridge verbs"
description: >
  fw bpmn compile exits 1 at agents/bpmn/bpmn.sh:47 (compiler not found at FW_ROOT/tools/bpmn_to_tasks.py);
  .agentic-framework/tools/ is absent entirely. 18 AEF component cards document tools
  inside it and 3 shipped scripts route there. Dead: fw bpmn compile, fw bpmn promote,
  fw corpus lint/explain/spec. Degraded silently: fw ask corpus enrichment at fw:6956
  (2>/dev/null || true). Both stage-2 chain verbs are in the dead set, so workflow
  -> program cannot run at all. Never vendored: the file is absent from the vendor
  baseline ebf0c721 too, where only its empty doc-card stub appears. Root cause is
  AEF-side packaging (do_vendor omits tools/), same class as T-422 where AEF instructed
  us not to hand-add.

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
created: 2026-09-20T21:19:54Z
last_update: 2026-09-20T21:22:35Z
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
  - ts: '2026-09-20T21:20:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 0
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-20T21:20:10Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=7 
      (no-signal)
    rubric_sha: e4a00f38e801
---


## Context

**Reproduced 2026-09-20, live tree.** `.agentic-framework/tools/` does not exist. The vendored
AEF tree ships 18 component cards documenting tools inside that directory, three shipped scripts
that route to it, and none of the tools themselves.

| Verb | Routes to | Behaviour today |
|---|---|---|
| `fw bpmn compile <f.bpmn>` | `$FW_ROOT/tools/bpmn_to_tasks.py` | guarded at `agents/bpmn/bpmn.sh:47`, **exit 1** |
| `fw bpmn promote <uid\|all>` | `$FW_ROOT/tools/bpmn_promote.py` | guarded, same shape |
| `fw corpus lint` | `$FRAMEWORK_ROOT/tools/corpus_lint.py` | `exec` at `bin/fw:4272`, **unguarded** |
| `fw corpus explain` | `tools/corpus_explain.py` | `exec` at `bin/fw:4278`, unguarded |
| `fw corpus spec` | `tools/corpus_spec.py` | `exec` at `bin/fw:4280`, unguarded |
| `fw ask` search enrichment | `corpus_explain.py` | `bin/fw:6956` — `2>/dev/null \|\| true`, **degrades silently** |

`agents/termlink/termlink.sh:821` also routes there but iterates a candidate list including
`$PROJECT_DIR/tools/`, so it degrades gracefully. It is the only one that does.

**Both stage-2 chain verbs are in the dead set.** The project's headline chain is
workflow → program → execution; `fw bpmn compile` and `fw bpmn promote` ARE the
workflow → program bridge. That stage cannot run at all, and has not been able to.

**This was never vendored — it is not a regression.** `bpmn_to_tasks.py` is absent from the
vendor baseline `ebf0c721` (v1.6.763) as well as from HEAD. The only trace of it anywhere in
this repo's history is `docs/generated/components/tools-bpmn_to_tasks.md`, an empty stub whose
body reads verbatim *"TODO: describe what this component does"* under a `## What It Does`
heading with nothing under it. AEF ships the documentation and the caller, not the callee.

**Why no task carried this until now.** This is the part worth keeping. The defect is
structurally invisible to BVP quadrant selection, and the reason is mechanical:

1. `.fabric/components/` holds 379 cards; **8** mention `.agentic-framework/` at all.
   `agents/bpmn/bpmn.sh`, the file carrying the defect, has **no card**.
2. A task therefore cannot honestly declare `components:` for it.
3. `estimator.py score_blast_radius` returns `None` when `components:` is empty and no
   `target_blast_radius` is set (deliberate, T-542 — absent beats a blind 0).
4. No blast radius → no `cost_estimate` → **no quadrant**.
5. No quadrant → the Q1/Q2 selection rule cannot see the task, at any value.

Measured on this very task: `fw bvp estimate T-741` → `D1=4 D2=0 D3=2 D4=2 F-RECALL=0 F1=1`,
`fw bvp estimate-cost T-741` → `tier=2 effort=7`, and the ranking renders
`T-741  61  0.19  -  -` — value below the high-value boundary (hv ≥ 100 / lv ≤ 94), cost and
quadrant both absent. **Any defect in the vendored framework is unscorable for cost by
construction, and `fw` itself lives in the vendored framework.** That is a strictly sharper
statement than T-738's "46 of 128 tasks carry no quadrant": it names which population is
systematically excluded and why.

Note `D2=0` — the Reliability driver, weight 7 — on a defect that kills five verbs. Recorded as
an observation about the heuristic, **not** acted on: the score stands as the scorer produced it.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The breakage is reproduced from the live tree with the exact failing command, its exit
      code, and the emitting line named by file:line — not "bpmn compile is broken".
- [x] The full blast radius is enumerated: every shipped script that routes into the absent
      directory, separated into hard-fail, unguarded, and silently-degrading.
- [x] Established whether this is a regression or was never shipped, by checking the vendor
      baseline commit and not only HEAD.
- [x] The reason no task carried it is measured, not asserted — the fabric-coverage →
      blast-radius → quadrant chain, with the numbers.
- [ ] **BLOCKED on the Sovereign question below** — remedy applied and the five verbs return
      non-error on a real corpus fixture.

<!-- The first four ACs are diagnosis and are complete. The fifth is the repair, and it is
     not the agent's to perform: see the RCA. A task whose repair is blocked should look
     blocked rather than merely undone (T-340/T-341/T-358 convention). -->

## Verification

# Diagnosis legs only. The repair leg is absent by design — there is nothing to verify until
# the Sovereign question is ruled on, and a green leg asserting nothing is the T-486/PL-178 trap.

# The absent directory is still absent (the premise of the whole task).
test ! -d .agentic-framework/tools

# fw bpmn compile still fails closed on a real corpus fixture, with the documented message.
.agentic-framework/bin/fw bpmn compile examples/aef-processes/rendered/arc-lifecycle.bpmn > /tmp/.t741.out 2>&1; test $? -eq 1 && grep -q "compiler not found" /tmp/.t741.out

# The guard that produces that exit is where this task says it is.
grep -q 'compiler not found at' .agentic-framework/agents/bpmn/bpmn.sh

# The unguarded corpus routes still point into the absent directory.
grep -q 'FRAMEWORK_ROOT/tools/corpus_lint.py' .agentic-framework/bin/fw

# The silent-degradation site still swallows the failure.
grep -q 'corpus_explain.py" --search' .agentic-framework/bin/fw

# The scorability finding: the file carrying the defect still has no fabric card.
sh -c '! grep -rlq "agents/bpmn/bpmn.sh" .fabric/components/ 2>/dev/null'

## RCA

**Symptom:** `fw bpmn compile <file>` exits 1 with `error: compiler not found at
/opt/832-Workflow-designer/.agentic-framework/tools/bpmn_to_tasks.py`. Four sibling verbs fail
the same way; a fifth degrades silently.

**Root cause:** AEF's vendoring omits `tools/` from the vendored tree while shipping the agent
scripts and component documentation that depend on it. The callers and the docs were packaged;
the callees were not.

**Why structurally allowed:** two independent blindnesses compounding.
(1) *Nothing checks that a shipped caller's target exists.* `bpmn.sh` guards and fails honestly,
which is correct behaviour and also why it never escalated — a clean error message every time
reads as a known limitation rather than a defect. `bin/fw:4272-4280` do not guard at all, and
`bin/fw:6956` actively swallows the failure with `2>/dev/null || true`.
(2) *The defect could not be prioritised even once filed.* The fabric-coverage → blast-radius →
quadrant chain above means a vendored-tree defect scores no quadrant, and a task with no
quadrant is invisible to Q1/Q2 selection. The project's own selection rule could not have
surfaced this, which is why three consecutive autonomous board sweeps reported "no eligible
work" while stage 2 of the headline chain was dead.

**Prevention — distinct from the fix:** a check that every `$FW_ROOT/tools/*` and
`$FRAMEWORK_ROOT/tools/*` path referenced by a shipped script resolves to an existing file, run
by the audit rather than by a human choosing to look. That catches the next omitted directory
regardless of which tool is missing, and it is ours to add even though the missing files are
not. It is deliberately NOT written under this task: writing prevention for a defect whose
remedy has not been ruled on would gate the wrong thing.

## Decisions

**The repair is not the agent's to perform, and this is the T-422 precedent rather than a
judgement call.** T-422 is the same class — vendored tree missing seven hooks — and AEF's
explicit instruction there was *do not hand-add them*, with root cause AEF-side (T-2911 parity,
T-2912 `fw upgrade` false-success). Hand-writing `bpmn_to_tasks.py` here would:

- author a substantial new AEF component under agent initiative, which is arc-level scope;
- create a 51st vendor divergence carrying an invented file rather than a fix to a shipped one,
  breaking the "vendored copy is a pinned artifact" property the whole seam rests on;
- and do it on the forward compile path, which the frozen standard
  `docs/standards/aef-bpmn-mapping-v1.md` Part I constrains and which is not agent-editable.

Filed, scored and parked. The counterparty owns the remedy.

### 2026-09-20T21:22:06Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
