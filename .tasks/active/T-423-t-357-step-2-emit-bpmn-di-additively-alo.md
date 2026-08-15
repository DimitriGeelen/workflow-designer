---
id: T-423
name: "T-357 step 2: emit BPMN DI additively alongside aef:position"
description: >
  Second of the three nested increments under T-357's GO. Emit bpmndi (dc:Bounds for shapes, di:waypoint for edges, label bounds) on export while continuing to write aef:position. Additive: no T-225 silent-migration question because nothing the author wrote is rewritten or dropped, and the intent extensions (forceStraight, routingHint, loopDetour) stay, so the spike-3 intent gap does not bite. Costs: all 24 corpus maps change bytes. [CORRECTED 2026-08-12 by T-473 — the clause that stood here, "so AEF's pinned source_bpmn_sha fixtures need a COORDINATED re-pin — this is the first step in the arc that touches the seam", is FALSE. Measured on AEF's side at rail 584 Q1: source_bpmn_sha is a provenance field THEIR promote tool writes into THEIR corpus meta, keyed by our IW-2 contract; it pins nothing of ours. They hold no copy of examples/aef-processes/rendered at all. The 24 maps are a ZERO-cost change at the seam. See ## Seam cost, corrected.] Blocked on step 1 (T-340 option b) landing. NOT blocked on A-020 — that was answered NO at rail 417 (2026-08-03) and is recorded invalidated: AEF never parsed or emitted DI and holds no record of agreeing to. The consequence sharpens this task rather than gating it — with no downstream DI generator on either side of the seam, emitting DI is NET-NEW CAPABILITY on both sides, not the completion of a handoff someone else was already honouring. Nobody is waiting for these bytes, and [CORRECTED by T-473: "the re-pin is the whole cost" was the conclusion drawn from the false premise above — there is no re-pin, so the seam cost is zero and the remaining cost is entirely one-party: our own _t308-export-byte-identity goes 24/24 drifted] the benefit is portability to standard viewers (bpmn.io, Camunda), not AEF interop.

status: started-work
workflow_type: build
owner: claude-code
horizon: now
tags: []
components: []
related_tasks: [T-357, T-340, T-424, T-425]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-10T20:23:27Z
last_update: 2026-08-15T09:29:30Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-423: T-357 step 2: emit BPMN DI additively alongside aef:position

## Context

Step 2 of three under T-357's GO (operator, 2026-08-10). Research: `docs/reports/T-357-di-adoption.md`.

**Not started — this task is scoped, not built.** ACs written now because G-020 requires
real criteria before any source edit, and because writing them is what exposes whether the
step is actually ready. It is not: it sits behind T-340's ruling.

Why this is the first step that touches the seam: steps land in strict subset order, and
step 1 (T-340 scoped `b`) is byte-neutral because the two populations are disjoint —
121 of 126 files carry `aef:position` and none carry DI. Step 2 breaks that: **every**
export gains a `bpmndi` sub-tree, so all 24 corpus maps change bytes.

> **CORRECTED 2026-08-12 (T-473).** This paragraph ended *"and AEF's pinned
> `source_bpmn_sha` fixtures go red. That is a coordinated re-pin, not a unilateral
> change."* Both sentences are false, and with them the claim that step 2 is the first step
> that touches the seam. See **§ Seam cost, corrected** below.

What A-020's answer changed: there is no DI generator anywhere — not on AEF's side (rail
417: `bpmndi` occurs once in their source, a namespace declaration with no reader or
writer) and not on ours. So emitting DI is net-new capability, and the beneficiary is any
standard viewer (bpmn.io, Camunda), **not** AEF. Nobody is waiting for these bytes. That
removes the urgency and clarifies the trade: ~~pay a two-party re-pin~~ **pay a one-party
byte churn on our own `_t308` baseline**, buy portability.

## Seam cost, corrected (2026-08-12, T-473 — from AEF's measurement at rail 584)

**The seam cost of this task is zero.** Not "small" — the mechanism it was attributed to
does not exist:

- `source_bpmn_sha` is a **provenance field AEF's own `bpmn_promote.py` writes into AEF's
  corpus meta**, keyed `(uid, source_bpmn_sha)` per our IW-2 contract. It records the sha of
  the staged BPMN *they* are promoting — their file. It has never pinned our bytes.
