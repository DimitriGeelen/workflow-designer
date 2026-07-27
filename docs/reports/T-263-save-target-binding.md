# T-263 — Save-to-project target binding: workflowMeta id vs dialog input

**Task:** T-263 (inception) · **Origin:** AEF observation, rail 225/228 (their T-2632 eventDef verify)
**Question:** When saving to a project, which field is authoritative for the write target —
the dialog's project-id input or the document's `workflowMeta id` — and does editing the
dialog input actually rebind the target?

## Reported symptom (peer, rail 225 + repro detail 228)

AEF loaded a scratch COPY of a map whose `workflowMeta id` still named the original
workflow. 'Save to project' bound the write target from `workflowMeta id` and wrote onto
the ORIGINAL project's workflow. Synthetically setting the dialog's project-id input value
and dispatching `input`/`change` events did NOT rebind the target. Untested with real
keystrokes. They cleaned up via `/api/delete`; explicitly framed as observation, not
defect claim.

Two hypotheses to separate:
- **H1 (synthetic-events artifact):** the dialog input is authoritative, but their
  synthetic value-set didn't reach editor state. Real keystrokes rebind.
- **H2 (dead UI / meta-wins):** the dialog field is display-only or its edits are
  ignored at save time; `workflowMeta id` wins regardless.

## Findings

**F1 — There is no project-id input in any save dialog; the save target is
`state.workflowMeta.id`, unconditionally.** `saveToProject()`
(src/aef-workflow-designer.html:7924) POSTs `/api/save` with
`id = state.workflowMeta.id` (:7930, :7954). The save-flow modal (`promptSaveNote`,
:7860) contains ONLY a note textarea — no target field. The only UI that changes the
save target is the props-panel "ID" field in the workflow metadata editor
(renderProperties, :5040), shown when nothing is selected. So "the dialog's project-id
input" the peer edited was either the props ID field or a mis-identified element —
there is no save-dialog target input to edit.

**F2 — The props ID field is LIVE for both synthetic and real edits.** Probe harness
`tools/_t263-save-target-cdp.mjs` (isolated served editor, real chromium):
- leg1: `.value = 't263-syn'` + dispatched `Event('input')` → `state.workflowMeta.id`
  rebound to `t263-syn`. The peer's synthetic edit class WORKS on this field —
  H1-as-stated refuted for the props field (their synthetic events must have targeted
  a different element/realm, e.g. inside their wrapper iframe).
- leg2: real trusted input via CDP `Input.insertText` → rebound to `t263-real`.
  H2 refuted: not dead UI.

**F3 — But the field has TWO silent-failure modes, either of which presents exactly
as "didn't rebind":**
- **Collision → silent no-op.** `renameActiveWorkflow` (:2585) returns `false` when
  `library.has(newId)` (:2588); the callback (:5043) just re-renders, reverting the
  field. Probe leg3: rename to an existing library key → state unchanged, **0 alerts,
  0 toasts**, field shows the old value after re-render. In the peer's scenario the
  library holds the seed + the loaded copy; renaming to any existing key silently
  reverts with zero feedback.
- **Success → focus loss mid-typing.** The field commits on EVERY `input` event
  (field(), :5645) and a successful rename re-renders the whole panel (:5048),
  destroying the input element. Probe leg2: after the rename, focus is on `body`
  (`sameElementFocused: false`). A human typing char-by-char commits ONE character
  and loses the field; only paste or select-all-replace edits behave as expected.
  (Third minor mode: the normalizer (:5041) lowercases/strips to `[a-z0-9_-]`; an
  edit that normalizes to empty or to the current key silently returns.)

**F4 — The incident mechanism is confirmed end-to-end.** Probe leg4: with `/api/save`
stubbed, `saveToProject()` POSTed `id === state.workflowMeta.id` — whatever the meta
id says at save time is where the bytes land. A scratch copy carrying the original's
meta id WILL overwrite the original's version chain, with the only guard being the
map-id regex (:7931). Nothing warns that the save target differs from where the
document was loaded from.

## Reading

`workflowMeta-id-wins` is the design (the document's id IS its project identity; the
props ID field is the sanctioned way to change it) — **but the design is under-guarded
in exactly the spot the peer hit**: the one field that redirects the save target fails
silently on collision, fights keyboard editing, and `saveToProject` never
cross-checks the target against the load source. The peer incident needed all three:
they loaded a copy (`?load` source ≠ meta id), tried to redirect the target (edit
failed silently — most plausibly collision or wrong element), and save wrote to the
original without a mismatch warning.

## Dialogue Log

- 2026-07-27, rail 228 (AEF): repro detail — synthetic value-set + input/change did
  not rebind; real keystrokes untested. Recorded pre-probe; leg1 shows the same event
  class DOES rebind the props ID field, so their edit hit a different element or one
  of the silent-failure modes.

## Recommendation

**GO** — one small build task (UX guard set, zero seam surface):
1. **Collision feedback:** rename-to-existing-key shows a visible hint at the field
   ("id 't263-other' already exists in this library") instead of silently reverting.
2. **Commit-on-blur/Enter for the ID field only:** stop renaming on every keystroke;
   commit on blur or Enter (kills the focus-loss trap; other fields keep live commit —
   they don't re-render on input).
3. **Save-target mismatch confirm:** when the current `?load`/deep-link source names a
   different map than `workflowMeta.id`, `saveToProject()` confirms once:
   "Loaded from '<source>' but will save as '<id>' — proceed?" (exactly the peer's
   incident, converted from silent overwrite to informed choice).

Not recommended: making any dialog field override the meta id at save time (a second
identity authority would fork the T-224 slug/uuid identity model).
