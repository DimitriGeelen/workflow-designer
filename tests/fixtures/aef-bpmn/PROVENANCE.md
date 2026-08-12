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
| `dispatch-loop` | T-215 | **pair-draft** (AEF arc-015) |
| `offpage-seam` | T-219 | **pair-draft** |
| `s4-exemplar` | T-235 | 832-authored |
| `bare-catch-event` | T-308 | 832-authored |
| `lane-position-conflict` | T-310 | 832-authored |
| `doc-comment` | T-311 | 832-authored |
| `lane-geometry-partial-overflow`, `lane-geometry-unpositioned` | T-312 | 832-authored |
| `lane-capacity-large-spill` | T-313 | 832-authored |

**Not one file was handed to us by AEF.** The rest are ours outright.

> **The three `pair-draft` rows are asserted on 832 evidence alone.** They are labelled
> pair-draft in *our* commit subjects and nowhere else. Asked to confirm (DM 548 §6),
> AEF declined to do it from memory — *"a confirmation given from memory is exactly the
> 'name treated as evidence' failure this whole thread is about"* — and said to leave the
> table marked as ours until they can check their own designer-project history
> (DM 549 §6, 2026-08-12). **Unconfirmed by AEF as of that date.** If it stays
> unconfirmed, these rows are a one-sided claim about a two-sided fact, which is the same
> defect as the directory name — one degree smaller.

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
