# T-006 — `fw vendor` should ship `orchestrator-mcp-baseline.yaml` to consumer projects

**Task:** T-006 (inception → GO, tag `upstream-framework`)
**Date:** 2026-06-05
**Author:** Claude Code (consumer project `832-Workflow-designer`, vendored AEF mode)
**Status:** confirmed defect; tracked upstream via consolidated pickup.

---

## Problem Statement

`orchestrator-mcp-scan.sh` expects a baseline at
`PROJECT_ROOT/.context/audits/orchestrator-mcp-baseline.yaml`, but `fw vendor`
does not copy it into consumer projects. On a fresh consumer the first audit
therefore FAILs on a missing baseline through no fault of the consumer.

## Investigation / Evidence

Confirmed by code inspection during framework bootstrap. The scanner references
the per-project baseline path; the vendor payload (`do_vendor()` in `bin/fw`)
omits the file. This is a packaging gap, not a logic bug.

## Recommendation — GO

Add the baseline copy step to `do_vendor()` so the baseline ships as part of the
vendored payload (or have the scanner self-seed an empty baseline on first run).

## Disposition

This is an **upstream-framework** fix — local edits to `.agentic-framework/`
are overwritten on re-vendor. Filed to the framework agent as finding **F2** in
the consolidated pickup: [`framework-agent-pickup-2026-06-05.md`](./framework-agent-pickup-2026-06-05.md)
(§F2). This task's role was to detect, confirm, and route the defect upstream —
not to patch the vendored tree.
