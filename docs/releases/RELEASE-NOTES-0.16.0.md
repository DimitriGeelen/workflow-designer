# Workflow Designer 0.16.0 — release notes

**Since:** `designer-v0.15.3` (2026-10-03) · **Greenfield's map review, answered.** Greenfield
(Evergreen trial, T-172) opened a real client map in the designer, straightened it by hand, and
reported what the designer got wrong. Three of those reports are fixed here. This is a minor
release rather than a patch because one fix changes how existing maps are DRAWN: cross-lane flows
now route as an L by default (see "Behaviour change" below). Saved files are unchanged in format.

## Behaviour change

- **Cross-lane flows route as an L, one bend** (T-1090, Greenfield T-172 #1). A flow from one lane
  to a later step in another lane used to be drawn as a Z (two bends) or, depending on box spacing,
  a four-bend staircase. The designer now leaves the source on the side facing the target lane
  and enters the target from the left, or leaves to the right and drops into the target, whichever
  gives exactly one bend without crossing a node. On Greenfield's map this took 91 bends to 24,
  the same 24 the owner drew by hand. The canvas and the exported BPMN DI use the same geometry.
  Flows you routed yourself (ports, waypoints, hints) are not touched. **To keep the old drawing:**
  Settings → untick "Cross-lane flows as an L"; the choice is remembered. Where a flow runs
  along the bottom of a task, the task id caption moves beside it so the two do not overlap.

## Fixes

- **Lane abbreviations are unique on import** (T-1088, Greenfield T-172 #2). Two imported lanes
  whose names abbreviate alike (e.g. two `tac…` lanes) both got `tac`, so their task ids looked
  the same. The second now gets a distinct abbreviation, as lanes created in the designer already
  did.
- **A map opened from a project saves as that project's next version** (T-1089, Greenfield T-172
  #5). A file without `aef:workflowMeta` opened from a project was saved as a NEW project
  (`process_*` v1). It now takes the project's id. A file that declares its own id keeps it (T-263),
  and Save asks before writing to a project other than the one the map was opened from.
- **Long edge labels wrap** (T-1067): the wrap width was wider than the label that motivated it.
- **Lane-aware labels stay off the lane header strip** (T-1068).
- **The "no authority" marker no longer sits on the incoming edge label** (T-1069).
- **Advisory banners no longer hide the top-lane node** they point at (T-1078).
- **A routing failure is recorded, not swallowed** (T-1090): if the L route cannot be computed,
  the flow falls back to normal routing and the failure goes to the editor's fault record (T-821).
- **`window._deepLinkSettled`** (T-1061): the editor reports when its `?load=` handling has
  finished (none / adopted / suppressed / failed), for tools that drive it.

## Authoring kit

Guide, rubric and validator unchanged from 0.15.3. One correction to the calibration maps (below).
Re-issued as 0.16.0 beside the artifact, with its own calibration record of these exact bytes
(`docs/authoring-kit/calibration-records/0.16.0.yaml`, ledger L16).

### Corrected: a deficiency in the calibration maps, addressed

**What was wrong.** The "clean" calibration map, the reference that is supposed to contain no
defects, ended in an end event named "Accepted order delivered and invoiced". The source states no
such outcome, and the two branches (delivery, invoicing) reach that end separately, with no join:
so the name asserted a result the source never gives AND a synchronisation the kit's own rule L26
forbids drawing. **0.15.3 shipped with this flaw.** It passed calibration only because the
reviewers did not flag it on those runs.

**How it was found.** An earlier fix (0.15.3, `34e07e87`) removed the unsupported join but kept the
name, which carried the same claim. The reviewer panel had already raised the name (ledger L21,
left open on a 2-1 split). Calibrating the 0.16.0 kit, codex (OpenAI) flagged it twice in a row with
the same finding (ledger L29). Both codex runs are recorded as FAIL; they were not re-run until they
passed.

**What changed.** The end event has no name. It carries the kit's standard citation for an end the
source does not name (`source: unstated - marks where the stated order ends; the source names no
result`) and a visible note: *"Outcome not recorded in the source: this end is left unnamed until
the source owner states one."* The gap is declared, not hidden. Same change in the planted map, so
the two maps still differ only by the planted defects.

**Lesson (L29, proposed for the guide; goes through the reviewer panel):** a name can assert what a
gateway would. When a join is removed, or never drawn, check the labels for the same claim.

## Re-test (Greenfield)

1. Open the client map from its project and Save: the project gains its next version, and no new
   `process_*` project appears (T-1089).
2. Look at the lane prefixes in the task ids: no two lanes share one (T-1088).
3. Compare cross-lane flows with the owner's hand-straightened map (T-1090).
