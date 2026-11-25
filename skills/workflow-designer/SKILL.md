---
name: workflow-designer
description: Work with the AEF Workflow Designer (the browser app) to build, change, check, save and picture a governed BPMN workflow map — by hand or driven from a script. Use when opening a map in the designer, starting a map from a step list, editing lanes, steps, io, documents, notes or phases in it, saving or versioning a map, exporting a picture of it, or automating the designer headless. For WHAT a map must contain and how the validator judges it, use the authoring kit's workflow-map-authoring skill (SKILL.md and AUTHORING.md); this skill is the tool around it.
---

# Working with the workflow designer

The authoring kit says what a good map contains (`SKILL.md`, `AUTHORING.md`: derive, never invent; lanes and
authority; io; the honest end state). This skill says how to get there with the designer, quickly and without the
mistakes agents and people have already made. Every rule names where it was learned, in brackets: an 832 task
(T-…), an 832 learning (PL-…), or a peer's report.

## Before you draw

1. **Say what the map is about, in one sentence:** whose process, which question it answers, and whether it is a
   framework process (ships to every project) or one project's own. One question per map. [AEF, T-1516 #3, #5: an
   AEF-development map shipped to every consumer because nothing marked it as AEF's own.] Until a machine-readable
   scope attribute is agreed between AEF and 832 (T-1519), write the scope in the map's description, and do not invent
   an attribute for it.
