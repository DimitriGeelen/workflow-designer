# T-893 Human AC#1 — evidence report (seat claude-code, rung-5-panel)

Dispatch: judge-t-893-r5-claude-code-7754835ace6d
Revision reviewed: 1de2010087da57dc32310ea416b5783dff372eca
**Degraded: single-vendor panel.** Fewer vendors could be dispatched than the panel requires, so this
run cannot satisfy a multi-vendor requirement; this verdict is recorded and reported and the criterion stays open.

## What I did

1. Exported the registered revision with `git archive` to a scratch directory and ran step 1 there
   (`node tools/_t893-authority-marker-shots.mjs`), so the run is of the reviewed revision and the
   repo's tracked shots were not overwritten by me. Exit 0:
   - L1 PASS: per size, 1 differs marker, 3 missing markers (= the 3 agent-lane nodes), 15 nodes.
   - L2 PASS: buildBpmnXml before == after (22736 bytes).
   - L3 PASS: 9/9 shots show their node (T-1429 clear-shot guard).
   - 9 PNGs written. All nine are byte-identical (sha256) to the committed `docs/reports/t893-shots/*.png`,
     so the committed shots are what the revision renders.
2. Opened `none-m`, `differs-m`, `missing-m` individually and side by side at 3x
   (`side-by-side-m-x3-judge-t-893-r5-claude-code-7754835ace6d.png`), and the s and l rows at 2x (`grid-s-l-x2-judge-t-893-r5-claude-code-7754835ace6d.png`).
3. Ran `tools/_t1069-authority-marker-clearance-cdp.mjs` on the same export: PASS 4 legs. Forced on every
   node of the corpus maps: 306 missing + 294 differs markers, 0 cross their node's own edges, 0 lack a
   hoverable full-text `<title>`.
4. Read the CSS at src/aef-workflow-designer.html:717-718: badge = `--text-faint` (#5a6173), mono 8px;
   missing = `--orange` (#f5a847), mono 8px, weight 600.

## What I saw (step 2 of the criterion)

- **none-m** (`none-m-judge-t-893-r5-claude-code-7754835ace6d.png`): no marker. The node "Start work (captured -> started-work)" shows only
  its type icon, the "1→0" I/O badge and the id badge. The common case is silent. Same at s and l.
- **differs-m** (`differs-m-judge-t-893-r5-claude-code-7754835ace6d.png`): a grey mono "◆ ini" above the top-left corner of "Enter issues
  (auto → healing diagnose)". It is dimmer than the id badge text beside the node and far dimmer than the
  node label; nothing about it is coloured. It reads as an annotation, not an alarm. Legible at 1x.
- **missing-m** (`missing-m-judge-t-893-r5-claude-code-7754835ace6d.png`): an orange, heavier "⚠ no auth" above the top-left corner of
  "Perform the work". It is the only saturated text in the crop and carries a warning glyph; it reads as a
  defect. It ends left of the arrowhead entering at top-centre, with a small gap, no overlap. Same at s and l.

## The judgement asked for: is the subtle/loud contrast right?

Yes. The two markers differ on three axes at once (hue: neutral grey vs orange; weight: regular vs 600;
glyph: ◆ vs ⚠), while sharing size, face and position, so they read as two kinds of statement in one
slot rather than as two intensities of one statement. Neither is mis-pitched: "◆ ini" is quiet but still
readable at 1x, and "⚠ no auth" is loud without being larger than the node's own label. Position: no
collision with an edge label in any of the nine shots.

## Notes that do not change the verdict

- The "If not" clause says `missing-m.png` shows an edge label sitting just above the marker. At this
  revision it does not: what sits above is the lane separator line, and the incoming flow's arrowhead sits
  to its right. That aside is out of date; the Steps and Expected clauses are current and met as written.
- The task's Visual Verification prose names `frw_4_enter` as the differs node; the script shoots
  `frw_2_enter`. Prose only.
- `--orange` is also the framework lane's node border colour (sampled (245,168,71) on the differs node's
  border). The missing marker in the shot is on a blue agent-lane node, where the hue is unique. On a
  framework-lane node with no authority the marker would share its hue with the border; the ⚠ glyph and
  weight still separate it, and the T-1069 run shows no geometric clash, but no shot shows that pairing.
- The ⚠ glyph itself renders thin at 8px; the word "no auth" carries the loudness. Acceptable.
- `differs-m.png` and `differs-l.png` are byte-identical (the label wraps the same at m and l); the marker
  is 8px at every size by design.
- The T-1069 clearance tool measures markers against their node's own edges, not against edge labels; the
  no-edge-label-collision statement above rests on the nine shots only.

## Verdict

green.
