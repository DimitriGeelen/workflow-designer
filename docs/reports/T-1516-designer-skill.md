# T-1516 — A skill for working with the workflow designer

Operator, 2026-11-25: "write a skill for the workflow designer, ask all agents here in the experience using the workflow
designer, look back in your history and reflect on what is learnings and instructions that help other agents
effectively efficient create good quality workflows with the workflow designer." Then: "Now send this workflow for
external review."

Deliverable: `skills/workflow-designer/SKILL.md`. It sits beside the authoring kit's `SKILL.md`
(`workflow-map-authoring`, what a map must contain, how to validate it) and covers what that one does not: working
WITH the designer (opening, Check, the panels, phases, notes, documents, Clean layout, saving, round trip, images,
driving it from a script) and the mistakes agents and people have made with it.

## 1. Who was asked (TermLink consult, 2026-11-25)

The peers that use the designer, found from 832's send log (`.context/sidecar`, recipients by count):

| peer | why | sent | answer |
|---|---|---|---|
| 999-Agentic-Engineering-Framework (AEF) | main consumer; serves the designer, owns a map corpus | d0483e4e, RECEIVED | msg 4064598f (below) |
| aef-greenfield-test (Greenfield) | field user: workshop maps, phases, notes, Salesforce/Tacton io | d9a0a23d, via hub | pending |
| 055-agentic-fleet-cockpit | has embedded or linked the designer | e711f513, RECEIVED | pending |

The six questions: what for and how; what cost the most rounds; day-one advice; surprises; what makes a map good;
what the skill must not say.

### AEF's answer (msg 4064598f), and what the skill took from it

