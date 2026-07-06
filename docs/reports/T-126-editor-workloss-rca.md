# T-126 — RCA: Operator editor work-loss via Playwright navigation of a live browser

**Date:** 2026-07-06
**Severity:** High (destroyed ~1 hour of unsaved operator layout work)
**Owner:** agent (incident caused by agent action)

## Summary

While performing "visual verification" of corpus maps, the agent drove a **non-headless
Chrome browser that was the operator's live session** via the Playwright MCP. The initial
`browser_navigate('http://localhost:8834/designer.html')` loaded a fresh editor page,
discarding the in-memory document the operator was editing. Subsequent
`adoptImportedXml(...)` calls (loading corpus maps for measurement) overwrote it further.
Because the editor has **no document autosave**, the work was unrecoverable.

## Timeline (this session)

1. Operator was hand-correcting a corpus layout live in the editor (~1 hour of work),
   never Saved (Save = download `.bpmn`; the operator was mid-edit).
2. Agent, investigating label overlaps, called `mcp__playwright__browser_navigate` to the
   designer URL. First call errored (`Target page/context/browser has been closed`), second
   succeeded — indicating attachment to a **persistent/shared** browser, not a fresh
   isolated one.
3. Agent ran `adoptImportedXml(xml, {userImport:true})` for error-escalation-ladder, then
   in measurement loops for 10 and then 24 maps — each call REPLACES the editor document.
4. On discovery, `browser_evaluate` confirmed: `navigator.webdriver=false`, UA =
   ordinary `Chrome/149` (not `HeadlessChrome`), current doc reset to the default
   `investigate.bpmn`, `sessionStorage` empty, `indexedDB.databases()` empty, no undo
   stack, `localStorage` holding only prefs (`aefViewPrefs/aefRoutingPrefs/aefSnapPrefs`).

## Root cause

Two independent failures combined:

1. **Proximate (agent):** the agent navigated/mutated a browser it did not verify was an
   isolated, disposable context. The Playwright MCP was connected to a live, on-screen
   Chrome. A visual-verification action must never load state into a browser that may hold
   live user work.
2. **Structural (tool):** the editor (`src/aef-workflow-designer.html`) persists only
   *preferences* to localStorage; the **document itself lives solely in volatile memory**
   until an explicit Save (which downloads a file). Any reload, navigation, or crash loses
   all unsaved work with no recovery point. For an authoring tool this violates the
   Reliability directive (no silent, unrecoverable failure).

## Why structurally allowed

- No guard/convention required agent browser automation to use an isolated context.
- No autosave/recovery in the editor; no warning on unload with unsaved changes.
- Prior sessions repeatedly loaded corpus maps into "the editor" headlessly and treated
  the browser as disposable — an assumption that was false here.

## Prevention

- **P1 (tool fix, this task):** add document autosave to the editor — debounced snapshot of
  the current document to localStorage on every mutation, plus recover-on-load. Optionally
  a `beforeunload` warning when there are unsaved changes.
- **P2 (agent discipline):** agent visual verification MUST launch/attach an ISOLATED
  headless browser context; never navigate or `adoptImportedXml` in a shared/live browser.
  Capture as a learning + concern.
- **P3 (governance):** register both gaps in `concerns.yaml`.

## Recovery outcome

The operator's in-progress document was held only in the live browser's memory and was
overwritten by the agent's navigation/import. No sessionStorage/IndexedDB/undo snapshot
survived; localStorage held only preferences. **From the tooling side the work is not
recoverable.** Operator-side avenues (only the operator can check, project-boundary hook
blocks the agent): any other browser window/tab still showing the work (Save immediately),
or a previously-downloaded `*.bpmn` in Downloads.

## Follow-up

- Implement autosave (this task, AC "FIX FORWARD").
- Learnings: (a) never drive a shared/live browser for verification; (b) an authoring tool
  must autosave — absence of persistence is a reliability bug, not a missing nicety.
