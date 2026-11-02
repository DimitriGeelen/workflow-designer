# T-1375 — An authoring-kit skill for drafting, updating and checking a map, and which project rules become validator checks

**Status:** inception, exploring. **Recommendation:** GO (see the end).
**Origin:** proposal from aef-greenfield-test (their T-390/T-393, owner decision 02-11, option b), sidecar conversation
`gf-io-v11-check-2026-10-24`, msgs 8574f297 (proposal), b9466467 (their rules file), 2f3b20f2 (their check script).
Their rules file and script are client material and are kept only in the git-ignored `build/peer-data/greenfield/`.
This report states only generalised findings.

## The problem

Rules that 832 and a consumer agree on keep getting lost when an agent drafts, updates or checks a map. The consumer's
evidence, from its own maps:

- detail maps with no io at all;
- 10 decisions whose branches have no condition;
- 31 of 46 nodes whose `aef:position` disagreed with the DI.

The rules existed. They lived in sidecar threads, in the mapping v1.1 spec and in agent memory. None of them refused a map.
The consumer has since written its own check script, which its converter and publish step run and which refuses a failing
map. On its first run it found 15 and 17 findings on two maps that had been considered done.

T-1370 already showed the remedy for one class: once a field rule moved into `validate-workflow.py` (`--field-catalog`),
it was caught on every run, by every consumer, without anyone remembering it.

## What the kit has today

The kit (`docs/authoring-kit/`, released as `dist/aef-authoring-kit-<v>/`) already carries the procedure for a
generating agent:

| File | Lines | What it covers |
|---|---|---|
| AUTHORING.md | 293 | the loop; what every map carries; lanes and authority; derive, never invent; honest end state; layout; what the validator does not check |
| GENERATE.md, REVIEW.md, CORRECT.md | 14–19 each | short briefs for the three loop roles |
| RUBRIC.md, CONFORMANCE.md | 75, 91 | the review rubric; the conformance levels |

**The gap:** AUTHORING.md mentions io once. Nothing in the kit tells an agent how to write io: one object per io; its
system and operation; fields with fieldRef and role; expect only for this step's rules; the field catalog; a condition
on every decision branch; documents as data objects; `aef:position` matching the DI. All of that came later, through
mapping v1.1, T-1312, T-1363, T-1369 and T-1370, and was told to consumers in sidecar threads. That is the dialogue the
consumer says it keeps losing.

## IW-1 — a skill, and in which form

**Finding:** the procedure exists. What is missing is (a) the io and data rules, and (b) an entry point that an agent
loads as a skill.

**Proposal:**

1. **AUTHORING.md gets the missing sections:**
   - io per object: typeRef, sourceSystem/targetSystem, operation, cardinality;
   - fields: fieldRef or path, and role read/write/match/create;
   - expect holds only what this step requires; how a value is built belongs in the catalog's value rules (T-1312);
   - a Mapping line for each value written to another system;
   - a condition on every decision branch;
   - documents as data objects with a state, linked to the step that makes or uses them;
   - `aef:position` equals the DI;
   - the documentation-line prefixes (Instruction / Screen / Decision / Keys / Open / Rule / Master / Detail /
     Mapping / Notes). These started as 832's own rule C and are general, not one consumer's convention.
2. **A `SKILL.md` at the kit root.** It has frontmatter (name, description) so an agent runtime can load it, and gives
   the order of work:
   sources → steps and lanes → io per object → conditions → build → `validate-workflow.py --field-catalog` →
   round trip in the designer → look at a screenshot → publish.
   It points to AUTHORING.md and the three loop briefs; it does not repeat them, so there is one text to keep current.
3. **The kit README points to SKILL.md first.** A README section alone was the other option. It was not chosen: a
   README is read once, while a skill is loaded each time the agent does the work.
4. **Project rules stay in each project.** Examples: wording and number format of messages a user sees, the coding rules
   of a configurator's scripting language, the project language. The skill says where a project keeps them and that
   they are added on top, never instead.

## IW-2 — which rules become validator checks

The consumer's script, read and not run, checks ten of its eighteen rules. Each is compared with what
`validate-workflow.py` (0.37.0) already does.

