# T-1219 AC#1 — independent review (rung-3-termlink-single-reviewer)

Revision reviewed: cb455b3a4586507108648f40c6ee65daab5baa46
Verdict: **amber**. The GO is sound. The inception record in the task file is not complete.

## What I checked

1. The task file `.tasks/active/T-1219-traceable-data-elements-on-aefio-ref-rol.md`: Recommendation, Evidence, Go/No-Go Criteria
   and the other sections.
2. The research artifact `docs/reports/T-1219-traceable-aef-io.md`: the request, IW-1..IW-3 and the dialogue log with AEF and the requester.
3. The T-1220 build claim, commit 44ba28d0 (src/aef-workflow-designer.html +34, guard tools/_t1220-io-extra-attrs-cdp.mjs,
   wired into tests/run-bridge-tests.sh:1112).
   - Ran `node tools/_t1220-io-extra-attrs-cdp.mjs` on the current source: `"ok": true`, exit 0.
   - Ran the same guard with `T1220_SRC` pointed at the pre-fix source (`44ba28d0~1`): exit 1, with legs 1, 3 and 6 red.
     This matches the commit message's "red against the pre-fix source (legs 1, 3, 6)".
4. VERSION is `0.23.0`, and T-1220 is still `status: started-work`.

## Judgement of the GO

- The decision is split well. Preserving unknown `aef:` attributes is a round-trip property: it is bounded, reversible,
  guarded, and AEF has no objection ("preserving is not interpreting", msg 42018c4e as logged). The new fields
  ref/role/cardinality/dataType are correctly deferred to AEF's v1.1 inception T-4415, so 832 does not invent anything
  in the frozen two-party standard. This respects "Any change to the frozen standard is decided with AEF, not here".
- I see nothing irreversible and nothing that is a sovereignty call, so no escalation is needed. The standard revision
  is owned by AEF's operator and is already routed there.
- The GO criteria are met in substance: the fix path is bounded, and the fix is scoped, tested (6-leg guard with
  bite) and reversible.

## Gaps (why amber, not green)

1. The task file's Problem Statement, Hypothesis, Assumptions, Open Questions, Exploration Plan and Scope Fence are
   still empty template placeholders. The Hypothesis block still reads `<change>/<outcome>/<measurable signal>`.
   The record defers to the report, but the hypothesis and disposition gates read the task file.
2. IW-1..IW-3 are not disposed in the task file's Open Questions in the required shape (confidence / disposition /
   rationale). In the report, IW-3 (what the designer shows) has no finding.
3. The Go/No-Go Criteria are the generic template ("Root cause identified..."), not criteria written for this
   feature request. They were not filled before the recommendation.
4. "ships in 0.24.0" is a forward claim. VERSION is 0.23.0 and T-1220 is not closed.
5. The evidence bullet "aef-greenfield-test msg 615dbee9" does not appear in the report's dialogue log. The log
   cites msg 50ac8f46 instead. I cannot verify the external messages (42018c4e, e9f02fa0, 53eb5724) from this repo
   beyond the producer's log.
