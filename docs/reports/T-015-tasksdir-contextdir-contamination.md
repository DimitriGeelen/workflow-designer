# T-015 — TASKS_DIR / CONTEXT_DIR export contaminates fw subprocesses

**Reconstructed 2026-09-16 under T-704 (finding RA-008).** This document did not exist
when T-015 was decided on 2026-07-04. It is assembled from the three sources that
survived — the task file, the episodic record, and the git trail — and every section
below states which of them it came from.

C-001 holds that for an inception the thinking trail IS the artifact: conversations are
ephemeral, files are permanent. T-015 reached a GO decision and left no file. This is the
repair of that omission, and it is honest about being a repair: **nothing here is
presented as a contemporaneous record of research that happened.**

---

## 1. The question

*Source: task name and `description:` frontmatter. Both present.*

> Framework: TASKS_DIR/CONTEXT_DIR env export causes cross-project contamination in fw
> subprocesses

Filed 2026-06-08. `workflow_type: inception`, `owner: human`, tagged `upstream-framework`.

**The `## Problem Statement` section of the task file is empty** — it contains only the
template comment `<!-- What problem are we exploring? For whom? Why now? -->`. The question
above is the task's title, not a statement anyone wrote.

## 2. The finding

*Source: `## Recommendation` → `**Rationale:**`. Quoted verbatim, not paraphrased (PL-323).*

> When a Claude Code session exports TASKS_DIR and CONTEXT_DIR (via fw context init), any
> subsequent subprocess that uses fw but sets only PROJECT_ROOT via env will inherit the
> caller's TASKS_DIR/CONTEXT_DIR and write to the wrong project. Confirmed: fw
> test-onboarding consistently creates tasks and writes focus into the calling project
> instead of the temp project. The local workaround (env -u TASKS_DIR -u CONTEXT_DIR) is
> applied in the vendored test, but the root fix should be in paths.sh: re-derive
> TASKS_DIR/CONTEXT_DIR from PROJECT_ROOT when PROJECT_ROOT is explicitly provided and
> differs from the directory implied by TASKS_DIR. This prevents consumer project
> contamination without breaking the export convention.

This is substantive and specific. It names the mechanism (env inheritance through
subprocess), the observed symptom (`fw test-onboarding` writing into the caller), the
applied mitigation (`env -u`), and the proposed root fix with its location (`paths.sh`) and
its constraint (must not break the export convention).

## 3. The evidence — and this is the part that is missing

*Source: `## Recommendation` → `**Evidence:**`.*

The Evidence heading exists. Under it is the unfilled template comment:

```
<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->
```

**No file path, no commit hash, no test output was ever recorded.** The rationale's word
"Confirmed" is not supported by anything in the task, the episodic record, or the git
history. That does not make the finding wrong — it reads as a real observation by someone
who had just watched it happen — but it means the claim cannot be re-checked from the
record, which is the property C-001 exists to preserve.

## 4. The decision

*Source: `## Decision` and the `## Updates` trail.*

**GO**, recorded 2026-07-04T22:49:09Z. The Decision's Rationale is a verbatim copy of the
Recommendation's Rationale, including the empty "Evidence:" line.

## 5. What the timeline shows

*Source: `## Updates` (task file) and `.context/episodic/T-015.yaml`.*

Three status transitions share one timestamp, to the second:

| Timestamp | Transition | Reason |
|---|---|---|
| 2026-07-04T22:49:09Z | inception-decision | Recorded inception decision: GO |
| 2026-07-04T22:49:09Z | captured → started-work | "Inception decision in progress" |
| 2026-07-04T22:49:09Z | started-work → work-completed | "Inception decision: GO" |

The episodic record reports `duration_days: 26`, `wall_clock_minutes: 37418` — that is
filing-to-decision elapsed time, not work. Against it: **`commits: 0`, `files_changed: 0`,
`lines_added: 0`, `lines_removed: 0`, `artifacts:` empty, `git_timeline:` empty.**

So the inception was opened, decided, and closed in a single second, with no exploration
recorded between filing and decision.

## 6. Two structural observations, recorded not resolved

**(a) Every acceptance criterion was ticked automatically, including the Human one.**
All four ACs carry the marker `<!-- @auto-tick-on-decide -->`:

```
### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
```

"Problem statement validated" is ticked against an empty Problem Statement. "Assumptions
tested" is ticked against an empty Assumptions section. And the `[REVIEW]` criterion —
the one CLAUDE.md protects with *"NEVER check a `### Human` AC. Only the human may verify
and check these boxes"* — was ticked by the same mechanism as the other three.

Whether `@auto-tick-on-decide` on a Human AC is the intended design (the human's act of
running `fw inception decide` IS the review, so the tick records it) or a sovereignty
leak is **not for the agent to decide**. It is recorded here and raised as a Sovereign
question.

**(b) The episodic record's `decisions:` block is template text marked complete.**
`.context/episodic/T-015.yaml` carries `enrichment_status: complete` and:

```yaml
decisions:
  - decision: '[date] — [topic]'
    chose: '[what was decided]'
    rationale: '[rationale]'
    alternatives_rejected: ['[alternatives and why not]']
```

Those are the literal template placeholders. A real GO decision with a real rationale sits
in the task file and did not reach the episodic record, which is the layer built for
retrieval. The audit's "All completed tasks have episodic summaries" check passes on this
file, and D1 reports `0% [TODO]` because the placeholders use `[date]`/`[topic]` rather
than the literal string `[TODO]`.

## 7. What is NOT decided here

- Whether the GO is still valid. The finding describes framework behaviour as of
  2026-07-04; whether `paths.sh` was since fixed has not been checked under this task, and
  checking it is build work, not artifact reconstruction.
- Whether `@auto-tick-on-decide` may tick a Human AC.
- Whether an inception decided without a filled Evidence section should be re-opened,
  annotated, or left standing.

All three are Sovereign questions. **Research is not authorization** — this document
records what was found and ratifies nothing.
