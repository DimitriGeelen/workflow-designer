# Workflow Designer 0.22.0 — release notes

**Since:** `designer-v0.21.0` (2026-10-17) · **Minor: lane problems show on the map; the slug follows the name.**
Includes everything in 0.21.0.

## Added

- **Validator findings about a lane are marked on that lane (T-1164).** Four checks report a lane rather than a step
  (W-XML-LANE-CAPACITY, W-XML-LANE-GEOMETRY, E-XML-ABBR-DUP, E-XML-LANE-AUTHORING-DEFAULT). Until now they appeared in
  the findings list as "not on the map". Now the lane's name strip gets the severity colour on its edge and a ✖/⚠ badge
  at its top; the list row is anchored and clicking it selects the lane; "N on the map" counts it. The mark lasts
  until the next check, and travels with the pinned lane names when you scroll (0.21.0).

## Changed

- **The Slug field is read-only and follows the name (T-1193).** It used to accept a hand-typed slug, but that slug
  was never saved: on reopening, the id went back to the one derived from the name, and the next save changed the id
  in the file without anyone touching it. The field now shows the slug, styled like UID and Owner, with the hint
  "follows the name · rename to change". Saved files are unchanged.
- **Leading gap, observation and learning ids are skipped in slugs too (T-1196),** as task ids are since 0.21.0:
  "G-062 close gates …" gives `close`, not `062`; the same for `OBS-<n>` and `L-<n>`. Look-alike words ("G-force",
  "L-shaped") are untouched. No example map changes; in AEF's maps 8 draft steps get readable ids on their next save.

## Fixed

- **A step dragged out of every lane no longer stretches the drawn lane around it (T-1164, follow-up to 0.21.0's
  pool fit).** It now hangs visibly outside, which is what the lane checks above report.
- **With the findings list open,** the "Restored your unsaved work" notice sits above it instead of over its rows,
  and a pinned lane name is centred in the part of its lane you can still see.

## Authoring kit

Guide, rubric and validator unchanged. Re-issued as 0.22.0 with its own calibration of these exact bytes
(`docs/authoring-kit/calibration-records/0.22.0.yaml`).

## Re-test

1. Drag a step below every lane and press Check: the lane it belongs to gets a ⚠ on its name strip; the list rows are
   not "not on the map"; clicking one selects the lane. Put the step back and Check again: the mark is gone.
2. Select a step: Slug shows its slug read-only; rename the step and the slug and id follow.
3. A step named "G-062 close gates" gets an id ending `_close`.
