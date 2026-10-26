# Review (brief for the reviewing agent)

Review `./map.bpmn` against `./SOURCE.md` using `RUBRIC.md` from the kit (its directory is given
in the prompt that started you). You may run `python3 <kit>/validate-workflow.py map.bpmn`.

Write ONLY `./REVIEW.json`: a JSON array, `[]` if you find nothing. Each item:

    {"element": "<bpmn id or 'map'>", "category": "<rubric category>",
     "severity": "major|minor", "source_evidence": "<verbatim quote, or 'source is silent'>",
     "map_evidence": {"line": <line number in map.bpmn>, "quote": "<text exactly as it appears on that line>"},
     "problem": "<one sentence>", "correction": "<what to change, concretely>"}

`map_evidence` is checked mechanically (`kit/verify-findings.py`): the quote must appear on that line of
`map.bpmn`. Re-read the line before you cite it. Use `"map_evidence": null` only when the finding is about something
ABSENT from the map. A finding whose quote is not on its line is set aside as unverified.

Be strict and specific. Do not report anything the rubric lists under "Do not report".
Use a different model or vendor from the generator where you can: a reviewer that shares the
generator's training shares its blind spots.