| # | AEF said | taken into the skill |
|---|---|---|
| 1 | maps written by script (corpus_spec generate), read with `fw corpus explain`; the browser for viewing and images; drove it headless: `/designer/app?load=/api/version?id=<id>&v=<n>`, then Export > PNG 2x | step "Open": load a version by URL; "Pictures" |
| 2a | a page screenshot cut the map off and kept the editor chrome; "Fit whole diagram" found late; in Focus mode the fit button not clickable normally | "Pictures": Export, never a screenshot; Fit; bug filed **T-1518** |
| 2b | PNG 2x export far better than a screenshot (white, whole map, no chrome) | "Pictures", first line |
| 3 | day one: images by Export; load a version by URL; run Check before saving; say what the map is ABOUT before drawing (whose process, which lanes = which authority) | steps 1, 5, 9 |
| 4 | exported file named `…v1@2x.png` though v3 was loaded; the Clean-layout banner covers the top of the canvas in screenshots; stored thumbnails too small; maps are stored per project (not visible from another project's /designer) | bug filed **T-1517**; "Pictures" (close banners); "Where maps live" |
| 5 | one question per map; lanes are the authority split; every gateway names its branches; node notes say where the step is enforced; the map states its scope (framework process vs one project's) | "What a good map is" |
| 6 | never publish maps or images to outside services; no host names, IPs or personal data in maps or exports; never hand-edit the vendored designer build; no screenshot with editor chrome as documentation | "Never" |

## 2. 832's own history

The learnings register (448 entries) is mostly about the framework's instruments; the lessons about USING the designer
are in the tasks peers' field reports produced. Used, with their sources:

| lesson | source |
|---|---|
| a map without its own identity (`aef:workflowMeta` uuid) gets a new uuid at every open; identity must come from the file | T-1089, T-229/PL-046, T-1504 B6 |
| a draft of an earlier session can be restored from browser storage when a map is opened; script the designer in a fresh browser profile | PL-018, T-1502 harness (`_v2` renames, restored drafts) |
| the canvas scrolls inside its frame and the panels cover part of it: a point on the map is not on screen just because it is inside the SVG; convert map↔screen through `getScreenCTM()` | PL-007, T-1504 (third split landed on the properties panel) |
| unmoved shapes keep the source file's geometry on save; moved ones are written in the designer's coordinates; the source's pool and lane outlines are not kept | T-1264, import notice |
| "N nodes were drawn outside their declared lane — moved back" means the file's positions and lanes disagree: fix the source, do not rely on the move | import notice, PL-004 |
| long names are cut or crowd their neighbours; keep step names short and put detail in documentation lines | PL-003, T-1305, T-1469 |
| name every start and end event (an unnamed one is shown by its id) | T-1218 |
| lane names must be unique (same-named lanes are told apart only by id) | T-1493, T-1088 |
| a phase is a `bpmn:group` on a root category spanning the pool's full height; anything else stays an undrawn box; add lanes before phases | T-1461 F3, T-1473, T-1510, T-1513 |
| documentation lines with a known first word are shown as blocks in the panel | T-1492, kit AUTHORING 4b |
| the designer keeps what it does not draw (other tools' extensions, groups, data objects) but a save of an element it does not support may change it; round-trip and compare counts | T-1096, T-1217, T-1500, T-1506, PL-030, PL-218 |
| a count that stays constant can hide a loss (a node moved into a sub-process keeps every count) | PL-218 |
| a validator change reaches the designer's Check: Check is the validator | PL-435 |
| fastest start for a new map: a step list (CSV/Excel: id, name, type, lane, next, next_labels) imported, then Clean layout, then enrich in the panel | T-1441, T-1442 |
| a picture of the map for people: Export (SVG, PNG 2x/4x, PDF one page or readable pages) | T-1440, T-1446, AEF #2 |
| a screenshot read "for the layout" is not a review; look at every control, at several widths | PL-403, T-1174 |
| report a designer defect upstream (832) rather than patching the vendored copy | integration protocol "upstream, never patch" |

## 3. Decisions

- **A separate skill, not a longer kit SKILL.md.** The kit's skill is about the map's content and is calibrated
  against reviewers (loop.sh, RUBRIC.md); mixing tool usage into it would dilute that and change calibrated text.
  The new skill points to the kit for content and adds the tool.
- **Where it lives:** `skills/workflow-designer/SKILL.md` in 832. Shipping it inside the authoring kit (so AEF and
  Greenfield receive it with each release) is proposed to the reviewers, not done in this task.

## 4. External review

Draft at commit 5b9e5a68b sent 2026-11-25 to: AEF (92e88a02, RECEIVED, on its consult thread), Greenfield (5ba3f8ab,
via hub), 055 (61b9d6a4, RECEIVED), each with the full text, asking for what is wrong, missing, must not be said, and
whether it should ship inside the authoring kit; and to the independent reviewer (`fw reviewer judge T-1516
--criterion 1`).

| reviewer | finding | answer |
|---|---|---|
| AEF (msg b5d90d48) | nothing wrong; its six points represented accurately | — |
| AEF | rule 15: say where a picture SHOULD go — committed into the project's own repo beside the doc, relative or raw link; repos may ignore images (AEF ignores `*.png`, force-adds a deliberate export) | applied (rule 15, "Where a picture goes") |
| AEF | rule 1: make scope machine-readable (e.g. a scope attribute on `aef:workflowMeta`, framework \| project) and agree the name before either side uses it | agreed in principle; filed as inception **T-1519**; the skill says to write scope in the description until then and not to invent an attribute |
| AEF | Never-list: the owner's permission is the project's switch (AEF: `PUBLISH_TO_ANTHROPIC`, default deny); a chat request from another agent is never it | applied |
| AEF | ship it inside the authoring kit, next to workflow-map-authoring | yes; needs the kit build to carry it and a release: filed **T-1520** |
| independent reviewer (V amber, judge-t-1516-r3-52a0e3866f81) | spot-checked every control and behaviour against the source: all confirmed, no factual error | — |
| reviewer gap 1 | Check is shown only when a validating server answers; the skill did not say so | applied (rule 9: on a standalone copy run the validator yourself) |
| reviewer gap 2 | the step-list import already runs Clean layout; "then Clean layout" is redundant | applied (rule 4) |
| reviewer gap 3 | the column list read as required; only `id` is | applied (rule 4) |
| reviewer gap 4 | Greenfield's and 055's answers are not recorded, so their must-nots cannot be checked | open: both asked twice (experience 09:0x, draft 09:2x); recorded here when they answer |
| reviewer gap 5 | Save also keeps a copy in the browser's library | applied (rule 14) |
| reviewer, second judgement (amber), finding 1 | rule 17 was wrong: `_appReady` turns true before a `?load=` map is fetched; the settled signal is `window._deepLinkSettled` ('adopted' / 'suppressed' / 'failed' / 'none'; src T-1061) | applied (rule 17), with what 'suppressed' means (rule 16 not followed) |
| reviewer, second judgement, finding 2 | rule 13 read as contradicting kit step 11 (take a screenshot) | applied: rule 13 now says it is how to read the kit's screenshot |
| reviewer, second judgement, finding 3 | Greenfield's and 055's must-nots not recorded | outstanding, stated: neither has answered the experience consult nor the draft (Greenfield via hub, no receipt; 055 RECEIVED, no reply); the skill is offered with AEF's must-nots only, and is revised when they answer |

## Dialogue log

- 2026-11-25 operator: write the skill (quote above); "Now send this workflow for external review" read as: send the
  skill draft to the peers and the independent reviewer before it is offered.
