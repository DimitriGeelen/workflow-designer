# Independent Review Brief: Decision W (832 T-1125)

## 1. Value Driver Scores

| Option | D1 [9] | D2 [7] | D3 [5] | D4 [3] | F1 [9] | F2 [6] | F3 [9] | F4 [9] | F-RECALL [6] | Weighted Total |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **W1** (Server Sidecar) | 0 | 0 | 3 | 0 | 2 | 0 | 0 | 0 | 0 | **33** |
| **W2** (In-Map XML) | 0 | 0 | 0 | 2 | 0 | 0 | 1 | 0 | 0 | **15** |
| **W3** (Both) | 0 | 0 | 3 | 2 | 2 | 0 | 1 | 0 | 0 | **48** |

### Rationales for Non-Zero Cells

- **W1 / D3 [Score: 3]**: Provides component-level discoverability by pinning expected empty fields per workflow in the properties panel, eliminating 13-field clutter.
- **W1 / F1 [Score: 2]**: Improves the immediate authoring surface ergonomics for editor properties without waiting for external approvals.
- **W2 / D4 [Score: 2]**: Embeds the profile directly inside the file, allowing workflow view preferences to travel across environments where the file is moved.
- **W2 / F3 [Score: 1]**: References AEF across the seam via a proposal, but scores low because forcing editor UI presentation into a frozen execution specification is unsound for AEF.
- **W3 / D3 [Score: 3]**: Delivers component-level discoverability immediately through the W1 server path.
- **W3 / D4 [Score: 2]**: Enables cross-environment profile portability eventually if the in-map XML element is ratified.
- **W3 / F1 [Score: 2]**: Improves authoring surface ergonomics immediately via the W1 server implementation.
- **W3 / F3 [Score: 1]**: References AEF across the seam via a parallel proposal, but inherits W2's architectural unsoundness.

*(Note: Untouched drivers D1, D2, F2, F4, and F-RECALL score 0. W2 scores 0 on D3 and F1 because it cannot be built until AEF approves, delivering zero immediate authoring capability.)*

---

## 2. Option Analysis

### W1 — On the Project Server (`.editor-versions/<map-id>/field-profile.json`)
- **Steelman**: W1 strictly enforces separation of concerns: field-visibility preferences reflect how an author views the map, not the executable process logic of the map itself. By keeping settings in `.editor-versions/<map-id>/field-profile.json`, W1 preserves the integrity of the frozen `aef-bpmn-mapping-v1` standard and ships immediately with zero external governance dependencies. Because of the operator's hard rule ("a field that carries a value is never hidden"), all populated process data remains 100% portable regardless of where the file travels. Greenfield and AEF remain completely insulated from designer-specific UI concerns, eliminating any risk of schema validation or compilation breakage.
- **Strawman**: W1 binds workflow-specific authoring ergonomics entirely to the gallery server, breaking the self-contained promise of file-based workflows. If an author exports a map to another repository, sends it via email, or opens it in a standalone local designer instance, the tailored empty-field pinning is lost, falling back to designer defaults. This creates friction when sharing workflow templates across projects, as receiving authors must manually reconfigure profiles or endure 13-field clutter. Furthermore, coupling workflow identity to the server's internal `<map-id>` makes workflow profiles fragile under map renaming, cloning, or external branching.
- **Fold**: The schema validation and whole-file rejection logic built for `field-profile.json` at the project layer must be reused strictly for per-workflow files, ensuring malformed workflow profiles fall back cleanly to the project layer.

