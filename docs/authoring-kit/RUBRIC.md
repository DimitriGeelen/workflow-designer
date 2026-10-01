# Review rubric (v3)

You review a BPMN map AGAINST ITS SOURCE TEXT, not against your own idea of the process.
Every finding must quote the source, or say that the source is silent.

## Categories (use exactly these names)

- **invented**: an element, edge, order, condition, performer or outcome the source does not
  support.
- **missed**: something the source states as part of the process that the map omits.
- **wrong-authority**: a lane authority or performer that contradicts the source. A named human
  role or department is `sovereignty`, an automated system acting on its own rules is
  `authority`, a party outside the organisation is `external`, nobody named is `none`.
- **undeclared-unknown**: the source leaves something unknown and the map hides it instead of
  declaring it (unknown owner -> `authority="none"`; unknown order -> unconnected and annotated).
- **citation**: an element's `<documentation>` source quote is missing, not verbatim, or does
  not support the element.
- **readability**: the map is valid but a human would misread it (misleading names, odd structure).
- **scope**: material that is not part of the process modelled as if it were: reference sections
  (command lists, option tables, examples, glossaries) turned into tasks. A step belongs in the
  map only if the source presents it as part of the flow.

## Severity

`major` changes what the process means; `minor` does not.
**`wrong-authority`, `invented` and `undeclared-unknown` are always major**: authority decides who
owns the work (human, agent or nobody), so a wrong one changes what would be built, not just how
it reads.

## Do not report

Layout coordinates; id spelling; the validator findings an honest map keeps (AUTHORING.md §5:
`W-XML-DISCONNECTED`, `W-XML-UNREACHABLE`, `W-XML-DEADEND` on declared unknown order;
`W-LANE-NO-OWNER` on a declared unknown owner; `W-XML-GW-AMBIGUOUS` on branches labelled in the
source's words; the geometry-skip note). They are not defects.

## Why each rule is here

- Governance categories always major: a calibration review rated a human department marked
  "automated" as minor (T-982 S1b).
- `scope`: two independent agent reviewers from different vendors both accepted CLI commands
  from a "Commands" section as process tasks; a human did not. Added from that disagreement, it
  then caught both, with no false findings on a clean control (T-982 S2b).
