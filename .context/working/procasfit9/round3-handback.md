# procAsFit round 3 of 9 — handback

**Status:** COMPLETE. Stop condition met on WORK, not on context (§11).
**Run:** 2026-09-29, session `S-2026-0929-0740`. Branch `bleeding-edge`, start commit
`bd670aa5`, end commit `ace2a830`. **Context at stop: 385K of the 1M cap** — the stop line is
800K, so this round stopped because nothing eligible remained, with 52% of its budget unspent.
**Commits (4, all local, none pushed):** `c0584cc5` (T-826) · `96adf169` (T-573) ·
`d95743b9` (T-573 closure + T-929) · `ace2a830` (T-922, scoring).
**Filed:** T-925, T-926, T-927, T-928, T-929 (all scored + confirmed) · OBS-440, OBS-441,
OBS-445, OBS-446.
**Closed:** T-573 (work-completed, verification 7/7). **Parked through the verb:** T-785, T-826.

> Written as a skeleton before any work, then filled as each unit landed — the method the
> round-3 dispatch asked for, because round 2's predecessor died with nothing written down.

## 1. Inherited-state census

Read at 2026-09-29T07:40Z. Start commit `bd670aa5`. New session `S-2026-0929-0740`
(`fw context init`), predecessor `S-2026-0929-0920`.

- **The open unit was T-785**, not a round-2 deliverable. Its only uncommitted change was a
  status line: `issues → started-work` stamped `2026-09-29T07:39:14Z` — the same minute as
  round 2's last commit `bd670aa5`. **No implementation work followed it.** 5 of 6 Agent ACs
  are ticked; the 6th is `BLOCKED` on **T-353**'s open `[REVIEW]` criterion (`owner: human`):
  *may an agent edit `## Verification` blocks inside `.tasks/completed/`?* That is a Sovereign
  question, so per the mandate it is surfaced, not resolved.
  **Action taken:** parked back through the verb —
  `fw task update T-785 --status issues --reason "…"` (healing diagnosis auto-fired). The task
  file now carries both status lines, so the round-trip is auditable rather than invisible.
- **Round 2's handback was NOT empty** (15,352 B, `round2-handback.md`). The empty-handback
  failure belongs to the *first* orchestration run (`orchestrator.log`: rounds 2–9 all
  `FAILED-NO-HANDBACK`, round 3–9 in 4–5 s each against a quota wall). The resume run
  (`orchestrator-resume.log`) re-ran round 2 to `exit=0 2528s handback=15352B -> OK`. So the
  26 lost minutes are real but already recovered; this round inherits a full predecessor record.
- **Uncommitted, not mine, unchanged by me:** 183 `.context/audits/cron/` deletions; 19
  `.context/episodic/*.yaml` rewrites; `metrics-history.yaml` (11,250-line churn);
  `bvp-auto-approval.jsonl`; the `.context/working/*` counter files; `last_update`-only bumps on
  T-737/T-889/T-897/T-922; and the T-891/T-906/T-908 status/components rewrites round 2 already
  listed. Left alone — they are not this round's work and predate it.
- Focus was `T-785` at dispatch; `fw context init` cleared it (see §7).

## 2. Selection trail

**Level 1 — Project gate.** `docs/832-project-purpose-and-goals.md` §7 is explicit:
arc-002 (EWCR) and arc-003 (audit remediation) **trace to no goal** in G1–G6. arc-003 holds 41
open tasks and §7 itself names it as the thing that "absorbs agent capacity by default". So the
64 arc-003 and 31 arc-002 tasks are ineligible however cheap — including the eleven `hv-lc`
RA-0xx items (T-702, T-723, T-732, T-708–T-722) that would otherwise top a Q1 sweep.
Goal-bearing arcs: **arc-001** (G6), **arc-005** (G2/G3/G4), **arc-004** (G0, the method).

**Level 2 — Arc gate.** The in-flight arc is **arc-005** (round 2 closed T-923/T-883/T-884 in
it). Its only remaining task at horizon `now` is **T-876**, and it is held by a *recorded* peer
decision, not my judgment: `decisions.yaml:2549` **PD-343** — *"hold T-876 (backfill `kind`
across 24 corpus maps) pending AEF's answer"* (filed 2026-09-28 under T-877). T-924 is `later`
by its author. So the in-flight arc **is blocked**, which is exactly the condition under which
the mandate permits moving to another arc.

