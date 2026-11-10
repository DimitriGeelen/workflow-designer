# Generate (brief for the generating agent)

Turn `./SOURCE.md` into `./map.bpmn` using the kit (its directory is given in the prompt that
started you). Read `AUTHORING.md` first.

On EVERY lane and EVERY flow node, add a `<documentation>` child whose text is either

    source: "<exact verbatim quote from SOURCE.md that supports this element>"

or

    source: unstated - <why this element exists although the source does not state it>

Validate: `python3 <kit>/validate-workflow.py map.bpmn`. Write nothing else except `map.bpmn`.
