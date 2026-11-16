# T-1427 Human AC#1: evidence report (judge-t-1427-r3-fcd443ec60a5)

Revision reviewed: 041e15457e0152fdeeda3e3ed61d6d3a24ae77cf (HEAD at review time; all ten cited files are
unmodified against it, `git diff --quiet HEAD` clean for each).

Method: opened every file named in step 1 and looked at it; for the width shots also cropped and enlarged the
frw_gw_all region (3x at 1024 and 1440, 2x at 1920) to check for the halo. Copies of the eight PNGs are in this
directory as `<name>-judge-t-1427-r3-fcd443ec60a5.png`.

## The v1 and v2 shots differ this time
md5 of v1 vs v2 at each width differ (1024: 04976b5a… vs 12cab440…; 1440: daff8bd7… vs d0d70bf5…;
1920: 72579b28… vs 2d990508…). The previous run's finding (byte-identical pairs, gateway off-canvas) no longer holds:
the fit-whole-map control (⤢) is active in every shot and the whole map, including frw_gw_all, is in view.

## v1 (projection v1, unplaced task files)
| check | 1024 | 1440 | 1920 |
|---|---|---|---|
| picker reads "T-9991 · agt_2_perform · started-work", visible, unclipped | ok | ok | ok |
| frw_gw_all ("All gates pass?") has no red halo | ok | ok | ok |
| toolbar controls visible (− fit + ⤢ panels fullscreen contrast All, Add Lane, Reset, Clean layout, View XML, Settings, Load…, Save) | ok (wraps to a second row, nothing cut) | ok | ok |

- Close-up `t1427-aef-v1-gw-all-node.png`: orange gateway diamond, "All gates pass?" / `frw_gw_all`, no halo, no badge.
- `t1427-aef-v1-title.txt`: same text at 1024/1440/1920, ends "…not a recorded history). Reads /api/instances; writes
  nothing." No ⛔ sentence.

## v2 (reason_code)
| check | 1024 | 1440 | 1920 |
|---|---|---|---|
| picker reads "T-9991 · agt_2_perform · started-work", visible, unclipped | ok | ok | ok |
| frw_gw_all has its red halo | ok (red rounded box around the gateway, visible at thumbnail scale) | ok | ok |
| toolbar controls visible | ok (two rows) | ok | ok |

- Close-up `t1427-aef-v2-refused-node.png`: red rounded halo around the gateway and a badge "⛔ unresolved_reference"
  above it, legible.
- `t1427-aef-v2-title.txt`: at all three widths carries "· ⛔ the node a refusal fired on, with the rule that refused
  it." No file path in it (the only path-like string is the endpoint /api/instances, present in v1 too).

## Observations (not failures of the criterion as written)
- At 1024 the fitted map is about 470 px wide, so node labels and the badge text are not readable there; the halo
  itself is. The criterion asks for badge legibility in the close-up only, which is met.
- The v2 width shots also show a second marker the criterion does not mention: a dashed red outline and a
  "refused target" tag on frw_5_finalize. It does not contradict anything the criterion states.

Verdict: green.
