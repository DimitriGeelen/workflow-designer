# Reviewer evidence — T-893 AC#1

- dispatch: `judge-t-893-r5-opencode-65e16cf61e4c`
- worker kind: `opencode` (vendor `zai`, model `zai-coding-plan/glm-5.3`)
- seat: `opencode`
- reviewed revision: `c7822ac5108b9b55e2bf47bf562e959f2f9f34f0`
- recorded by: the dispatch runtime on the worker's behalf (T-3582)
- result.jsonl sha256: `502cf548965a135989226ed8a0256984988dc341580413e4ab0a5e3e465a9bc0`
- result.md sha256: `98504532726b7ebe2fdc72f84b5eae05986f8c89ccebdb23debdf30bbb69a6c0`

## The worker's verdict block

```
1. [AC] Authority markers read as different kinds; common case silent (differs subtle vs missing loud)
VERDICT: not-evaluated
WHY: The shot pipeline ran cleanly in scratch (exit 0; L1/L2/L3 PASS; 9 PNGs byte-identical to the committed set) and every mechanical literal verified in the live DOM: none has no marker; differs renders faint-gray (#5a6173) normal-weight mono "◆ ini" above the shape's top-left; missing renders orange (#f5a847) bold "⚠ no auth" (longest fitting form, full text on hover) — two clearly different treatments. But this seat cannot view images (model does not support image input), and the criterion states its asked-for judgment is whether the subtle/loud contrast is RIGHT — taste, not geometry. I did not see the shots, so I cannot make that call, and per T-3986 I return not-evaluated rather than a false amber/red. One stale literal found: the parenthetical claims missing-m.png shows an edge label just above the marker; at this revision no edge label falls inside any -m clip (nearest, "re-check"/"placeholder ACs", sit in the same vertical band but horizontally outside the 24px-padded clip).
GUIDANCE: Route to a vision-capable reviewer, who should open differs-m/missing-m/none-m.png side by side and judge the pitch; they should specifically weigh whether the missing marker still "reads as a defect" given its luminance contrast (~2:1 on light background) is lower than the differs marker's (~6:1 on white / 2.84:1 on surface) — its loudness is hue+weight only. All mechanical prerequisites are confirmed, so only the taste call remains.
PROPOSED RESTATEMENT: The two markers read as different KINDS of thing, and the common case is silent. Steps: 1. cd /opt/832-Workflow-designer && node tools/_t893-authority-marker-shots.mjs (isolated headless Chromium; writes 9 PNGs to docs/reports/t893-shots/) 2. Open docs/reports/t893-shots/differs-m.png, missing-m.png, none-m.png side by side. Expected: none-m shows no marker; differs-m shows a faint mono "◆ ini" above the node that reads as an annotation, not an alarm; missing-m shows an orange "⚠ no auth" that reads as a defect (longest form fitting left of the shape's top-centre, full text on hover). The judgment asked for is whether the subtle/loud contrast is RIGHT, which is taste, not geometry. If not: name which of the two markers is mis-pitched (too loud / too quiet); note the marker sits above the shape's top-left and at this revision no edge label falls inside the -m clips (nearest labels share its vertical band but sit horizontally outside), so judge crowding on your own maps rather than this shot.
Evidence against the restatement: all its mechanical literals are verified as above; only the taste judgment is outstanding and needs a reviewer that can see the PNGs.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```

## The worker's full output (result.md)

