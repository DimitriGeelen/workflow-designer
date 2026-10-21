# T-325 Human AC#1 — reviewer evidence (rung-1-same-vendor-independent)

Revision reviewed: 289f41b0d55b3aa219100d238dbaaff7fd12d425

## What the criterion asks
A recorded human ruling on (a) how `aef:laneMeta/@height` and `@abbr` are classified under mapping-v1 §1,
and (b) whether `W-GW-AMBIGUOUS`/`W-XML-GW-AMBIGUOUS` should accept a branch `name=` label as a condition carrier.

## What I checked (all at 289f41b0)
- `docs/reports/T-309-validator-surfacing.md` lines 190-305: section "2026-08-01 — IW-1b RESOLVED (T-325)" exists; the
  "A hole in the frozen standard" paragraph (line 271) states the hole and says explicitly that it is "a ratification
  question for the operator and the rail, not something to settle here".
- `docs/standards/aef-bpmn-mapping-v1.md` §1 (Part I — Frozen (v1)): "Every `aef:` datum is exactly one of two classes";
  neither the Semantic nor the Presentational list names `aef:laneMeta` or its `height`/`abbr` attributes. Confirmed hole.
- mapping-v1 line 88: exclusiveGateway "outgoing edges = branches; edge label = condition", so the label is admitted as a carrier.
- `tests/fixtures/warn/W-XML-GW-AMBIGUOUS.xml` lines 35-37: branches carry `name="code"`, `"design"`, `"environment"`,
  so the shipped warning fixture uses the label carrier the standard admits. This confirms the report's claim.
- `tests/test_rule_dialect_axis.py` exists in the tree (the guard that prints the two unclassified carriers).
- Searched docs/ and .context for an existing ruling that classifies laneMeta height/abbr: found none (only usage/schema
  mentions, e.g. docs/designer/schema.md:593, T-835 report:146).

## Verdict: escalate
The work an agent can do is done and accurate: the hole is real, and the evidence for (b) is correct. The criterion,
though, is a ruling itself, and both parts fall to the human:
- (a) amends the FROZEN v1 standard (a v1.1 delta batched with T-189/T-195 sign-off). That is a sovereignty and
  project-direction call, and the standard may not be edited under agent control.
- (b) changes what fires on AEF's bytes, and the producer says it needs a rail conversation with AEF. That is an
  outward-facing, cross-party direction call.
A reviewer cannot record a ruling on the operator's behalf. No ruling exists yet, so the criterion is not met.
I am escalating it rather than marking it red, because nothing is wrong with the work.
