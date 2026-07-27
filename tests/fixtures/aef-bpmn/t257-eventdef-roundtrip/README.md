# T-257 eventDef round-trip fixture pair (AEF field repro)

Byte-verbatim pair delivered by AEF on the collaboration rail (offsets 208 + 209,
2026-07-27, their T-2627 follow-up to the T-2620 defect report at offset 201).
Accepted by 832 at offset 203. Do NOT edit — these are the peer's field bytes.

| file | provenance | sha256 |
|------|-----------|--------|
| `draft-trigger-handling-v1.bpmn` | PRE-editor bytes (agent-generated pair-draft skeleton) | `5845caae2f83479bc7aeb4b97c2db297cb77edca4cf75fcdc1a3db21bbfa293f` |
| `draft-trigger-handling-v2.bpmn` | POST-editor bytes (operator layout-only edit + save in designer 0.4.0) | `7c0bd69a17e1c240771cc4727e403002423e36b2ee03fe6bc97cb8c7c24deb4b` |

The repro (diff v1 → v2):
- startEvent uid `th_obs_fire`: `<aef:eventDef kind="timer"/>` **DROPPED**
- intermediateThrowEvent uid `th_signal`: `<aef:eventDef kind="message"/>` **DROPPED**
- intermediateCatchEvent uid `th_pickup`: `<aef:eventDef kind="message" binding=""/>` **RETAINED**

Everything else round-tripped clean (19 uids, 20 flows, all aef:meta attrs preserved,
name→workflowRef auto-resolve held). Root lineage: T-237 decision (eventDef =
catch-hosts-only; typed-THROW deferred to a future contract round, offered at rail 156).
The build task that fixes preservation must make v1's three eventDefs survive a
layout-only open→save round-trip; see T-257 for the inception.
