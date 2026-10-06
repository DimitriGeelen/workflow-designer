# T-310 Human AC#1 — independent review (rung-5-panel:claude-code, dispatch judge-t-310-r5-claude-code-a5559d8459d5)

Revision reviewed: c7b6414b1cefb407b1e112f9dd229caaa25f4593

## What I did
1. Loaded `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn` into the real editor
   (`src/aef-workflow-designer.html`, v0.15.3 badge) through the toolbar **Load…** button's
   file chooser (Playwright headless chromium, 1720x1000) — the operator's real import path
   (`adoptImportedXml(text,{userImport:true})`). Screenshot: `AC1-judge-t-310-r5-claude-code-a5559d8459d5-after-src.png`.
2. Repeated against the released `dist/aef-workflow-designer-0.15.3.html` — identical result.
3. Compared with the old-build image `docs/screenshots/t310-both-before.png` (copied as `AC1-judge-t-310-r5-claude-code-a5559d8459d5-before.png`).
4. Ran `python3 tests/test_t310_lane_position_conflict.py` — OK, errs [] (8 legs incl. idempotent re-import and clean export).

## Findings (read from the live editor after import)
Lanes: Agent · Initiative band 62..222; Framework · Authority band 222..382.

| node | declared lane | y after import | lane at centre |
|---|---|---|---|
| request arrives | agent | 110 (unchanged) | agent |
| framework validates the request | framework | 270 (was 100) | **framework** |
| agent carries out the work | agent | 110 (was 300) | **agent** |
| recorded | framework | 310 (unchanged) | framework |

Notice at top of canvas (visible, dismissible ✕):
"⚠ 2 nodes were drawn outside their declared lane — moved back into place"

On the old build (before image) "framework validates the request" sat in the AGENT lane and
"agent carries out the work" in the FRAMEWORK lane, and only a "could use Clean layout" nudge
was shown. Now each sits in its own lane, the two agreeing nodes are untouched, and the notice
states a repair with the correct count (2). x positions are preserved, so the map is
recognisably the operator's layout, with only the two mis-drawn nodes shifted vertically.

## Minor observation (not blocking)
Because x is preserved, the edge into "agent carries out the work" now enters from below and
loops back down to "recorded"; the arrowhead touches the node's displayId caption. Cosmetic;
Clean layout tidies it if wanted.

## Verdict: green
