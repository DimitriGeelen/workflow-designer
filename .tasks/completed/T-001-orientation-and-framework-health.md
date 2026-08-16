---
id: T-001
name: "Orientation: explore framework and verify health for 832-Workflow-designer"
description: >
  Understand what the Agentic Engineering Framework provides: task system, context
  fabric,
  enforcement hooks, agents. Verify everything is properly installed.
status: work-completed
workflow_type: build
owner: agent
horizon:
tags: [onboarding]
components: []
related_tasks: []
created: 2026-06-04T07:53:20Z
last_update: '2026-08-16T13:57:13Z'
date_finished: 2026-06-05T09:08:50Z
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:30Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 4
      D3: 0
      D4: 0
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=0 (no-signal); D2=4 (body:fw-audit-or-doctor); D3=0 
      (no-signal); D4=0 (no-signal); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 4
    rationale: blast_radius=absent (no-signal); tier=2 (no-signal); effort=4 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-001: Orientation — explore framework and verify health for 832-Workflow-designer

## Context

First task for 832-Workflow-designer. Read CLAUDE.md to understand the framework, verify installation, and prepare for project definition.

## Acceptance Criteria

### Agent
- [x] Read CLAUDE.md — understand core principle, task system, enforcement tiers
- [x] Run `fw doctor` — all checks pass (2 warnings, both host-level re: global /root install; no failures)
- [x] Run `fw audit` — note current state (Pass 75, Warn 2, Fail 0; warns = uncommitted volatile files + cross-repo tag-format drift T-1649)
- [x] Install git hooks: `fw git install-hooks`

## Verification

fw doctor
# fw audit exits 1 for warnings (expected on fresh projects) — only block on exit 2 (failures)
fw audit; test $? -le 1

## Updates

### 2026-06-04T07:53:20Z — task-created [fw-init]
- **Action:** Auto-created by `fw init` (greenfield onboarding)

### 2026-06-05T09:08:50Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
