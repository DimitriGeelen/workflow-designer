# Pending for the next designer release

Items merged since the last tag that the next release's notes and AEF announcement must carry. The release
author moves each item into `RELEASE-NOTES-<version>.md` and deletes it here. (The older
`RELEASE-NOTES-DRAFT-next.md` dates from the 0.13.0 cycle and is not this list.)

- **T-1222: native BPMN event definitions survive a save; third-party boundary events are boundary events again.**
  A save used to drop 46 of the 49 `*EventDefinition` elements in the third-party fixtures (message, timer, signal,
  error, escalation, conditional, compensate, cancel, terminate) and flattened every third-party `boundaryEvent` into a
  `serviceTask`, losing its `attachedToRef`. Now each definition is kept verbatim on its own host, with any root
  `message`/`signal`/`error`/`escalation` it names; boundary events keep `attachedToRef` (and gain the designer's
  `cancelActivity`). A catch whose one definition is timer, message or error takes that designer type, with no
  `aef:eventDef` added until a binding is set; anything else (signal, escalation, ..., and every throw) is a plain
  catch/throw event, never a link. **What changes in stored maps:** third-party maps saved for the first time get
  different display ids than 0.24.0 gave them (boundary events no longer count as numbered steps, typed catches take
  their type word); maps already saved by 0.24.0 keep their ids. Maps the designer authored are byte-identical.
  Guard: `tools/_t1222-event-definitions-kept.py`.
