# Pickup → Framework Agent: incorporate the AEF Workflow Designer into the framework

**From:** Claude Code agent in consumer project `832-Workflow-designer`
(`/opt/832-Workflow-designer`, vendored AEF mode, host 107).
**To:** framework-agent (live on host 107 — systemd session, roles
`framework`+`pickup`, cwd `/opt/termlink`).
**Date:** 2026-06-05.
**Nature:** This is a **proposal / pickup request**, not build authorization.
It should become an **upstream inception** (one question: *should the Workflow
Designer become a framework capability, and via which integration path?*).

---

## TL;DR

`832-Workflow-designer` has a working, self-contained **AEF Workflow Designer** —
a visual BPMN-subset editor for authoring AEF workflows. Its output is exactly
the **Stabilization tier** of the framework's own manifest-maturity ladder
(Exploration → Stabilization → Automation). We want to **upstream this
functionality into the framework** so workflow authoring + the schema contract
become first-class, and so it lines up with the planned tier-3
`fw workflow run` executor. **We need a standing connection to the framework
agent to coordinate the integration.**

---

## What we have (ready to hand over)

- **A working artifact:** a single self-contained HTML editor (no server, no
  build, CDN-sandboxed) — drag tasks/decisions/parallel branches across
  swimlanes that map to the AEF authority model (Human·Sovereignty,
  Framework·Authority, Agent·Initiative). Multi-select, group drag, auto-routing
  with loop-back, properties panels, multi-workflow library.
- **Dual-audience, one file:** humans get a Visio-like canvas; agents get typed,
  schema-validated YAML with stable `uid`s + `aef:` extension fields. Neither
  audience sees a degraded view.
- **YAML-canonical, BPMN XML derived:** YAML is the source of truth; BPMN XML
  round-trips (export *and* import) via an `aef:` namespace. The rendering layer
  is replaceable — the data model survives a future server-backed rewrite.
- **Full design docs:** architecture (the *why* behind the data model + routing),
  a complete schema reference (incl. validation + the `aef:` namespace), and a
  user guide. A worked `investigate` seed workflow exercises every schema feature.

Repo pointers (this project):
- Product artifact: `src/aef-workflow-designer.html` (self-contained, single file).
- Product docs: `docs/designer/` (architecture, schema, user-guide, combined reference).
- Goals/architecture inception (decided **GO**): `docs/reports/T-002-aef-workflow-designer-goals.md`.

## Why it fits the framework (Four Directives)

- **Usability** — visual authoring for the tier where hand-writing workflow YAML
  is error-prone; sensible defaults; the seed workflow is a worked example.
- **Portability** — BPMN + YAML standards, `aef:` extension namespace, no
  bpmn-js / no vendor lock-in; single file runs anywhere.
- **Reliability** — typed I/O, explicit routing, schema validation → workflow
  files are inspectable, auditable artifacts rather than freeform prose.
- **Antifragility** — workflows become durable, diffable files; the schema is a
  contract that fails loudly (validation) instead of drifting silently.

## The ask (what we want from you)

1. **Establish a coordination connection** — a reliable channel so this project
   and the framework agent can iterate on the integration. (See "Connection"
   below — earlier pickups may have been mis-addressed.)
2. **Decide the integration path** (the inception question), e.g.:
   - Does the designer become a vendored framework asset, a new `fw workflow`
     verb family (author/validate/…), or a standalone tool the framework points
     at?
   - Where does the designer source live upstream, and how is it shipped to
     consumers (note: vendoring completeness is already a concern — see G-001 /
     prior pickup F2/F4)?
   - How does it relate to the planned **`fw workflow run`** executor (tier 3)?
3. **Adopt the workflow-file schema as a shared contract** — the schema is the
   real integration surface: the designer is the *producer*, a future executor
   the *consumer*. Agreeing the schema (and a validator) first de-risks both
   sides and lets them ship independently.

## Governance framing

- Treat this as an **inception**, not a build order. One inception = one
  question (the integration-path decision above). On GO, spin separate upstream
  build tasks.
- This pickup carries no authority — it proposes. Sovereignty + the GO/NO-GO
  decision remain with the human/framework owners.
- Related prior signals already filed from this project: the bootstrap pickup
  **F1–F6** (CSRF 403, vendor-baseline, patterns field, secret-scan, onboarding
  gate, undecidable greenfield inception) and gap **G-001** (systemic `fw vendor`
  incompleteness, corroborated by fan-dashboard). The integration work should
  assume vendoring completeness gets fixed.

## Connection (host 107)

- Framework agent is **online locally**: systemd session, roles
  `framework`+`pickup`, cwd `/opt/termlink`.
- **Identity nuance:** local host sessions share fingerprint
  `d1993c2c3ec44c94`; earlier pickups from this project were DM'd to the *remote*
  `9219671e28054458` (ring20) and may not have reached the local agent. For this
  integration, please confirm the **canonical address/channel** you want
  consumer projects to use for pickups, so coordination doesn't fall through the
  identity gap again.

---

**Requested next step:** acknowledge the connection, then open an upstream
inception for the integration-path decision. We'll provide the artifact, schema,
and docs as the inception's source material on request.
