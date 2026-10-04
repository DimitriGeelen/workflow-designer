# T-1020: which local fixes to vendored files did the re-vendors lose silently?

**Status:** inception, exploration in progress (2026-10-04).
**Trigger:** T-931's `fw task delegate` owner fix (0a00d59d) was found erased by the 1.7.740 re-vendor (T-1009). It was never declared and held by no test, so `_t517` could not see it.

## Method

**Spike A (mechanical):**
- Take every commit since the T-276 vendor baseline that changed `.agentic-framework/`, excluding the pristine re-vendor commits themselves.
- For each vendored file the commit touched, measure how many of the lines it **added** still exist, verbatim, in HEAD's copy of that file.
- Ignore blank lines and trivially common lines.

A file whose added lines are largely missing from HEAD is a **candidate**. Being a candidate doesn't prove a loss, because a later edit may have rewritten the same lines.

**Spike B (judgement):**
- For each candidate, check whether it was declared and re-applied (T-1005 rows), superseded upstream (the behaviour exists in another form), or lost.
- Run the commit's own probe where one exists.

## Findings

### Spike A (2026-10-04)

- **Population:** 211 (commit, vendored file) rows from the post-T-276 commits that changed `.agentic-framework/`. The three pristine re-vendor commits and our own files (the register, `.context/`, the designer pin) are excluded.
- **Candidates:** 88 rows (67 tasks) where fewer than half of the commit's added lines survive verbatim in HEAD.
- **By register status:**
  - 48: the path is declared and the task is named in the register (handled by T-1005).
  - 20: the path is declared, but this task appears nowhere in the register.
  - 12: the path is undeclared, but the task is mentioned somewhere.
  - **8: the path is undeclared and the task appears nowhere.** This is the riskiest class: exactly T-931's shape.

### Spike B: behaviour, not lines (the 28 rows whose task is not in the register)

A missing line is not a missing behaviour, so each task's own probe was run against HEAD where one exists.

