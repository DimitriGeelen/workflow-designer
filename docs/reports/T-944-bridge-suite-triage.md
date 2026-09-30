# T-944 — triage of the standing failures in `tests/run-bridge-tests.sh`

**Date:** 2026-09-30 · **Task:** T-944 · **Status:** in progress (full-suite run finishing)

---

## The headline is not the suite

I was asked to sort 16 failing legs into real defects, stale expectations and backlog. Doing it
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
3. **The detector has no delivery surface.** `_t517` is referenced **0 times** in `audit.sh`, and
   this morning's audit YAML contains **no occurrence of "diverg"**. The detector runs nowhere.
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
| T-509 instrument sweep | pending | run finishing | — |
| T-821 swallowed-failure census | pending | run finishing | — |
| T-358 third-party byteid | pending | fixture drift reported | — |

Counts and the remaining rows will be reconciled against the completed full run before this report
is marked final. **Nothing below the line above has been fixed by this task** — triage only.

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