**Level 3 — Task gate.** Ranked with `fw bvp --include-proposed` (119 tasks; `fw bvp` alone
returns only 4, all `horizon: later`, because the rest carry *proposed* not *confirmed* scores —
a finding in §8). Intersected with "horizon `now` ∧ `owner: agent` ∧ status captured/started-work
∧ goal-bearing": the field is small, and only **one** candidate is **Q1 (hv-lc)**.

| # | objective → arc → task | quadrant | why this over the next | outcome |
|---|---|---|---|---|
| 1 | **G2 class ≠ instance** → arc-005-adjacent (filed under arc-002) → **T-826** *Emit the diagram-kind marker* | **Q1 — hv-lc**, BVP 115 (confirmed this round), cost 3.2 | The mandate says Q1 first, to exhaustion. T-826 is the ONLY `hv-lc` task at horizon `now`, owner `agent`, in goal-bearing content: its subject is T-213's ratified `aef:workflowMeta` diagram-kind enum, i.e. G2's marker verbatim. Next candidates are all Q2 and dearer: T-358 (175, cost **6.8** — the most expensive thing on the board), T-341 (127, cost 4.4), T-889 (133, Sovereign on AC 1), T-811 (189 — but an **inception awaiting a go/no-go**, so Sovereign). Cost 3.2 vs 6.8 with both above the BVP median is the whole reason Q1 precedes Q2. | see below |

| 2 | **G6 idea↔implementation round-trip** → arc-001 → **T-573** *Emits panel writes a scalar where the exporter requires an array* | **Q1 — hv-lc**, BVP 106, cost **1.9** (the cheapest high-value item on the board) | **Q1 was NOT exhausted after T-826, and I nearly stopped as though it were.** My first eligibility scan filtered on `horizon: now`; CLAUDE.md makes **`next` eligible too** (only `later` is excluded from suggestions), and T-573 sits at `next`. Re-running the sweep over the whole `hv-lc` quadrant found it. Over T-341 (127, Q2) and T-358 (175, Q2) because Q1 precedes Q2 by the mandate; both were then opened and confirmed `[REVIEW]`-blocked anyway. | **CLOSED** `96adf169` + `d95743b9` — 6/6 ACs, `fw task verify` 7/7, 8/8 CDP legs, 5/5 mutants, 24/24 byte-identity, two screenshots read |

**Candidates opened and REJECTED with a reason, not skipped:** T-341 (T-891 states in its own
description that it does not close T-341; its `[REVIEW]` is the operator's) · T-358 (its two
remaining ACs say `BLOCKED` pending a five-way `[REVIEW]` choice) · T-889 (a recorded
`SOVEREIGN QUESTION` dated 2026-09-27 whose own text says *producer-not-judge*) · T-669
(**lv-hc** — out on its score under "low-value is out of scope regardless of how cheap", and
separately blocked by the same T-353 ruling as T-785) · T-811 (an inception awaiting go/no-go).

**What T-826 turned out to be.** Scored before started (`fw bvp estimate` → `estimate-cost` →
`confirm`; the confirm was AUTO-APPROVED under the pre-existing operator ruling T-856 /
`BVP_AUTO_CONFIRM=1`, recorded to `bvp-auto-approval.jsonl` — not a gate I bypassed). Then
`fw work-on T-826`, which walked `frw_1_task → frw_2_build → frw_3_start` through T-923's
writer. Verifying its eight ACs against the tree before building anything showed **five of
eight already delivered under other task ids** (§8 F4) — and **AC 5 pointing at a live red**
(§8 F2). So the unit became: close the two ACs that are genuinely open, for the two kind rules
**only**, and file everything else rather than absorb it.

## 3. Objectives advanced, against run start

**G4 / G0 — the diagram-kind marker's two validator rules went from *declared* to
*witnessed and compared*.** At run start `E-WORKFLOW-KIND` and `E-XML-WORKFLOW-KIND` had
never been seen to fire on any document in the tree, `E-XML-WORKFLOW-KIND` was unclassified in
the anchorability table, and `E-WORKFLOW-KIND` sat in the parity table as `PAIRED` while being
absent from the cross-form harness's `PAIRS` — i.e. the claim "the two forms agree on kind" had
never been tested by a comparison. All three are now closed, rule-scoped, with
`tools/_t826-kind-rule-axes-teeth.sh` at 15/15 and every absence leg paired with a presence
control aimed at a rule that is still red. This is G0 work in service of G2: the marker itself
was already built (T-875/T-911), but nothing had shown its rules work.