- **AEF holds no copy of `examples/aef-processes/rendered/`.** Their own T-2522 report says
  *"there is no rendered corpus in AEF"*; the only occurrences of our paths in their tree are
  prose in two reports.

So all 24 maps can change bytes with no coordination required and nothing of theirs going
red. What survives is a **one-party** cost that was never AEF's: our own
`_t308-export-byte-identity` goes 24/24 drifted. That is a baseline we own and refresh.

### What AEF actually vendors — six artifacts, byte-digested, two of them ours

| their constant | file | export-path output here? |
|---|---|---|
| `SHA_832_TYPED` | `tests/fixtures/aef-bpmn/typed-events.bpmn` | **no** |
| `SHA_832_BOUNDARY` | `tests/fixtures/aef-bpmn/boundary-events.bpmn` | **no** |
| `CANONICAL_SHA256` | their `inception-gonogo-canonical.bpmn` | their file |
| `RESUME_STATUS_SHA256` | their `resume-status-canonical.bpmn` | their file |
| `832/pair-draft-3.sha256` | their vendored copy | their file |
| `832/s4-exemplar.sha256` | their vendored copy | their file |

**Read the last row carefully before it scares a later reader.** We do have an
`s4-exemplar.bpmn` and it *is* export-path output — but AEF's digest guards **their vendored
copy at their path**. Regenerating ours does not touch their file and cannot turn their guard
red. Only a **re-delivery** of new bytes would, and that is a deliberate act.

The two rows that are genuinely ours-and-theirs (`typed-events`, `boundary-events`) are both
**not** export-path output — the T-469 finding, now confirmed from the other end.

### Announcement protocol (AEF's stated preference, rail 584 Q4)

If any of the six ever moves: **a rail post, one line per changed artifact, `path + old →
new` digest, inline.** Not a manifest (the digests *are* the payload, and there are at most
six), not a version bump (it carries no per-file digests). Manifest only if a single change
ever moves more than ~10 at once.

**Lead time is wanted for notice, not for work.** Their cost is one constant edit plus one
test run — minutes. The reason to announce *before* is that their guard's failure message
tells the reader to conclude someone mutated a fixture locally; an unannounced change makes
a true event read as tampering.

## Ordering satisfied, and two obstacles the ACs did not anticipate (2026-08-14)

**The gate this task was waiting on is open.** Operator recorded ruling (b) as PD-200 and
step 1 landed at `fc7f7263`: the importer now reads DI behind `aef:position`, and the
emitter re-emits DI when the input carried it. So the first AC below is satisfied and the
two-contradictory-geometries risk it names is gone — DI written by step 2 is now readable.

Two things block the rest, neither of which is in the ACs:

**(1) The `DI_TRAILER` disposition is unowned, and step 2 forces it.**
Step 1 left the emitter as `if (sourceCarriedDi) { DI block } else { trailer }`. Step 2
makes DI unconditional, so the `else` never fires and `DI_TRAILER_PREFIX` stops being
emitted — permanently, on every export. That prefix is documented at `src:9430` as
load-bearing: *"documents exported by all 11 prior releases carry it, and both readers
match on it."*

- **Our reader is fine.** `src:9540` uses it only to decide that a comment consisting of
  nothing but the trailer is not an authored doc comment. Absent trailer → null doc
  comment, which is the same outcome. Checked, not assumed.
- **AEF's reader is not visible from here** and is the reason this is a rail question
  rather than a code question.

The task that would have owned this is **T-425, closed `work-completed` as a duplicate** —
correctly, because the defect it was filed against had already been fixed by T-361. But
withdrawing it retired the ticket and not the obligation, and step 2 is where that
surfaces. Same shape as this week's others: something closed for a good reason leaves an
adjacent question with no owner, and the next step walks into it.

