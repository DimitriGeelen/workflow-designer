# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-antigravity-af694276113f`
- worker kind: `antigravity` (vendor `google`, model `worker default`)
- seat: `antigravity`
- reviewed revision: `eb0a943ff6de81c1b2b6bcd9a7efcdb9e2c3752c`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.md sha256: `e775c365537dc40ab91e387a8e74495b365a4b205a1362c45a2d58f791f93084`

## The worker's verdict block

```
1. [AC] The two markers read as different KINDS of thing, and the common case is silent.
VERDICT: green
WHY: Inspected all nine supplied screenshots in docs/reports/t893-shots/ (none-{s,m,l}.png, differs-{s,m,l}.png, missing-{s,m,l}.png) alongside tools/_t893-authority-marker-shots.mjs. In none-m.png (frw_1_start, "Start work (captured -> started-work)"), no marker is rendered above the node, keeping the common case completely silent. In differs-m.png (frw_2_enter, "Enter issues (auto → healing diagnose)"), a muted grey/slate monospace ◆ ini appears at the top-left above the node border, reading quietly as a contextual metadata annotation rather than an alarm. In missing-m.png (agt_2_perform, "Perform the work"), a bright orange/amber ⚠ no auth marker appears at the top-left above the node border, fitting cleanly to the left of the incoming vertical sequence-flow arrowheads at top-centre without colliding with incoming edges or labels, and reading unmistakably as a defect warning. The visual contrast between the silent default, the subtle annotation (◆ ini), and the loud defect marker (⚠ no auth) is well-pitched across all three label sizes (s, m, l).
GUIDANCE: none

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```

## The worker's full output (result.md)

```
1. [AC] The two markers read as different KINDS of thing, and the common case is silent.
VERDICT: green
WHY: Inspected all nine supplied screenshots in `docs/reports/t893-shots/` (`none-{s,m,l}.png`, `differs-{s,m,l}.png`, `missing-{s,m,l}.png`) alongside `tools/_t893-authority-marker-shots.mjs`. In `none-m.png` (`frw_1_start`, "Start work (captured -> started-work)"), no marker is rendered above the node, keeping the common case completely silent. In `differs-m.png` (`frw_2_enter`, "Enter issues (auto → healing diagnose)"), a muted grey/slate monospace `◆ ini` appears at the top-left above the node border, reading quietly as a contextual metadata annotation rather than an alarm. In `missing-m.png` (`agt_2_perform`, "Perform the work"), a bright orange/amber `⚠ no auth` marker appears at the top-left above the node border, fitting cleanly to the left of the incoming vertical sequence-flow arrowheads at top-centre without colliding with incoming edges or labels, and reading unmistakably as a defect warning. The visual contrast between the silent default, the subtle annotation (`◆ ini`), and the loud defect marker (`⚠ no auth`) is well-pitched across all three label sizes (`s`, `m`, `l`).
GUIDANCE: none

Summary: 1 green, 0 amber, 0 red, 0 escalate, 0 not-evaluated
```
