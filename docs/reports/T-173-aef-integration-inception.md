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

## Joint recommendation (converged with the AEF agent — 2026-07-10)

Both agents concur; nothing remains to resolve **between** the two sides. What remains is the
operator's call (GO/NO-GO + the IW-3 integration-unit pick).

**Mechanism — M3 + `fw designer`** (agreed, no dissent):
- **832 publishes a versioned single-file build** of the designer. 832 stays SoT; future development
  continues here (C1/C2 honored).
- **AEF vendors a *pinned copy* of that release** and exposes it via a `fw designer` route.
- **Why not submodule/subtree (M1/M2):** those pull 832's *source* recursively. Since 832 already
  vendors AEF, that closes the dependency cycle and couples histories. Referencing a *build artifact*
  (a pinned ref, not source) breaks the cycle cleanly (resolves IW-4). Rejected for that reason.

**Integration unit (IW-3) — recommend phase-1 = the single-file editor** (`src/aef-workflow-designer.html`),
with one honest caveat folded into the `fw designer` build:
- The single HTML file is fully self-contained for **authoring** (diagramming + BPMN import/export, no
  server) → maps cleanly to "AEF serves one pinned HTML + a launcher."
- The **project browser / Save-to-project / version history** depend on the **Flask server**
  (`/api/list`, `/api/save`, `.editor-versions/`) + a corpus dir — *not* in the single file. Shipping
  those = **phase-2** where AEF hosts a service (a materially bigger cost jump). The YAML→BPMN bridge +
  validator are separate pipeline tools, not needed for the editor.
- **Recommendation: ship phase-1 = editor-only (authoring); defer server/corpus to phase-2 pending
  real demand.**

**Division of build work (only after operator GO):**
- AEF agent files the `fw designer` build task on the AEF side.
- 832 (this repo) files the versioned-release task.
- **Neither side builds before GO.**

## Proposed decision

**DEFER** — the two-agent design work is complete and a single mechanism is recommended; the decision
now belongs to the operator. On GO, this DEFER converts to the two build tasks above. The mechanism
choice (M3 + `fw designer`) is settled; only the operator's GO and IW-3 confirmation remain.

## Dialogue Log

- 2026-07-10 — Inception created (operator directive: "integrate the workflow designer into AEF, keep
  this repo, future development continues here"). Fleet discovery located the AEF agent (`aef`,
  `tl-uhqt63fb`, `/opt/999-Agentic-Engineering-Framework`) and two AEF task-workers (T-2512, T-2517).
  Next: send the kickoff message and record the AEF agent's response here.
- 2026-07-10 09:44Z — **Kickoff posted** to the AEF agent (DM topic `dm:d1993c2c3ec44c94:…`, offset 16):
  goal + C1–C3 + IW-1..IW-5. (Shared-identity fleet: the "DM" is a shared-identity inbox, not
  point-to-point — messages are distinguished by content, not sender fingerprint.)
- 2026-07-10 — **AEF agent replied** (via its session, relayed): concur/push-back sought on **M3 + `fw
  designer`**; asked me to (1) concur or push back on the mechanism, (2) recommend the IW-3 unit, (3)
  assemble the joint recommendation for the operator. AEF agent's default IW-3 = the single-file editor.
- 2026-07-10 09:31Z — **My concurrence posted** (offset 17): concur on M3 + `fw designer`, no push-back;
  recommend IW-3 phase-1 = single-file editor with the server/corpus phase-2 caveat; agreed neither
  side builds before operator GO. **Convergence reached** — see "Joint recommendation" above.
- **IW resolution (collaboration outcome):**
  - IW-1 (does AEF have a mechanism?) → **answered:** yes — AEF exposes tools via `fw <route>`; the
    designer plugs in as `fw designer` serving a pinned vendored build.
  - IW-2 (reference/sync mechanism?) → **answered:** M3 — a versioned released artifact AEF pulls.
  - IW-3 (integration unit?) → **operator's pick;** recommendation = single-file editor (phase-1).
  - IW-4 (cycle avoidance?) → **answered:** reference a pinned *build artifact*, never a recursive
    source pull; that keeps the 832↔AEF cycle open.
  - IW-5 (version/release cadence?) → **answered (couples to IW-2):** 832 cuts versioned releases; AEF
    pins a specific version; release bumps propagate by AEF re-pinning.
- **Awaiting: operator GO/NO-GO + IW-3 confirmation.** No build on either side before GO.
