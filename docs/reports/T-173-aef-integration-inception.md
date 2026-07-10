# T-173 Inception — Integrate the Workflow Designer into AEF (this repo stays source of truth)

**Status:** exploration (kickoff) · **Task:** T-173 (inception) · **Created:** 2026-07-10
**Owner:** agent → decision: human · **Collaborator:** AEF agent (`aef`, `tl-uhqt63fb`, `/opt/999-Agentic-Engineering-Framework`)

> C-001 thinking-trail artifact. Started before research/dialogue. The operator asked to integrate the
> Workflow Designer into AEF **while keeping this repo (832-Workflow-designer) as the source of truth**,
> with all future designer development continuing here. This is a cross-repo, cross-agent architecture
> decision with portability lock-in implications — hence an inception, not a build.

## Problem

Today the Workflow Designer is a standalone project that **consumes** AEF: it vendors the framework at
`.agentic-framework/` and is governed by it. The operator now wants the reverse relationship as well —
the designer should become a **component of AEF** (AEF ships/references/exposes it), so that AEF users
get the designer as part of the framework. But development of the designer must **stay in this repo**;
AEF must not fork or absorb it.

So the core question is an **ownership + topology** one:

> How does the Workflow Designer become part of AEF's surface area while 832-Workflow-designer remains
> the single source of truth and the place future development happens?

This is subtle because it's nearly circular: 832 vendors AEF; AEF would now reference 832. We must avoid
a dependency cycle, a double-vendoring mess, or a sync loop.

## Hard constraints (operator-set, non-negotiable)

- **C1 — 832 stays source of truth.** The canonical designer source (`src/aef-workflow-designer.html`,
  server, corpus, gallery) lives and evolves here. AEF consumes a *copy/reference*, never the origin.
- **C2 — Future development continues here.** Contributors keep working in 832; AEF picks up changes
  through whatever sync/reference mechanism we choose — not by editing its own copy.
- **C3 — No provider/topology lock-in beyond necessity (Directive 4).** Prefer standard git/packaging
  mechanisms over bespoke glue.

## Candidate integration mechanisms (design space — to evaluate with the AEF agent)

| # | Mechanism | How 832 stays SoT | Cost / risk |
|---|-----------|-------------------|-------------|
| **M1** | **Git submodule** — AEF adds 832 as a submodule at a pinned ref | Native: submodule points at 832; AEF pins a commit | Submodule UX friction; consumers must init; pin bumps manual |
| **M2** | **Git subtree** — AEF vacuums 832 in via `git subtree pull` | 832 remains upstream; AEF subtree is a mirror | Subtree merges fiddly; history bloat |
| **M3** | **Released artifact** — 832 publishes a versioned build (tarball/single-file); AEF pulls a pinned version | 832 owns the release; AEF references a version tag | Needs a release pipeline + version discipline; AEF lags releases |
| **M4** | **AEF plugin/component** — 832 ships an AEF component card / plugin manifest; AEF's registry loads it from a pinned source | 832 authors the manifest; AEF registry references it | Depends on whether AEF has a plugin/component-loading mechanism (ASK the AEF agent) |
| **M5** | **Mirror/vendor sync** — the pattern AEF already uses to vendor itself into consumers, run in reverse (sync script copies 832's designer into AEF on release) | 832 is upstream of the sync | Bespoke; another sync surface to maintain |

Almost certainly a hybrid: e.g. **M3 (versioned release from 832) + M4 (AEF references it as a
component)** — releases give a clean version boundary; the component mechanism gives AEF users a
first-class entry point (`fw designer …`?). To be confirmed with the AEF agent, who knows AEF's actual
component model.

## Open Questions (mirror of task ## Open Questions — IW-N)

- **IW-1 — Does AEF already have a plugin/component/tool-registration mechanism** the designer can plug
  into (component cards in `.fabric/`, a `fw <tool>` route, a plugins dir)? → **ASK the AEF agent.** This
  decides whether M4 is available or must be built.
- **IW-2 — What is the reference/sync mechanism** (submodule / subtree / released artifact / mirror)?
  Which gives the cleanest "832 = SoT, AEF = consumer" with least ongoing friction?
- **IW-3 — What exactly is the integration unit?** Just the single-file editor? Editor + server +
  corpus? Editor + the YAML→BPMN bridge + validator? The smaller the unit, the cheaper the integration.
- **IW-4 — How is the dependency cycle avoided?** 832 vendors AEF; AEF would reference 832. Confirm the
  reference is to a *build artifact / pinned ref*, not a recursive source pull.
- **IW-5 — Version & release cadence** — how does an AEF user get a *specific, reproducible* version of
  the designer, and how do designer releases propagate to AEF?

## Collaboration plan (with the AEF agent)

1. **Kickoff message** to `aef` (`tl-uhqt63fb`): state the goal + C1–C3, ask IW-1..IW-5 (esp. IW-1:
   does AEF have a component/plugin mechanism?).
2. Based on their answer, narrow M1–M5 to a recommended mechanism + integration unit.
3. Produce a joint recommendation; bring GO/NO-GO to the operator (I do not build integration code
   under this inception before a GO).
4. On GO: decompose into build tasks — likely one in 832 (release/manifest) and one in AEF (reference/
   registry), coordinated across the two agents.

## Proposed decision

**DEFER** pending (a) the AEF agent's answer on IW-1/IW-2 (AEF's component + reference model) and
(b) operator confirmation of the integration unit (IW-3). This is a genuine two-repo architecture
decision; getting the mechanism right up front avoids a sync/lock-in mess later.

## Dialogue Log

- 2026-07-10 — Inception created (operator directive: "integrate the workflow designer into AEF, keep
  this repo, future development continues here"). Fleet discovery located the AEF agent (`aef`,
  `tl-uhqt63fb`, `/opt/999-Agentic-Engineering-Framework`) and two AEF task-workers (T-2512, T-2517).
  Next: send the kickoff message and record the AEF agent's response here.
