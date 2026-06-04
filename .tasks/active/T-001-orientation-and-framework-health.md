---
id: T-001
name: "Orientation: explore framework and verify health for 832-Workflow-designer"
description: >
  Understand what the Agentic Engineering Framework provides: task system, context fabric,
  enforcement hooks, agents. Verify everything is properly installed.
status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [onboarding]
components: []
related_tasks: []
created: 2026-06-04T07:53:20Z
last_update: 2026-06-04T08:05:25Z
date_finished: null
---

# T-001: Orientation — explore framework and verify health for 832-Workflow-designer

## Context

First task for 832-Workflow-designer. Read CLAUDE.md to understand the framework, verify installation, and prepare for project definition.

## Acceptance Criteria

### Agent
- [ ] Read CLAUDE.md — understand core principle, task system, enforcement tiers
- [ ] Run `fw doctor` — all checks pass
- [ ] Run `fw audit` — note current state
- [ ] Install git hooks: `fw git install-hooks`

## Verification

fw doctor
# fw audit exits 1 for warnings (expected on fresh projects) — only block on exit 2 (failures)
fw audit; test $? -le 1

## Updates

### 2026-06-04T07:53:20Z — task-created [fw-init]
- **Action:** Auto-created by `fw init` (greenfield onboarding)
