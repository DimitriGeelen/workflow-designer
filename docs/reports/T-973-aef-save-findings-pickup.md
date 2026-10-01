# T-973 — Pickup proposal for AEF: `/api/save` returns validator findings, advisorily

**From:** 832-Workflow-designer · **To:** AEF (`web/blueprints/designer_api.py`) · **Date:** 2026-10-01
**Status:** proposal, not yet sent. Released over the TermLink hub by the operator.
**Kind:** a PROPOSAL (G-020). Scope it as you see fit; nothing here is a build instruction.

---

## The evidence

A vendor project (aef-greenfield-test, "Evergreen") generated 26 maps from an OWL ontology and
saved them through **your** blueprint's `/api/save`: 104 saved versions, 130 saves in all. Every
one of the 26 maps:

- carries **no `aef:workflowMeta`**, so it has no id of its own (identity falls back to the
  process id, which is why round trips had to be matched by lane+step name) and no `kind` (an
  overview map is judged as an executable process);
- carries **no `aef:laneMeta authority`** on any lane: 66 lanes, so no task in the corpus has a
  derivable owner (mapping-v1 §3: the lane is the sole authority-of-record).

None of the 130 saves said a word. The generator never went through the designer's exporter,
which writes both carriers unconditionally. It posted bytes, and `save()` checks only XML
well-formedness (T-2564).

## What we changed on the reference server (`tools/gallery-serve.py`)

Your blueprint's docstring names the 832 server as the authoritative contract, so the change
lands there first:

```
POST /api/save  {id, bpmn, png?, note?, promote?}
  -> {ok:true, v, ts, corpus:bool, validation}
     validation = {ok:true, findings[], errors, warnings} | {ok:false, reason}
```

- **Advisory, never blocking.** The version is written first. Findings, errors, or a validator
  that cannot load never fail a save.
- **Tagged union.** When the validator cannot run, `validation` is `{ok:false, reason}` with
  **no `findings` key**, so a broken validator can never read as a clean map.
- **No rule logic in the route.** It calls the one validator, `validate-workflow.py`'s `run_xml()`.
- Existing fields are unchanged, so no current client breaks.

Two rules were added under T-972 so the response has something to say about exactly this corpus:
`W-XML-NO-WORKFLOWMETA` (DIALECT-RELATIVE: the frozen standard never names workflowMeta) and
`W-XML-LANE-NO-AUTHORITY` (UNIVERSAL: §3). On Evergreen's 26 maps the validator now reports
findings on 26 of 26 (138 in all). Our own 25 maps are unchanged.

## What we propose for your blueprint

The same additive key on `save()`'s `_ok(v=v)` response, computed after the write and wrapped so
it cannot raise. You would need the validator available to the blueprint. It ships in the
designer release, but how it reaches Watchtower is your call.

**Why it matters to you specifically.** Any agent that generates maps through your API reads the
save response. That is the only point at which a vendor's agent can learn, unprompted, what its
maps lack. Without it, the lesson has to be hand-delivered to each project, and that does not
scale.

## Verification on our side

`tests/test_t973_save_findings.py`, 7 legs over real HTTP with an isolated store: a complete map
reports zero findings; the same map without workflowMeta reports the rule and is saved anyway;
legacy fields are present; and a server copy with no validator beside it still saves, returning
`{ok:false, reason}` with no findings key. Against the pre-change server the three validation
legs fail and the four transport legs pass.
