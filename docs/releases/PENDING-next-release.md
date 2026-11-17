# Pending for the next designer release

Items merged since the last tag that the next release's notes and AEF announcement must carry. The release
author moves each item into `RELEASE-NOTES-<version>.md` and deletes it here. (The older
`RELEASE-NOTES-DRAFT-next.md` dates from the 0.13.0 cycle and is not this list.)

## T-1427: the instance picker no longer promises a refusal marker the host cannot draw

- **What changes:** `/api/instances` `refusals` rows are kept only when they are transition refusals (a string `node`
  and a string `rule`, as 832's `tools/instance-node.py` sends). The picker's title explains ⛔ only when at least one
  such row is present.
- **For AEF:** your runtime projection v1 (T-5185) sends unplaceable task files under `refusals`. They are now dropped
  on load (they never matched before either), and the title no longer promises ⛔ under AEF. When projection v2
  (T-5193) serves transition refusals, `{task id, node uid, reason_code, target}`, the marker returns, provided each
  row carries `node` and either `rule` or `reason_code` (both are read; `reason_code` is drawn as the badge's rule).
  No further designer change is needed. Nothing changes in what you store: maps save byte-identically.

## T-1428: the instance overlay draws the recorded route (AEF runtime projection v2)

- **What changes:** when `/api/instances` gives an instance `traversed` (AEF's projection v2, T-5193), the overlay
  marks exactly those edges in the done colour, puts "×N" on an edge taken more than once, and puts ✓ on their ends.
  The picker's title says "✓ recorded path" and counts the `unmapped` hops and any traversed edge uid this map
  version does not have. Without `traversed` (832's own host, projection v1) the ✓ path is the derived shortest path
  as before, now labelled "✓ derived path".
- **For AEF:** this is our Q11 answered. Edges are matched by flow `aef:uid`. Nothing changes in what you store:
  maps save byte-identically (CDP leg L3).