### W2 — Inside the Map (`<aef:fieldProfile>` in extensionElements)
- **Steelman**: W2 ensures the BPMN XML file is the single, self-describing unit of distribution and collaboration across teams. An author designing a specialized workflow can curate exactly which extension fields colleagues should fill, and that authoring guidance travels seamlessly wherever the file is moved, cloned, or emailed. Greenfield and other BPMN 2.0 compliant tools can simply ignore the extension element under round-trip preservation rules without losing data. Standardizing workflow authoring metadata inside the file prevents the proliferation of disconnected sidecar metadata files across different editor server implementations.
- **Strawman**: W2 breaches the normative §1 boundary of the frozen `aef-bpmn-mapping-v1` standard by forcing editor-specific UI folding rules into a shared execution interchange format. It creates a blocking dependency on AEF approval, which has already backlogged earlier proposals like decide-gate since 2026-10-04, halting delivery of an urgent ergonomics fix. Even if accepted, AEF compilers and Greenfield portals gain zero value from editor field visibility, while risking XML parse failures or schema pollution across independent tools. Finally, burning organizational goodwill with AEF to standardize the hiding of empty fields is an unjustifiable expenditure of governance capital.
- **Fold**: If the designer ever encounters an in-map `<aef:fieldProfile>` element (e.g., from future imports or external tools), it must respect the project's existing round-trip preservation rule and preserve it byte-for-byte upon re-export.

### W3 — Both (W1 Now, W2 Proposed in Parallel)
- **Steelman**: W3 delivers immediate usability relief to authors today via W1 while establishing a forward-looking path toward full file portability through W2. It unblocks the product roadmap without stalling on AEF's governance schedule, giving the team time to negotiate the standard extension properly. Once AEF ratifies the schema, workflows can transition seamlessly to self-contained in-map storage without any disruptive migration break for existing users. It maximizes user ergonomics across both managed gallery server workflows and distributed external file handoffs.
- **Strawman**: W3 introduces an insidious two-source-of-truth problem that will plague the designer with subtle synchronization, precedence, and cache invalidation bugs. When a server profile and an in-map element diverge, authors will face silent override confusion—such as updating a project/workflow server profile only to find it ignored due to a stale embedded XML tag. Moreover, committing to pursue W2 legitimizes the flawed premise that UI view preferences belong in a frozen execution standard, permanently dividing maintenance focus across two distinct storage backends for a trivial cosmetic feature.
- **Fold**: A deterministic precedence hierarchy must be documented and tested: if any secondary storage layer is ever read, the resolution order (`designer default < project server < workflow server < in-map`) and conflict-logging must be explicit and observable.

---

## 3. Recommendation & Primary Risk

**Recommendation: W1.** The implementing agent is right to choose W1, though the argument is stronger than stated: W3's mechanically higher score (48 vs 33) is an artifact of additive feature bias that fails to penalize dual-source-of-truth technical debt. Crucially, the operator's hard rule ("a field that carries a value is never hidden") guarantees that all actual workflow semantics remain 100% portable in the BPMN file—only the temporary scaffolding of empty fields stays on the server. Contaminating the frozen `aef-bpmn-mapping-v1` standard and stalling on AEF governance for an empty-field cosmetic preference is unjustified.

**Single Biggest Risk**: **Identity drift across file operations.** Because settings are bound to the gallery server's internal `<map-id>`, exporting, cloning, or renaming a map file detaches it from its per-workflow profile, silently reverting the properties panel to project defaults without warning the author.

---

## 4. Critique of the Brief

1. **Overlooking the Hard Rule's Portability Guarantee**: The brief treats in-file storage (W2) as necessary for workflow portability, failing to realize that the hard rule already guarantees full semantic portability. The profile only controls empty-field scaffolding, which is an authoring concern, not a portable workflow attribute.
2. **Missing Standalone / Offline Mode Specification**: The brief notes that the designer runs as a single HTML file without a server, where "designer default applies." Under W1, local file users have no mechanism to use per-workflow profiles; the brief should clarify whether local storage or an optional sidecar drop is intended for offline mode.
3. **Misleading Precedent on Unknown Content**: Key fact 5 cites round-trip preservation of unknown scalars riding existing carriage elements, but W2 requires introducing a brand-new structural container element (`<aef:fieldProfile>`), which directly violates the normative presentational partition of §1 in the frozen standard.
4. **W3's Additive Scoring Masking Governance Friction**: The brief presents W3 as a harmless compromise, ignoring the permanent maintenance burden of two storage backends and the expenditure of political capital on AEF for a non-execution feature.
