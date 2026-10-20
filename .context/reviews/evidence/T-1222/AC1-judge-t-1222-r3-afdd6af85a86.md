# T-1222 Human AC#1: independent render review (reviewer judge-t-1222-r3-afdd6af85a86)

Revision: 2d96fa61464fda57a95cef21a31a6a8762542e4b. The screenshots in docs/reports/T-1222-evidence/ are committed, with no working-tree diff.
Opened: all 12 PNGs (before/after × 1024/1440/1920, full and detail).

## Step 2: BEFORE
Met. Order changed, Escalate (truncated "Esc") and Interrupted are drawn as task boxes overlapping their hosts. Announce shipped has the yellow link chevron.

## Step 2: AFTER
- Order changed: an event on Check order's bottom edge with a green message ring. Only the lower half of the envelope glyph is visible (see the defect below).
- Interrupted (plain, double ring) and Escalate (dashed outer ring) sit at separate points along Ship order's bottom edge.
- Wait one day: blue timer glyph. Stock low and Announce shipped: plain grey events, no chevron.
Met in substance.

## Step 3: full pages
The toolbar, palette and properties panel are visible and unclipped at 1024, 1440 and 1920. At 1024 the toolbar wraps to two rows (Add Lane … Save), the same as BEFORE. The panels are identical before and after; only the canvas content differs. Met.

## Step 4: known items
I see both. The circle covers the host's grey id (lan_2_check / lan_2_ship), and the id labels "lan_link_interrupted" and "_link_escalate" run into each other. Accepted as reported.

## Defect that is NOT in the known list: host box painted over its boundary events
In every AFTER shot, the host task's filled box is drawn over the top half of each boundary circle:
- The Order changed envelope is only half visible below Check order (after-1920-detail).
- The tops of the Interrupted and Escalate rings are hidden under Ship order, so the dashed non-interrupting ring of Escalate is only partly readable.

The designer does not draw its own boundary events this way. In docs/reports/T-204-slice2-visual/boundary-on-host.png (copied here as t204-boundary-on-host.png), the timer and error boundary circles are painted fully on top of the host.

Cause (verified): renderNodes paints nodes in state.nodes order. Loading the fixture into the current src/aef-workflow-designer.html with Playwright (adoptImportedXml + renderAll, same call as the shots tool) gives this DOM paint order:
['Start','Done','Announce shipped','Wait one day','Stock low','Order changed','Escalate','Interrupted','Check order','Ship order']
Both hosts are painted after their boundary events, so they cover them.

## Verdict: amber
What has to change: paint attached boundary events after their hosts on import, either by ordering state.nodes so that boundaries follow their host or by raising boundary groups in renderNodes. Then retake t1222-after-{1024,1440,1920}{,-detail}.png so that the full circles, the envelope glyph and the dashed ring are visible over the hosts.
