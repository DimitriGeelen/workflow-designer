# External review brief — where per-workflow field settings live (832 T-1125, decision W)

You are an independent reviewer for the project **832-Workflow-designer** (a browser-based BPMN workflow designer,
one HTML file, plus a small Python "gallery" server that stores maps). Give advice on ONE design decision. You are
not asked to write code. Read everything below; it is self-contained.

## 1. Background

**The operator's decision (T-1118, approved):** the designer's properties panel shows too many empty fields. A
service task offers 13 "extension" fields; across the 42 service tasks in the project's example maps a median of 2
are filled. The operator ruled:
- empty fields fold away by default (built: "B1");
- which fields show is set **per project** and **per workflow** ("B2"); most specific wins:
  designer default < project < workflow;
- **hard rule above all layers: a field that carries a value is never hidden**;
- new kinds of field appear only after the operator approves them ("B3", later).

**Built already (B2, project layer):** one file `field-profile.json` at the root of a project's map repository,
served by the gallery server at `GET /api/field-profile`. Shape:

```json
{ "version": 1,
  "types": { "serviceTask": { "hide": ["horizon", "workflowType"], "show": ["sideEffect"] } } }
```

`hide` removes an (empty) field from the panel; `show` pins it so it is drawn even when empty. A malformed file is
refused whole. Without a server (designer opened as a local file) the designer default applies. Saving a map is
byte-identical with or without a profile — the profile is view-only.

**Open: the per-workflow layer — where is it stored?**

Key facts:
1. A *map* is a BPMN 2.0 XML file. Three parties read these files: this designer; **AEF** (the "Agentic Engineering
   Framework", a separate project and team) which compiles maps into governed tasks; and **Greenfield**, an external
   client who opens maps in their own portal.
2. The file format is fixed by a shared standard, `aef-bpmn-mapping-v1`, whose v1 is marked **frozen**. Its §1 says
   (verbatim): *"Every `aef:` datum is exactly one of two classes. This partition is normative ... Presentational
   (diagram cosmetics): `aef:position`, `aef:anchors`, `aef:endpoint`, `aef:waypoint`, `aef:routing`,
   `aef:routingHint`, `aef:forceStraight`, `aef:loopDetour`, and the `aef:extensionElements` wrapper. The reverse
   compile MAY write these (layout) but MUST treat them as derived, never authoritative."* A field-visibility setting
   is not on that list.
3. Changes to the standard have so far gone through a **proposal AEF must agree to**; one earlier proposal (a
   decide-gate) has waited since 2026-10-04.
4. In the gallery server, a map is identified by an `id`; saved versions live in `.editor-versions/<id>/vN.bpmn`
   with an `index.json`. The repository as a whole is the "project".
5. The project already has a precedent for **unknown content**: content the designer does not understand is kept
   and written back unchanged (round-trip preservation), and unknown `aef:` scalars ride an existing carriage
   element.

## 2. The options

- **W1 — on the project server, next to the map.** `.editor-versions/<map-id>/field-profile.json`, same shape as
  the project file, served e.g. as `GET /api/field-profile?id=<map-id>`. No file-format change; nothing for AEF to
  approve. The setting stays with the project: a map emailed elsewhere or opened in Greenfield's portal does not
  carry it (they see their own project's settings).
- **W2 — inside the map, as the operator originally approved.** A new element, e.g. `<aef:fieldProfile>` in the
  process's extensionElements. Travels with the file. Extends the frozen standard, so it is proposed to AEF first
  and built only after AEF agrees; every reader of the files then sees an element it may not know.
- **W3 — both.** W1 now; W2 proposed to AEF in parallel; once agreed, the in-map setting overrides the server one.
  Feature now, travelling version later; two storage places for the same kind of setting.

The implementing agent recommends **W1** (a field-visibility setting is about how a team *views* a map, not about
the process the map describes, so it belongs with the project, not inside the shared file).

## 3. The project's value drivers (score each option 0-5 on each)

Protected drivers (the project's constitutional directives), weights in brackets:
- **D1 Antifragility [9]** — gets stronger from stress/failure. 0 no connection; 1 patches one local bug;
  2 fix + learning captured; 3 regression test/check catches the class in one component; 4 structural gate at
  framework level; 5 changes the class of failure the system can have.
- **D2 Reliability [7]** — predictable, observable, no silent failures. 0 none; 1 a log line; 2 one path observable;
  3 removes a silent-failure mode in one component; 4 surfaces the silent-failure class system-wide;
  5 removes a silent-failure class structurally.
- **D3 Usability [5]** — human ergonomics. 0 none; 1 one message improved; 2 sensible default; 3 discoverability
  at component level; 4 a class of friction removed system-wide; 5 a new collaboration mode.
- **D4 Portability [3]** — no lock-in, file-based, standards over proprietary. 0 locked to one environment;
  1 removes one local assumption; 2 one component works across a class of environments; 3 new abstraction over a
  locked-in concept; 4 cross-machine/cross-project semantics; 5 provider/environment-neutral at a new layer.

Free drivers (current focus):
- **F1 SDLC enablement [9]** — the path from a drawn workflow to running software. 0 nothing on that path;
  2 improves the authoring surface (editor behaviour, import/export, validation an author sees);
  3 adds/repairs a capability an SDLC step depends on (compile, promote, producer/consumer contract);
  4 closes a loop workflow→running software; 5 a new stage, or collaboration/tenancy for several authors.
- **F3 AEF integration [9]** — the SEAM between this project and AEF (shared standard, rendered corpus, contracts).
  0 no seam touched; 1 references AEF; 2 consumes across the seam; 3 changes a seam artifact both sides depend on;
  4 closes a seam loop (round-trip proven, divergence detected mechanically); 5 extends the seam itself (new shared
  contract or conformance dimension). Note: a seam change scores high only if it is sound for BOTH sides.
- **F4 Workflow routing [9]** — how tokens move between nodes/lanes/pools; layout and routing rules. 0 none;
  2 one map; 3 a corpus-wide rule; 4 closes a routing loop; 5 extends the routing substrate.
- **F2 Component fabric [6]** — dependency/topology mapping of the codebase. 0 none … 5 extends the fabric.
- **F-RECALL Recall leverage [6]** — durable, retrievable knowledge across sessions. 0 none … 5 improves retrieval
  for every future task.

Score what the option DOES, not what it mentions. A driver the decision does not touch scores 0 — say so; do not
inflate.

## 4. What to return (plain text/markdown, under ~900 words)

1. **Scores** — a table: rows W1, W2, W3; columns D1 D2 D3 D4 F1 F2 F3 F4 F-RECALL; each cell 0-5. Under it one
   line per non-zero cell saying why. Then the weighted total per option (sum of score × weight).
2. For EACH option:
   - **Steelman** — the strongest honest case FOR it (3-5 sentences).
   - **Strawman** — the strongest honest case AGAINST it (3-5 sentences). Not a caricature: the objection a
     sceptical expert would actually raise.
   - **Fold** — what from this option should be folded into the final choice even if this option is NOT chosen
     (a safeguard, a constraint, a migration path, a test).
3. **Your recommendation** (W1, W2, W3 or a variant you name), one paragraph, and the single biggest risk of it.
4. Anything in the brief you think is wrong or missing.

Be direct; disagree with the implementing agent if you think it is wrong.
