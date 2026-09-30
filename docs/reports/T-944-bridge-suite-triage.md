# T-944 — triage of the standing failures in `tests/run-bridge-tests.sh`

**Date:** 2026-09-30 · **Task:** T-944 · **Status:** reconciled against a completed full run

---

## Correction: the failure count was 16 because I read an incomplete run

**A completed full run reports `bridge round-trip: 122 passed, 32 failed`.** Not 20, and not the
16 I was asked to triage.

Where "20" came from: the earlier run I read had been launched with a timeout and I read its log
while it was still inside the T-509 instrument sweep — roughly 1066 lines into a ~1500-line run.
Everything after that section had not executed yet. I counted the FAIL lines present, got 20,
subtracted the 4 disposed that day and reported "16 remaining" as a total. It was a partial count
stated as a complete one, which is the second unmeasured number I have asserted today.

The corrected accounting: **32 failing legs now**, after 4 were fixed on 2026-09-30, so **36 were
failing before that work**. Sixteen of the 32 were never in my earlier reading at all — they sit
past the point where the log I read stopped. They are triaged below and none of them changes the
headline.

## The headline is not the suite

I was asked to sort the failing legs into real defects, stale expectations and backlog. Doing it
surfaced something larger, and it changes what the triage is for.

**One commit — `7b5e227e`, "T-840: upgraded to AEF bleeding-edge 1.7.68", 2026-09-25 — reverted at
least four local fixes, and in the same commit removed the audit rail that would have reported it.**

The upgrade's own subject line already admits one regression ("*and it REGRESSED the mandated commit
spelling*"). Nobody looked for a second. There were at least five.

### What it reverted, measured by occurrence count

| local fix | file | evidence | status |
|---|---|---|---|
| **T-574** exact-heading refusal for the P-011 gate | `agents/task-create/update-task.sh` | `_v_exact`, `_v_why`, `COULD NOT READ THE BLOCK` → **0 occurrences** | **fixed 2026-09-30 (T-943)** |
| **T-568** fabric card cache keyed on content sha256 | `web/blueprints/fabric.py` | `sha256`/`hashlib` → **0**; line 33 is back to `os.stat(COMP_DIR).st_mtime`, the exact defective expression T-568 replaced | **LIVE DEFECT** |
| **T-569** card purpose rendered through `render_markdown_safe` | `web/blueprints/fabric.py` | `purpose_html`/`render_markdown_safe` → **0** | **LIVE DEFECT** |
| **T-657** audit delivery surface for the divergence guard | `agents/audit/audit.sh` | the `# T-657: give the vendored-divergence guard a delivery surface.` region → **gone** | **LIVE — and it is the reason the rest went unseen** |
| **T-557** `fw note` refusal wording | `agents/observe/observe.sh` | `Nothing was written` → **0 occurrences** | **NOT a loss — see below** |

### The two live defects, in user terms

**T-568.** `_load_components()` caches on the *directory's* mtime while caching the *contents* of
files inside it. POSIX does not move a directory's mtime when a file already in it is written. So
`fw fabric register` (creates a file) invalidates correctly and **`fw fabric enrich` (rewrites cards
in place) never does** — the page serves the pre-enrichment card for the life of the process, at
HTTP 200, with no warning and no log line. T-568's own commit records the sting: *our audit prints
"Mitigation: Run: fw fabric enrich" under Priority Actions on every run*, so the framework routes
operators at the invisible half. It printed that again this morning.

**T-569.** A card's `purpose` is emitted autoescaped, so a markdown link written into a card comes
out as literal text. The T-569 commit also records that the fix closed an `ImportError` branch in
`render_markdown_safe` which returned **raw text** while instructing every caller to mark the result
`| safe` — *"latent here (markdown2 present) and an injection on any host where it is not."*
Reverting the fix restores that branch.

Both were reported by a peer project (**001-CashWeb-Lightspeed-Ecwid-integration**) who had lost a
diagnosis to T-568 and rated it above their own longer-waiting request. **Their fixes are gone and
they have probably not been told.**

### T-557 is the one that is *not* a loss — recording it because I pitched it as one

The failing leg says *"guard reverted in the vendored .agentic-framework, or a re-vendor overwrote
it"*, and I cited it to the operator as a second instance of T-943's class. It is the same commit,
but the outcome is different: upstream ships its own refusal, and it is **arguably better than
ours** — it names the discarded payload, shows the correct invocation and lists the real sub-verbs.
What it does not contain is the literal string `Nothing was written`, which is all leg 3 tests.

