# T-975 — External review of the vendor authoring kit

**Task:** T-975 · **Date:** 2026-10-01 · **Kit under review:** `docs/authoring-kit/AUTHORING.md`
plus the generated `CONFORMANCE.md`, `exemplar.bpmn` and the validator (T-974).

The operator delegated the guide's review: *"Don't ask me to review the guide, you think about it
and if you need more then get external guidance."* So: my own critique first, written before any
reviewer replied so the reviews can be compared against it rather than absorbed into it, then
three external agents doing the job the guide is for.

---

## 1. My own critique (written before any external reply)

Read cold, as the Evergreen agent: a generator, a source, this kit, nothing else.

**C1. A false statement about `/api/save`.** The guide says the save response carries the
verdict. That holds only on our reference server (T-973). AEF's blueprint, the one Evergreen
actually saves through, does not have it yet. A vendor reading the guide would see no
`validation` key and could conclude the map was fine. The guide must say: no `validation` key
means this server does not validate, so run the validator yourself.

**C2. The aef namespace URI is never stated.** A generator cannot emit `aef:laneMeta` without
`xmlns:aef="http://anchorpoint.framework/aef/extensions"`. It is only discoverable by opening the
exemplar.

**C3. No guidance on what a lane IS.** Evergreen laned by *system* and invented a
"(systeem niet bekend)" lane. The authority vocabulary (sovereignty / authority / initiative /
external / none) is AEF's human/agent/framework governance axis, and the guide never maps it
onto a business process: a human department is `sovereignty` (a human performs it), an
automated system step is `authority`, a party outside the organisation is `external`. Without
that mapping a generator either guesses or omits, and omission is what happened.

**C4. `aef:uid` stability is asserted, not explained.** "Stable" requires deriving the uid from
the source's own identity (a step's ontology IRI, a requirement id), never from a counter or a
random value. Otherwise every regeneration is a new map. That was Evergreen's #2/#3: they had to
match round trips by lane+step name.

**C5. No snippet for the "order unknown" pattern.** The guide says "add a textAnnotation" but
not how: `textAnnotation` plus `association` to the steps.

**C6. Layout is not mentioned.** The operator's original complaint about Evergreen was that the
layout was messy. The guide says presentational data never changes meaning, which is true, but
says nothing about what a generator should emit for geometry (nothing, and let the designer lay
it out? lane-banded `aef:position`?). I do not yet know the right answer; this is a question for
the reviewers and for the trial.

**C7. `kind="work-plan"` is listed in CONFORMANCE.md and never explained.**

**C8. When to split.** One map per process; an overview that names sub-processes should link
them rather than inline them. Not covered.

### C6 answered by measurement, and the answer inverted my draft

Draft advice was going to be "emit no geometry; the designer lays the map out". Tested before
writing it, by importing one Evergreen map with and without its BPMN DI (screenshots read, then
deleted: their content is not ours to keep):

- Import precedence is `aef:position` -> BPMN DI -> auto-layout (src:11442). Evergreen's
  generator emitted DI (`BPMNShape` ×11 on bo-production, ×20 on primary, 0 `aef:position`),
  so its own coordinates were used.
- **With their DI the layout is reasonable** for that map: one row in flow order, orphans
  below.
- **With the DI stripped, the designer's layout is worse**: one row in DOCUMENT order (End_12 at
  x=210, ahead of Assembly at x=300), boxes overlapping. ✨ Clean layout keeps document order;
  it tidies rows, it does not layer by flow.

So "omit geometry" would have been wrong advice. The product gap is ours: **the designer has no
flow-aware layout**. Filed as **T-976**. Until it lands, the guide's honest advice is cheap and
true: if you emit no geometry, write elements in flow order, because document order is what the
import layout follows.

## 2. The external panel

Brief, identical for each reviewer: act as a vendor's generating agent; given a synthetic source
text (an order-fulfilment process deliberately containing a human decision, an automated system
step, an external party, an undocumented step order and an out-of-scope sub-process) and ONLY
the kit, produce `map.bpmn`, validate it with the kit's validator, then report what you had to
guess, what the guide got wrong, and anything you were tempted to invent.

