# T-732 Human AC#1 (H1) — reviewer evidence

Revision reviewed: af3a1d1c2fe90cdcca6302fe06e6e8cef7f4837b (HEAD at review; operator-decisions.yaml has no uncommitted diff)

## Checked
1. `docs/reports/T-732-h-register-dossier.md`: read. Its 2026-10-18 currency note says H1 was RESOLVED by the operator on 2026-09-21 (the DEFERs and the NO-GO stand).
2. `docs/research/executable-workflow/operator-decisions.yaml` lines 40-88, entry `id: H1`:
   - `status: resolved`, `decided_by: operator`, `decided_at: "2026-09-21"`
   - `chosen`: the DEFERs (T-279/280/281/282) and AEF's T-2669 NO-GO STAND; roadmap Arcs 4–6 do NOT supersede them.
   - `source_of_truth`: present (file = the register itself, path decisions[id=H1].chosen, with a note saying why no envelope exists).
   - `ruling_channel`: "Given verbally by the operator in session on 2026-09-21 ... NOT a Watchtower tick. T-732's Human AC for H1 ... is the operator's to tick ... If the two ever disagree, the tick wins — an agent transcribing a conversation is a weaker witness than the operator's own signature."
3. `git log -S` finds the commit that brought this in: 22014fea (2026-09-21, "T-732: H1 ruled by the operator"). The author identity is the operator's git identity, but agent commits in this repo use the same identity. So the commit does not prove who ruled.
4. GET http://192.168.10.107:3013/approvals returned HTTP 200, and the page mentions T-732 (its approval is still pending). I fetched it with curl. I did not view it in a browser and took no screenshot.

## Finding
The mechanical part of **Expected** is met: H1 is `status: resolved` and has a `source_of_truth`.

The criterion's question is still a sovereignty call (the register says: "Reversing a recorded disposition is a sovereignty act"). The only record that the operator ruled is an agent's transcription of a verbal ruling. The register itself says that record is weaker than the operator's own tick, and that the tick is the operator's to make. If a reviewer turned this green, the reviewer's signature would stand in for the operator's on a sovereignty act. The operator's T-1213 ruling keeps exactly that kind of decision for the human.

Verdict: escalate. The operator should tick the H1 AC on /approvals, which confirms the 2026-09-21 verbal ruling through the instrument. Or, if the transcription is wrong, they should correct it.