**A false-attribution hazard closed, in the one instrument the tree reaches for when adding a
validator rule.** `tools/_t820-rule-axes.sh` invited a rule id by its own docstring and read
none; it now refuses one with `exit 2` and names the argument it got. Zero blast radius
(measured: no `## Verification` block in the tree passed it an argument;
`_t820-axes-controls.sh` still 7/0). Before this, the next author to follow that docstring would
have banked a green earned by other people's rules — which is the T-816 defect the file exists
to prevent.

**Four defects converted from prose into owned items.** T-925 (the bridge erases document-level
`aef:workflowMeta`, so no cross-form rule on any of its ten attributes can be compared), T-926
(`_index()` scores any id-bearing element as a flow node, plus the `.bpmn`-only fixture
population), T-927 (no per-rule mode exists for the five axes), OBS-440 (the 4/5 red and which
task each red rule belongs to), OBS-441 (a sharpened diagnosis of the recurring
`fw fabric register` self-description refusal). None of these existed in any register at run
start; all five were found by *trying to close one AC honestly*.

**Not advanced, and worth saying plainly:** G2's headline deliverable (the 24 maps classified)
did not move, because it is T-876 and T-876 is held by PD-343. arc-005's exit demo is unchanged
from round 2's handback. No goal's *state* line in
`docs/832-project-purpose-and-goals.md` §3 changes as a result of this round.

## 4. Arc state (tasks by status and quadrant)

