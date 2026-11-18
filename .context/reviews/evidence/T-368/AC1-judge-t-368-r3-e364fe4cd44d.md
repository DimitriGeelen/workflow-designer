# T-368 Human AC#1: "Decide whether to cut 0.9.0, and whether AEF should be told to re-pin"

Reviewed revision: d2328fde63d9f8241c49d6443bf5d6bf55a26207. Verdict: **amber** (Expected literal out of date; restatement proposed).

## What I ran

| check | command | result |
|---|---|---|
| manifest today | `grep ^latest dist/MANIFEST.yaml` | `latest: "0.43.0"` (not `0.9.0`) |
| 0.9.0 artifact | `ls -l dist/aef-workflow-designer-0.9.0.html` | present, 934239 B |
| its sha256 | `sha256sum dist/aef-workflow-designer-0.9.0.html` | `9ccd2c584e073bcd3702eb7efac5b0e5ec734b9ecabb572a3cff012083ff801a` |
| manifest at the release commit | `git show 8cd0c5d3d:dist/MANIFEST.yaml` | `latest: "0.9.0"`, `sha256: "9ccd2c58...f801a"`, `bytes: 934239`, equal to the file |
| tag | `git rev-list -n1 designer-v0.9.0` | `8cd0c5d3d5e6...` (T-393, 2026-08-08 21:05 +0200) |
| artifact unchanged since the cut | `git diff --stat 8cd0c5d3d d2328fde6 -- dist/aef-workflow-designer-0.9.0.html` | empty |
| T-311 fix present | `grep -c docComment` | 0.9.0: 5; 0.8.0: 0 |
| restatement from the earlier review | `grep T-368 .context/reviews/restatements.jsonl` | no row: neither accepted nor rejected; the criterion has no `**Restated:**` line |

## Findings

1. 0.9.0 was cut on 2026-08-08 under T-393 (`8cd0c5d3d`, tag `designer-v0.9.0`). At that commit the Expected clause held exactly: `latest:` read `0.9.0` and the manifest sha256 equalled the artifact's. The artifact is byte-identical today.
2. The Expected literal does not hold as written today: `dist/MANIFEST.yaml` `latest:` reads `0.43.0`. That is the out-of-date part, so green is not available on the criterion as written.
3. "A decision recorded": I found no record of the operator's decision to cut. T-368 has no entry under this criterion, and the task's own text says the cut is the operator's and "NOT attempted under agent control", while T-393's commit shows the cut was made the same day. The record shows the act, not the authorisation.
4. "AEF told to re-pin": T-393's commit message says the release was announced on the rail at offset 480, and T-512's commit (`2824e6b4f`) says "AEF is pinned to 0.9.0". Both are the producer's statements. I found no local copy of the rail to read, so I did not verify this part.
5. Nothing remains to decide: the release is published, tagged and superseded 34 times. A hold duration no longer applies.

## Why amber

The criterion's literal is out of date and the brief forbids green on what it probably meant. Escalating would ask the operator for a decision that has no options left. The operator can accept or reject the restatement, with finding 3 in view.

PROPOSED RESTATEMENT: [REVIEW] **0.9.0 was cut and AEF was told to re-pin.** `dist/aef-workflow-designer-0.9.0.html` exists, its sha256 equals the `sha256:` that `dist/MANIFEST.yaml` recorded at release commit `8cd0c5d3` (tag `designer-v0.9.0`), and the artifact is byte-unchanged since that commit.
The evidence above meets the cut part of this restatement. "AEF was told" rests on the producer's commit messages (rail offset 480; T-512's "AEF is pinned to 0.9.0"), which I could not check against the rail.