| reviewer | vendor | status |
|---|---|---|
| Codex | OpenAI | _pending_ |
| opencode · glm-5.2 | Z.ai (coding plan) | _pending_ |
| Vibe | Mistral | rate-limited at first probe; retried |
| cursor-agent | Cursor | not signed in, needs an interactive login; not used |

## 3. Replies and dispositions

### 3.1 Codex (OpenAI) — completed; map + REPORT.md

**What it did with the kit, which is itself the main result:** it invented nothing. Unknown
performers (who handles a rejection; what AEF authority ERP automation has) were declared
`authority="none"` rather than guessed. Inspection and labelling were left unconnected and
annotated. It refused every temptation it listed: connecting the unordered steps, giving the
rejection to sales, calling ERP `external` to silence a warning, marking the map documentation
to reduce findings. Final map: 0 errors, 7 warnings, all honest. **"Derive, never invent"
transferred.** What did not transfer is everything the guide leaves implicit.

| # | Codex point | verified? | disposition |
|---|---|---|---|
| X1 | Guide says "lane is sole authority, lane wins", but the validator prefers an element's `aef:meta authority` over its lane (T-889) | yes, src `_check_iw9_authority` | **fold**: guide states the real precedence (element if declared, else lane) |
| X2 | Unknown-order pattern also yields W-XML-UNREACHABLE + W-XML-DEADEND ×2 each, not just DISCONNECTED; DISCONNECTED's prose ("independent processes", "UNREACHABLE stays silent here") is false on this map; DEADEND's "control never terminates" overstates | yes, reproduced in its output | **fold** (guide lists all three) + **validator message fix**, new task |
| X3 | CONFORMANCE says DISCONNECTED is UNIVERSAL while its own code comment calls it a convention | yes; already OBS-467 | **defer** to OBS-467 (axis model gap), noted in guide |
| X4 | "Everything here is checkable" overpromises: uid presence, exactly-one lane membership, and workflowMeta field completeness are not checked | yes | **fold**: guide separates checked from unchecked requirements |
| X5 | `kind="documentation"` gates no validator rule, so the guide's claim misleads | yes; kind-aware applicability is known-unbuilt (T-971 §4.2) | **fold**: guide says what kind does today (stops task minting) and does not do (rules still apply) |
| X6 | Plain `task` missing from `NODE_OCCUPANCY`, so capacity checks skip lanes holding plain tasks | **yes, confirmed**: third table my T-970 missed | **fix** now in validator |
| X7 | Every exclusiveGateway must have ≥2 outgoing, so the standard BPMN merge pattern is an ERROR | **yes, confirmed** (src:1208) | **new task**: same class as T-970, rejecting standard BPMN |
| X8 | `E-XML-PARSE` / `E-LOAD` absent from CONFORMANCE | yes: emitted outside XmlValidator | **fold**: builder lists load/parse rules too |
| X9 | "Validate before you save" is unclear when the CLI needs a file on disk | fair | **fold**: write candidate -> validate -> publish |
| X10 | Governance decision table for business processes (departments, ERP automation, external parties, known performer vs unknown authority) | matches my C3 | **fold**: top priority |
| X11 | A worked partial-process example (known routing + unconnected same-process steps, every resulting warning listed) | matches C5 | **fold** |
| X12 | Serialization contract: identity generation, schemaVersion, kind vs isExecutable, condition syntax, merge pattern, geometry/DI | matches C2, C4, C6 | **fold** |

### 3.2 opencode · glm-5.2 (Z.ai) — completed; map + REPORT.md

Same headline as Codex: **it invented nothing**, and refused the same temptations (connect the
unordered steps, move the passive-voice rejection into a plausible lane, retype plain tasks to
silence the capacity skip, give the carrier an agent authority). Final map: 0 errors, 7 warnings,
the identical honest set.

**The divergence that proves the main gap:** Codex mapped the ERP automation to `none` (no rule
told it otherwise); GLM mapped it to `authority`. Two careful agents, one fact, two answers.
That is C3/X10, and it is now section 3 of the guide.