> ### RESOLVED 2026-08-14 — AEF answered, and the answer inverts the assumption
>
> Their reader **does** match on the string, and it does not matter, because of a
> distinction I had no way to see from here: `tools/corpus_spec.py:153` defines
> `_DI_TRAILER_PREFIX`, used at `:194` inside `_is_boilerplate_comment()` as a **negative
> filter, not a positive requirement.** Its job is to stop the trailer being laundered into
> a map's doc slot — their position-blind reader adopted a trailing comment, `generate()`
> re-emitted it in leading position, and the corruption became indistinguishable from
> authored doc (their T-2682, which hit two already-promoted maps).
>
> **So nothing in their tree requires the trailer to be EMITTED — only RECOGNISED when
> present.** New exports carrying no trailer match nothing and land correctly. They said
> explicitly: proceed, no sequencing needed against them.
>
> Two constraints, recorded as constraints rather than preferences:
>
> 1. **Their constant stays.** All 11 prior releases' documents carry the trailer and their
>    fixtures encode them as historical-document regressions. Nothing here touches those.
> 2. **Dropping it is safe; changing its wording is not.** They pin three live wordings, and
>    the prefix match exists precisely because the tail drifts; a *fourth* phrasing would
>    reopen T-2682's hole on that variant. **This task makes the `else` unreachable and
>    rewords nothing** — the string stops being emitted, it does not become a different
>    string. That distinction is now a constraint on the implementation, not a detail.
>
> Also recorded because it is the more interesting half: their guard is deliberately **not**
> producer-gated, and their source says in as many words *"do not 'correct' this to match
> theirs."* Our T-406 inference works because the boilerplate is *our* text, so a document
> naming another producer cannot carry it. Theirs arrives through their own reader and
> leaves stamped `exporter="aef-corpus-spec"` — a laundered document names **them**, so
> producer-gating would blind the guard in exactly the case it exists for. Two correct
> answers with opposite shapes because the threat models are mirror images. Not to be
> "aligned" in either direction.

**(2) The schema-validation AC cannot be satisfied in this environment.**
It requires validating an exported map against the BPMN 2.0 DI schema and explicitly rules
out the cheap substitute (*"not by grepping for the element names"* — which is the right
instruction and is exactly what this week says about mention-vs-instance). There is no
`xmllint` on this host and no `.xsd` anywhere in the tree. The AC is not wrong; it is
unbuildable until a validator exists. Left unticked and stated rather than downgraded into
a grep, which is the failure it was written to prevent.

> **Re-measured 2026-08-14, and it still stands — this is now the ONLY blocker.**
> `find . -iname '*.xsd'` → nothing in the tree; `command -v xmllint` → absent. With
> obstacle (1) resolved above, the blocker list went from two to one, and the survivor is
> the one that needs no other party.
>
> **It is a decision, not a task.** Satisfying AC2 means vendoring a third-party XSD into
> this repo or installing a system validator — both scoping choices that a "proceed as you
> see fit" directive does not carry, since that delegates initiative and not authority. In
> front of the operator.
>
> **Deliberately not done: rewording AC2 into something satisfiable.** A structural check —
> assert every `BPMNShape/@bpmnElement` resolves to a real node id, every `BPMNEdge` carries
> at least two waypoints — is far stronger than a grep and arguably honours the intent. It
> is still not what the AC says. T-340's own file carries the argument: *"a task whose scope
> is blocked should look blocked, rather than reworded into something satisfiable."*
> Building the emitter and verifying it by the one method the AC excludes would produce a
> green task and an unvalidated emitter, which is the worst of the three outcomes available.

