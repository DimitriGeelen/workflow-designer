# Pending for the next designer release

Items merged since the last tag that the next release's notes and AEF announcement must carry. The release
author moves each item into `RELEASE-NOTES-<version>.md` and deletes it here. (The older
`RELEASE-NOTES-DRAFT-next.md` dates from the 0.13.0 cycle and is not this list.)

- **T-1212: the exclusive-gateway arity rules are WARNINGS now, and renamed.** Operator decision 2026-10-19.
  An exclusive gateway with fewer than two outgoing flows that does not converge (1-in/1-out, or 0 out) is still
  reported, but no longer fails the check: nothing requires it (mapping-v1 §3 has no MUST/SHALL there, BPMN admits
  the shape, and the dialect axis classes it CONVENTIONAL). **Id map, for anything that stores finding ids:**
  `E-GW-OUTGOING` → `W-GW-OUTGOING`, `E-XML-GW-OUTGOING` → `W-XML-GW-OUTGOING`. **For AEF:** a check that FAILED on
  such a gateway now passes with a warning (exit 1 instead of 2). If your compiler relied on the error, tell us.
  The finding text and the converging-gateway exemption are unchanged. Kit: CONFORMANCE.md lists both as WARN.
- **T-1209: the element details view opens at the top every time.** Before, closing it kept its scroll position,
  so every later open (any element) started where the last one was left, with the element's header and Name/Slug
  row above the fold. An edit while the view is open still keeps the place. No change to what AEF stores.
  Test: `tools/_t1127-element-details-cdp.mjs` leg G.
