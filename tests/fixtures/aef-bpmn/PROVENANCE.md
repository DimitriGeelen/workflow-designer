# Provenance of `tests/fixtures/aef-bpmn/`

**This directory does not contain AEF's BPMN files.** The name says otherwise, which is
why this note exists.

## The name asserts SCOPE, not AUTHORSHIP — and it is not ours to change

`aef-bpmn` means *"BPMN fixtures concerning the AEF seam"*. It has never meant *"BPMN
files originating from AEF"*, and nothing in this directory should be cited as evidence
of AEF authorship. The per-file table below is the **only** provenance source; the
directory name is not one.

**This path is normative in a frozen two-party standard** (measured 2026-08-11 under
T-365, and the reason the rename was NOT performed):

| Document | Reference | Status |
|---|---|---|
| `docs/standards/aef-bpmn-mapping-v1.md:142` | `tests/fixtures/aef-bpmn/inception-gonogo.bpmn` as a **Reference fixture** | line 142 — inside **Part I, Frozen** (Part II starts at 146) |
| `docs/standards/aef-bpmn-forward-compile-v1.md:21` | `tests/fixtures/aef-bpmn/*.bpmn` as **"the reference corpus"** | §5 at :106 is titled after the path |

**Cite the clause, not the line.** AEF keeps the same standard at `policy/standards/`
and ours lives at `docs/standards/`; their copy carries the same sentence at **:113**
where ours has **:142** (DM 549 §5). Line anchors do not survive between the two trees.
The portable anchor is the literal string **`Reference fixture:`**, which is why
`_t365-normative-fixture-guard.py` matches on path shape rather than position.

So a unilateral `git mv` would strand a reference inside a document this project may
not edit under agent control, and would move a path AEF's forward-compile contract
names as the corpus — a seam change dressed as housekeeping. **T-365 therefore does not
rename.** A rename is a standard delta (two-party, operator-governed), offered to AEF
alongside the v1.1 deltas drafted by T-189/T-195, not a refactor.

`tools/_t365-normative-fixture-guard.py` enforces the half that can be enforced: every
fixture path the standards name normatively must resolve. It fails if a rename strands
the standard, and it derives the paths BY READING the standards, so it follows them
rather than restating them.

## What it actually is

BPMN fixtures **about the AEF seam, authored here (832)**. Measured 2026-08-04 via
`git log --diff-filter=A` on every file — each one's first commit:

| Fixture | Added by | Character |
|---|---|---|
| `arc-lifecycle`, `harvest-pipeline`, `investigate`, `resume-status` | T-183 | 832-authored reference fixtures |
| `inception-gonogo` | T-192 | 832-authored |
| `boundary-events`, `typed-events` | T-204 | 832-authored |
| `two-lane-joint` | T-208 | 832-authored |
| `session-handover` | T-214 | **pair-draft** (AEF arc-014) |
| `dispatch-loop` | T-215 | **pair-draft** (AEF arc-014 — was arc-015, corrected 2026-08-12) |
| `offpage-seam` | T-219 | **pair-draft** (no AEF counterpart draft — see below) |
| `s4-exemplar` | T-235 | 832-authored |
| `bare-catch-event` | T-308 | 832-authored |
| `lane-position-conflict` | T-310 | 832-authored |
| `doc-comment` | T-311 | 832-authored |
| `lane-geometry-partial-overflow`, `lane-geometry-unpositioned` | T-312 | 832-authored |
| `lane-capacity-large-spill` | T-313 | 832-authored |

**Not one file was handed to us by AEF.** The rest are ours outright.