> ### RE-MEASURED 2026-08-15 (T-510 session) — the blocker is SMALLER than stated, and one of the options put to the operator is now dominated
>
> The paragraph above says AC2 needs *"vendoring a third-party XSD into this repo **or**
> installing a system validator."* Measured today, the second half is unnecessary and the
> first half is five files. The four options I put in front of the operator were priced by
> assumption; here they are priced by measurement.
>
> **(a) A validator is already installed. No host mutation is required.**
> ```
> python3 -c "from lxml import etree; print(etree.LIBXML_VERSION, hasattr(etree,'XMLSchema'))"
> → (2, 9, 14) True          # lxml 5.2.1, XMLSchema present
> command -v xmllint  → ABSENT
> ```
> `lxml.etree.XMLSchema` is the same libxml2 engine `xmllint --schema` drives. So option (b)
> "install `xmllint`" buys nothing that is not already here, and it was the only option that
> would have written outside `/opt/832-Workflow-designer` — i.e. the only one that collided
> with the T-559 boundary as well as with scope. **Withdrawn as dominated**, not chosen.
>
> **(b) Our exports are validatable BY CONSTRUCTION, which was not established before.**
> This is the finding that actually matters, because if it had gone the other way AC2 would
> have been unsatisfiable rather than merely unbuilt. Every `aef:` element in a rendered map
> sits inside `bpmn:extensionElements` (`arc-lifecycle.bpmn:51-58`), never loose in the BPMN
> content model. `Semantic.xsd` types that element as
> `<xsd:any namespace="##other" processContents="lax" minOccurs="0" maxOccurs="unbounded"/>`,
> and `tBaseElement` carries `<xsd:anyAttribute namespace="##other" processContents="lax"/>`.
> `##other` admits our namespace; `lax` means "validate only if a schema for it is loaded",
> and none will be. So the 13 `aef:` element kinds and their attributes pass through untested
> rather than failing — a schema run would report on the BPMN and DI, which is exactly what
> AC2 asks it to report on.
>
> **(c) The vendoring closure is five files, and it is the WHOLE remaining decision.**
> Walked from the root by reading each schema's own import/include list rather than assuming
> the set:
> ```
> BPMN20.xsd   include Semantic.xsd            import BPMNDI.xsd (…/BPMN/20100524/DI)
> BPMNDI.xsd   import  DC.xsd (…/DD/20100524/DC)  import DI.xsd (…/DD/20100524/DI)
> DI.xsd       import  DC.xsd
> ```
> Closure = **BPMN20.xsd, Semantic.xsd, BPMNDI.xsd, DC.xsd, DI.xsd**. Note the shape: DI
> cannot be validated standalone — `BPMNDI.xsd` describes shapes that reference BPMN element
> ids, so the schema run is over the whole exported document, all five files or none.
>
> **HONESTY MARKERS ON THE THREE ABOVE, because this task's session is the one that shipped a
> mechanism it had not checked (PL-204):**
> * (a) and (b)-the-`extensionElements`-shape are measured **here, on this tree**, and the
>   commands are in `## Verification`.
> * (b)-the-`Semantic.xsd`-quote and (c)-the-closure are read from the **served** OMG schemas
>   through a summarising fetch. They are second-hand and **not byte-verified here**, because
>   byte-verifying them means writing them into the tree, which is the decision itself. Treat
>   the closure as "five files, confirm on vendoring" rather than as established fact.
> * **Not measured at all, and it is the operator's half anyway:** the OMG licence terms. The
>   schema files carry no notice in their own body; the spec page's terms were not read.
> * **Not measured:** whether libxml2 2.9.14 loads this particular schema set cleanly. That
>   is testable in one command the moment the files exist, and untestable before.
>
> **What this leaves in front of the operator** — one question instead of four options:
> *may five third-party OMG schema files be vendored into this repo?* Yes → AC2 is buildable
> today with no further asks and step 2 unblocks. No → AC2 stands unsatisfiable as written
> and the honest move is an explicit scope amendment recorded as a decision, still theirs.
>
> **Still deliberately not done:** rewording AC2 into the structural check, and building the
> emitter ahead of the ruling. The paragraph above gives the reasons and none of them
> changed — what changed is only the price of saying yes.

**Status: `started-work` (set by `fw work-on` when I opened it to record this). No source
edited under this task, and none will be until §2's rail question is answered.** An earlier
draft of this paragraph said `captured`, which was true when I wrote the sentence and false
by the time it was committed — the same stale-claim shape as T-340's BLOCKED paragraph,
caught one commit later instead of twelve days.

## Acceptance Criteria

### Agent
- [x] **Ordering respected: this task does not start until T-340 is ruled and step 1 has
      landed.** Step 2's precedence rule (`aef:position` → else DI) is step 1's deliverable;
      building step 2 first means writing DI that the importer cannot yet read, which is
      the two-contradictory-geometries state PL-114 exists to prevent, self-inflicted.
      **Satisfied 2026-08-14: PD-200 ruled, step 1 landed at `fc7f7263`.**
- [ ] `bpmndi:BPMNDiagram` / `bpmndi:BPMNPlane` emitted on export with `dc:Bounds` for every
      shape, `di:waypoint` for every edge, and label bounds where a label position is
      persisted. Verified by validating one exported map against the BPMN 2.0 DI schema —
      not by grepping for the element names.
- [ ] `aef:position` is **still written**, unchanged, on every node. This is the property
      that keeps step 2 out of T-225's scope: it adds a representation and rewrites nothing.
      A diff of one round-tripped map shows DI added and no existing element removed or
      reordered.