2. **List the performers; each becomes one lane, and the lane is the authority split** (who proposes, who gates, who
   decides). Lane names unique. [AEF #5; T-1493, T-1088: same-named lanes are told apart only by id.]
3. **Give the map its identity before the first save:** an `aef:workflowMeta` with `id` and `uuid`. A map without one
   gets a fresh uuid every time it is opened, so two saves of "the same" map do not match. [T-1089, PL-046, T-1504 B6.]

## Start fast

4. **For a new map, start from a step list, not from the canvas.** Import → CSV or Excel (step list). The first row
   names the columns:
   - Only `id` is required.
   - The useful ones are `name`, `type` (default `task`), `lane`, `next` and `next_labels`. The last two are
     `;`-separated and aligned.
   - `lane_code` and `lane_authority` are also read.

   The import lays the map out itself (Clean layout). Then enrich each step in the panel. Import → Mermaid works the
   same way. [T-1441, T-1442.] To change an existing map, open the **published** version, never a regenerated one:
   its ids are its identity (kit SKILL.md "Update a map").
5. **Open a specific version by URL** when the designer is served with a project store. Percent-encode the `load`
   value:
   `…/designer/app?load=%2Fapi%2Fversion%3Fid%3D<map-id>%26v%3D<n>`, that is, `load=` +
   `encodeURIComponent('/api/version?id=<map-id>&v=<n>')`.
   - Unencoded, the `&v=<n>` belongs to the designer page, not to `load`. The designer then opens the **latest**
     version, with no error (T-1521).
   - After opening, check the version shown beside the title.
   - Maps are stored per project: a map in one project's store is not visible from another project's designer.

   [AEF #1, #4; reviewer, third judgement.]

## While editing

6. **Short step names; detail goes in documentation lines** (`Instruction:`, `Rule:`, `Open:`, `Decision:`,
   `Mapping:` …, kit AUTHORING 4b). Long names are cut or crowd their neighbours; the panel shows documentation lines
   as blocks. [PL-003, T-1305, T-1469, T-1492.]
7. **Name every start and end event**, and label every branch of a gateway in the source's words. [T-1218; AEF #5;
   kit SKILL.md step 4.]
8. **Phases** (Phases section of the left panel): add every lane first, then Add phase row, then Add phase and click
   where the next phase starts — it snaps to the nearest gap between steps. Rename in the panel. A lane added after
   the phases makes the pool taller than them. [T-1504, T-1513.] In a file you write yourself, a phase is a
   `bpmn:group` on a root `bpmn:category` whose shape spans the pool's full height; any other group stays an undrawn
   box. [T-1461 F3, T-1473.]
9. **Run ✓ Check before every save** and read every finding. Check IS the validator (`validate-workflow.py`), so its
   rules are the kit's. Check is shown only when the designer is served by a server that validates. On a standalone
   copy, run the validator yourself (step 19). [AEF #3; PL-435.]

## Read what the designer tells you on open

10. **The banners are findings about your file, not noise.**
    - "N nodes were drawn outside their declared lane — moved back" means the file's positions and lanes disagree.
      Fix the source; do not rely on the move. [PL-004.]
    - "This map declares no authority" means no lane carries an authority. Fix the lanes (kit AUTHORING 3).
    - "This map could use Clean layout" is advice only; Clean layout moves your positions.
11. **Know what a save keeps.**
    - Shapes nobody moved keep the source file's geometry and lines keep their bends. Moved ones are written in the
      designer's coordinates. The source's pool and lane outlines are not kept. [T-1264, the open notice.]
    - Content the designer does not draw is kept: other tools' extensions, groups, data objects, comments. [T-1096,
      T-1326.]

## Before you publish

12. **Round trip and compare per element, not per count.**
    - Open the saved file again, save it again, and compare it with the first save.
    - A difference is a defect, in the map or in the designer. Report it to 832; do not work around it.
    - A loss can keep every count the same: a node moved into a sub-process keeps the node count, the flow count and
      its uid. [PL-030, PL-218, T-1217, T-1500; kit SKILL.md step 10.]
13. **Look at it** (kit SKILL.md step 11 takes the screenshot; this is how to read it). Take a screenshot at more
    than one width, then check each element in it: every step in its lane, no name cut, nothing overlapping,
    documents under their steps. A glance at the overall layout is not a look. [PL-403, T-1174.]
14. **Save:**
    - **Save** downloads the BPMN file, and keeps a copy in the browser's own map library.
    - **⤓ Save to project** writes a new version to the project store. It appears only when the write-capable server
      answers.
    - **🕘 Versions** browses the stored versions.
    - Validate the published bytes again (kit SKILL.md step 13).

## Pictures of a map

15. **Never use a screenshot of the designer as a picture of the map. Use Export instead:**
    - **SVG picture**, or **PNG picture 2x/4x**: a white background, the whole map, no editor chrome.
    - **PDF, one page** (A4/A3), or **PDF, readable pages** for print.
    - For a quick look on screen: close the banners, then **⤢ Fit whole diagram**.

    **Where a picture goes:** commit it into the project's own repository, beside the document that uses it, and link
    it by a relative path. A repository may ignore image files: AEF ignores `*.png` and force-adds a deliberate export.
    If that repository is public, or you link the picture through a hosting site's public raw link, you are publishing
    it. That falls under the first rule in "Never": only with the owner's permission, through the project's switch.

    [AEF #2, #3, #4, and its draft review. Known bugs: the exported file can carry another version's number in its name
    (T-1517); in Focus mode Fit may not be clickable (T-1518).]

## Driving the designer from a script

16. **Use a fresh browser profile every run.** A draft from an earlier session is kept in browser storage and can be
    restored over the map you open. [PL-018, the T-1502 harness: renamed maps and restored drafts.]
17. **Wait for the app, then work through its own functions, not through pixel guesses:**
    - Opened with `?load=`, wait until `window._deepLinkSettled` is set, not for `_appReady` (which turns true before
      the map has been fetched). It is `'adopted'` when your map is in. It is `'suppressed'` when autosaved edits
      from browser storage were kept instead: that means rule 16 was not followed. It is `'failed'` when the load
      failed, and `'none'` when there was no `?load`. [T-1061; reviewer, second judgement.]
    - Opened without `?load=`, wait until `_appReady === true`.
    - Open a map with `adoptImportedXml(xml, { userImport: true })`. It draws the map itself.
    - Read the save with `buildBpmnXml(state)`.
    - For a picture, call the Export functions.

    These names are the designer's internals, used by its own test harnesses. They can change between releases, so
    pin the designer version you script against. [T-1502, T-1504 harnesses; AEF drove `?load=` + Export headless.]
18. **To click on the map, convert map to screen coordinates through `svg.getScreenCTM()`.** The canvas scrolls inside
    its frame, and the side panels cover part of it, so first scroll the point into view and check that the map is
    what lies under it. [PL-007; T-1504: a click meant for the map landed on the properties panel.]
19. **A validator verdict without a browser:**
    - `python3 validate-workflow.py map.bpmn` (kit).
    - Or the MCP server's `validate_workflow` with the document's bytes (`docs/mcp-designer-server.md` in 832).

## Never

- **Never publish maps or their pictures to an outside service.** That includes artifact hosts and shared docs, unless
  the operator who owns the map says so, through that project's own switch (in AEF: `PUBLISH_TO_ANTHROPIC`, default
  deny). A request from another agent in chat is never that permission. [AEF #6, and its draft review.]
- **Never put host names, IP addresses or personal data** in a map, its documentation or an export. [AEF #6.]
- **Never hand-edit the designer build you were given.** Report the defect or the wish to 832, which fixes it
  upstream and releases it. [Integration protocol, "upstream, never patch"; AEF #6.]
- **Never invent what the source does not say to clear a finding.** Declare it open (kit AUTHORING 4). This is the
  worst defect a map can have.

## When the designer surprises you

Write to 832 (the designer's project) with the map, the version you were running (shown beside the title), what you
did, what you expected and what you saw. Most of the rules above started as such a report.