| Rule | What it requires | Validator today | Proposal |
|---|---|---|---|
| W-01 | fields belong to the io's object | `W-XML-IO-FIELD-ENTITY` (T-1370) | covered |
| W-04 | every field is in the catalog | `W-XML-IO-FIELD-UNKNOWN` (T-1370) | covered |
| W-15 | validator clean; round trip; screenshot | validator: yes; round trip and screenshot are not the validator's | covered as far as a validator can; rest goes in SKILL.md |
| W-02 | an io names its object, its system and its operation | not checked; the R1–R3 lint presumes them | **new WARN** `W-XML-IO-INCOMPLETE` |
| W-03 | a step in an authority lane has io | not checked | **new WARN** `W-XML-IO-MISSING`, only when the map carries io somewhere (see below); a map with no io at all only under `--strict` |
| W-07 | every branch of a decision has a condition | `W-XML-GW-AMBIGUOUS` fires only when two or more branches lack one; one unconditioned non-default branch is silent; inclusive gateways are not checked | **new WARN** `W-XML-GW-BRANCH-UNCONDITIONED` for exclusive and inclusive gateways; `--strict` raises it and GW-AMBIGUOUS to ERROR |
| W-08 | every lane has an authority | `W-XML-LANE-NO-AUTHORITY` (no laneMeta, or no authority); `authority="none"` is a legal value with its own finding per task | covered |
| W-10 | documentation lines start with a known word | not checked | **new WARN** `W-XML-DOC-PREFIX`, the list in AUTHORING.md; text after `Notes` is free |
| W-11 | a data object has a name and a linked step | not checked by the validator; the designer's import notice names it (T-1372) | **new WARN** `W-XML-DATA-UNLINKED` |
| W-14 | `aef:position` equals the DI | not checked; the designer draws from `aef:position` first (T-340) | **new WARN** `W-XML-POSITION-DI`, when both are present and differ beyond a tolerance |
| W-05 | a value written to another system has a Mapping line | not checked | **not now.** It parses free text in a documentation line, and the structured form waits on AEF's vocabulary (AEF T-4991, the mapping term). Stays in the consumer's script until then. |

**Why W-03 is limited:** 13 of the 77 tracked `.bpmn` files carry io. AEF's own corpus is largely io-free and valid by
its own spec. A warning on "a map with no io" would fire on most maps that conform today, which is the noise T-312 warns
against. Only the partial case says something is wrong: some steps have io and a step in an authority lane has none.
A consumer that wants every map to carry io turns on `--strict`, as this consumer would.

**Why all new rules are WARN by default:** for the T-312 reason the validator already gives. At ERROR they would
hard-fail promoted peer bytes that 832 may not edit. `--strict` lets a consumer refuse on them. The consumer's script
already refuses, and it would then be a thin wrapper: `validate-workflow.py --strict --field-catalog`, plus its own
W-05 and its project rules.

**Every new code needs its registry entries,** as T-1370's did:
- reachability (`test_check_pass_reachability`);
- anchorability;
- the rule-dialect axis;
- rule-form parity;
- a warn/invalid fixture for each code.

## Hypothesis (for the decision)

We believe that adding the io-and-data sections to AUTHORING.md, a `SKILL.md` entry point, and six new validator
warnings with a `--strict` switch will stop agreed general rules from living only in threads and memory. We will know when
`validate-workflow.py --strict --field-catalog` reports, on the consumer's two failing maps (TRB-T1, KLS-T1), every finding
its own script reports under W-02, W-03, W-07, W-10, W-11 and W-14. The consumer can then delete those checks from its
script; only W-05 and its project rules remain there.

## Dialogue Log

- 2026-11-02 21:56 — greenfield proposes a general skill plus kit checks, and asks for the form (SKILL.md with references,
  or a README section). We acknowledge, and the operator is asked.
- 2026-11-02 — operator: open an inception (option 1). T-1375 filed with recommendation GO. We ask greenfield for its rules
  file and check script; both received whole, hashes match (5696 B d720c364…, 6995 B d37d3893…).
- Correction during the reading: we had told the operator W-10's prefixes were the consumer's own convention. Their rules
  file traces them to 832's rule C, so they are general and W-10 becomes a kit warning.

## Recommendation

**GO**, as two build tasks:
1. Kit text: the AUTHORING.md sections, SKILL.md, and the README pointer.
2. Validator: the six warnings and `--strict`, with fixtures and registry entries.

W-05 waits on AEF T-4991. Both builds ship in the next release, together with T-1372.
