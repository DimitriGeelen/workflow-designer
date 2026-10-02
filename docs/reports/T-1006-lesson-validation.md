# T-1006 — How a lesson gets validated (evidence + a cross-vendor panel, not operator assent)

## Why
The ledger (T-984) said a learning becomes `confirmed` "by repetition or by a human", and every
confirmation so far (L1-L15) was routed to the operator as a yes on technical claims. On
2026-10-02 the operator refused L16-L25 on those terms:

> "I cannot confirm that the lesson is right and I am not involved in that. So why are you asking
> me that? What do you expect me from an operator? If value reviewers on that, then what's a good
> way to get validation of this in or to get multiple views or perspectives on this in?"

The obligation was misrouted (same class as T-996: a check enforced on the party that cannot
perform it). An operator "yes" on a claim they cannot judge looks like validation and is none.

## The rule
A learning is `confirmed` only when both hold:

1. **Evidence re-runs green.** Each entry carries an `evidence_cmd` that reproduces its claim
   against the shipped kit *now* (`tools/_t1006-lesson-evidence.sh <id>`). A lesson that no longer
   reproduces is stale or wrong.
2. **A cross-vendor panel agrees.** Agree verdicts from at least 2 distinct vendors, none of them
   the author's (Anthropic: the lessons are written by Claude), and no standing disagree/refine.
   Two reviewers of one vendor are one view. A disagree or refine marks the entry `escalated`.

Every reviewer gets the same prompt: the lesson, how it was observed, the proposed change, the
evidence command and its live output, and the instruction not to defer to the author.
A reply without a parseable verdict is `no-verdict`, never `agree`.

The operator is asked only for **value** (is it worth doing) or **priority** (when) rulings,
recorded as `rulings`; `rule --kind correctness` is refused. L1-L15 stay valid as legacy
(`legacy_until: L15`).

## Panel
| reviewer | vendor | command |
|---|---|---|
| codex | OpenAI | `codex exec --skip-git-repo-check --sandbox read-only` |
| glm-5.3 | Z.AI | `opencode run -m zai-coding-plan/glm-5.3` |
| Antigravity | Google | not yet wired (T-979) — would make 2-of-3 possible |

Not on the panel: Claude (author's vendor); the operator (not a correctness reviewer). The
affected party (Evergreen) confirms field effect after release, which is a separate signal.

## Incident during the first real run
Two reviews ran in parallel; each loaded the ledger, waited minutes for its reviewer, then saved —
codex's verdict on L20 was overwritten by GLM's. Fixed: `review` re-reads under a lock before
appending (561d11f5; test 11 + mutant).

## Results (L16-L27), four rounds

**What the panel caught that the operator could not have, and I had not:**
- **L26 (new):** 0.15.2's guide says "a parallel fork (and its join) says the same as the plain
  flows". True of the fork, false of the join: a join waits for every branch, plain converging
  flows fire the next step once per arrival. That sentence came from MY T-993 "correction" — the
  very case L16 cites as a reviewer being wrong. The control map was partly right.
- **L27 (new):** our hand-over rule (promoted earlier, K4) draws cross-map hand-overs as BPMN link
  events; BPMN 2.0.2 link events connect sections of ONE process. It is an AEF convention the kit
  never declares as such.
- **L21:** my lesson said "drop the end event's name"; the evidence, once complete, showed the
  source DOES state the outcome — the defect is its `source: unstated` citation. Lesson reversed.
- **L18:** GLM noticed planted.bpmn carries the same mislabelled branch; the fix now covers both.
- **L16, L17, L19, L22, L23, L24:** each narrowed to what its evidence supports (e.g. callActivity
  only when the source establishes invocation; aggregate reachability only for proven seedless
  components).

Codex's most frequent objection was "evidence insufficient" — and every time, the evidence
command really was thinner than the claim. The evidence probe grew accordingly.

**Reviewer calibration (the quality question).** Two PLANTED-FALSE lessons
(docs/learning-ledger-controls.yaml). `learning-ledger.py stats`:

| reviewer | vendor | agree | refine | disagree | no-verdict | planted-false controls |
|---|---|---|---|---|---|---|
| codex | OpenAI | 10 | 18 | 6 | 0 | C1 disagree, C2 disagree |
| glm-5.3 | Z.AI | 31 | 1 | 0 | 3 | first run: both timed out (900 s); re-run at 1800 s: C1 disagree, C2 disagree |
| glm-5.2 | Z.AI | — | — | — | — | C1 refine ("the BPMN premise is false"), C2 disagree |

GLM agreed with 31 of 32 lessons it judged and has never been shown able to withhold agreement.
So the rule now counts an agree only from a reviewer that answered a planted-false control and
agreed with none. Consequence, stated plainly: **the 7 lessons that had reached two-vendor
agreement (L18, L20-L23, L25, L26) were demoted back to proposed** — their second vendor is
uncalibrated. L16, L24, L27 reached two-vendor agreement in round 4 and are held the same way.
L17 and L19 have a standing refine/disagree from codex.

Re-run with a longer timeout, GLM rejected both plants and said exactly why each premise is false.
So GLM can withhold agreement; its high agree rate on the revised lessons is not by itself proof of
deference. Two plants is a small sample: every new panel round should carry fresh controls.

**Outcome after re-check under the calibrated rule: 10 of 12 confirmed** (L16, L18, L20-L27: evidence
green, agree from OpenAI and Z.AI reviewers that both passed the controls). **L17** (codex: consumption
depends on the CLI parser; the claim should name claude's variadic option, not all multi-value options)
and **L19** (codex: evidence lacks the kit's entry convention) stay open with those precise gaps.

Third seat: the 1.7.740 upgrade brought the direct-call ruleset the operator promised
(`.agentic-framework/docs/harnesses.md`): Antigravity (`agy`, Google) via
`sudo -n -u dimitri-mint-dev -H /home/dimitri-mint-dev/.local/bin/agy -p "<prompt>" --mode plan --sandbox`,
operator-approved 2026-09-30. `review` now accepts a `{prompt}` token for that form and closes stdin.

## What the operator is asked
Nothing. L27 was the one candidate VALUE question (keep the AEF link convention or move to message
flows); the panel settled it — keep the convention, declare it, name the standard alternative.
