#!/usr/bin/env python3
"""T-655 — assert the AC tick counts reported to the operator for the review-queue tasks.

WHY A FILE AND NOT A VERIFICATION ONE-LINER. Two instruments disagreed about the same
question, and picking the wrong one would have told the operator that tasks they had
already signed off were still awaiting their review:

  naive grep over the `### Human` range .... T-093 = 1 ticked of 3
  HTML comments stripped first ............. T-093 = 7 ticked of 7   <- correct

The `### Human` section of every task carries the template's two worked examples,
`[REVIEW] Dashboard renders correctly` and `[REVIEWER] Block message names both bypass
mechanisms`, INSIDE an HTML comment — with real `- [ ]` checkboxes. Any counter that does
not strip comments first counts them as outstanding human verification.

A sed-based strip is not good enough either. `sed '/<!--/,/-->/d'` on T-093 yields ONE
ticked criterion, not seven: the range deletes from each opener to the NEXT closer
anywhere in the file, which over-deletes whenever the two do not pair the way the range
assumes. Measured, not guessed — it is why this is a Python file with a non-greedy match
rather than the shell one-liner that was tried first.

Third witness: `fw task archive-eligible --dry-run` independently reports "7 AC all
ticked" and "6 AC all ticked". The numbers asserted here are the ones two instruments
agree on, and the disagreeing one is documented above so nobody re-derives it.

Exit 0 = counts are as reported. Exit 1 = they are not — the operator brief is stale.
"""
import glob
import re
import sys

EXPECTED = {"T-093": 7, "T-178": 6}

failures = []
for task, expected in EXPECTED.items():
    matches = glob.glob(f".tasks/active/{task}-*.md")
    if not matches:
        # Not a failure: the operator running the surfaced command is the SUCCESS case,
        # and it moves the file to completed/. Saying so beats a red check on a good day.
        print(f"{task}: no longer in active/ — presumed completed by the operator")
        continue
    body = re.sub(r"<!--.*?-->", "", open(matches[0]).read(), flags=re.S)
    section = re.search(r"## Acceptance Criteria(.*?)\n## ", body, re.S)
    if not section:
        failures.append(f"{task}: no '## Acceptance Criteria' section found")
        continue
    ac = section.group(1)
    total = len(re.findall(r"^\s*-\s*\[[ x]\]", ac, re.M))
    ticked = len(re.findall(r"^\s*-\s*\[x\]", ac, re.M))
    if (ticked, total) != (expected, expected):
        failures.append(f"{task}: {ticked}/{total} ticked, brief claims {expected}/{expected}")
    else:
        print(f"{task}: {ticked}/{total} ticked — matches the operator brief")

if failures:
    print("\nThe operator brief in T-655 no longer matches the tasks:", file=sys.stderr)
    for f in failures:
        print(f"  {f}", file=sys.stderr)
    sys.exit(1)
