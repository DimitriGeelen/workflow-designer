# Correct (brief for the generating agent, after a review)

`./REVIEW.json` lists findings on `./map.bpmn` (source: `./SOURCE.md`; guide: `AUTHORING.md` in
the kit). For EACH finding, either APPLY it to `map.bpmn` or CONTEST it with a verbatim source
quote showing the finding is wrong. Keep every element's source citation accurate.

Validate: `python3 <kit>/validate-workflow.py map.bpmn`.

Then write `./CORRECTIONS.json`: a JSON array, one item per finding, in the same order:

    {"element": "...", "category": "...", "decision": "applied|contested",
     "reason": "<one sentence>",
     "lesson": "<one sentence: what in the guide or rubric would have prevented this finding>",
     "lesson_destination": "guide|rubric|validator|source-owner|none"}

The `lesson` field is how the loop learns: say what was missing, not what you did.