Leg 1 already asserts the *behaviour* (no husk reaches the inbox) and **passes**. So the property is
verified and the expectation is stale. Disposition: broaden leg 3 to accept an equivalent
statement, keep leg 1 as the real guarantee, and ask AEF to add the explicit line.

---

## The chain that let all of this sit for five days

This is four deep, and every layer exists and works:

1. **The fixes** were reverted by the upgrade.
2. **The detector exists and fires.** `tools/_t517-vendor-divergence.py` reports, verbatim:
   `STALE [content] .agentic-framework/web/blueprints/fabric.py — declared as diverged but matches
   the baseline now — adopted upstream, or the local fix was lost.`
   It names **11 stale declarations** and exits non-zero. It is *right*, and it states the exact
   ambiguity a reader needs.
3. **The detector reports only into the unscheduled suite.** `_t517` is referenced **0 times** in
   `audit.sh`, and this morning's audit YAML contains **no occurrence of "diverg"** — so it never
   reaches the surface that runs on cron every 15 minutes.
   **Correction:** I first wrote "the detector runs nowhere". It is wired into
   `tests/run-bridge-tests.sh` (6 references) and **is** one of the 32 failing legs there, #19:
   *"vendored framework divergence no longer matches .vendor-divergence.yaml"*. So it runs — in the
   one place nothing schedules. That is a weaker claim than I made and the more useful one, because
   it means the fix is a delivery surface, not a new detector.
4. **The guard for layer 3 cannot even measure, and nothing runs it.**
   `tools/_t657-vendor-divergence-must-reach-an-audit-line.sh` exits **rc=3**:
   `COULD-NOT-MEASURE: the T-657 region was not found in audit.sh` — because the upgrade removed
   the region it looks for. And `grep -c _t657 tests/run-bridge-tests.sh` → **0**, so nothing runs
   the guard that checks the surface that carries the detector that watches the fixes.

The detail that makes this a pattern rather than an accident is in T-657's own commit message:
*"the divergence guard was priced at its host — 13 minutes for a 300ms check, so it ran nowhere and
was right twice into the void."* **This exact problem was already diagnosed and fixed once. The
upgrade undid the fix.**

`rc=3 / COULD-NOT-MEASURE` is the same shape as the `ABORT` that T-943 found: an instrument
correctly refusing to claim a pass it cannot justify, in a place no one is looking.

---

## Blast radius of the upgrade

Measured over `7b5e227e` against all prior non-upgrade commits touching `.agentic-framework/`:

| | |
|---|---|
| files the upgrade changed under `.agentic-framework/` | **1407** |
| of those, files carrying ≥1 prior **local** commit | **545** |
| local commits landed on those files | **657** |

Overwriting a locally-modified file is not automatically a revert — upstream may have adopted the
change, which is why `_t517`'s wording is *"adopted upstream, or the local fix was lost"* and not a
verdict. But **every one of the 545 is at risk, and the four confirmed reverts are all from the small
subset that happened to have a teeth probe pointed at them.** There is no reason to think the probes
covered the worst of it.

Most locally-modified files the upgrade overwrote:

```
 17 local commit(s)  agents/audit/audit.sh
 13 local commit(s)  agents/context/lib/safe-commands.sh
 12 local commit(s)  agents/task-create/update-task.sh
 11 local commit(s)  agents/context/check-active-task.sh
  7 local commit(s)  web/test_safe_commands.py
  6 local commit(s)  agents/task-create/create-task.sh
  4 local commit(s)  bin/fw
  4 local commit(s)  web/shared.py
  3 local commit(s)  agents/observe/observe.sh
```

**Note what the top two entries mean for today's work.** T-941 added an audit rail to `audit.sh`
(17 local commits) and T-943 fixed `update-task.sh` (12). Both are on this list. **The next upgrade
will revert them**, by exactly the mechanism documented above, unless either AEF adopts them or this
project gains a working divergence surface.

---

## Per-leg triage

Classification axis, per T-943's lesson: a probe whose **control** fails has an *unverified property*;
a probe whose control passes and whose **mutation leg** fails has a *verified property with partial
teeth*. These are different severities and I conflated them once already this session.

