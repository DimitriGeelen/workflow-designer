# T-007 — `fw init` seeds `patterns.yaml` with `origin_task`; canonical is `learned_from`

**Task:** T-007 (inception → GO, tag `upstream-framework`)
**Date:** 2026-06-05
**Author:** Claude Code (consumer project `832-Workflow-designer`, vendored AEF mode)
**Status:** confirmed defect; tracked upstream via consolidated pickup.

---

## Problem Statement

`fw init` seeds `lib/seeds/patterns.yaml` using the field `origin_task:`
(12 occurrences), but the canonical field name is `learned_from:`. Seeded
patterns therefore lose their task back-links everywhere downstream.

## Investigation / Evidence

Confirmed by code inspection during framework bootstrap:

- Canonical `learned_from` is **written** by `agents/context/lib/pattern.sh:112`,
- **parsed** by `agents/healing/lib/patterns.sh:64`,
- **rendered** by `web/templates/patterns.html:183-184`.
- The seed file diverges: `lib/seeds/patterns.yaml:15,25,35,…` use `origin_task`.

The writer/parser/view triad agrees on `learned_from`; only the seed file is out
of step, so seeded patterns silently drop their provenance link.

## Recommendation — GO

Rename `origin_task:` → `learned_from:` in `lib/seeds/patterns.yaml` for
consistency with the canonical writer/parser/view.

## Disposition

This is an **upstream-framework** fix — local edits to `.agentic-framework/`
are overwritten on re-vendor. Filed to the framework agent as finding **F3** in
the consolidated pickup: [`framework-agent-pickup-2026-06-05.md`](./framework-agent-pickup-2026-06-05.md)
(§F3). This task's role was to detect, confirm, and route the defect upstream.
