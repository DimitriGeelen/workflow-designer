# T-851 — triage of the 14 red instruments

**Date:** 2026-09-25 · **Method:** each instrument run individually via the `--only` mode
added in T-850 (≈1s each instead of the 11-minute full sweep), actual output captured and
read, not inferred from the sweep's one-line `rc=1`.

## Headline

| | count |
|---|---|
| **DEAD GUARD** — the instrument is broken, so its subject's health is **unknown** | **6** |
| **REAL REGRESSION** — the instrument works and the thing it guards is actually broken | **8** |
| total | 14 |

**The sweep's own classification is wrong, and by a lot.** It reported `regressed 12,
dead-control 2`. The truth is 6 dead and 8 regressed, because the sweep's dead-control bucket
depends on each instrument *volunteering* exit code 4 (the T-666 convention). Four instruments
announce, in plain English in their own output, that their guard is broken — and exit 1 anyway:

- `_t542` raises `AttributeError` and never reaches a verdict
- `_t568` prints `FAIL control: unmutated source passes all four legs`
- `_t569` prints the same
- `_t574` prints `ABORT: … This probe can no longer test what it claims to test, and that is a
  failure, not a skip`

So the sweep counted four broken guards as regressions in the things they guard. **A
classification that depends on the classified party self-reporting honestly is not a
classification** — it is the same shape as the absence-assertion census before T-843, when the
detector was opt-in. Worth its own fix: the sweep could pattern-match these self-declarations,
or the four could adopt rc=4.

## The standout finding: `fw fabric validate` is a rubber stamp

`_t524` fails **9 of 10 legs**, and the reason is the same every time:

```
Deep validation not yet implemented — use 'fw fabric drift' for basic checks
rc=0
```

It returns **0 on every input**: a card with no `location:`, an unparseable card, two cards
claiming one id, an empty register. A shipped verb that certifies whatever you hand it. The
teeth are working perfectly; they have been reporting this into a sweep nobody ran.

This is the purest instance of the session's thesis — a check that cannot distinguish *passed*
from *did not look* — and it is worse than the others because it is not an internal probe but a
verb the framework offers its users. `_t524`'s own leg 1 notes this is "the exact card shape that
aborted update-task.sh in T-522 and lost two episodics; if it does not surface here, nothing
surfaces it."

## One of the twelve is mine, from today

`_t400-schema-teeth.sh` reports:

```
SCHEMA FAIL — 1 field name(s) nothing accounts for:
  - prevention_missing       (in 1 entry/entries)