| Task | File(s) | Probe on HEAD | Verdict |
|---|---|---|---|
| T-381 | `context/lib/focus.sh` | `_t381` 12/12 | PRESENT (rewritten upstream) |
| T-567 | `context/lib/episodic.sh` | parse check PASS; teeth 4/4 | PRESENT |
| T-913 | `update-task.sh` | `_t913` green | PRESENT |
| T-919 | `active/completed-task-scan.py`, `lib/research_preserved.py` | `_t919` green | PRESENT (superseded, as recorded in T-1005) |
| T-921, T-639 | `check-active-task.sh`, `safe-commands.sh` | `_t921` 21/21; `_t1005` drift 14/14 | PRESENT (restored by T-1005/T-1009) |
| **T-866** | `lib/inception.sh`, `lib/task-audit.sh` (undeclared) | `_t866` TEETH BROKEN: `audit_inception_hypothesis` is gone | **LOST.** `fw inception decide … go` no longer requires an observable hypothesis (arc-004 S1). |
| **T-908** | `fabric/lib/traverse.sh` (undeclared) | no probe; reproduced by hand | **LOST, live regression.** 24 of 704 `depends_on` entries are plain strings, and `dep.get('type')` raises `AttributeError: 'str' object has no attribute 'get'` (shown with the mask removed in a scratch copy). `2>/dev/null` hides it, so `fw fabric impact` prints an **empty chain**, which reads as "nothing depends on this". |
| T-628, T-629 | `check-active-task.sh` | red (6 and 3 legs); mutants cannot be built | gate usability. Probably superseded by upstream T-3299 (the block message now names the Edit tool and the metadata-only escape); to confirm. |
| T-636, T-650 | `safe-commands.sh` | red (2 and 6 legs) | gate usability (OVER-blocking): a commit message mentioning `rm` is refused with no task; `fw git commit` and `fw fix-learned` are refused where `git commit` and their targets are admitted. No unguarded write. |
| T-632, T-640, T-647 | `safe-commands.sh` | mutant derivation broken; checked by behaviour | PRESENT (`curl -o`, `curl -O` and `wget` are refused; `curl -s`, `wget -qO-`, subshells and `$(…)` reads are allowed) |
| T-575 | `check-active-task.sh`, `update-task.sh` | behaviour check | b17e49fa is covered (T-1005). The T-607 form (`fw git commit -m "T-N:"`) was **broken by my own 37865ec7 today**, found here and fixed as **T-1023** (0b9a3ec7). T-392 (pattern 2) is PRESENT. |
| T-652 | `safe-commands.sh` | no probe | same spelling-dependence class as T-650 (usability) |
| T-624, T-625 | `check-inception-schema.py` (undeclared) | `_t624` green | message wording LOST (the warning that the example defaults plant the template's opinion). Superseded in effect by the re-applied T-865 estimator, which proposes real values. Low value. |
| **T-912** | `observe.sh` | behaviour check | **LOST.** `fw note promote` writes the literal `promoted_to: task` instead of the new task ID (observe.sh:382), so an observation no longer records which task it became. |
| **T-914** | `observe.sh` | behaviour check | **LOST.** The `fw note resolve` verb no longer exists, so the inbox's largest class has no exit. The inbox stands at 128 pending. |

### The 12 rows on undeclared paths whose task appears elsewhere in the register

| Task | Verdict |
|---|---|
| T-343, T-373, T-516, T-675 | PRESENT: `_t343`, `_t373` 8/8, `_t516` 8/8 and `_t675` are green on HEAD. |
| T-401 | Behaviour PRESENT (`_t675` fence, the T-1005 step-1 measurement). Its test file `web/test_context_tokens.py` is GONE: T-1005 restored it to the working tree but it was never committed. |
| T-295, T-351 | Not verified (`healing/lib/resolve.sh` learnings append; one line of compiled JS). |
| **T-939** | **LOST, security-relevant.** T-939 (1b98bebd, 09-30) redacted this host's `/etc/machine-id` from `.agentic-framework/docs/reports/T-375-agent-3-key-storage.md`, because the secrets-store encryption key derives from it. The 1.7.740 pristine vendor commit (2659abad, 10-02) **re-introduced the real value**: verified equal to `/etc/machine-id` by comparison, value not printed. It is also in **AEF's public GitHub mirror on both `master` and `bleeding-edge`**, since the file comes from AEF's own tree. 832's copy is pushed only to the internal OneDev server. |

## Answers

- **IW-1:** 211 rows had added lines measured; 88 are candidates. 28 of those name a task the register never mentions, plus 12 on undeclared paths.
- **IW-2:** Most candidates are PRESENT by behaviour (rewritten or superseded upstream). **Genuinely lost: T-866** (GO requires an observable hypothesis), **T-908** (`fw fabric impact` crashes silently and prints an empty chain), **T-912** (promote records `task` instead of the ID), **T-914** (`fw note resolve` gone), **T-939** (machine ID re-published). Usability-only: T-636, T-650, T-652. Wording-only: T-624/T-625.
- **IW-3:** T-908 and T-939 have live consequences now. T-866, T-912 and T-914 are wanted features with no probe; each needs one.

## Recommendation: GO

Five lost fixes, each with a bounded restore. Rank by consequence:
1. **T-939: the machine ID.** Redact it again in our tree and declare it. The real exposure is in AEF's public repo, so AEF must redact it there too. History and any rotation are **the operator's call**: they decide whether anything encrypted with the old key still needs rotating, and whether a history rewrite is wanted (Tier 0).
2. **T-908: `fw fabric impact`.** Restore the string-dep guard and the IMPACT NOT COMPUTED refusal, with a probe.
3. **T-866**, **T-912**, **T-914:** re-apply each with a probe.

Each becomes its own build task after the decision, and each goes upstream in bundle E (T-1021). Method cost: about 1 minute mechanically plus probe runs, repeatable before every re-vendor.

## Dialogue log

- 2026-10-04: The operator, given the suggested next steps, said "Proceed as suggesting you see fit." This inception follows.
