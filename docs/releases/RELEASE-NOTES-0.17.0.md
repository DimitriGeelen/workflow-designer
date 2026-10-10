# Workflow Designer 0.17.0 — release notes

**Since:** `designer-v0.16.0` (2026-10-09) · **Several pools, kept and shown.** A BPMN collaboration — your
process plus the systems or parties it talks to, each a pool, with message flows between them — used to lose
everything but your own pool on the first save. 0.17.0 keeps all of it and draws it. This is a minor release
because multi-pool files now save differently (more is kept) and the canvas shows something new. One-pool maps
open, draw and save exactly as before.

## Several pools (T-1119, T-1120)

- **Nothing is dropped any more.** Opening and saving a file with several pools keeps every pool — including a
  black-box pool such as a system you only exchange messages with — the process behind each pool, every message
  flow and the message it carries, and the diagram data that draws them. Before, a save kept one pool and no
  message flow (measured: a two-pool file came back with one pool and zero flows).
- **The right pool is "yours".** The designer opens the pool whose process it edits, even when another pool is
  listed first in the file (0.16.0 took the first one, e.g. the system pool).
- **The other pools are drawn, read-only.** Each appears below yours as a band with its name; a black-box pool is
  an empty band ("… · black box (read-only)"), a pool with its own process shows its steps and arrows.
- **Message flows are drawn the BPMN way:** dashed, an open circle where the message leaves, an open arrowhead
  where it arrives. A flow from one of your steps follows the step when you move it. Two flows between the same two
  ends are drawn side by side.
- **What you see is what is saved:** the diagram data written for the other pools and the flows is computed from
  the same layout the canvas draws.
- Not yet: editing the other pools, adding pools or message flows. That comes with field approval and visibility
  settings (T-1118), on the operator's approval per element kind.

## Other changes

- **A portal link opens the right project** (T-1109): a link of the form `?load=/api/version?id=X` (with or
  without `&v=N`) opens as project X, and Save writes X's next version without asking. The "Loaded from … but will
  save as …" question no longer appears on such links.
- **The mirror L** (T-1110): Settings → "…the L leaves sideways" draws cross-lane flows leaving to the right and
  entering from the top or bottom. Off by default. Settings → Reset now also restores the cross-lane routing.

## Authoring kit

Content unchanged from 0.16.0. Re-issued as 0.17.0 beside the artifact (the version is stamped into it) with its
own calibration record of these exact bytes (`docs/authoring-kit/calibration-records/0.17.0.yaml`, ledger L16).

## Re-test (Greenfield)

1. Open a map with your system pools (e.g. Tacton CPQ) and message flows: every pool shows as a band below your
   process, every message flow as a dashed arrow; nothing reports as hidden.
2. Save, reopen: the same pools and flows are still there (before: one pool, no flows).
3. Move a step that sends or receives a message: its message flow follows.
4. Open a map through your portal link `/api/version?id=<project>`: Save writes that project's next version, no question.
