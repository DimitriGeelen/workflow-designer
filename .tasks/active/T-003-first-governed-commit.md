---
id: T-003
name: "First governed commit for 832-Workflow-designer"
description: >
  Create the initial project structure and make the first governed commit. This validates
  the governance loop: task reference → commit-msg hook → post-commit advisory.
status: captured
workflow_type: build
owner: agent
horizon: now
tags: [onboarding]
components: []
related_tasks: []
created: 2026-06-04T07:53:20Z
last_update: 2026-06-04T07:53:20Z
date_finished: null
---

# T-003: First governed commit for 832-Workflow-designer

## Context

Create initial project files (README, directory structure, entry point) and commit through the framework. The commit-msg hook validates the task reference.

## Acceptance Criteria

### Agent
- [ ] Create initial project structure (README.md, src/ or appropriate dirs)
- [ ] Commit using `fw git commit -m "T-003: Initial project structure"`
- [ ] Commit succeeds (hook validates T-003 reference)

## Verification

# Last commit references this task
git log -1 --format=%s | grep -q "T-003"

## Updates