> **The three `pair-draft` rows are no longer one-sided — and what came back is that the
> two sides never meant the same thing by the word.** Asked to confirm (DM 548 §6), AEF
> declined to do it from memory — *"a confirmation given from memory is exactly the 'name
> treated as evidence' failure this whole thread is about"* — and checked their records
> instead (DM 556, 2026-08-12, their `docs/reports/T-2934-pair-draft-provenance.md`).
>
> **Two definitions, both coherent, never diffed.** Theirs is fixed in writing at arc-014's
> inception — T-2553:101, recording their operator's choice of scope option 2d: *"pair:
> 832/AEF draft, operator reviews+corrects in designer UI"*, and at :144 *"pair-draft BPMN
> **(AEF or 832)** → operator reviews/corrects in designer UI"*. So on their side the pair
> is **drafting-agent + their operator**, and the drafting agent is explicitly either of us:
> a file drafted entirely here IS a pair-draft, and their contributing no bytes is the
> design rather than an anomaly. Ours cannot be that reading, or the column would be empty —
> this table contrasts the 15 "832-authored outright" with 3 "genuine pair-drafts", and that
> contrast only does work if the three contain something of theirs.
>
> **Bytes: all three are ours, unmodified, zero AEF content.** Their pins match the shas we
> delivered — `session-handover` rail 92 (11373 B, `d971a2fc…`), `dispatch-loop` rail 96
> (18793 B, `95bc24cd…`), `offpage-seam` rails 120/121 (10014 B, `0bc15bfa…`) re-delivered
> at rail 366 after our T-324 fix. One commit each touching them, two for `offpage-seam` and
> both ours. Under a *"did AEF bytes go in"* reading, all three move to 832-authored and the
> split becomes 18/0.
>
> **What is theirs is real and is not bytes.** For `session-handover` and `dispatch-loop`,
> an independent AEF counterpart draft of the same process — `aef-session-lifecycle`
> (`2640d597…`, T-2561/D3) committed **22 minutes** before intake, `aef-dispatch-loop`
> (`e32a518c…`, T-2563/D4) **42 minutes** before. There, "pair" is carried by two drafts of
> one process. For `offpage-seam` **there is no AEF counterpart draft at all** — they
> searched all 13 designer projects and none was ever made — but its three legs exercise
> *their* compile taxonomy, and the RESOLVED leg is not constructible without a live uuid
> only they could supply (posted rail 118 with `1f9b5f0c…` RECOMMENDED plus a 3-uuid
> avoid-list; confirmed rail 119 using exactly that). **That joint step exists precisely
> because the T-559 boundary forbids us reaching into their :3001.** So the row this
> ordinal calls #3 is the *weakest* of the three under a two-drafts reading and the
> *strongest* under a joint-work reading — exactly inverted.
>
> **OPEN, and the operator's call — not applied here.** AEF recommends keeping the three
> distinct from the 15 but labelling them by contribution rather than authorship:
> `832-authored / AEF-paired` for the first two, `832-authored / AEF-specified` for
> `offpage-seam`. They explicitly declined to assert it — *"I am deliberately not sending
> you a 'confirmed' … it would have converted your evidence into agreement while adding
> nothing"* — and noted their own tree never claimed co-authorship either: their commit
> subjects read *"**832** pair-draft #1/#2/#3 intake"*. **No row has been relabelled and the
> 15/3 split is unchanged**, because choosing which definition this file ratifies changes
> the headline count and is a definition ruling rather than a measurement.
>
> The residual defect is not the label. It is that one word carried two readings across a
> seam for months with nothing in either tree recording that a reading had been chosen —
> the same shape as the directory name, and as OBS-230's HOLD-vs-PRODUCES question.

## `inception-gonogo.bpmn` — a reference that crosses the seam

AEF's frozen Part I (`policy/standards/aef-bpmn-mapping-v1-partI.md:113`, their tree)
names `tests/fixtures/aef-bpmn/inception-gonogo.bpmn` as a Reference fixture, and their
own directory census reports that file **absent** on their side (DM 549 §5). They filed
it as OBS-225 with two dispositions: restore the missing fixture, or correct the
reference by delta.

**Measured here, and it supports neither.** Re-derived 2026-08-12 from git objects and
the rail, not from the table above:

| Fact | Evidence |
|---|---|
| Authored here, not by AEF | first commit `564e9aa2` (2026-07-12), T-192 |
| Delivered to AEF the same day | rail offset **34**, sha `093858400716…`, 4314 B |
| That sha is the original blob | `git show 564e9aa2:…` hashes to `093858400716…` |
| Re-pinned by T-314 | `e133cf9e` (2026-07-31), laneSet reorder, size unchanged at 4314 B |
| Current bytes | `bbfbc5ec48356c3a643efa21e37912994a3fff56532b7e0ef4815f91fbed00ab` |
| **AEF holds and pins that sha** | rail offset **354**: re-derived from the public mirror at `e133cf9`, `T-2706 re-pinned to bbfbc5ec…` |

So the fixture is not missing and the reference is not wrong. It is an **832-authored
file that AEF has verified and pinned**, named by a path clause inside AEF's frozen
standard — a reference that points across the seam into the producer's tree. The open
question is not which of their two dispositions to take; it is whether a `Reference
fixture:` clause names a path each side must **hold**, or a path in the tree that
**produces** it. Nothing in either standard says, and the two readings disagree exactly
where the two trees do.

## Why this note is not pedantry

AEF reports **5 files** at this same path on their side, including
`session-lifecycle-d3` which does not exist here. On 2026-08-04 I measured this
directory, found 149/149 `aef:uid` coverage, and told AEF that "our copies of your maps
corroborate your 424/424". Every number was correct. The **subject noun was supplied by
the directory name**, and the claim had to be retracted at RAIL-438.

Their figure ranges over 32 maps under `.context/designer/projects/` on their side. The
two sets have no established overlap. The agreement was real; the corroboration was not,
because independent confirmation requires that both sides can name the same set.

## If you are about to measure this directory

1. It is **ours**, so a result here says nothing about AEF's corpus, fidelity, or drift.
2. For a claim about AEF's bytes you need bytes AEF can name — ask on the rail.
3. `149/149 uid coverage` and `7 of 18 files carry same-lane x ties` (harmless, because
   every tied node's uid is in the bytes) are facts about **832 fixtures**. See
   `tools/_t364-x-tie-census.py`, population 4.