```

`git log -S` puts it in `69908764` — **my own commit from this session**, in the G-080 entry I
appended to `concerns.yaml` under T-841. I invented a plausible-looking field name that no code
reads, which is precisely the G-027 shape the instrument exists to catch: *"the entry looks
complete and the tooling behaves as if it is empty."*

Two consequences worth stating. First, T-669's acceptance criteria record `_t400` as "cleared by
T-668" — that was **true when written**; I re-broke it hours ago. Second, this is the third time
today a guard I was not thinking about caught my own work within hours, after the absence gate
refused four of my legs and the mutation control set caught two hollow test cases. Position keeps
beating discipline.

## Full table

| instrument | rc | classification | deciding evidence | smallest next action |
|---|---|---|---|---|
| `_t524-fabric-validate-teeth.py` | 1 | **REAL REGRESSION** | `fw fabric validate` prints "Deep validation not yet implemented" and exits 0 for a location-less card, an unparseable card, duplicate ids, and an empty register | implement `do_validate()` in `.agentic-framework/agents/fabric/lib/drift.sh`, or make it refuse (rc 2) instead of certifying |
| `_t545-error-shape-teeth.py` | 1 | **REAL REGRESSION** (user-facing) | 403 on `/api/*` returns 66,746 bytes of full HTML against a 2,048 ceiling; toast extracts JavaScript source; no `HX-Error-Kind` header; boosted form posts get the whole document | the compact-403 fix never landed or regressed — 5 named findings, each specific |
| `_t400-schema-teeth.sh` | 1 | **REAL REGRESSION** (mine, today) | `prevention_missing` in the G-080 entry is read by no code | rename to a field the schema knows, or fold the text into `detail:` |
| `_t411-census-teeth.sh` | 1 | **REAL REGRESSION** | emitter drift: `learning.sh` no longer writes `application: TBD`, `resolve.sh` no longer writes `Apply when encountering similar`; MACHINE entries may now count as AUTHORED | re-pin the census's literals to what the emitters actually write |
| `_t535-trend-key-teeth.py` | 1 | **REAL REGRESSION** | the trend normaliser folds identifier tokens — 18 CTL-029 entries where 2 distinct keys were expected; visible in every audit's TREND ANALYSIS block | stop folding the task id when building the trend key |
| `_t371-audit-partition-teeth.sh` | 1 | **REAL REGRESSION** | ABSENT and PRESENT-WITHOUT produce identical output; "two or more states produced identical output — still collapsed". The guard's pre-fix control reproduces correctly | restore the per-state message in the C-002 partition |
| `_t547-hx-prompt-decode-teeth.py` | 1 | **REAL REGRESSION** | 2 sites read the `HX-Prompt` header directly (lines 760, 934); exactly one is expected | route the second site through `_hx_prompt()` |
| `_t550-audit-parse-anchor-teeth.py` | 1 | **REAL REGRESSION** (caveat) | 4/5 legs pass; leg 5 says the live audit still emits the old finding shape. Caveat: leg 5 greps **live audit output**, which is the mutable-corpus anchor T-3326 warns against, so it may red for corpus reasons | confirm against a fixture before treating leg 5 as a subject defect |
| `_t542-cost-blast-radius-teeth.py` | 1 | **DEAD GUARD** | `AttributeError: module 'aef_bvp_estimator' has no attribute '_BODY_PATH_RE'` — raises instead of measuring | find the attribute's current name (or its deletion) and update the probe; adopt rc=4 |
| `_t568-fabric-card-cache-teeth.sh` | 1 | **DEAD GUARD** | `FAIL control: unmutated source passes all four legs — failing: edit=FAIL` — its own control is red, so nothing below it proves anything | fix the control leg first; exit 4, not 1 |
| `_t569-card-purpose-markdown-teeth.py` | 1 | **DEAD GUARD** | same shape: `control: unmutated source passes all four legs — failing: {'anchor': 'FAIL', 'taskref': 'FAIL'}` | as above |
| `_t574-p011-block-locator-teeth.py` | 1 | **DEAD GUARD** | `ABORT: the T-574 exact-heading locator is GONE from update-task.sh` — the probe declares it can no longer test its claim | decide whether the locator's removal was intended; if so retire the probe, if not restore it |
| `_t534-d2-queue-tier-teeth.py` | 4 | **DEAD GUARD** (correctly signalled) | `TEETH BROKEN — audit.sh no longer composes a line starting d2_msg="D2: Human review queue` | re-anchor to the current message, or assert structure rather than a sentence |
| `_t585-census-teeth.sh` | 4 | **DEAD GUARD** (correctly signalled) | `TEETH BROKEN: an unmutated copy of the census exits 2, not 0` — and it says every leg would be satisfied by a non-zero exit alone, so it refuses to run them | find why the unmutated census refuses |

## What the split means

**8 real regressions is the serious half.** These are not tooling debt: `fw fabric validate`
certifies anything, a 403 handler ships a 66KB HTML document to fragment clients and leaks
JavaScript into a toast, and every audit's trend block has been folding distinct findings
together. All of it measured, named and precise — and all of it sitting in an instrument suite
nobody could afford to run.

**6 dead guards mean 6 subjects whose health is currently unknown**, which is not the same as
healthy. Repairing those does not fix anything; it restores the ability to find out.

## Deliberately not done here

No instrument is fixed under this task — one bug, one task. The four that hide behind rc=1
(`_t542`, `_t568`, `_t569`, `_t574`) and the sweep's dependence on self-reported exit codes are a
distinct defect from any of the fourteen, and the biggest single item is `fw fabric validate`,
which is a framework verb and not a probe at all.
