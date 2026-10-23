# T-1285 — Quality engine: what makes a designer change reach AEF right first time

**Status:** exploration (inception). Nothing is built before the operator's go/no-go.
**Question:** which few structural changes to how 832 builds, checks and ships would make a designer change reach
AEF in one pass?

## Why this exists

On 2026-10-23 the operator said: "what do we need to do to improve our quality? We keep f***ing around, reading
around the bush, we're still not really getting good runs. ... Structurally, it's about improving the engine." The
goal is fixed (CLAUDE.md, 2026-10-17): the designer is AEF's base, and a change is done only when AEF serves it.

## Evidence so far (one day, 2026-10-22/23)

| Loop | What happened | Caught by | Could the engine have caught it first? |
|---|---|---|---|
| T-1241 round 1 → T-1274 | flow label reads as one run with a gateway name | codex reviewer | yes: nearness of labels on the rendered SVG |
| T-1241 round 2 → T-1276 | two task names ellipsized | codex reviewer | yes: count fit-ladder floor hits |
| T-1241 round 3 → T-1277 | captions on arrowheads | codex reviewer | yes, IF the check had modelled arrowheads (it treated flows as zero-width lines) |
| T-1241 round 4 → T-1278 | 9 px text, Name field cut, palette wording, contrast | codex advisory sweep | mostly yes (size, clipping, contrast); wording no |
| suite run 2 | `_t910` mutant left in src and a fixture | the agent, after the fact | yes: kill-safety of mutation scripts (now T-1273) |
| suite runs 1–4 | 8 / 3 / 6 / 1 reds, almost all environment, stale anchors or census drift | manual triage each run | yes: a hermetic core suite plus quarantine |
| 0.25.0 release | commit subject copied from 0.24.0 | the agent, after push | yes: derive the subject from the notes (learning, now done in 082/083) |
| 0.26.0 job 082 | GLM-5.3 false finding on the clean map; our validator's identical warning text contributed | the release gate | partly: a quote-checker on findings (IW-5); the text fix is T-1284 |
| AEF parity | 4 of 13 designer endpoints absent in AEF, unnoticed for months | the operator's question | yes: a generated contract diffed against AEF's server code |
| framework upgrades | 37 local patches re-applied each time, 5 conflicts in one upgrade | manual re-vendor | partly: upstreaming the patches removes the work |

## Spikes

Results are filled in below as they land.

### Spike 1 — rework census, 30 days (IW-1)
_pending_

### Spike 2 — suite-red classification, last 10 runs (IW-2)
_pending_

### Spike 3 — reviewer findings a deterministic check could have caught (IW-3)
_pending_

### Spike 4 — generated designer-to-host contract vs AEF's server (IW-4)
_pending_

### Spike 5 — verifiable reviewer findings (IW-5)
_pending_

## Candidate changes (to be ranked by the spikes)

1. A "what a person sees" gate on every corpus map at 1024/1440/1920 in the opening state, run before any review.
2. A hermetic core suite that must be 100% green on every push, plus a quarantine set with owners.
3. A designer-to-host contract file generated from source and checked against AEF on every release and upgrade.
4. Verifiable release findings (file:line + quote check), with calibration at kit-change time.
5. Upstreaming 832's local framework patches; framework tags taken in batches.

## Dialogue Log

- 2026-10-23, operator: "what do we need to do to improve our quality? ... Structurally, it's about improving the
  engine." Agent proposed five changes and an inception. Operator: "stay busy" while release job 083 runs. The agent
  started this inception (DEFER until the spikes land).
