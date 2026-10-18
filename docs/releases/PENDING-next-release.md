# Pending for the next designer release

Items merged since the last tag that the next release's notes and AEF announcement must carry. The release
author moves each item into `RELEASE-NOTES-<version>.md` and deletes it here. (The older
`RELEASE-NOTES-DRAFT-next.md` dates from the 0.13.0 cycle and is not this list.)

- **T-1209: the element details view opens at the top every time.** Before, closing it kept its scroll position,
  so every later open (any element) started where the last one was left, with the element's header and Name/Slug
  row above the fold. An edit while the view is open still keeps the place. No change to what AEF stores.
  Test: `tools/_t1127-element-details-cdp.mjs` leg G.
