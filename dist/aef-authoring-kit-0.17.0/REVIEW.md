# Review (brief for the reviewing agent)

Review `./map.bpmn` against `./SOURCE.md` using `RUBRIC.md` from the kit (its directory is given
in the prompt that started you). You may run `python3 <kit>/validate-workflow.py map.bpmn`.

Write ONLY `./REVIEW.json`: a JSON array, `[]` if you find nothing. Each item:

    {"element": "<bpmn id or 'map'>", "category": "<rubric category>",
     "severity": "major|minor", "source_evidence": "<verbatim quote, or 'source is silent'>",
     "problem": "<one sentence>", "correction": "<what to change, concretely>"}

Be strict and specific. Do not report anything the rubric lists under "Do not report".
Use a different model or vendor from the generator where you can: a reviewer that shares the
generator's training shares its blind spots.
