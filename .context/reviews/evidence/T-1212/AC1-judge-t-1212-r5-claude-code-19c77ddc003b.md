# T-1212 Human AC#1 — evidence report (panel seat claude-code, dispatch judge-t-1212-r5-claude-code-19c77ddc003b)

Revision reviewed: 736159b355715bcd54494531e9abb9cc1d8cfd36. The three screenshots are committed and unmodified in the
working tree at that revision (git status clean for docs/reports/T-1212-evidence/; added by c4d818f7c).

## What I did
Opened each of the three screenshots myself (full frame), and cropped/enlarged the map area (4x) and the dock (2x).
Read the fixture tests/fixtures/warn/W-XML-GW-OUTGOING.xml: exclusiveGateway agt_1_gate has one incoming (flow_1) and
one outgoing (flow_2), i.e. the 1-in/1-out case.

## Findings per screenshot

| check | 1024 (1024x768) | 1440 (1440x900) | 1920 (1920x1080) |
|---|---|---|---|
| Header shows designer v0.23.0 | yes | yes | yes |
| Dock line "1 finding · 0 errors, 1 warning · 1 on the map" | yes, verbatim | yes, verbatim | yes, verbatim |
| Row severity | WARN (amber), no ERROR row | WARN (amber), no ERROR row | WARN (amber), no ERROR row |
| Rule id W-XML-GW-OUTGOING | yes | yes | yes |
| Message | "exclusiveGateway has 1 outgoing flow(s); requires >= 2", full, legible | same | same |
| Dock close button (x) | visible at right end of dock header, whole | visible, whole | visible, whole |
| Toolbar "Check" button | visible in second toolbar row, whole | visible in second toolbar row, whole | visible in the single toolbar row, whole |
| Gateway finding marker | map is drawn very small (fit); a small amber badge is discernible at the gateway's lower right but not readable | amber boxed warning badge at lower right of agt_1_gate, clear | amber boxed warning-triangle badge at lower right of agt_1_gate, clear |

Notes:
- At 1024 the dock row sits at the bottom edge of the viewport; the WARN label, rule id and message are all fully inside
  the frame with space beneath. Nothing is cut off.
- At 1024 the map is too small for the marker to be read as such. The criterion asks for the marker only "where the map
  is drawn large enough to see it", which is the case at 1440 and 1920, where it is present. So this is within the
  criterion as written.
- No control in any of the three frames is clipped; toolbar wraps to two rows at 1024 and 1440, without cutting a button.
- The unrelated yellow banner ("This map declares no authority...") is not a validator error and does not cover the
  dock, the Check button or the gateway.

## Cited copies (this directory)
- t1212-check-1024-judge-t-1212-r5-claude-code-19c77ddc003b.png, t1212-check-1440-judge-t-1212-r5-claude-code-19c77ddc003b.png, t1212-check-1920-judge-t-1212-r5-claude-code-19c77ddc003b.png (byte copies of the originals)
- gateway-marker-1024-zoom-judge-t-1212-r5-claude-code-19c77ddc003b.png, gateway-marker-1440-zoom-judge-t-1212-r5-claude-code-19c77ddc003b.png, gateway-marker-1920-zoom-judge-t-1212-r5-claude-code-19c77ddc003b.png (4x crops of the map)

## Limits
I judged the recorded screenshots, as the criterion's steps say. I did not re-run the designer or re-take the shots, so
I do not vouch independently that they were produced the way step 1 describes, beyond the visible v0.23.0 label, the
fixture's element names (agt_1_start, agt_2_end, agt_1_gate) appearing on the map, and the rule id matching the fixture.

## Verdict
green — all three show the finding as a warning, with 0 errors, and nothing clipped.
