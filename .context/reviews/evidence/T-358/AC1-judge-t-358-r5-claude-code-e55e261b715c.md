# T-358 AC1: independent review (rung-5-panel:claude-code, dispatch judge-t-358-r5-claude-code-e55e261b715c)

Revision reviewed: 58c641d640a6d4f20476bcb8c3285035e249a042. The screenshots in docs/reports/T-358-evidence/ were last changed in that commit (git log); there are no uncommitted changes to them.

Scope as written: the vertical extent (top and bottom of the pool enclose the diagram), no invented lane band or header, "+ Add a lane" below the pool, advisory controls reachable, collaboration's second pool below without overlap. Left-edge overlap excluded (T-1386).

## I opened all 21 screenshots myself

| map | 1024 | 1440 | 1920 |
|---|---|---|---|
| simple | ok | ok | ok |
| boundary-events | **pool bottom not in frame** | ok (joker at ~y728, pool bottom ~y796, add-lane strip ~y816) | ok (joker ~y684, bottom ~y752, strip ~y772) |
| collaboration-message-flows | ok, read-only pool below, no overlap | ok | ok |
| i18n-documentation | ok | ok | ok |
| multiple-diagrams | ok | ok | ok |
| nested-subprocesses | ok vertically (end event off the right edge at 1024; same pool height as 1440, where end event ~y596 is inside the bottom ~y662) | ok | ok |
| zeebe-service-task | ok | ok | ok |

- No screenshot draws a lane band or a lane header. Each shows a single pool header, "<Process> · workflow:<id>" or "Pool · …".
- The "+ Add a lane" strip sits directly below the pool in every screenshot where the pool bottom is visible. At 1024 the strip's right-aligned text is clipped by the inspector, but the strip itself is visible below the pool.
- The advisory cards' × / "Clean layout" / "▸ 1 more" controls are visible and unobstructed at every width.
- For collaboration-message-flows, at 1024, 1440 and 1920, the "Pool · read-only" sits below our pool with a gap (the add-lane strip) and does not overlap it. Nit (outside the literal): the dashed message-flow lines and their end markers cross the "+ Add a lane" text in the gap (1440/1920).

## The gap: boundary-events-1024
In boundary-events-1024-judge-t-358-r5-claude-code-e55e261b715c.png the canvas ends at about y≈765 (horizontal scrollbar). The lowest element, the "joker" link event and its label (y≈690–750), is visible, but the pool's bottom border and the "+ Add a lane" strip below it are NOT in the frame. See the crop boundary-events-1024-bottom-crop-judge-t-358-r5-claude-code-e55e261b715c.png: the pool's left border runs down to the scrollbar with no bottom corner. So this screenshot cannot show that the pool's bottom encloses the diagram at 1024, or that "+ Add a lane" sits below the pool.
The same map at 1440 and 1920 (boundary-events-1440-judge-t-358-r5-claude-code-e55e261b715c.png) shows a pool bottom that encloses joker, and pool height comes from content, not from viewport width. So the render is very likely correct. But the criterion asks for this at all three widths and is judged on screenshots, and this one does not show it. Nothing is seen outside the pool. The evidence is incomplete, not failing.

## Verdict: amber
Needed: re-take boundary-events-1024 with the pool's bottom edge and the "+ Add a lane" strip in view (scroll the canvas down, or fit/zoom-out), and add it to docs/reports/T-358-evidence/.