| # | GLM point | disposition |
|---|---|---|
| G1 | actor -> authority table is "¾ guesswork" | **folded**: guide §3 |
| G2 | unknown order earns 5 findings, not 1; a generator will think it failed and "fix" the map | **folded**: guide §5, the honest end state |
| G3 | DISCONNECTED class vs its code comment | = X3, deferred to OBS-467, guide §9 says so |
| G4 | plain task missing from NODE_OCCUPANCY | = X6, **independently re-found**, already fixed |
| G5 | `version`/`schemaVersion` never checked | **folded**: guide §8 |
| G6 | **my brief's command had a stray `.`; argparse exits 2, the same as "invalid"** | my error, acknowledged. Guide §1 now warns that a bad invocation also exits 2 |
| G7 | E-XML-PARSE / E-LOAD missing from CONFORMANCE | = X8, **fixed**: builder derives an intake section from the AST |
| G8 | where do events and gateways go when no performer is named | **folded**: guide §2 |
| G9 | `kind` for an as-is captured process; `isExecutable` | **folded**: guide §6 |
| G10 | positions never mentioned | **folded**: guide §7, backed by the T-976 measurement |

### 3.3 Mistral Vibe — rate-limited

Mistral answered every attempt with "Rate limit exceeded" (probe + retry loop of 2-minute
waits). **Two of three reviewers answered.** Not presented as a full panel.

### 3.4 What changed

`AUTHORING.md` rewritten: loop with publish step and save-API caveat (C1, X9); namespace, event
and gateway placement, uid derivation (C2, C4, G8); performer -> authority table with
element-over-lane precedence (C3, X1, X10, G1); annotation snippet, merge workaround, no invented
conditions (C5, X7, X11); the honest end state (X2, G2); kind and isExecutable as they really
behave (C7, X5, G9); layout, measured (C6, G10); what is NOT checked (X4, G5).
`CONFORMANCE.md` gains the intake rules (X8, G7). Validator: plain-task occupancy (X6/G4).
New tasks: T-976 layout, T-977 XOR merge, T-978 message prose.

### 3.5 Round 2 — a FRESH Codex session on the revised kit, same source

The test of a revision is whether a new reader guesses less, not whether the reviewers' points
were addressed. Same source and brief (stray `.` removed), new session, revised kit.

- **Governance guesses gone.** Round 1 guessed what a lane is, ERP's authority, kind,
  isExecutable, and event placement. Round 2 guessed none of those. It mapped ERP to
  `authority`, agreeing with GLM, so the round-1 divergence closed. Guess count 9 -> 7 by hand
  (a regex count read 0 because the report used a different heading level; not reported as 0).
- **What remains is the SOURCE's ambiguity** ("after shipment" = after collection?), which no
  guide can remove and which it annotated rather than resolved. Plus one real gap: uid minting for
  prose sources.
- Still invented nothing; same honest finding set, plus 2 × W-XML-GW-AMBIGUOUS from branches
  labelled in the source's words, exactly as §4 told it to.

| # | round-2 point | disposition |
|---|---|---|
| R1 | §5 stopping table omits W-XML-GW-AMBIGUOUS, which §4's "label in source words" produces: self-contradiction | **folded**: §5 row + "never invent to satisfy the validator" |
| R2 | geometry-free layout yields I-XML-LANE-GEOMETRY-SKIP, absent from §5 | **folded**: §5 row |
| R3 | "derive uid from source identity" is impossible for prose | **folded**: semantic-key rule in §2 |
| R4 | "a downstream compiler must invent one" prescribes the wrong thing; "sole authority" contradicts element precedence | **added to T-978** (message prose) |
| R5 | CONFORMANCE calls E-XML-GW-OUTGOING UNIVERSAL while the guide calls it a limitation | **T-977**: the rule is wrong, so its class is wrong with it |
| R6 | "inside its lane's band" overstates what geometry checks verify | **folded**: §7 states what is and is not checked |

Independent agreement with my pre-written critique: C2, C3, C4, C5, C6 all re-found. New to me:
X1, X2, X4, X5, X6, X7, X8. **Two are real validator defects (X6, X7)**, found by an outside
agent using the kit for its intended job, which is the strongest argument for this method.
