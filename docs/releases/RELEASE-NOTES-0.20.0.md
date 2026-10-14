# Workflow Designer 0.20.0 — release notes

**Since:** `designer-v0.19.1` (2026-10-12) · **Minor: step numbers count activities only.** Requested by Greenfield
(their T-172 item 2b). Includes everything in 0.19.1.

## Changed

- **The number in a node id now counts ACTIVITIES only (T-1168, operator decision T-1094).** A node id is
  `<lane>_<number>_<name>`, and map owners read the number as "step N of the work". Until now every node took a
  number by its position in the lane, gateways and events included, so a gateway between two tasks made a lane's tasks
  read 1, 2, 4, 5, and a lane's first task was number 2 because its start event was number 1. Now tasks and
  sub-processes are numbered 1, 2, 3 … with no gaps, and events and gateways carry a type word instead of a number:

  | node | before | now |
  |---|---|---|
  | start event "Lead" (Verkoper) | `ver_1_lead` | `ver_start_lead` |
  | first task (Verkoper) | `ver_2_lead` | `ver_1_lead` |
  | parallel gateway "Tegelijk" (Salesforce) | `sal_3_tegelijk` | `sal_gw_tegelijk` |
  | fourth task (Salesforce) | `sal_5_opportunity` | `sal_4_opportunity` |
  | end event "Einde" | `ver_11_einde` | `ver_end_einde` |

  Type words: `start`, `end`, `gw` (gateway), `link`, `error`, `timer`, `message`; an event from another tool `ev`. Two
  with the same type word and name in one lane: the second gets `_2`.

  **What this means for saved maps:** a map gets the new ids the next time it is saved, once. Nothing else in the file
  changes. Ids were already recomputed whenever a node moved, so nothing should rely on them staying put; Greenfield
  and AEF confirmed nothing of theirs does. The example maps that ship with the designer were renamed in place; the
  old -> new list for every one is in `docs/reports/T-1168-node-id-map.md`.

- **The browser tab names the map you have open (T-1155).** It always read "investigate.bpmn"; it now reads
  `AEF Workflow Designer — <map>.bpmn`, and so does the heading of the XML panel. It follows a switch to another map
  and a rename.

- **The toolbar is never cut off (T-1176).** On a window narrower than about 1450px, Check, Versions, Save to project
  and Save fell off the right edge. The toolbar now wraps onto a second row when it has to, keeping the zoom buttons
  together and the view buttons together; on a wide window it is one row as before.

- **The side panels fold away and can be resized (T-1177).** Each side panel has a small tab on its inner edge: click
  it to fold the panel away to a notch at the window edge, and click the notch to bring it back (◧ ◨ in the toolbar do
  the same). Drag a panel's inner edge to set its width (palette 160–480px, properties 240–640px; the canvas always
  keeps at least 320px), and double-click the edge for the default. Folded panels and widths are remembered.

## Authoring kit

Guide, rubric and validator unchanged; re-issued as 0.20.0 with its own calibration
(`docs/authoring-kit/calibration-records/0.20.0.yaml`).

## Re-test (Greenfield)

1. Open `after-owner-straightened.bpmn` and save it. In every lane the task ids read 1, 2, 3 … with no gap:
   Salesforce `sal_1_lead`, `sal_2_account`, `sal_gw_tegelijk`, `sal_3_tacton`, `sal_4_opportunity`; Verkoper starts
   `ver_start_lead`, `ver_1_lead`.
2. Your doc-merge, generators and links still work on the re-saved map (they key on names, map ids and lane ids).
3. The tab title shows the map you opened, and changes when you open another.
4. Make the window narrow (about 1024px): every toolbar button is still on screen. Fold a side panel with its edge
   tab, unfold it from the notch, drag its edge wider, reload: the panels come back as you left them.
5. Everything in 0.19.1 (the field-settings re-test) is included, if you have not run it yet.
