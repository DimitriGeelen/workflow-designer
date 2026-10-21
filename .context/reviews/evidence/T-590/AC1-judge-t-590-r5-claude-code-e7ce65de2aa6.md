# T-590 Human AC#1 — evidence (panel seat claude-code, rung-5-panel)

Revision reviewed: 4b8ec8d623e7919d73e7e53cba610e1e69487f73
File: docs/research/executable-workflow/designer-contract-inventory.md (331 lines, read in full via `git show 4b8ec8d6:...`)
Cross-checked against: docs/standards/aef-bpmn-mapping-v1.md @4b8ec8d6 (§2 table l.64-70, §3 l.84-97, §5 l.112-121, §6, §7, Part II l.151)
and src/aef-workflow-designer.html @4b8ec8d6 (uid derivation block, l.13175-13206).

## What holds (verified)
- §3 decision table matches the standard §2 table row for row: horizon→`now`, workflowType inference text,
  owner derived from lane (no override), tier "project default" (Part II, unratified), agentType→`primary`.
  Each row states value, closed set, absent behaviour, kind of rule (DEFAULT / INFERENCE / DERIVATION) and ratification state.
- Owner collapse map (sovereignty→human, initiative/authority→agent, external→no task) matches standard §3 l.97.
- O-1 (lane wins, warn-not-refuse) and O-3 (inception sovereignty-laned, compile-time MUST) cited correctly.
- D-1 is real: standard l.67 infers `user→human-facing`, which is not in the closed set. Routed as R3a.
- tier routed as R2; the table as a whole as R3; reverse renderer as R5b. Requests in §7 are named and owned.
- §4.1 restates standard §5 faithfully; §4.2 M1-M4 cite instruments and task states.
- It is a negotiating document, not a restatement: it classifies each rule, names defects and the asks.

## Gaps — rules still ambiguous for an AEF engineer with only this file
G1. Import-time uid derivation is a DERIVATION the Designer performs and is not stated.
    src @4b8ec8d6 l.13175-13206 (T-364, operator ruling 2026-08-04): a node/edge arriving without
    <aef:uid> gets `<prefix>_<FNV-1a-32 hex of the BPMN element id>`, salted `seed#n` in document order
    on collision. The inventory only alludes to it ("A derived uid colliding with an authored one *is*
    guarded", M1) with no value, no citation and no named request. This interacts with standard §5
    Forward ("no aef:uid ⇒ create proposal"): after one Designer open/save a uid-less node carries a
    derived uid, so AEF cannot tell from this file whether such a node is create or modify.
G2. Edge uid in the reverse direction: "a deterministic hash for edges" (§4.1) — algorithm/input not
    stated and no request names who defines it; a reverse renderer cannot be byte-stable against us without it.
G3. workflowType inference is under-stated. Standard §3 table (l.87) says scriptTask → `build|test`,
    "disambiguate via workflowType", which contradicts the §2 rule "service/script→build" the inventory
    quotes; inference for other task-like kinds (plain `task`, `manualTask`, non-inception subProcess) is
    not stated, and "task-like nodes" (where the four keys MUST be emitted, §6.2) is never enumerated.
G4. Forward "no uid ⇒ create" (§4.1) vs T-202 export refusing an owner-bearing node with no aef:uid (§3/§5)
    — the two are listed but not reconciled (is create-via-export possible at all?).
G5. (minor) owner derivation for a task-like node in no lane / a lane with no or an unknown laneMeta
    authority: only the export refusal is stated, not the compile-time behaviour.

## Verdict: amber
Per the AC's own "If not" clause, each gap is an added row in §3 (G3, G5) or §4 (G1, G2, G4) with value,
citation and a named request (extend R3, or new R3b/R5c) — not a rewrite.
