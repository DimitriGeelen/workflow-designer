# Review — T-1125: where the per-workflow field profile lives

## 1. Scores

|      | D1 | D2 | D3 | D4 | F1 | F2 | F3 | F4 | F-RECALL | **Total** |
|------|----|----|----|----|----|----|----|----|----|----|
| W1   | 2  | 2  | 3  | 1  | 2  | 0  | 1  | 0  | 0  | **77**  |
| W2   | 2  | 2  | 2  | 3  | 2  | 0  | 4  | 0  | 1  | **111** |
| W3   | 2  | 2  | 3  | 3  | 2  | 0  | 4  | 0  | 1  | **116** |

Weights: D1×9, D2×7, D3×5, D4×3, F1×9, F2×6, F3×9, F4×9, F-RECALL×6.

F2 and F4 are 0 for all three: field visibility touches neither component topology nor token movement/layout. W3's D2=2 assumes the inspector in its Fold is built; without it, 1.

- **W1** D1=2: the layering invariants (precedence; value-never-hidden) become reusable testable learning for B3. D2=2: profile is fetchable and malformed files are refused whole — *if* the project-layer validator is reused. D3=3: per-workflow tailoring works end-to-end today. D4=1: map file stays pure frozen-standard BPMN (borderline 0: preservation, not new portability). F1=2: authoring-surface improvement; no SDLC step depends on it. F3=1: touches the seam only by declining to change it.
- **W2** D1=2: round-trip preservation for the new element must be tested; learning lands in the standard text. D2=2: the file becomes self-describing — no hidden server state. D3=2: same panel benefit as W1 but gated on another team (precedent: pending since 10-04); B1's fold is the sensible default meanwhile. D4=3: settings acquire cross-machine semantics — but only for readers that adopt or preserve the extension. F1=2: as W1, delayed. F3=4: genuinely extends the shared contract; not 5 because §1 makes "sound for both sides" unproven (below). F-RECALL=1: the proposal and amended text are durable cross-team artifacts.
- **W3** D1=2: W1's invariants plus an override rule to test — and a second source of truth to diverge. D2=2: conditional, see above. D3=3: W1's benefit now, W2's travel later. D4=3, F1=2, F3=4, F-RECALL=1: as W2, with the proposal decoupled from delivery; documented two-layer precedence is reusable for B3.

Note the totals are not the decision: F3's weight pays W2/W3 for seam work whose payoff is contingent on AEF agreeing and on the partition question being solvable. W1 loses on this rubric while being the only option fully inside this project's control.

## 2. The options

**W1 — server-side, per map**
- *Steelman:* The setting is a fact about how a team works with a repository — `.editorconfig`, not document content. The artifact stays exactly what the frozen standard defines; AEF, Greenfield, and the reverse compile see nothing new, and byte-identical saving stays trivially true. It delivers the operator-approved feature now, reusing the project layer's shape, validator, and API. Greenfield seeing *their* settings is arguably correct: their portal, their panel.
- *Strawman:* The operator originally approved this layer as in-map; W1 quietly narrows an approved decision, and if any of T-1118's intent was "a pinned empty field is a message to whoever opens this map" (e.g. Greenfield), W1 drops that silently. The brief gives no write path (GET only) and the profile sits outside `.editor-versions` versioning: restoring vN.bpmn restores a map whose contemporaneous profile is gone. Local-file users lose both layers without warning.
- *Fold:* a PUT/PATCH endpoint with the same refuse-whole validator shared across both layers; precedence + never-hide-valued invariant tests; an effective-profile inspector ("hidden by: workflow profile") — mandatory for any layered config; explicit merge-vs-replace semantics (does a workflow profile omitting `serviceTask` fall back to project or replace it?); version the profile or document current-state-only.

**W2 — in-map `<aef:fieldProfile>`**
- *Steelman:* A `show` pin is authorial intent — "in this workflow, fill sideEffect" — and intent belongs in the artifact every reader sees, like documentation. The file is self-describing and versioning comes free (restore vN restores its profile). The presentational class shows the standard already tolerates tool-facing data compile must ignore; growing it deliberately, with conformance wording, beats letting view config accrete in server sidecars forever.
- *Strawman:* §1's partition is normative and exhaustive — "exactly one of two classes" — and its presentational items are enumerated diagram cosmetics the reverse compile treats as *derived*. fieldProfile is *authored tool config*: not diagram cosmetics, derived from nothing, fitting neither class. W2 is therefore not "add an element" but "amend a normative clause of a frozen version" — the heaviest change on the slowest path, while an approved feature waits on another team's calendar and Greenfield pays an unknown-element tax for our panel layout.
- *Fold:* the §1 analysis must anchor any future proposal (an explicit third class or a v2, with authored-not-derived status and MUST-ignore-on-compile wording); a round-trip preservation test; the insight that only in-map storage makes pins travel to external readers.

**W3 — both**
- *Steelman:* The only option that separates the two real questions: operators need the feature now (existing machinery), and the standard question is real but shouldn't block — with a proposal already pending since 10-04, AEF latency is the scarce resource, so starting that clock in parallel is nearly free. If AEF agrees, travellers win; if not, nothing is wasted. The stated override rule gives deterministic semantics.
- *Strawman:* Two homes for one setting is a standing divergence generator: server says hide, file says show, and "in-map wins" is invisible to whoever is editing the server file — a silent override unless provenance is surfaced. It pre-commits to the dual system and its migration before knowing whether AEF says yes, no, or "yes, as v2 next spring", and doubles the precedence semantics to specify, test, and explain.
- *Fold:* the discipline, not the pre-commitment: submit the proposal as a question and decide override/migration only on a real answer; make the inspector and precedence tests entry criteria for any second storage; interim travel via manual export (sidecar/clipboard), which needs no format change.

## 3. Recommendation

**W1.5 — W1 now, plus the AEF proposal submitted in parallel, with the override/migration decision explicitly gated on AEF's answer.** I agree with the implementing agent that server-side is the right *first* home and that visibility is team-view state, not process semantics. I disagree that plain W1 is enough: it settles the travelling question by inertia, never tests whether AEF can accommodate authored view config, and ignores that the operator originally conceived the layer in-map. The proposal costs little, buys information (including AEF's real latency), and — per W2's fold — must be written as a partition amendment, not an element request. **Biggest risk:** if AEF agrees, we inherit dual storage with its silent-override mode; that is acceptable only if the effective-profile inspector and precedence tests are non-negotiable entry criteria — otherwise decline the override and stay server-side.

## 4. Wrong or missing in the brief

1. No write path or concurrency story for per-map profiles (GET only).
2. Profiles sit outside `.editor-versions` — history/view divergence on restore; unaddressed.
3. The brief understates W2: it amends §1's exhaustive two-class partition (fieldProfile is authored, not derived — it fits neither class), which is heavier than "a new element" and likely the real reason AEF would stall.
4. It never states what T-1118 assumed about travel to Greenfield; if travelling pins were intended, W1 narrows an approved decision without operator sign-off — check before building.
5. Merge-vs-replace semantics between layers are unspecified; a silent-divergence source in every option.
6. Given B1 already folds empties, per-workflow `hide` is near-redundant — the layer's real payload is `show` pins. Which one the operator wants determines whether travel matters at all; the brief doesn't ask.
