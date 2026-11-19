# T-1449 — Greenfield's layout findings, reproduced on the current designer

Map: `tests/fixtures/greenfield/nooteboom-offerte-tot-order-with-notes.bpmn` (Greenfield's workshop map, owner consented,
saved under T-1447). Designer: bleeding-edge at 3e70420fa (after 0.44.0, T-1447 and T-1438). Measured in headless
Chromium from the drawn geometry (each flow's `path.edge-path`, each label's and tag's `getBBox`), at 1440 unless stated.
Findings from Greenfield msgs ef63bb29 (on 0.38.0) and 5468c2ba (on 0.43.0), plus one from T-1447's reviewer.

| # | Finding | Now | Measured | Task |
|---|---|---|---|---|
| 5 | task-to-task associations (Opportunity/Solution -> Product, Open Order -> Sales Order) not drawn | **gone** | drawn dotted with an arrowhead since T-1447 | T-1447 (done) |
| 6 | the 'wel' loop-back from gateway Redesign ends on the same side as Opportunity/Solution's outgoing flow, two arrowheads over each other | **reproduces** | both on the RIGHT side of Opportunity/Solution: out at (681, 314), 'wel' in at (681, 318), 4 px apart | T-1456 |
| 6b | that loop runs through the Novis lane | **reproduces** | its route dips to y 381, inside Novis + 98/97 (y 322-452); both its ends are in Tacton (192-322) | T-1456 |
| 7 | at Productieorder (NAV) the incoming and outgoing lines enter side by side on the top | **reproduces** | in at (2294, 485), out at (2302, 485): both on the TOP side, 8 px apart | T-1457 |
| 7b | a small arrowhead at source ends (under Negotiation, above Redesign) | by design | the T-598 source-direction cue; Greenfield asked whether it is a bug: it is not | — |
| 8 | the '(task)' tag above "Open VO" and "Verkooporder compleet" lies over the vertical arrow from the step above | **not reproduced** | no type tag or id caption box crosses a drawn flow segment (0 of all tags, at 1440) | — |
| 9 | the gateway label 'Redesign?' falls half outside the view, against the lane boundary | **not reproduced** | label x 1578-1628; the lane header ends at x 90 | — |
| R3 | id caption `sal_6_opportunity` printed over the "⟨task⟩" tag of Opportunity Closed -> Won (T-1447 reviewer) | **reproduces, and depends on the window width** | caption box at (1643, 94, w 94) over the tag (1635, 96, w 33) at **1024 and 1920**; at **1440** it is below the step (1696, 179): label placement must not depend on the window | T-1458 |

Not reproduced (8, 9): routing and label placement changed in 0.39-0.44 (T-1381, T-1427, T-1447's note obstacles);
they are reported to Greenfield as gone on the current designer, with this table, to re-check on 0.45.0.
