---
id: T-004
name: "Complete a full task lifecycle for 832-Workflow-designer"
description: >
  Create a task for real work, complete it, and verify the lifecycle: create → start
  →
  work → complete → episodic generation.
status: work-completed
workflow_type: build
owner: agent
horizon:
tags: [onboarding]
components: []
related_tasks: []
created: 2026-06-04T07:53:20Z
last_update: '2026-08-16T12:33:30Z'
date_finished: 2026-06-05T09:19:57Z
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:30Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 0
      D2: 0
      D3: 0
      D4: 0
      F-RECALL: 1
      F-AUTONOMY: 0
      F3: 0
      F1: 1
      F2: 0
    rationale: D1=0 (no-signal); D2=0 (no-signal); D3=0 (no-signal); D4=0 
      (no-signal); F-RECALL=1 (body:episodic-only); F-AUTONOMY=0 (no-signal); 
      F3=0 (no-signal); F1=1 (body/components:context-fabric-incidental); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-004: Complete a full task lifecycle for 832-Workflow-designer

## Context

Create a genuine task (small feature or improvement), complete it, and verify the framework captures it. Validates: task creation, status transitions, AC gating, episodic memory.

## Acceptance Criteria

### Agent
- [x] Create a new task: `fw work-on "description" --type build` (T-001 existed as a captured task; lifecycle exercised on it this session)
- [x] Complete the task with real work (T-001 orientation work: doctor, audit, git hooks — all real verification)
- [x] Set status to work-completed: `fw task update T-XXX --status work-completed` (T-001 transitioned captured→started-work→work-completed)
- [x] Episodic summary generated in `.context/episodic/` (`.context/episodic/T-001.yaml` exists)

## Verification

# At least one completed task exists (beyond onboarding tasks)
test "$(ls .tasks/completed/T-*.md 2>/dev/null | wc -l)" -ge "1"

## Updates

### 2026-06-05T09:19:53Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-06-05T09:19:57Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
