# T-368 Human AC#1 — "Decide whether to cut 0.9.0, and whether AEF should be told to re-pin"

Reviewed revision: 49e8fe2777ddee255b26b43e7c708bb222e1b03c. Verdict: **amber** (literal out of date; restatement proposed).

## What I checked

| check | command | result |
|---|---|---|
| 0.9.0 artifact exists | `ls dist \| grep 0.9.0` | `dist/aef-workflow-designer-0.9.0.html`, 934239 B |
| its sha256 now | `sha256sum dist/aef-workflow-designer-0.9.0.html` | `9ccd2c584e073bcd3702eb7efac5b0e5ec734b9ecabb572a3cff012083ff801a` |
| manifest at the release commit | `git show 8cd0c5d3d:dist/MANIFEST.yaml` | `latest: "0.9.0"`, `sha256: "9ccd2c58…f801a"`, `bytes: 934239` — equal to the file |
| artifact untouched since the cut | `git diff --stat 8cd0c5d3d HEAD -- dist/…0.9.0.html dist/…0.8.0.html` | empty |
| tag | `git rev-list -n1 designer-v0.9.0` | `8cd0c5d3d5e6…` (the release commit, T-393, 2026-08-08 21:05 +0200) |
| the T-311 fix is in it | `grep -c docComment` | 0.9.0: 5, 0.8.0: 0 |
| manifest today | `grep latest dist/MANIFEST.yaml` | `latest: "0.43.0"` |

## Findings

1. The cut was made on 2026-08-08, the same day the criterion was written, under T-393 (commit `8cd0c5d3d`). At that commit the Expected clause held to the letter: `latest:` read `0.9.0` and the manifest sha equalled the artifact's.
2. The Expected literal no longer holds as written: `dist/MANIFEST.yaml` `latest:` reads `0.43.0` today, because 34 further releases followed. That is the out-of-date part.
3. "Tell AEF to re-pin": the T-393 commit message says the release was announced on the rail at offset 480, and the T-512 commit (2026-08-15) says "AEF is pinned to 0.9.0". Both are the producer's statements; I did not read the rail myself.
4. "A decision recorded": I found no record of the operator's decision as such. T-393 is `owner: agent`, its Decisions section is the empty template, `.context/episodic/T-393.yaml` records none, `decisions.yaml` has only PD-159/PD-160 (about the tag), and the 2026-08-08 handovers still list this criterion as open after the cut. T-368's own text says the cut "is NOT attempted under agent control". So the record shows the act, not who authorised it.
5. The question is no longer open in any practical sense: the release is published, tagged, consumed and superseded. Nothing remains to decide; there is no hold to give a duration for.

## Why amber, not green or escalate

The brief forbids green on what an out-of-date literal probably meant. The decision the criterion asked for cannot be made any more (the release is three months old), so escalating would ask the operator for a ruling that has no remaining options. What the operator can still do is accept or reject a restatement, and note finding 4 while doing so.

PROPOSED RESTATEMENT: 0.9.0 was cut and AEF told: `dist/aef-workflow-designer-0.9.0.html` exists, its sha256 equals the `sha256:` that `dist/MANIFEST.yaml` recorded at the release commit `8cd0c5d3` (tag `designer-v0.9.0`), and the artifact is byte-unchanged since that commit.
The evidence above meets this restatement, except that "AEF told" rests on the producer's commit messages (rail offset 480; T-512's "AEF is pinned to 0.9.0"), which I did not verify on the rail.