| leg | class | evidence | disposition |
|---|---|---|---|
| T-568 fabric card cache | **control fails → property UNVERIFIED, live defect** | control leg `edit` FAIL: *in-place edit, directory mtime pinned → 'the original purpose'*; `sha256` absent from `fabric.py` | **Restore the fix.** File a task; re-declare divergence |
| T-569 card purpose markdown | **control fails → property UNVERIFIED, live defect** | control legs `anchor` + `taskref` FAIL; `purpose_html` absent | **Restore the fix**, including the ImportError branch |
| T-557 `fw note` payload | stale expectation | leg 1 passes (no husk written); leg 3 pins our wording, upstream ships an equivalent refusal | Broaden leg 3; ask AEF for the explicit line |
| T-570 meta-carriage teeth | mutation-leg fails → property verified | control PASSES 8 legs; mutant D anchor `'horizon', 'workflowType', 'owner'];` absent | Re-anchor mutant D |
| T-572 bridge-vocabulary teeth | mutation-leg fails → property verified | control PASSES 6 legs; mutant B anchor absent; key count drift 8 wanted / 7 observed | Re-anchor + reconcile the count |
| T-574 P-011 locator | **FIXED 2026-09-30** | 13/13 | done (T-943) |
| designer export contract | **FIXED 2026-09-30** | rc=0 | done (T-942) |
| designer owner-derived | **FIXED 2026-09-30** | rc=0 | done (T-942) |
| T-316 runner orphans | **FIXED 2026-09-30** | 47 collectable, all invoked | done (T-942) |
| release immutability (G-007) | broken probe | `FileNotFoundError: /tmp/.../dist/aef-workflow-designer-0.1.0.html` — the probe's own fixture build is missing | Investigate as a probe defect, not a release defect |
| rule-form parity (T-320) | real, needs a decision | `E-META-AUTHORITY` emitted by the validator, no parity classification | Classify PAIRED / OUT_OF_SCOPE / GAP |
| cross-form agreement (T-328) | real | NEW DISAGREEMENT `E-NODE-LANE`: yaml fires=True, xml fires=False | Investigate; the two implementations disagree |
| check-pass reachability (T-333) | real | 4 rules fire on no corpus doc and no fixture, undeclared | Add fixtures or declare, with reasons |
| finding anchorability (T-335) | real | 4 XmlValidator rule ids unclassified in ANCHOR | Classify |
| unwired-guard ratchet (T-451) | ratchet grown | baseline 64, current 143, **GREW by 86**; also 7 stale baseline entries | Needs its own sitting; do not re-baseline silently |
| G-015 hygiene ratchet (T-508) | ratchet grown | a new carrier appeared; 1 baseline entry now clean (`--tighten` available) | Tighten the 1; triage the new carrier |
| T-509 instrument sweep | regression | an instrument that passed 2026-08-15 no longer does | Fold into the re-vendor sweep below |
| T-821 swallowed-failure census | real | a bare catch appeared, or an excuse's site count moved | Needs its own look |
| T-358 third-party byteid | fixture drift | a third-party document's recorded bytes changed | Re-record deliberately, or find the drift |

### The sixteen legs past where my earlier log stopped

These were never in the "16" I was asked to triage — they sit after the point the truncated log
ended. Listed with what I established and, where I did not investigate, **that fact rather than a
guess**:

| # | leg | class | basis |
|---|---|---|---|
| 17 | Human AC invisible to the approvals queue | real | not individually investigated |
| 18 | **episodic decisions extractor regressed** | **re-vendor revert, confirmed** | `lib/extract-decisions.py` is on `_t517`'s stale list AND its guard fails — by the rule below, the local fix was lost, not adopted |
| 19 | **vendored divergence no longer matches the declaration** | **this is the detector itself** | `FAIL — 1349 unrecorded, 11 stale, 2 reclassified` |
| 20 | episodic memory can be lost silently (pipefail guard in `update-task.sh`) | suspected re-vendor revert | same file as T-574 (12 local commits, confirmed reverted once); **not individually confirmed** |
| 21 | malformed component cards undetected (`fw fabric validate`) | real | not individually investigated |
| 22 | fabric coverage warning stopped discriminating | real | not individually investigated |
| 23 | a suite leg discards its probe's output | real | not individually investigated |
| 24 | D2 review-queue line disagrees with its own threshold | real | not individually investigated |
| 25 | audit trend detector merges or drops controls | real | not individually investigated |
| 26 | a watching gap's closure gauge unreadable by `lib/gaps.py` | real | not individually investigated |
| 27 | a BVP driver is dead / vacuous / ungraded | real | not individually investigated |
| 28 | BVP cost axis collapsed to a flag | real | not individually investigated |
| 29 | operator `hx-prompt` rationale stored percent-encoded | real | not individually investigated |
| 30 | T-344 denominator guard reading the wrong audit line | real | not individually investigated |
| 31 | `_t525` fixture legs no longer detect a broken coverage check | real | not individually investigated |
| 32 | absence-assertion census stopped discriminating | probe stale, gate works | the T-843 gate it guards **refused one of my own verification lines today**, so the enforcement is live; the census probe is the part that drifted |

