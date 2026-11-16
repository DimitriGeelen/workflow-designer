# Workflow Designer 0.43.0 — release notes

**Since:** `designer-v0.42.0`. The validator now recognises the kit's own `source:` citation line (T-1416), and the
authoring kit is brought in line with the validator. Its guide and rubric no longer ask for a `callActivity`
(T-1417). It ships a new exemplar built to every rule (T-1418). Its guide and checklist agree on rule classes,
messages and the warnings an honest map keeps (T-1419). All of these were found by an outside reader, Google's
Antigravity, in the third round of the kit review (832 T-979; report `docs/reports/T-975-kit-external-review.md`
§3.6). The designer page itself is unchanged apart from its version number.

## Changes

- **`source:` is a known documentation prefix (T-1416).**
  - **Before.** The kit requires every element to cite its source on `source: "…"` lines (GENERATE.md, AUTHORING
    §1b). The validator's list of documentation prefixes did not include `source:`. So a cited step that also had an
    `Open:` line drew W-XML-DOC-PREFIX on its own required citation. Under `--strict`, every cited step was an ERROR.
  - **Now.** `source:` is a known prefix, and the guide's table of known words lists it. A genuinely unknown prefix
    still fires.
  - Guard: core, `tests/test_t1377_general_map_checks.py` leg 16 (red on 0.42.0's validator).
- **The kit no longer asks for a `callActivity` (T-1417).**
  - **Before.** AUTHORING §4 and RUBRIC allowed a `callActivity` for "is detailed in / invokes X". The validator
    rejects it as `E-XML-NODE-TYPE`, so a vendor following the guide got an error. The same sentence prescribed a
    `Detailed in:` line, which is not a known prefix.
  - **Now.** The guide and rubric ask for a cited `Detail: X` line on the task, and say a `callActivity` is not yet in
    this designer's vocabulary. The callActivity build (832 T-1252) will change this text when it ships.
  - Guard: core, leg 17 (the advice validates; a callActivity is E-XML-NODE-TYPE).
- **A new exemplar, built to every rule (T-1418).**
  - **Before.** `exemplar.bpmn` was a copy of the corpus map `task-lifecycle.bpmn`: no source citations, counter ids
    (`flow_1`…) and the v1.0 io form. The guide said "copy its shape".
  - **Now.** It is a small expense-claim map, generated from the synthetic source in its header comment. Every lane
    and node has a verbatim `source:` line, ids and uids name what they are, and every system step has v1.1 io. It
    validates clean, `--strict` included.
  - Guard: core, `tests/test_t974_authoring_kit.py` legs 4e (the shipped exemplar) and 4f (control: the old one is
    flagged on all three counts).
- **Guide and checklist agree (T-1419).**
  - **Rule classes:** AUTHORING §9 names the checklist's five classes (it named three) and gives
    `W-XML-DISCONNECTED` its real class, CONVENTIONAL (it said UNIVERSAL). It also says the generated
    `CONFORMANCE.md` wins on any disagreement.
  - **Warnings an honest map keeps (§5):** the table adds `W-XML-PGW-UNBALANCED` (a fork with no stated join) and
    `I-XML-LANE-CAPACITY-SKIP` (lane heights kept on a map without positions). It also states when
    `W-XML-IO-MISSING` fires: only when the map gives io elsewhere.
  - **`CONFORMANCE.md`** lists every distinct message of a rule, joined by "— or:". It used to show only the first,
    which hid the second trigger of `W-XML-DATA-UNLINKED` and `W-XML-IO-MISSING`.
  - Guard: core, T-974 legs 4b-4d (4c is the control).

## What changes in stored maps

- **Nothing.** The designer page is unchanged apart from `APP_VERSION`. Every map saves byte-identically to 0.42.0.

## Not kept yet

Unchanged from 0.42.0:
- nested lanes (T-1267, deferred);
- another tool's pool and lane outlines;
- drawing a subprocess's contents inside it (drawn flat, saved nested);
- escalation and compensate events draw as plain events;
- the `Mapping:` lines are not checked by the validator, which waits for AEF's mapping vocabulary (T-4991).

## For AEF

**What changes in what you store:** nothing. Maps save byte-identically to 0.42.0.

**What changes in Check (`POST /api/validate`):** one thing. `validate-workflow.py` now treats a `source:` line as a
known documentation prefix. A step whose documentation mixes `source:` lines with other known prefixes, or any cited
step under `--strict`, no longer draws W-XML-DOC-PREFIX on its citations. No other rule changes. The kit's `SHA256SUMS`
changes with the files above.

The endpoints as you confirmed them (msg adadee0b, 2026-11-08; msg 219d838b, 2026-11-15):

| Endpoint | Feature (task) | In AEF |
|---|---|---|
| `POST /api/validate` | **Check**: validator findings on the map (T-962), under the io (T-1303); catalog checks need the catalog passed (T-1370); `--strict` needs it passed (T-1377); your wrapper passes neither (your choice) | served (your T-4830, T-4845, T-5058) |
| `GET /api/instances?template=<id>` | **Instance overlay** (T-884) | served (your T-4831) |
| `GET /api/field-catalog` | **Ref picker** (T-1312); **value rules** (T-1365); extra keys passed through (pinned by your test) | served |
| `GET/PUT /api/field-profile[?id=<id>]` | **Project field profile** (T-1125, T-1128) | not served by design (your T-4737 IW-3): its settings are hidden (T-1391) |
| `GET/POST /api/field-suggestions` | **"Suggest as a field"** (T-1126) | not served by design (your T-4737 IW-3): the button is hidden (T-1391) |

Contracts: 832 `docs/reports/T-1300-designer-data-api-contract.md` and `docs/reports/T-1312-field-catalog-contract.md`.

## Shared contracts

Added on 2026-11-16, after the release (T-1425), when AEF and 832 paired the five shared contracts (AEF T-5183). From
the next release on, every release's notes carry this table, and `tools/_t1425-shared-contracts.py --check` (a core
leg) holds the last column to what moved since the previous release. The released 0.43.0 bytes on 832's side are the
designer page sha256 85119747…, the kit `SHA256SUMS` 126451b6… and `validate-workflow.py` 08ac4443….

| # | Contract | AEF artifact | 832 artifact | Moved in this release |
|---|---|---|---|---|
| 1 | Procedure interchange | contracts v2 `procedure.schema.json` v1, ac9aaefc | designer page (export) | no |
| 2 | Mapping / compatibility | "designer produces contracts v2" (AEF T-5184, drafting) | authoring kit | yes |
| 3 | Validation / refusal diagnostics | contracts v2 `refusal.schema.json` v2, c4148a34 | validate-workflow.py | yes |
| 4 | Runtime projection | projection schema (AEF T-5185, to be frozen) | designer page (overlay renderer) | no |
| 5 | Ratification | `task-lifecycle-contract.md` (frozen T-3386) | designer page (save/export proposal-only) | no |
