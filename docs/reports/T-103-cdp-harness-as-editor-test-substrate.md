# T-103 — Adopt the T-101 zero-dependency CDP harness as the editor-test substrate

**Reconstructed 2026-09-16 under T-705 (finding RA-009).** This document did not exist when
T-103 was decided on 2026-07-05. It is assembled from the task file, the episodic record and
the present state of the tree, and every section states which of those it came from.

Companion to `docs/reports/T-015-tasksdir-contextdir-contamination.md`, written under the
same finding class. As with that one: **nothing here is presented as a contemporaneous
record of research that happened.** Where this document goes further is §5 — T-103's
decision, unlike T-015's, is testable against the repository as it stands today, and it was
tested.

---

## 1. The question

*Source: task `name:` and `description:`. The `## Problem Statement` section is empty — an
unfilled template comment — so the title is the only statement of the question anyone wrote.*

> Adopt the T-101 zero-dependency CDP harness as the substrate for editor test coverage
> (G-002/G-003)

Filed 2026-07-05. `workflow_type: inception`, `owner: human`.

## 2. The finding

*Source: `## Recommendation` → `**Rationale:**`. Quoted verbatim, not paraphrased (PL-323).*

> The harness both gaps ask for already exists and is proven (T-101): it drives the real
> editor JS headless with ZERO npm dependencies (native Node>=22 WebSocket/fetch + cached
> Playwright Chromium), so the Directive-4 toolchain cost that stalled G-002/G-003 is far
> lower than assumed — node is already a committed repo tool. Recommend adopting it as an
> OPT-IN editor-test substrate (skipped when node/chromium absent, never a hard audit gate),
> starting small with a load/serialize/Clean-fixpoint invariant suite that also makes T-102's
> claimed regression-prevention real; the full pointer-event suite (G-003) is a scoped
> follow-on build task after GO.

The reasoning is a cost argument against Directive 4 (Portability): the objection that had
stalled G-002 and G-003 was toolchain weight, and the finding is that the weight was already
paid. It names its own evidence base — **T-101** — and proposes a bounded first slice with an
explicit guard (opt-in, never a hard gate).

## 3. The evidence section — empty, as in T-015

*Source: `## Recommendation` → `**Evidence:**`.*

The heading exists; under it is the unfilled template comment asking for file paths, commit
hashes and test results. **None were recorded.**

This is the same omission as T-015, but it is not equally severe, and the difference is worth
stating rather than flattening. T-015's rationale asserts "Confirmed:" with no referent at
all. T-103's rationale points at **T-101** — a real task whose output can be inspected. The
evidence was not written down; it was, however, identifiable. That is a weaker failure than
an unfalsifiable claim.

## 4. The decision and the timeline

*Source: `## Decision` and `## Updates`; metrics from `.context/episodic/T-103.yaml`.*

**GO**, recorded 2026-07-05T21:06:08Z. The Decision's Rationale is a verbatim copy of the
Recommendation's Rationale, carrying the same empty "Evidence:" line.

| Timestamp | Transition |
|---|---|
| 2026-07-05T17:16:07Z | captured → started-work |
| 2026-07-05T21:06:08Z | inception-decision: GO |
| 2026-07-05T21:06:08Z | started-work → work-completed |

Episodic metrics: **`commits: 0`, `files_changed: 0`, `lines_added: 0`, `lines_removed: 0`**,
`artifacts:` empty, `git_timeline:` empty.

Unlike T-015 — whose three transitions share a single second — T-103 sat in `started-work`
for **just under four hours** before the decision. So there was a window in which exploration
could have occurred, and the rationale's content suggests it did (reading T-101's harness).
It produced no commit and no file.

## 5. Was the GO carried out? Checked, not assumed

*Source: the present tree, 2026-09-16.*

This is the section the T-015 artifact could not write, because that decision concerned
framework behaviour with no local trace. T-103's decision is directly observable:

| Claim in the GO | Checked | Result |
|---|---|---|
| The harness exists | `ls tools/_cdp-attach.mjs` | **present** |
| Adopted as an editor-test substrate | `grep -c cdp tests/run-bridge-tests.sh` | **29 CDP references in the runner** |
| Opt-in, "skipped when node/chromium absent, never a hard audit gate" | `run-bridge-tests.sh:228`, `:411` | **honoured** — `:411` prints "a LOUD SKIP line"; `:228` notes the suite "skips for lack of chromium, so the shared byte contract is never silently unguarded" |
| T-101 is the source task | `.tasks/active/T-101-bake-clean-layout-into-the-rendered-corp.md` | **exists — and is still open** |

**The GO was executed.** The CDP harness is the editor-test substrate today, invoked across
29 legs of the bridge test runner, and the opt-in guard the recommendation insisted on was
implemented as specified — including the refinement that a skip must be loud rather than
silent, so an absent toolchain cannot be mistaken for a passing suite.

One qualification, recorded because it cuts against a clean reading: **T-101, the task this
decision rests on, is still in `.tasks/active/`.** An inception was decided GO on the proven
status of a task that has not itself closed.

A second, from the observation register: **OBS-338** records that these CDP legs require
Node ≥ 21 while `/usr/bin/node` on this host is v18.19.1, so they need
`PATH` pointed at the nvm-managed v22 to run at all. The "zero-dependency" claim holds for
npm packages; it does not hold for the node binary on the default path.

## 6. Two structural observations, recorded not resolved

**(a) All four acceptance criteria were auto-ticked, including the Human one.** T-103 carries
four `<!-- @auto-tick-on-decide -->` markers and four ticked ACs, one of them the `[REVIEW]`
criterion that CLAUDE.md protects with *"NEVER check a `### Human` AC."* Two of the Agent
ones are false on their face: "Problem statement validated" is ticked against an empty
Problem Statement, "Assumptions tested" against an empty Assumptions section.

This is identical to T-015 and is the subject of OBS-348. T-250 carries the same four
markers. Whether `@auto-tick-on-decide` may tick a Human AC is a **Sovereign question** and
is not decided here.

**(b) The episodic `decisions:` block is template text marked complete.**
`.context/episodic/T-103.yaml` carries `enrichment_status: complete` over:

```yaml
decisions:
  - decision: '[date] — [topic]'
    chose: '[what was decided]'
    rationale: '[rationale]'
```

A real GO with a real rationale sits in the task file and did not reach the retrieval layer.
Identical to T-015.

## 7. What is NOT decided here

- Whether the follow-on G-003 pointer-event suite the GO scoped was ever built. Not checked;
  checking it is build work, not artifact reconstruction.
- Whether T-101 being still open, while an inception rests on it as "proven", needs
  reconciling.
- Whether `@auto-tick-on-decide` may tick a Human AC (OBS-348).

**Research is not authorization.** This document records what was found and ratifies nothing.