**arc-005 process-instances** (round 2's in-flight arc; **blocked**, not entered for new work):
12 in `completed/` (T-875/877/878/879/880/881/882/883/886/911/923 + T-884 closed by round 2) ·
**T-876** captured/`now`, **held by PD-343** (`decisions.yaml:2549`, "pending AEF's answer") ·
T-924 captured/`later` (filed by round 2). Nothing agent-executable.

**arc-001 designer-authoring-surface** (entered; where unit 2 lived): **T-573 CLOSED this
round** (hv-lc Q1 → `completed/`) · T-889 started-work/`now`, hv-hc Q2, **recorded SOVEREIGN
QUESTION on AC 1** dated 2026-09-27 · T-901 captured/`now` (a decision task) · T-424
captured/`now`, blocked on T-357 (partial-complete, human) · `later`: T-279, T-280, T-281,
T-282, T-564, T-895, T-896 · 42 partial-completes awaiting the human.

**arc-002 EWCR** (T-826's nominal arc; traces to no goal per §7, entered only because T-826's
*content* is G2's marker): **T-826 parked at `issues`** with 3 of 8 ACs closed.

**arc-004 hypothesis-first-inceptions** (the *focused* arc, per `arc-focus.yaml`): unchanged
since round 1 — T-866 partial-complete, T-869 `later`. Nothing at `now`. Worth flagging that
the focused arc has had nothing eligible for three rounds.

**arc-003 audit remediation:** not entered. §7: traces to no goal, holds 41 open tasks, and is
named there as the thing that "absorbs agent capacity by default."

**New this round, all captured + scored + confirmed:** T-925 (142, `now`, Sovereign at step 1)
· T-926 (124, `later`) · T-927 (`later`) · T-928 (`now`) · T-929 (`now`).

## 5. What remains in Q1/Q2, per task, and why not done

**Q1 (hv-lc) is empty.** Re-measured after T-573 closed: zero tasks in the `hv-lc` quadrant are
`owner: agent` at horizon `now`/`next`. The ten in that quadrant are, without exception,
`owner: human` (T-702, T-723, T-700, T-696, T-732), horizon `later` (T-863, T-869, T-246,
T-286), or arc-003/arc-002 and therefore outside the objective gate. T-573 was the last one.

**Q2 (hv-hc), all four eligible candidates, each Sovereign-blocked — verified individually this
round, not inherited:**

| task | BVP / cost | the blocker, read from the task file |
|---|---|---|
| **T-811** | 189 / 3.6 | an **inception awaiting a go/no-go decision** (`fw inception decide`). Not an agent's to rule. |
| **T-358** | 175 / **6.8** | 4 of 7 ACs done; the remaining two say `**BLOCKED**` pending its `[REVIEW]` AC — *"Choose the lane/pool fabrication repair: **A · B · C · AB · no repair**"*. A choice among five named alternatives is the definition of a Sovereign scope decision. |
| **T-889** | 133 / 4.4 | 6 of 7 ACs ticked. AC 1 carries a **recorded `SOVEREIGN QUESTION` dated 2026-09-27**: *"AC 1 names a proof that cannot exist. Yours to rule."* Measured there: deleting `'authority'` from the editor's `metaKeys` leaves every leg of its own CDP probe green, so the discriminator AC 1 names does not exist. The AC's own text says **producer-not-judge**. |
| **T-341** | 127 / 4.4 | 4 ACs say `**BLOCKED** on the Human AC below`. **T-891 (completed 2026-09-28) states explicitly: *"Does NOT close T-341 — that task's `[REVIEW]` criterion is the operator's and is untouched."*** This disproves the supersession I suspected in §8 F4. |

**Also open, not eligible:** T-925 (142, the round's best finding — but Sovereign at step 1: the
bridge emitting `workflowMeta` changes bytes AEF byte-pins) · T-876 (142, PD-343) · T-885 (160,
human-owned, 5/5 verified since round 1) · T-424 (blocked on T-357) · T-669 (**lv-hc** — out on
its score, and blocked by the same T-353 ruling as T-785) · T-926/T-927 (`later`, my own filing)
· T-928/T-929 (framework/fabric hygiene — traces to no G1–G6 per §7, and T-929's fix is inside
the **vendored** `.agentic-framework/` tree, i.e. upstream rather than project work).

## 6. Sovereign questions, unresolved, priority order

1. **T-826 AC 6 contradicts T-826 AC 1, and the ratified side should win.** AC 6 demands *"a map
   with no kind … proven to fail the validator"*; T-213 IW-3 as re-derived under T-875
   (`tools/validate-workflow.py:72-75`) says absence is **legal and not a warning**, and AC 1
   demands T-213's disposition be used *verbatim*. Both validator rules implement absent-is-legal
   and T-876's load-bearing AC assumes it. **The ask:** strike AC 6's first clause (it was written
   2026-09-22, six days before the build settled the question the other way), or rule that T-213
   IW-3 changes. I did not edit it — rewriting my own unpassable AC is the producer-as-judge move.
   Everything else in T-826 is then either closed or T-876.
2. **T-925 — should `tools/yaml-to-bpmn.py` emit `aef:workflowMeta` at all?** The round's most
   valuable finding (142, top of the confirmed rank bar T-189) and unexecutable without this
   ruling: all 24 rendered maps are bridge-produced and AEF byte-pins them, so emitting the
   element is a **seam change**. Until it is ruled, no cross-form rule on any of the ten
   document-level attributes (`id, uuid, version, schemaVersion, title, description, source,
   tier_default, pageWidth, kind`) can ever be compared — the harness's own words apply: *"that
   inference is exactly how a genuine coverage hole gets absorbed as a repair."*
3. **T-889 AC 1** — the 2026-09-27 question is still unanswered, and it is the last thing between
   arc-001 and its highest-value open task. T-896 owns the seam half.
4. **T-876 / PD-343** — waiting on AEF. It is arc-005's last open slice and the thing standing
   between that arc and a close (see round 2's handback, Sovereign question 1, unchanged).
5. **T-358** — pick one of `A · B · C · AB · no repair`. 4 of 7 ACs are already done; one word
   from the operator converts the most expensive item on the board (cost 6.8) into buildable work.
6. **T-341 / T-353 / T-901** — unchanged from rounds 1 and 2. T-353's ruling in particular is a
   multiplier: it unblocks T-785 **and** T-669, both of which are red-baseline tasks that six
   other tasks run through.
7. **`fw handover` was again not run** (OBS-413: it pushes to origin without a flag). This file is
   the handback; 4 commits are local and unpushed.

## 7. Gates that refused me, and what I did instead

No `--force`, no `--skip-rca`, no `--skip-*`, no `FW_ALLOW_*` anywhere this round. Every refusal
below was worked *through*, and two of them changed the deliverable for the better.

- **G-019 refused the close of T-573 for an empty `## RCA`** — after verification had already
  passed 7/7. Wrote the RCA; it is the best thing in the task, because forcing the "why was this
  structurally allowed" question produced the finding that **the guard which existed was TRUE for
  the entire life of the defect**. The gate earned its keep here rather than merely costing time.
- **G-020 refused a shell write to T-573's task file** while its ACs were placeholders
  (`[First criterion]`), and named the exemption precisely: the task file is exempt for the
  **Write/Edit tool**, and shell writes stay blocked because "the write scanner cannot prove a
  shell write's sole target is the task file" (T-3299). Used the Edit tool, as prescribed. This
  is the gate working as designed — the task genuinely had no ACs and I was about to edit source.
- **`check-active-task` refused several commands after focus was cleared.** Focus is nulled by a
  task close (documented) but *also* drifted twice without a verb — see **OBS-445**, filed
  undiagnosed after three eliminations. Recovered each time with `fw context focus`.
- **The bootstrap-exemption refusal is worth quoting** because its message is a model of the
  kind: my line was `fw context focus T-922 >/dev/null && git reset …`, and the hook explained
  that the exemption is voided for the whole line by any write pattern *even when the pattern
  belongs to a different command on the line*, then told me exactly what to do ("Run the
  bootstrap command BARE and alone first"), then said **"This is a message, not a permission:
  the redirected form stays blocked by design."** I ran it bare. No bypass.
- **`fw bvp rank` and `fw bvp --arc` are not verbs** (`unknown verb 'rank'`). The ranking verb is
  bare `fw bvp`. Round 2 hit the `--arc` half of this; recording the `rank` half too.
- **`fw fabric register` REFUSED two files that describe themselves at length** and wrote
  unpopulated cards anyway. Fifth sighting across rounds 2–3 — and this round it was **diagnosed
  to root cause** rather than re-observed: **T-929**, with OBS-446 correcting the wrong diagnosis
  I had filed an hour earlier as OBS-441.
- **`fw bvp confirm` is §ACD-gated and did NOT refuse me** — it auto-approved under
  `BVP_AUTO_CONFIRM=1`, a *pre-existing operator ruling* (T-856), and logged each one to
  `.context/telemetry/bvp-auto-approval.jsonl`. Recorded explicitly so it is not mistaken for a
  sovereignty boundary I walked through.
- **A gate I expected and did not hit:** the completion gate on T-573 passed its seven
  verification legs first time, including four browser harnesses.

## 8. Findings surfaced

**F1 — `tools/_t820-rule-axes.sh` ignores its argument, and the whole tree reads it as per-rule.**
Its own docstring says *"Run it when adding or changing a validator rule; put it in that task's
`## Verification`"*, and T-826's AC 5 names it as the check that *"that rule satisfies ALL FIVE
axes"*. It reads no `$1` at all (`tools/_t820-rule-axes.sh:55-90` — `AXES` is a fixed five-element
list; no positional parameter is referenced anywhere in the file). Proven by control rather than
by reading: three invocations, one real rule (`E-WORKFLOW-KIND`), one different real rule
(`E-TOPLEVEL-MISSING`), one rule id that does not exist (`E-NOT-A-REAL-RULE`), produce
**byte-identical verdicts**. So the tool cannot distinguish a rule that satisfies the axes from
one that does not, and when the suite is green it hands any caller a green *about someone else's
rules*. `docs/reports/VALUE-REVIEW-repo-2026-09-25-evidence.md:1238` had already flagged it as
having **no live caller** — T-826's AC 5 is the only thing in the tree that would make it one,
and it would have made it one with a false premise. Latent, not live: no `## Verification` block
anywhere passes it a rule id.

**F2 — the five axes are 4/5 RED right now, and the red names rules from four tasks that closed
green.** This is the defect T-820 exists to prevent, recurring after T-820 shipped:
- `form parity` FAIL — `E-META-AUTHORITY` (shipped by **T-902**, commit `5a0e1b46`) has no
  `PARITY` classification. Verbatim: *"Adding a rule to one form without deciding whether the
  other form needs it is exactly the T-317 class."*
- `anchorability` FAIL — five rules unclassified in `ANCHOR`: `E-XML-LANE-AUTHORING-DEFAULT`,
  `E-XML-META-AUTHORITY`, `E-XML-NODE-UNASSIGNED`, **`E-XML-WORKFLOW-KIND`**,
  `W-XML-AUTHORITY-DEFAULT-MISMATCH`.
- `cross-form agreement` FAIL (3) — **`E-WORKFLOW-KIND` is `PAIRED` in the parity table but
  absent from `PAIRS`**, so the claim that the two forms agree *was never compared*; plus a
  **NEW DISAGREEMENT** on `E-NODE-LANE` (yaml fires=True, xml fires=False, reporting
  `E-XML-NODE-UNASSIGNED`) that parity reports green *"because both forms merely NAME it"*.
- `dialect axis` is the one that passes — because **T-903** did exactly this classification work
  for the two kind rules on that one axis, and stopped there.

**F2 is what makes T-826 real rather than a phantom.** Two of the named rules —
`E-WORKFLOW-KIND` and `E-XML-WORKFLOW-KIND` — are **T-875's own**, the diagram-kind marker's
rules. So T-826's AC 5 is not superseded: it is *unsatisfied, and satisfiable*. The rest of the
red belongs to T-889/T-890/T-894/T-902/T-909 and is not mine to fix (one bug = one task).

**F3 — T-826 AC 1 and AC 6 contradict each other, and AC 1 wins on ratified authority.**
AC 6 demands *"a map with no kind … proven to fail the validator"*. AC 1 demands T-213's
disposition be *"used verbatim"*, and T-213 IW-3 as re-derived under T-875
(`tools/validate-workflow.py:72-75`) says **"ABSENT IS LEGAL AND IS NOT A WARNING … the default
is UNSET so the marker stays an explicit author decision and no map is silently reclassified by
its own tooling."** Both validator rules implement absent-is-legal (`:339` guards on
`"kind" in _wm`; `:1119` on `_kind is not None`). T-876's own load-bearing AC says the same from
the other side: *"a map left unmarked must still round-trip byte-identical, proving the UNSET
default is inert."* So AC 6's first clause was written (2026-09-22) against a design that the
build (2026-09-28) settled the other way. I did **not** rewrite it to something I could pass —
see §6, Sovereign question 1.

**F4 — the board carries phantoms whose subject was delivered under a different task id.**
T-826's ACs 1/2/3/7/8 were delivered by T-875 (schema, both validator rules, exporter,
round-trip), T-911 (panel + canvas badge) and T-877 (told AEF) — none of which names T-826.
`grep -c diagramKind src/aef-workflow-designer.html` still returns **0**, exactly as T-826's
description says, yet the marker is fully built: the field was named `kind`, not `diagramKind`,
so T-826's own staleness probe can never notice its own completion. Same shape suspected on
**T-341** ("an unresolvable flowNodeRef silently reassigns the orphaned node") vs **T-891**
("Unresolvable flowNodeRef becomes a hard validation error"), completed 2026-09-28 — not
investigated this round, flagged in §5. Nothing in the register detects supersession, so a
phantom keeps its BVP score and competes for selection: T-826 ranked **115, hv-lc, Q1** and won
this round's Q1 slot on work that was 5/8 already done.

## 9. Cost vs estimate

- **T-826** (confirmed 115, cost 3.2, `hv-lc`): ~50 min. The estimate was *right about the cost
  and wrong about the work.* 3.2 correctly said "cheap", but the cheap thing turned out to be
  verification and filing, not building — five of eight ACs were already delivered under other
  task ids. **The cost model cannot see supersession**, which is the same blind spot as §8 F4.
- **T-573** (confirmed 106, cost **1.9** — the cheapest high-value item on the board): ~100 min,
  the round's most expensive unit by a wide margin. The 1.9 came from `blast_radius=1`
  (`components: [src/aef-workflow-designer.html]`), and one component is exactly what the source
  edit touched. What 1.9 could not see: **two other guards had to be taught about the change**,
  each after refusing it, and one of those (`_roundtrip-serialization-cdp.mjs`) needed a new
  source kind plus a control run. Blast radius counts the components a task *names*; it does not
  count the instruments that *watch* them. Round 2 said the same thing about verification
  standard, from the screenshot side. **Two rounds, two different mechanisms, same conclusion:
  cost under-predicts wherever the change crosses an instrument.** That is a concrete
  calibration input — a candidate term is "number of guards whose denominator includes the
  touched component", which the fabric already knows.
- **Estimate vs outcome, the honest comparison:** T-826 at cost 3.2 took half as long as T-573 at
  cost 1.9. The ordering was inverted. Both were correctly placed *above* the value median, so
  Q1-before-Q2 held; it was the within-quadrant ordering that the cost figure got backwards.
- **Wasted effort, recorded:** ~15 min on `channels()` scoping by BPMN id when the exporter
  writes display ids (four legs failed on a correct implementation — §8 F6); ~10 min on three
  refuted hypotheses for the `fw fabric register` refusal before reading the code (the code read
  took 3 minutes and settled it — a lesson about hypothesis-vs-source-read ordering when the
  source is 40 lines); two gate round-trips on focus loss; one `pkill` self-kill (exit 144),
  the same one round 2 recorded.

## 10. Auditability

Every claim in this handback traces to a recorded check or a verb-gated state change.

- **Every state change went through a verb.** `fw task update T-785 --status issues` ·
  `fw work-on T-826` / `T-573` (each walked `frw_1_task → frw_2_build → frw_3_start` through
  T-923's writer, printed in the transcript) · `fw task update T-826 --status issues` ·
  `fw task update T-573 --status work-completed` (which moved the file to `completed/` and
  generated `.context/episodic/T-573.yaml`). No direct write to `focus.yaml`, `arc-focus.yaml`
  or `.next-directive.yaml` at any point.
- **Every score went through the scorer**, never an estimate: `fw bvp estimate` →
  `estimate-cost` → `confirm`, for T-826, T-573 and all five tasks filed this round. No
  calibration parameter was touched; nothing already completed was rescored.
- **Every green has a re-runnable leg, and every absence leg has a presence control.**
  `fw task verify T-826` 8/8 · `fw task verify T-573` 7/7 ·
  `tools/_t826-kind-rule-axes-teeth.sh` 15/15 (legs 6, 8, 10, 12 are the controls, each aimed at
  a rule that is still red) · `tools/_t573-emits-panel-shape-cdp.mjs` 8/8 (leg
  `reproduce-string-write` is the control arm) · `tools/_t573-one-vocabulary-teeth.py` 5/5
  against mutants · `tools/_t570-meta-carriage-cdp.mjs` 8/8 unchanged ·
  `tools/_t308-export-byte-identity-cdp.mjs` 24/24 identical ·
  `tools/_roundtrip-serialization-cdp.mjs` `pass: true` · `tools/_t820-axes-controls.sh` 7/0.
- **The one control I ran as a throwaway mutation, declared:** to prove the new `moduleObject`
  source kind still bites, I pointed the declaration at `STRUCT_LIST_KEYS_NOT_A_THING`, ran the
  guard (it refused on all three of its checks), restored the file and verified with
  `grep -c` that 0 occurrences of the bogus name remain. A throwaway is legitimate for a
  *control*; the *witnesses* this round added are persistent files, which is what the
  pass-reachability axis demands.
- **Visual claims have PNGs that were READ, not just taken:** `docs/reports/t573-shots/` ×2,
  each with a row in T-573's `## Visual Verification` recording what came back. The
  single-visual-mode claim is itself evidenced by a grep returning nothing for `data-theme`,
  `prefers-color-scheme` and `toggleTheme`.
- **Two claims I explicitly did NOT make.** T-826 AC 3 (panel authorability) is left unticked
  even though the code is there, because it is a rendered-UI claim and I did not look at a
  screenshot of it. T-826 AC 8 (AEF was told) is left unticked because I did not read the rail.
  Citing another task's delivery is not verifying it.
- **Working tree at stop:** the pre-existing noise only — 183 `.context/audits/cron/` deletions,
  the `.context/episodic/*` and `metrics-history.yaml` churn, `.context/working/*` counters, and
  the T-891/T-906/T-908/T-737/T-889/T-897 rewrites inherited from earlier rounds and listed in
  §1. None of it was created or touched by this round.

## 11. Stop condition

**Fired: "a Sovereign question blocks every remaining eligible path"** — and, independently,
"all Q1 and Q2 tasks in the active arc are complete, and no other arc has eligible Q1/Q2 work."

Both are measured in §5 rather than asserted: Q1 is empty of agent-owned non-`later` tasks after
T-573 closed, and each of the four Q2 candidates was opened and read this round to confirm its
blocker (which is how T-889's inherited "Sovereign" label was verified and T-341's suspected
supersession was **disproven**).

**Context was NOT the binding constraint: 385K of 1M at stop, against a 800K stop line.** This
round ended with 52% of its budget unspent. That is the finding the next round should weigh most
heavily: the board is **decision-limited, not capacity-limited**. Six of the seven Sovereign
questions in §6 have been open across all three rounds of this run, and unblocking any one of
T-353, T-889 AC 1 or T-358's `[REVIEW]` would convert a high-value blocked task into work an
agent can finish inside a single round.

Nothing was left mid-task: T-573 closed through the verb, T-826 and T-785 parked through the
verb, the working tree at stop carries only the pre-existing noise the census in §1 lists.

---

## 8b. Findings surfaced in unit 2 (T-573), and a correction to F4

**F4 CORRECTED — T-341 is NOT a phantom.** §8 F4 named T-341 ("an unresolvable flowNodeRef
silently reassigns the orphaned node") as a supersession suspect against T-891 ("Unresolvable
flowNodeRef becomes a hard validation error"). **Disproven by reading T-891**, which says in its
own description: *"Does NOT close T-341 — that task's `[REVIEW]` criterion is the operator's and
is untouched."* The author had already thought about it and written the answer down. The
supersession pattern F4 describes is real (T-826 is the evidence) but it is **not** a licence to
assume it wherever two task names rhyme — and one cheap read settled it. Left in the record with
the correction attached rather than quietly deleted.

**F5 — the guard that existed was TRUE for the entire life of the defect T-573 fixes.**
`tests/test_editor_bridge_structured_parity.py` asserted that the editor's **two** copies of the
structured-key triple each agree with the bridge. That held continuously while the properties
panel — a *third* writer of `n.aef.emits` — wrote an incompatible shape, because the panel was
outside its denominator BY CONSTRUCTION. **Two copies agreeing is a weaker claim than one copy
existing, and the defect lived in the gap between those two claims.** Prevention was therefore
to *invert* the assertion (exactly one copy; `0` reads as blindness, not health), not to add
another test of the old kind. Same shape as T-885 one instrument over, and as T-570's asymmetric
`metaKeys`/import pair — this is now a three-instance pattern and worth a project learning.

**F5b — T-570 reduced the symptom and thereby postponed the defect, knowingly.** Its carriage
rescued the author's string as `<aef:meta emits=…>`, and its own comment records the two channels
as "disjoint by construction". Correct, and it stopped data being destroyed. It also meant
nothing hurt enough to force the shape question for 40 days. *A fix that removes the pain of a
defect postpones the defect* — not an argument against T-570, an argument for filing the residue
as its own task, which is what T-573 was.

**F6 — a probe that cannot find its subject reports the same shape as a broken feature.**
Four of eight CDP legs failed on an implementation that was already correct, because my
`channels()` helper scoped the exported XML by the fixture's BPMN id (`id="E1"`) and the exporter
writes the **display id** (`displayIdOf`), which the editor re-derives. `uid` is the identity that
survives (T-224). Cost ~15 minutes and is recorded in the helper's own comment, because the
failure text ("NO `<aef:emits>` was emitted") was indistinguishable from a real regression.

**F7 — `_roundtrip-serialization-cdp.mjs` caught a regression I introduced, and its message named
the cause exactly.** `pass: true → false` with *"COMPUTED_SOURCES.key declares object source
`structList` which does not exist in the emitter"*. This is **T-905's guard working as designed**
— it was built so a misdeclaration could not be mistaken for a correct one, and it wasn't.
Worth recording as a positive finding: the project's investment in refutable declarations paid
out on an unrelated change six days later.

**F8 — `focus.yaml`'s `current_task` drifts without a focus verb, and the drift silently
re-points the task gate.** Twice this round: once to `null` mid-unit, once to **T-669** — a task
this session only ever *read*. Three hypotheses eliminated (`fw bvp T-XXX` tested and cleared; no
crontab entry for this project; `checkpoint.sh` only reads the file). Escalated undiagnosed as
**OBS-445**, because the value alone does not name its writer — a reproduction needs an inotify
watch recording the writing PID. Consequence if left: a write attributed to the wrong task, or a
`BLOCKED: No active task` mid-unit, which is what happened.

**F9 — the C-003 inception research checkpoint has never fired for any task** (**T-928**).
Hypothesis 3 of the focus investigation turned this up: `checkpoint.sh:499` reads the focused
task as `grep '^task_id:'` from a file that carries `current_task:` — `grep -c` gives **0 and 1**.
So `focus_task` is always empty, the enclosing guard never runs, and a rule CLAUDE.md states as
mandatory for inception work has been inert. It emits only on the unhappy path, so its silence
read as compliance. **This is the same shape as F5**: a check whose subject it cannot find.

**F10 — a Sovereign-blocked AC has no machine-readable marker, and PL-145 already said so.**
T-785, T-358 and T-341 write `**BLOCKED**` in their AC text; T-889 writes *"See the Sovereign
question in `## Decisions`"* as prose. My grep for blocked ACs therefore scored T-889 as
**0 blocked** and it took opening the file to see the recorded 2026-09-27 ruling request. PL-145,
which `fw context focus` printed at me twice today, is exactly this: *"A ruling filed as PROSE is
invisible to every instrument that looks for rulings."* Not filed as a new task — it is PL-145's
territory and arguably T-901/T-353's queue — but it is why a selection pass cannot be automated
from the register as it stands, and why every candidate in §5 had to be opened by hand.
