# T-358 lane-provenance fixtures

Four documents, one per branch of the lane-origin partition in `parseBpmnXml`.
They exist because the three *defaulted* causes previously produced byte-identical
output: no instrument could separate "the input had no lanes" from "we failed to read
the lanes it had", so no repair to either could be verified.

| fixture | expected `laneProvenance` | why it is the case it claims |
|---|---|---|
| `authored-lanes.bpmn`      | `authored`                        | one laneSet with 2 real lanes — the NEGATIVE CONTROL |
| `no-laneset.bpmn`          | `defaulted:no-laneset`            | no `<laneSet>` element anywhere — a property of the input |
| `empty-laneset.bpmn`       | `defaulted:empty-laneset`         | one `<laneSet>`, zero `<lane>` children |
| `later-laneset-ignored.bpmn` | `defaulted:later-laneset-ignored` | first laneSet empty, SECOND carries 2 lanes — our T-348 first-only read |

The last row is the one that matters most: it is the only case where the document
*did* carry lane structure and we discarded it. Reported as a plain empty laneSet it
would read as the author's omission rather than our defect.

`authored-lanes.bpmn` is not decoration. A probe that merely counts lanes in the
OUTPUT reads 3 for a designer map and 3 for a fabricated one and discriminates
nothing; the control is input-derived — lanes-in must equal lanes-out.
