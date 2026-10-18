# T-1165 — Does the rule-dialect axis need a CONVENTIONAL class?

Inception research artifact (C-001). Origin: OBS-467 (T-967, 2026-10-01). Status: exploration complete, recommendation
below, decision is the operator's (`fw inception decide T-1165 go|no-go`).

## The question

Every validator rule carries a dialect class, derived in `tests/test_rule_dialect_axis.py` from what the frozen
standard (`docs/standards/aef-bpmn-mapping-v1.md`) says about the carrier the rule reads:

| class | derivation (`classify()`, axis line ~356) | what the kit tells authors |
|---|---|---|
| PRESENTATIONAL | every carrier is §1 Presentational | "layout only" |
| DIALECT-RELATIVE | REQUIRES polarity over a SEMANTIC_OPTIONAL carrier | "house convention, not the standard" |
| UNIVERSAL | everything else | "any conformant document satisfies it" |

W-XML-DISCONNECTED fires when the flow graph falls into more than one weakly-connected component. The standard
nowhere requires connectivity, yet the derivation returns UNIVERSAL, because `sequenceFlow` is a STRUCTURE carrier
and no branch of `classify()` looks at whether the standard backs a structural property at all.

## Findings

### F1 — The standard is silent on graph shape (IW-1: answered, confidence 3)