- [ ] The intent extensions (`forceStraight` 12, `routingHint` 22, `loopDetour` 9,
      `anchors` 19, `aef:waypoint` 1) are untouched. Spike 3 established DI has no
      vocabulary for layout *intent*, only for computed results, so DI cannot carry these
      and must not be treated as having replaced them.
- [ ] Round-trip is lossless in both directions: export → re-import → export produces
      byte-identical output on all 24 corpus maps. A DI emitter that is not idempotent
      makes every save a spurious diff.
- [ ] ~~**Re-pin is coordinated, not announced.**~~ **VOID 2026-08-12 (T-473)** — this AC
      required agreement AEF has no stake in. It read: *"AEF's `source_bpmn_sha` fixtures are
      pinned over whole files; all 24 change. Agreed with AEF on the rail BEFORE the bytes
      change."* They pin none of the 24 and hold no copy of the corpus (rail 584 Q1/Q3).
      **Replacement obligation, which is weaker and different in kind:** none of AEF's six
      vendored digests is touched by this task, so nothing needs agreeing. *If* a future
      change moves one of the six, announce per § Seam cost → Announcement protocol — a
      rail post, one line per artifact, `path + old → new`, before the bytes change. Notice,
      not permission.
- [x] A competing-carrier guard exists, in AEF's shape rather than ours: they pin
      `test_di_drop_has_a_competing_carrier`, which asserts the rival carrier *exists* —
      delete `aef:position` and the test goes red. Our equivalent must fail loudly the day
      step 3 removes `aef:position`, instead of silently permitting two geometries.
      (Adopting their instrument, not just their answer — T-340's Human AC records why.)
      **DONE 2026-08-15.** `tools/_t423-position-carrier-guard.py`, wired as a standing leg
      of `tests/run-bridge-tests.sh` (suite 80 → 81 passed, 0 failed). Three assertions,
      none of them a count: every flow node carries **exactly one** `aef:position` (zero
      misses), no `aef:position` lives outside a flow node's own `bpmn:extensionElements`
      (zero strays), and at least one map with at least one node — the last because the
      first two are both satisfied by an empty corpus, so without it deleting the corpus
      turns the guard green. Teeth in `tools/_t423-position-carrier-teeth.py`, 6/6, picked
      up by T-509's instrument sweep by name (population 24 → 25, runnable 19/19 → 20/20)
      so they have a standing caller rather than a second hand-wired leg. Legs 2–4 are
      AEF's shape exactly — drop one carrier, drop a map's worth, add a stray — and leg 6
      is the anti-overfit control: a benign coordinate edit must leave it **green**, which
      is what separates this from a guard that merely reddens on any diff.
      **KNOWN LIMIT, recorded the day it landed rather than discovered later — see the AC
      below.** This guard proves the carrier is *present*. It cannot prove the two carriers
      *agree*, because until the emitter exists there is nothing to disagree with.
- [ ] **The two carriers must be shown to AGREE, not merely to both exist.** `dc:Bounds`
      x/y must match `aef:position` x/y for every node, within a stated tolerance, and the
      check must be watched going red when they are made to differ. **This AC exists
      because of AEF at rail 11876**, reporting their own index canary was a false green
      *twice*: once because the control was sized so it could never trip, and once because
      — already genuinely broken — it still ranked first, since on a small index *"is the
      canary the top hit?"* is satisfied by having **no rival**. They had to plant a decoy
      that wins when the canary is broken before the assertion meant anything. Their
      question, transferred here verbatim: *"has anyone watched it go red, against a real
      artefact, with a real competitor?"* Applied here the answer is uncomfortable — the
      moment DI lands, `aef:position` **has** a rival, and the guard ticked above stays
      green while the two geometries drift apart, which is the exact failure its own
      docstring claims to guard. Present-and-agreeing is the assertion; present-alone was
      only ever the half that could be built before the emitter existed.

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

# ── AC2's two PRECONDITIONS, measured 2026-08-15 and pinned here ─────────────────────
# Not global moving state: both are properties AC2 rests on, and if either stops holding
# AC2 genuinely stops being satisfiable. The first says a schema engine exists without a
# host change; the second says our extension content is parked where BPMN20's `xsd:any
# processContents="lax"` admits it, so a schema run reports on the BPMN and DI rather than
# tripping over 13 aef: element kinds. Neither counts a population.
python3 -c "from lxml import etree; import sys; sys.exit(0 if hasattr(etree, 'XMLSchema') else 1)"
python3 -c "import re,sys,glob; f=sorted(glob.glob('examples/aef-processes/rendered/*.bpmn'))[0]; s=open(f).read(); loose=[m for m in re.finditer(r'<aef:', s) if s.rfind('<bpmn:extensionElements', 0, m.start()) <= s.rfind('</bpmn:extensionElements>', 0, m.start())]; sys.exit(1 if loose else 0)"

# ── The competing-carrier guard (landed 2026-08-15, AC ticked) ───────────────────────
# WHY `bash tests/run-bridge-tests.sh` IS DELIBERATELY ABSENT, for the third task running:
# the suite's green is a GLOBAL, ALWAYS-MOVING property — G-015 / PL-200's exact class.
# Under a daily re-runner it goes red for somebody else's change and this task's record
# would then be lying about this task. The legs below are properties of THIS deliverable.
#
# The teeth are the load-bearing leg. They build their own population under mkdtemp in the
# same breath as using it, so they cannot go stale as the corpus grows (T-508's one
# CORRECT count-pinning shape), and they prove the guard DISCRIMINATES: red on a dropped
# carrier, red on a stray one, REFUSAL on an empty corpus, and still green on a benign
# coordinate edit — that last one is the anti-overfit leg without which a guard that
# reddened on any diff would pass everything else.
python3 tools/_t423-position-carrier-teeth.py > /dev/null
python3 tools/_t423-position-carrier-guard.py > /dev/null
grep -q '_t423-position-carrier-guard.py' tests/run-bridge-tests.sh
# No population pin in the guard: today's corpus size must appear nowhere in EXECUTABLE
# code. Deliberately an AST walk and not a grep — the first version of this leg was
# `! grep -q 306 …` and it failed, correctly, because the docstring quotes `nodes == 306`
# in the passage explaining the shape the guard must not take. A grep cannot tell the
# warning from the defect; excluding docstrings is the whole distinction.
python3 -c "import ast,sys; t=ast.parse(open('tools/_t423-position-carrier-guard.py').read()); d={ast.get_docstring(n,clean=False) for n in ast.walk(t) if isinstance(n,(ast.Module,ast.FunctionDef,ast.AsyncFunctionDef,ast.ClassDef))}; bad=[n for n in ast.walk(t) if isinstance(n,ast.Constant) and n.value not in d and '306' in str(n.value)]; sys.exit(1 if bad else 0)"
python3 -c "import py_compile,sys; py_compile.compile('tools/_t423-position-carrier-guard.py', doraise=True); py_compile.compile('tools/_t423-position-carrier-teeth.py', doraise=True)"

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

### 2026-08-15 — AC2 was priced by assumption; priced by measurement it is one yes/no

- **What changed:** three things I had been treating as unknown or as costs.
  (1) A schema engine is **already on this host** — `lxml.etree.XMLSchema`, the same libxml2
  that backs `xmllint --schema`. Every prior statement of this blocker said "vendor a schema
  **or install a validator**"; the second disjunct was never needed and is the only one that
  would have written outside the project boundary.
  (2) Our exports are **validatable by construction**, which nobody had established. All 13
  `aef:` element kinds live under `bpmn:extensionElements`, typed in `Semantic.xsd` as
  `xsd:any namespace="##other" processContents="lax"`, with `tBaseElement` carrying the
  matching `anyAttribute`. Had this gone the other way — loose `aef:` elements in the BPMN
  content model — AC2 would have been **unsatisfiable**, not merely unbuilt, and the right
  answer would have been an AC rewrite rather than a vendoring decision.
  (3) The vendoring closure is **five files** (`BPMN20`, `Semantic`, `BPMNDI`, `DC`, `DI`),
  walked by reading each schema's own import list, and DI cannot be validated standalone —
  `BPMNDI` references BPMN element ids, so it is all five or none.
- **Plan impact:** the blocker paragraph above overstated the ask. The operator's question
  drops from four options to one: *may five third-party OMG schema files be vendored here?*
  Option (b), install `xmllint`, is withdrawn as dominated rather than declined.
- **Triggered:** nothing built. Two preconditions added to `## Verification` — and the
  second was **checked for vacuity before being trusted**, since a green from a check that
  cannot fire is the exact defect `_t364-t308-teeth.py` exists to catch. Fed the classifier
  three synthetic documents: `aef:` inside `extensionElements` → 0, `aef:` after the closing
  tag → 1, `aef:` with no `extensionElements` at all → 1. The 0 on the real corpus is a
  classification, not an absence.
- **Not triggered, deliberately:** the emitter. Nothing here changes the argument for
  waiting — only the price of the answer.

### 2026-08-15 — the competing-carrier AC does not depend on the blocker, and its measurement is in

- **What changed:** the last Agent AC (*"a competing-carrier guard exists, in AEF's shape"* —
  their `test_di_drop_has_a_competing_carrier`, which goes red when the rival carrier is
  deleted) has been sitting behind the same blocker as the rest of the task. It does not
  belong there. That guard asserts `aef:position` **exists**; it needs no DI, no schema and
  no emitter. It is buildable today and is the one piece of this task the operator's
  vendoring ruling does not gate.
- **Measured, so the next window builds instead of re-measuring:**
  ```
  maps=24  nodes=306  aef:position=306   maps with fewer positions than nodes: 0
  ```
  Exact 1:1 across the whole rendered corpus. So the invariant the guard would protect
  holds today and the guard would not land red on a pre-existing backlog — the T-491 rule.
- **The shape it must NOT take, and this task is the reason to say so out loud.** The
  obvious leg is `nodes == 306 && positions == 306`. That is **population-pinned** — G-015's
  exact class, 17 instances of which this project catalogued two days ago — and it falsifies
  itself the first time a map is added. The correct assertion is **per-node and ratio-shaped**:
  *every node carries exactly one `aef:position`*, i.e. zero maps where the position count is
  under the node count. That is what the measurement above actually reports (`gaps: 0`), it
  is an emptiness assertion, and it does not go stale as the corpus grows.
- **Plan impact:** none to the blocked half. This AC can be split out and landed independently
  the moment there is budget for a source-adjacent write; it is recorded here rather than
  built because the context budget crossed the framework's critical line mid-session and
  writes to `tools/` are blocked there by design.
- **Triggered:** nothing yet. Next window: build the guard, wire it, tick this AC alone.

### 2026-08-15 — built, wired, and one AC of a blocked task is now closed

- **What changed:** the entry above was a plan; this is its outcome. The guard and its teeth
  exist, the guard is a standing suite leg, and that AC is ticked. **The rest of T-423 is
  untouched and still blocked** on the operator's five-file vendoring ruling — no DI emitter,
  no schema, no XSD. Splitting the AC out was the whole point: it was never behind the
  blocker and had been sitting there for weeks because nobody separated the two.
- **The measurement held.** 24 maps, 306 nodes, 306 positions, and the per-file set identity
  is exact — the ids in each map's `laneSet/flowNodeRef` are precisely the ids of flow nodes
  carrying one `aef:position`, on all 24, no exceptions. Three independent counts agreeing is
  why the guard could land green rather than red on a backlog (T-491's rule).
- **Two things the build found that the plan did not:**
  1. **A truncation bug in my own teeth**, caught by the teeth failing rather than by review:
     `open(v,"w").write(f(open(v).read()))` truncates before the nested read runs, so two
     legs fed the guard an *empty file*. Both went red — for the wrong reason. Had the guard
     been sloppier and treated an unparseable map as "no violations found", those legs would
     have gone **green** for the wrong reason and I would have shipped teeth that prove
     nothing. The guard refusing (rc 2) on unparseable input is what made the bug visible.
     The comment is left in the file at the fix site.
  2. **The no-population-pin verification leg had to become an AST walk.** The obvious
     `! grep -q 306 …` failed — correctly — because the guard's docstring *quotes*
     `nodes == 306` in the passage explaining the shape to avoid. A grep cannot distinguish
     the warning from the defect. The leg now parses the module and excludes docstrings, and
     it was checked against an injected pin to confirm it still fires.
- **Not triggered:** the emitter, the schema, the vendoring question. Unchanged.

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-10T20:23:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md
- **Context:** Initial task creation

### 2026-08-10T20:29:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-08-10T20:31:11Z — status-update [task-update-agent]
- **Change:** status: started-work → captured

### 2026-08-14T15:24:27Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
