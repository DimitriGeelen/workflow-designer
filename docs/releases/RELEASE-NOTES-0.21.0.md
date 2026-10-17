# Workflow Designer 0.21.0 — release notes

**Since:** `designer-v0.20.0` (2026-10-16) · **Minor: readable ids for task-named steps, lane names stay in view, the
pool encloses its labels.** Asked for by the operator, AEF (option c on their designer re-pin, AEF T-4224) and
Greenfield (T-172 #3). Includes everything in 0.20.0.

## Changed

- **A leading task id no longer becomes a node's name in its id (T-1194).** A node id is `<lane>_<number>_<name>`, and
  the name part is the first word of the node's name. Steps named after the task that does them, such as
  "T-001: Orientation and Framework Health Check", therefore all got the task's digits as their name:

  | node name | 0.20.0 | 0.21.0 |
  |---|---|---|
  | T-001: Orientation and Framework Health Check | `agt_1_001` | `agt_1_orientation` |
  | T-003: First governed commit | `agt_2_003` | `agt_2_first` |
  | T-002: Define project goals (inception) | `hum_1_002` | `hum_1_define` |

  A leading `T-<number>` followed by `:`, `-`, `—` or a space is skipped. A name that is only a task id ("T-001") keeps
  its digits. Every other name gives exactly the id it gave before; none of the example maps that ship with the
  designer changes.

  **What this means for saved maps:** a map whose step names start with a task id gets the new ids the next time it is
  saved, once. AEF's maps are named this way; an old -> new list for each of them is delivered with this release.

## Added

- **Lane names stay in view when you scroll (T-1091).** Zoomed in, the canvas scrolls, and on a wide map the lane
  names on the left used to scroll away. They now stay pinned at the left edge, each on its own lane (also when you
  scroll up or down), on a solid strip above the diagram; clicking one selects the lane. Settings → **Sticky lane
  labels** turns it off (on by default, remembered). Fit-to-screen view never scrolls and is unchanged. While a name is
  pinned it covers a strip of the diagram under it; a little more scrolling shows it.

## Fixed

- **The pool encloses its labels (T-1154).** A label or id badge under the right-most step could reach past the pool's
  right border (a long end-event label by over 100 px), and id badges under the bottom lane could sit on its bottom
  border. The pool and its lanes are now drawn around them, with a small margin. This is drawing only: the saved map is
  byte-for-byte the same.

## Authoring kit

Guide, rubric and validator unchanged since 0.20.0. Re-issued as 0.21.0 with its own calibration of these exact bytes
(`docs/authoring-kit/calibration-records/0.21.0.yaml`).

## Re-test

1. Open a map whose steps are named "T-001: …" and save it: the ids carry the step's first word
   (`agt_1_orientation`, not `agt_1_001`). A map without such names saves with the same ids as before.
2. Zoom in (**+**, or Ctrl+wheel) on a wide map and scroll right: every lane name stays at the left edge, on its own
   lane. Click one: the lane is selected. Turn off Settings → Sticky lane labels: the names scroll away again.
3. On a map whose last step has a long name under it, the pool's right border runs clear of the label.
