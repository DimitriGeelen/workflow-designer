# T-1249 Human AC#1: read-only v1.1 io display (reviewer judge-t-1249-r3-e9a86f1be12a, rev a3a62820)

Viewed: v11-step-{1024,1440,1920}-panel, v11-step-1024-panel-end, v11-step-1024, v11-step-1920, v1-step-1440-panel,
v1-step-1440, empty-step-1024-panel, workflow-1024-panel, workflow-1920. Read the Visual Verification table, the
fixture in tools/_t1249-v11-io-shots.mjs and ioV11Block/wfV11Section (src/aef-workflow-designer.html:8181-8300).

Findings, checked against the fixture XML:
- Input opp: typeRef, conceptRef, cardinality and sourceSystem are all shown. Also: field LineItems[] cardinality many, an
  indented when Kind const TradeIn, expect Status enum Won, Closed Won, and expect Amount minimum/exclusiveMaximum/pattern
  (wraps at a pair boundary). example Amount = 12500 is there too. Nothing is clipped at 1024, 1440 or 1920; the panel is
  320 px at every width, so the layout is the same.
- Nameless input: fieldRef sfdc:Opportunity.Id role read, and sourceSystem sys:crm-default is labelled in italics
  "derived · step default".
- Output 1: tacton typeRef, operation upsert, three fields with roles. No system is derived because the tacton prefix
  has no system, which is correct. Output 2: targetSystem sys:salesforce "derived · prefix sfdc" and expect StageName
  const Closed Won. Output 3: explicit targetSystem (not marked derived), path fields, required true.
- Keys are faint and values bright; key/value pairs never split. "role match"/"role create" go to the next line as a
  whole pair after a long fieldRef. That is legible.
- v1 step (owner/team/assignment) and empty step: plain rows / "(no inputs)" "(no outputs)", with no v1.1 block. They
  look as before.
- Workflow panel: the MAPPING section shows mappingVersion 1.1, sfdc IRI · system sys:salesforce · kind field, and
  tacton IRI · kind type. The name column is aligned and the IRI wraps inside its column. It sits above Recently
  opened/Tips with no overlap.
- Toolbar: two rows at 1024 and 1440, one row at 1920. Every button is visible and none overlaps. This is the same
  toolbar set as before.
- Not shown: the input's ref="nid:x" and dataType="id". These are v1 ontology attributes (T-4415), not v1.1 constructs,
  so they are outside this AC.

Known limit (nameless v1.1 io: empty name field and type select at the default): mildly misleading. The worst case is
nameless output 1, where the select reads "string" next to typeRef tacton:Opportunity. The name field shows a dim
placeholder, and the authoritative typeRef/fieldRef is directly below in the v1.1 block, so a reader is not misled
about the contract. I judge it NOT worth fixing in slice 1. Slice 2 (editing) should render the select blank or "—"
when the io has no type and carries typeRef/fieldRef, so that a touch does not write type="string".

Verdict: green.