```
The export contains both the shot script and pre-existing PNGs. To review independently, I'll read the script, then run it in a copy under my scratch space.
The script serves a fixture of `src/aef-workflow-designer.html` in headless Chromium and screenshots three nodes (`none`=frw_1_start, `differs`=frw_2_enter, `missing`=agt_2_perform) at three label sizes. I'll run it in a scratch copy, leaving the export untouched.
Prerequisites are present. Copying the export to scratch and running the shot script there:
Exit 0, all legs pass (L1 counts, L2 no-mutation, L3 9/9 clear shots). Now comparing my fresh PNGs to the committed ones and viewing the three `-m` shots:
Byte-identical to the committed shots — reproducible. Viewing the three medium-size shots:
The image reads failed — this seat's model does not support image input, so I cannot visually inspect the shots. Before deciding, I'll extract everything checkable programmatically: the marker implementation in source, and DOM-level facts via the page itself.
Implementation matches the described forms and hover titles. Now the CSS pitch of the two classes and the abbreviation map:
CSS confirms the designed pitch: `differs` = faint fill, normal weight; `missing` = orange, bold (600). Checking the color variables, then pixel-analyzing my fresh PNGs to confirm what actually rendered:
Pixel heuristics on full-node clips are noisy (the node's own icon/fill is warm-colored). Direct DOM evidence via the live page is precise — I'll write a small CDP driver in scratch, reusing the repo's own helpers, to report exactly what rendered for each marker: text, computed color/weight, position relative to the shape, hover title, and any edge label overlapping. First, how edge labels are classed:
Edge labels are `text.edge-label`. Writing a scratch CDP driver (outside the export) that reuses the repo's own helpers to interrogate the live page:
File writes outside the sanctioned plan paths are denied; I'll feed the driver to node via stdin instead (no files written outside scratch/tmp):
Precise DOM facts confirmed. One more targeted pass: does any edge label actually sit in the `missing-m` clip (the criterion's parenthetical claims one just above the marker), and what forms render at sizes s/l:
All mechanical facts hold at every size. The criterion's parenthetical claims an edge label sits just above the marker in `missing-m.png`, yet no edge label fell in my ±24px probe — one wider probe (45px band ≈ full clip height) to settle whether that literal is stale:
All checks are complete. The export was never modified (everything ran in `$TMPDIR/run`; the committed PNGs still md5-match my fresh render). Printing the record:

---

**Evidence summary (what I ran and found)**

- Ran the criterion's step 1 in a scratch copy (`cp -a . $TMPDIR/run`, script there, not in place): `node tools/_t893-authority-marker-shots.mjs` → **exit 0**, `L1 PASS` (per size: differs=1, missing=3 = all 3 agent-lane nodes), `L2 PASS` (buildBpmnXml 22736 bytes, unchanged), `L3 PASS` (9/9 shots show their node), 9 PNGs written. My 9 PNGs are **byte-identical (md5)** to the committed `docs/reports/t893-shots/` set — the shots are reproducible.
- **I could not visually open the three `-m` PNGs: this seat's model does not support image input** (Read of the images returned "Cannot read image"). The criterion's asked-for judgment — whether the subtle/loud contrast *reads* right, which it itself calls "taste, not geometry" — I therefore cannot make, and I will not vote on what I did not see (T-3986).
- What I could verify mechanically, from the live page in my own isolated headless Chromium (CDP, reusing the repo's `tools/_cdp-*.mjs` helpers), all matches the Expected literals:
  - `none` (frw_1_start): **no marker element at all** (`marker: null`) — common case silent.
  - `differs` (frw_2_enter): text **"◆ ini"** (`AUTHORITY_ABBR.initiative='ini'`), fill `rgb(90,97,115)` = `--text-faint` (muted slate), font-weight **400**, 8px mono, sits above the shape (gap ~1px), starts 2px from left edge, ends at 26.9px — left of top-centre (55px); full text on hover `<title>` "authority: initiative (differs from the lane default)". Annotation-pitched by construction: neutral hue, normal weight.
  - `missing` (agt_2_perform): text **"⚠ no auth"** (longest of `['⚠ no authority','⚠ no auth','⚠']` fitting `def.w/2-9` = 46px; verified identical at sizes s/m/l), fill `rgb(245,168,71)` = `--orange`, font-weight **600** (bold), 8px mono, above the shape, ends at 45.4px < centre; hover `<title>` "no authority — this element has none and its lane offers no default". Alarm-pitched by construction: saturated hue + bold.
  - CSS at src/aef-workflow-designer.html:717-718 and marker code at 4541-4570 confirm the two-class design.
  - Position/collision: no edge label falls inside any of the `-m` clip regions — the only foreign text in the missing clip is the node's own id badge below the shape. Nearest edge labels ("re-check" dy≈+6.5px, "placeholder ACs" dy≈-14.5px) share the marker's vertical band but sit **horizontally outside** the 24px-padded clip. So the criterion's parenthetical ("missing-m.png shows an edge label sitting just above it") is **stale for this revision** — consistent with the T-1069 fix described at src/aef-workflow-designer.html:4544-4548 (marker now constrained left of top-centre; "104 crossings on the corpus" fixed).
  - One quantitative flag for the vision-capable reviewer: on a light background the orange missing marker has materially **lower luminance contrast (~2:1)** than the gray differs marker (~6:1 on white; the app's own CSS comment at line 149 measures `--text-faint` at 2.84:1 on the surface). Its loudness rests on hue + bold, not darkness — whether "⚠ no auth" at that contrast still "reads as a defect" is exactly the taste call I cannot make.

---

1. [AC] Authority markers read as different kinds; common case silent (differs subtle vs missing loud)
VERDICT: not-evaluated
WHY: The shot pipeline ran cleanly in scratch (exit 0; L1/L2/L3 PASS; 9 PNGs byte-identical to the committed set) and every mechanical literal verified in the live DOM: none has no marker; differs renders faint-gray (#5a6173) normal-weight mono "◆ ini" above the shape's top-left; missing renders orange (#f5a847) bold "⚠ no auth" (longest fitting form, full text on hover) — two clearly different treatments. But this seat cannot view images (model does not support image input), and the criterion states its asked-for judgment is whether the subtle/loud contrast is RIGHT — taste, not geometry. I did not see the shots, so I cannot make that call, and per T-3986 I return not-evaluated rather than a false amber/red. One stale literal found: the parenthetical claims missing-m.png shows an edge label just above the marker; at this revision no edge label falls inside any -m clip (nearest, "re-check"/"placeholder ACs", sit in the same vertical band but horizontally outside the 24px-padded clip).
GUIDANCE: Route to a vision-capable reviewer, who should open differs-m/missing-m/none-m.png side by side and judge the pitch; they should specifically weigh whether the missing marker still "reads as a defect" given its luminance contrast (~2:1 on light background) is lower than the differs marker's (~6:1 on white / 2.84:1 on surface) — its loudness is hue+weight only. All mechanical prerequisites are confirmed, so only the taste call remains.
PROPOSED RESTATEMENT: The two markers read as different KINDS of thing, and the common case is silent. Steps: 1. `cd /opt/832-Workflow-designer && node tools/_t893-authority-marker-shots.mjs` (isolated headless Chromium; writes 9 PNGs to `docs/reports/t893-shots/`) 2. Open `docs/reports/t893-shots/differs-m.png`, `missing-m.png`, `none-m.png` side by side. Expected: `none-m` shows no marker; `differs-m` shows a faint mono "◆ ini" above the node that reads as an annotation, not an alarm; `missing-m` shows an orange "⚠ no auth" that reads as a defect (longest form fitting left of the shape's top-centre, full text on hover). The judgment asked for is whether the subtle/loud contrast is RIGHT, which is taste, not geometry. If not: name which of the two markers is mis-pitched (too loud / too quiet); note the marker sits above the shape's top-left and at this revision no edge label falls inside the -m clips (nearest labels share its vertical band but sit horizontally outside), so judge crowding on your own maps rather than this shot.
Evidence against the restatement: all its mechanical literals are verified as above; only the taste judgment is outstanding and needs a reviewer that can see the PNGs.

Summary: 0 green, 0 amber, 0 red, 0 escalate, 1 not-evaluated
```
