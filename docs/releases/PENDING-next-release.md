# Pending for the next designer release

Items merged since the last tag that the next release's notes and AEF announcement must carry. The release
author moves each item into `RELEASE-NOTES-<version>.md` and deletes it here. (The older
`RELEASE-NOTES-DRAFT-next.md` dates from the 0.13.0 cycle and is not this list.)

## Kit: rule classes (T-1200, from T-1165 GO, 2026-10-18)

- The authoring kit's `CONFORMANCE.md` gains a fourth class, **CONVENTIONAL**, and a **basis** column naming what
  each rule's class rests on (standard text, a well-formedness ground, the carrier read, or none).
- **Class changes, UNIVERSAL -> CONVENTIONAL** (validator severity and messages unchanged; nothing stored in maps
  changes, so no migration):
  - XML form (listed in the kit): `W-XML-DISCONNECTED`, `W-XML-NO-START-EVENT`, `W-XML-NO-END-EVENT`,
    `W-XML-UNREACHABLE`, `W-XML-DEADEND`, `W-XML-PGW-NOOP`, `W-XML-PGW-UNBALANCED`, `E-XML-GW-OUTGOING`
  - YAML form: `W-NO-START-EVENT`, `W-NO-END-EVENT`, `W-UNREACHABLE`, `W-DEADEND`, `W-PGW-NOOP`,
    `W-PGW-UNBALANCED`, `E-GW-OUTGOING`
- Say plainly in the AEF announcement: `E-XML-GW-OUTGOING` is an ERROR that rests on no basis (a house rule with
  error severity). Its severity is unchanged in this release; whether it should stay an ERROR is an open question.
- The kit bytes change, so the release job's kit calibration (codex + GLM-5.3) runs on the new kit.
- mapping-v1 Part II gained a non-normative note: the standard places no requirement on graph shape. AEF accepted
  the wording as written (msg 37a67ab0); it moves into Part I at the next frozen v1.x. AEF also confirmed its
  compiler has no basis for E-GW-OUTGOING either, so CONVENTIONAL fits; keeping it an ERROR is 832's call.
