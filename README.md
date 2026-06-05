# 832-Workflow-designer

**AEF Workflow Designer** — a visual, BPMN-subset editor for authoring AEF
workflows. Humans drag and drop on a swimlane canvas; agents read the same
file as a typed, schema-validated YAML/XML representation. YAML is canonical;
BPMN XML is a derived import/export format.

The editor is **dual-audience** and **single-file**: a self-contained HTML
artifact that runs in any modern browser with no server. Swimlanes map to the
AEF authority model (Human · Sovereignty, Framework · Authority,
Agent · Initiative).

It occupies the **Stabilization** tier of AEF's manifest-maturity ladder:
richer than markdown dispatch templates, but usable today without the planned
`fw workflow run` executor.

## Repository layout

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Claude Code operating guide + AEF governance (auto-loaded) |
| `zzz-seed-design-files/` | Source design material: architecture, schema, user guide, and the implemented `aef-workflow-designer.html` artifact |
| `.tasks/` | Governed task system (active / completed / templates) |
| `.context/` | Context Fabric — working, project, and episodic memory |
| `.agentic-framework/` | Vendored Agentic Engineering Framework tooling |

## Design documentation

The complete design lives in `zzz-seed-design-files/`:

- `README.md` — project orientation and feature status
- `architecture.md` — the *why* behind the data model, routing, and interaction model
- `schema.md` — the workflow file format and `aef:` extension namespace
- `user-guide.md` — using the editor

## Governance

This project is developed under the Agentic Engineering Framework. **Nothing
gets done without a task** — see `CLAUDE.md` for the operating model. Common
entry points:

```bash
fw work-on "name" --type build   # create task + set focus + start work
fw doctor                        # framework health check
fw audit                         # compliance audit
fw handover                      # end-of-session handover
```

## Status

Bootstrapping. The product design is complete (`zzz-seed-design-files/`) and a
working single-file artifact exists. Project goals and the canonical repository
structure for the product are being defined in task **T-002** (inception,
awaiting go/no-go decision).
