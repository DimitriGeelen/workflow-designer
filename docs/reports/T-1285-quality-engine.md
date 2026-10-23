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

### Spike 2 — suite-red classification (IW-2) — first pass 2026-10-24, 5 runs

Each red leg was triaged by hand in the runs below. The three 2026-10-23 runs (logs
`.context/working/t1275-suite.log`, `t1279-suite.log`, `t1280-suite.log`) are classified per leg. The two
2026-10-22 runs are classified from the session record, since their logs sat in the pre-remount /tmp.

| Run | Result | Red legs and cause |
|---|---|---|
| 10-22 #1 (pre-release) | 305/8 | 2 expected-by-design (0.25.0 dist and calibration record not yet cut) · load timeouts · mutant contamination |
| 10-22 #2 | 305/8 | same pre-release pair · load timeouts · `_t910` mutant left in src and a fixture (kill-unsafe teeth, T-1273) |
| 10-23 be.3 | 310/3 | G-015 hygiene: a Verification line I wrote (process) · instrument sweep `_t572`/`_t1060` under load (environment) · `_t629` anchor after the be.3 upgrade (upgrade drift) |
| 10-23 be.5 | 307/6 | `_t1068`, `_t604`: Chromium socket path over 108 chars from my TMPDIR (environment, self-inflicted) · unwired-guard census 89→92 after task closes (bookkeeping drift) · sweep `_t910` under load (environment) · `_t634` second call site from be.5 (upgrade drift) · `_t598` counted a read as an application after T-1277 (guard too literal) |
| 10-23 be.8 | 315/1 | `_t568` create/delete inside one tmpfs mtime tick (environment) |

**Tally over the three per-leg runs (10 reds):**
- product regressions: **0**;
- environment (load, /tmp tmpfs, TMPDIR): **5**;
- upgrade drift (a guard anchored on vendored framework text): **2**;
- guard too literal / bookkeeping drift: **2**;
- process (a line I wrote): **1**.

**Answer to IW-2, first pass:** in these runs the suite caught **no product regression**, but every run was red, and
each red cost a manual investigation. The reds are dominated by environment and drift, the two things a hermetic
core suite with a quarantine set removes from the "must be green" signal. That supports candidate 2. A 10-run pass
(spike 2 proper) would firm up the ratio; the direction is already clear.

### Spike 3 — reviewer findings a deterministic check could have caught (IW-3)
_pending_

### Spike 4 — generated designer-to-host contract vs AEF's server (IW-4) — done 2026-10-24

A throwaway script (`.context/working/t1285/contract.py`, ~30 lines) extracts every `/api/...` path from
`src/aef-workflow-designer.html` and every route from AEF's Watchtower code at a given commit, and diffs them. Against
AEF be.8 (pristine 2f87fdb1) it reproduces the manual 2026-10-23 result exactly: 13 used, 9 served, 4 missing.

| Missing in AEF | Feature | In the designer since | Undetected for |
|---|---|---|---|
| `/api/instances` | instance overlay (T-884) | 2026-09-29 | 25 days |
| `/api/validate` | Check (T-961/T-962) | 2026-10-01 | 23 days |
| `/api/field-profile` | project field profile (T-1125) | 2026-10-11 | 13 days |
| `/api/field-suggestions` | Suggest as a field (T-1126) | 2026-10-11 | 13 days |

**Answer to IW-4:** yes. The contract is cheaply generated from source and checkable against AEF's code with no
access to AEF's running server. Run at release time it would have flagged each gap the day the feature shipped. Every
release since 0.15 has gone to AEF without these four.
**Limits:** it compares paths, not methods or payloads (a route can exist and still differ in contract), and it
reads the vendored copy, so it is only as current as our last framework upgrade.

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