**The inference rule used above, stated so it can be checked:** a file on `_t517`'s stale list was
declared as carrying a local fix and now matches the upstream baseline. `_t517` correctly reports
that as ambiguous — *"adopted upstream, or the local fix was lost."* The ambiguity resolves when you
look at that fix's own guard: if the guard still passes, upstream adopted the behaviour; if the
guard fails, the fix is gone. That is how T-568, T-569 and the decisions extractor were classified
as losses, and how T-557 was classified as an adoption.

### `_t517`'s eleven stale declarations — the authoritative list

```
 1  agents/context/check-inception-schema.py
 2  agents/context/lib/extract-decisions.py        <- guard fails (#18) => LOST
 3  docs/spikes/T-586-loop-detect-ts/loop-detect.js
 4  lib/ts/dist/loop-detect.js
 5  web/blueprints/fabric.py                       <- guards fail (#9,#10) => LOST x2
 6  web/conftest.py
 7  web/templates/fabric_detail.html               <- part of T-569 => LOST
 8  web/test_app.py
 9  web/test_context_tokens.py
10  web/test_costs.py
11  web/test_safe_commands.py
```

`update-task.sh` and `observe.sh` are **not** on this list, and that is not reassuring — it is an
artefact of timing. `update-task.sh` diverges from baseline again because T-943 re-fixed it hours
ago; before today it would have been stale. The list shows the reverts **that have not yet been
re-fixed**, not all of them.

**Nothing in this report has been fixed by this task** — triage only, with one exception noted next.

### One thing was fixed: a regression of my own

The G-015 hygiene ratchet (#12) flagged a **new** carrier, and it was mine. T-942's verification
block contained:

```
test "$(grep -l 'CONSOLE_WHITELIST = (' tests/*.py | wc -l)" -eq 1
```

with a comment of mine claiming it "pins the INVARIANT rather than a corpus count". The ratchet
classified it `[population-pinned]` and was right: it counts a glob over `tests/*.py`, so it moves
when anyone else adds a test file. My comment asserting otherwise is precisely the self-issued
exemption that rule exists to refuse.

Replaced with four assertions naming the four files T-942 actually changed. What is **lost** is the
"no other file defines its own copy" guarantee — that belongs to a tree-wide ratchet, not to one
task's verification block, and saying so is better than keeping a line that claims a property it
does not have. Carrier count 43 → 42, carrier-files 114 → 113.

---

## Recommended dispositions, in order

1. **Restore T-568 and T-569.** Two live, user-visible defects, one carrying a latent injection
   path, both previously reported by a peer project. Cheapest confirmed win here.
2. **Give `_t517` a delivery surface again** — restore the T-657 audit region, and wire
   `_t657-...must-reach-an-audit-line.sh` into the suite so the surface's absence is itself
   reported. Without this, item 1 is temporary: `fabric.py` gets overwritten again.
3. **Tell AEF, and tell 001-CashWeb.** AEF already has the T-943 report at `aef-install-findings`
   @39 asking for upgrade-time detection of overwriting locally-modified files. This is the
   evidence for that ask: 545 files, 657 local commits, 4 confirmed reverts, one of them a
   security-relevant branch. CashWeb's two fixes are gone and they do not know.
4. **Then** decide about scheduling the suite. It remains the right idea and it is still not
   actionable while the reds are undifferentiated — but note that scheduling the *audit* is not the
   same problem: the audit already runs on cron, and the fix in item 2 routes this class there.
5. Re-anchor T-570/T-572 (properties verified — genuinely lower priority).

## What this says about the original question

The operator asked whether to schedule the suite. The answer the evidence gives is **the suite is
the wrong lever for this class.** The audit already runs on cron every 15 minutes. The divergence
detector needed one line in it, had one, and lost it in the same commit that caused the damage it
was watching for. Restoring that line covers every future re-vendor revert — including the ones no
probe watches — and costs nothing per run.