mapping-v1 §6 defines v1-conformance by four requirements: the §1 partition is honoured, the §2 meta-keys
round-trip, `aef:uid` is stable (§5), and presentational edits are no-ops. None of them concerns connectivity,
start/end events, reachability, dead ends or gateway balance. §3 maps elements to concepts ("sequence flow = ordering
dependency", "startEvent / endEvent = process boundary markers, no task") without requiring any of them to be
present or connected. BPMN 2.0 itself admits a process with no start event and with disconnected fragments.

So the authoring kit currently tells every external author that a disconnected map, or one without a start event,
fails something "any conformant document satisfies". That is false (see the kit's `CONFORMANCE.md` rows, last
generated for calibration job 030: all seven graph-shape WARNs it lists print `UNIVERSAL`. The kit documents the
XML form only, so it shows 7 of the 13 rules below; the other 6 are their YAML-form twins).

One qualification (independent review): §3 line 89 ("fork = independent tasks; join = barrier") is a semantic hook
someone could cite for W-PGW-UNBALANCED. It describes what a join means, not that every fork MUST have one, so it is
not a requirement; but it is the nearest text, and the build task should rule on it explicitly.

### F2 — It is a population, not one rule (IW-2: answered, confidence 3)

Measured over `RULE_CARRIERS` (63 rules: 55 UNIVERSAL, 4 DIALECT-RELATIVE, 4 PRESENTATIONAL): **31 rules read
STRUCTURE carriers only, and all 31 derive UNIVERSAL.** By what actually backs them:

| tier | rules | backed by | today | honest class |
|---|---|---|---|---|
| A — absence of a structural feature | W-XML-DISCONNECTED; W-NO-START-EVENT, W-NO-END-EVENT, and their XML twins (5) | nothing: standard and BPMN silent; the axis file itself already flags all five as "the OBS-467 model gap" | UNIVERSAL | CONVENTIONAL |
| B — graph-quality heuristics | W-UNREACHABLE, W-DEADEND, W-PGW-NOOP, W-PGW-UNBALANCED, and their XML twins (8) | nothing normative: house expectations about well-formed flows | UNIVERSAL | CONVENTIONAL |
| C — well-formedness | the 18 E-* structural rules (dangling refs, duplicate ids, unparseable document, missing lane, node type, …) | XML / BPMN schema validity (ID/IDREF, element vocabulary) or mapping-v1 §3 (a lane is the owner) | UNIVERSAL | UNIVERSAL, each with its citation |

Tier C is not uniformly safe either. E-XML-GW-OUTGOING refused the ordinary BPMN converging XOR gateway as an ERROR
until T-977, found by an external reviewer using the authoring kit (T-975 X7), the same class as T-970. Its remaining
refusal (a 1-in/1-out gateway) is defensible as "decides nothing" but is still a house rule, not BPMN. That history
is the cost of this gap made concrete: rules labelled universal that refuse standard BPMN get found by outsiders.

Expected outcome if built: 13 rules (tiers A+B) move to CONVENTIONAL; the 18 tier-C rules stay UNIVERSAL with a
cited basis, and any that cannot cite one surface as a finding rather than staying silently universal.

### F3 — It can be derived, but needs one new declared input (IW-3: answered, confidence 2)

`classify()` has no input that says whether the standard backs a structural property; carrier class and polarity
cannot express it (that is exactly why W-XML-DISCONNECTED came out UNIVERSAL). So the derivation needs a new input,
and T-323's rule ("derived, never asserted") constrains its shape:

- a per-rule `basis` for STRUCTURE-only rules: a citation of a normative source, either a mapping-v1 anchor (a
  section plus a quoted phrase the test finds verbatim in the standard file, the same way `_bullet()` already
  reads §1) or a named well-formedness ground (`xml-id`, `xml-idref`, `bpmn-schema`);
- `classify()` then derives: a STRUCTURE-only rule with a resolving citation is UNIVERSAL; with none it is
  CONVENTIONAL. A citation that does not resolve fails the test, so the class cannot be asserted by typing a
  label. This is the same pattern as the existing `UNRATIFIED` carrier list: declared, but checked against the
  standard's own text every run.

Confidence 2, not 3: the citation check is mechanical, but whether a quoted phrase really *requires* the property
is still a reading. The test can prove a citation exists, not that it is apt. That limit should be printed by the
test, as the axis already prints what it does not prove.

### F4 — Who sees the change (IW-4: answered, confidence 3)

- **Authoring kit** (`tools/build-authoring-kit.py`): the CONFORMANCE.md rule table and its class legend. A changed
  table changes the kit's bytes, so the kit calibration gate (codex + GLM-5.3, `tools/kit-calibration-gate.py`)
  must be re-run before the next designer release.
- **AEF**: receives the kit with every release; 13 rows change class. No AEF-stored data changes (classes are not
  written into maps), so no migration, but the announcement must say so.
- **Designer**: does not consume the axis yet (stand-in comment at `src/aef-workflow-designer.html:10713`), so no
  UI change. When it does, the class is what decides whether a finding is shown as a defect or a convention, which is
  where this matters most.
- **Validator output**: unchanged. Severity and messages stay; only the class label moves.

## Options

1. **Fourth class, CONVENTIONAL** (OBS-467's remedy). Keeps DIALECT-RELATIVE meaning one precise thing (an optional
   carrier was omitted: fix by adding it, or ignore it as the peer's dialect), and gives graph-shape house rules
   their own label (fix by restructuring, or ignore as our style). Cost: one more word in the kit legend.
2. **Fold into DIALECT-RELATIVE.** The kit already glosses that class as "house convention, not the standard", so
   authors would read the same message. Cheaper, but it blurs the derivation: DIALECT-RELATIVE would mean either
   "optional carrier absent" or "unbacked structure", and the polarity hinge that makes the axis checkable
   (REQUIRES vs CONSTRAINS on one carrier) no longer explains the class.
3. **Do nothing.** Keeps a false claim in every kit we ship and every finding a future designer surfaces.

## Recommendation

**GO, option 1**, as one bounded build task:
- add `basis` to the axis for the 31 structure-only rules, derive CONVENTIONAL from a missing basis, and fail on a
  citation that does not resolve;
- regenerate the kit; re-run kit calibration; ship with the next designer release and name the 13 class changes in
  the AEF announcement;
- out of scope: changing any rule's severity or predicate, and the designer consuming the axis (its own task).

Bounded: one test file, one generator, one legend; reversible (a label, no stored data); testable (the axis test
already derives and counts every class, so 13 moves and 18 citations are assertable).

The choice between option 1 and option 2 is a vocabulary decision for map authors, so it is the operator's.
Option 2 is a fine answer too; both beat option 3.

## External consultation (2026-10-18)

The operator asked for outside views before deciding. Two were requested:

**Independent reviewer** (a read-only TermLink worker, `t1165-review`, told to form its view before reading this
recommendation). Facts: confirmed (31/63 structure-only, all UNIVERSAL; 55/4/4 split; 13 without a normative basis;
§6 has no graph-shape clause). Pick: **option 1**, because the two cases ask the author for different actions (add a
carrier vs restructure). Its strongest counter-argument against its own pick: the kit legend already says "house
convention, not the standard", which is exactly true of the 13, so authors gain little from a fourth word; and
CONVENTIONAL is a negative class ("UNIVERSAL unless cited") that rests on a hand-kept citation table.
Additions this write-up missed, adopted for the build task if GO:
- **A third option: show the basis.** Keep the classes and add a `basis` column to the kit's CONFORMANCE.md, so an
  author sees *why* a rule is universal, and a blank basis explains itself. Compatible with option 1 or 2.
- **Harden the citation check:** require the quoted span to carry a normative keyword (MUST / MUST NOT / SHOULD,
  with SHOULD's status decided explicitly); make the non-standard grounds (`xml-id`, `xml-idref`, `bpmn-schema`) a
  closed list with their own probe; normalise whitespace before matching.
- **Fix upstream is a real alternative:** AEF could ratify a graph-shape clause in mapping-v1.x, which would make
  some of the 13 genuinely UNIVERSAL. That is AEF's call (asked, below).
- **Tier C needs its own criterion:** any E-* structural rule that cannot cite a basis (candidates: E-GW-OUTGOING's
  remaining 1-in/1-out refusal, E-LANES-EMPTY) must surface as a finding, not stay silently UNIVERSAL.
- Scope note: mixed rules with a SHOULD basis (W-TYPE-LANE-MISMATCH, §3 line 97) are outside the 31 and unchecked.

**AEF** (consulted on conversation `832-t1165-dialect-class`, msg f0550119): which label serves them as kit
consumer and co-owner of the standard, whether their compiler requires any of these graph properties, and whether
they would rather the standard say something. **Answer (msg f1f5ef6f):**
- Prefers **option 1**: "the standard is silent, our house style expects this shape" is a different statement from
  "an optional carrier was omitted"; folding them would make DIALECT-RELATIVE mean two things, "the same kind of
  mislabel you are fixing".
- (a) AEF requires **none** of these graph properties: their `tools/bpmn_to_tasks.py` compiles maps with no start
  event, unreachable or dead-end nodes without refusing (a task with no path from a start gets horizon "now" and no
  related_tasks, ~line 672), and their corpus lint has no graph-shape rule. So none of the 13 stays UNIVERSAL on
  AEF's account.
- (b) Yes to a **non-normative v1.x note** in the standard: it does not constrain connectivity or start/end events,
  and validators may flag them as conventions. That keeps the kit's UNIVERSAL gloss true.

Net: the reviewer and AEF independently pick option 1; AEF closes the "fix upstream" alternative in favour of a
clarifying note rather than a requirement.

## Dialogue log

- 2026-10-18: operator asked (in Dutch) what separates options 1 and 2, and whether outside consultation is
  possible. Answered with the add-a-carrier vs restructure distinction; AEF and an independent reviewer consulted.

- 2026-10-18: operator "proceed as you see fit" (backlog work delegated); this inception was chosen by the agent,
  research only, no build artifacts. No operator dialogue on the question itself yet.
