# T-1035: 832's hook fixes whose teeth fail on 1.7.740 — adopted, lost, or obsolete?

**Status:** inception, exploration in progress (2026-10-04).
**Trigger:** T-1013 wired the unwired standing guards. 13 teeth for 832 framework-hook fixes (T-628..T-662) fail (9) or cannot build their pre-fix mutant (4) on the 1.7.740 vendor. T-1020's census, which looked for exactly this class, did not flag them.
**Why now:** the v1.8.0 upgrade is next. Anything lost and undeclared will be lost again.

## Method

- **Spike A (mechanical):** per tool, the fix commit(s) under `.agentic-framework/`, the share of added lines surviving in HEAD, the T-1020 census row, and the register status. Answers IW-2.
- **Spike B (behavioural):** per tool, the behaviour it protects, tested directly on today's tree. Verdict ADOPTED / LOST / OBSOLETE with the check that decided it. Answers IW-1 and IW-3.

## The 13

| Tool | Today (T-1013) |
|---|---|
| `_t628-g020-remedy-reachable.sh` | 5/11 |
| `_t629-g067-remedy-reachable.sh` | 7/10 |
| `_t631-tier0-approval-reachable.sh` | 4/6 |
| `_t632-read-only-misclassification.sh` | cannot measure |
| `_t633-shared-tmp-sinks.sh` | 6/8 |
| `_t634-guard-verdict-reaches-caller.sh` | 4/7 |
| `_t636-prose-verbs-vetoed-by-their-own-text.sh` | 13/15 |
| `_t637-inception-coverage.sh` | 7/8 |
| `_t638-commit-exemption-is-clause-scoped.sh` | cannot measure |
| `_t639-drift-gate-reads-fixtures.sh` | cannot measure |
| `_t650-an-alias-is-the-command-it-aliases.sh` | 10/16 |
| `_t654-watchdog-detections-must-be-surfaced.sh` | cannot measure |
| `_t662-null-focus-commit-path-must-be-discoverable.sh` | 4/9 |

## Findings

### Spike A (2026-10-04)

Per fix: commits under `.agentic-framework/` (`git log --grep '^T-N:'`), mentions in the T-1020 census report, entries in `.agentic-framework/.vendor-divergence.yaml`.

| Fix | Framework commit | T-1020 census | Register |
|---|---|---|---|
| T-628 | 6be478ad | red; "probably superseded by upstream T-3299 … **to confirm**" (never confirmed) | — |
| T-629 | b71e5b2a | same row as T-628 | — |
| T-631 | none | not seen | — |
| T-632 | a468a994 | PRESENT by behaviour (curl -o/-O, wget refused; reads allowed) | — |
| T-633 | none | not seen | — |
| T-634 | none | not seen | — |
| T-636 | 674d68b5 | red; classed "gate usability (OVER-blocking)", not restored | — |
| T-637 | none | not seen | — |
| T-638 | a12e1497 | not seen | 1 entry |
| T-639 | fab771f2 | PRESENT (restored by T-1005; `_t1005` replaces `_t639`) | 1 entry |
| T-650 | 3032e3e2 | red; same usability row as T-636 | — |
| T-654 | 3653bdbb | not seen | 2 entries |
| T-662 | 72588583 | not seen | 1 entry |

**IW-2 (why T-1020 "missed" them), corrected.** My hypothesis said T-1020 could not see them. That is wrong for 6 of the 13:
- **T-628/T-629:** it saw them and deferred confirmation; nothing tracked the deferral.
- **T-632 and T-639:** it judged them present.
- **T-636/T-650:** it classed them as usability and chose not to restore.

The 7 it did not see split two ways:
- **T-631, 633, 634, 637** changed nothing under `.agentic-framework/`. Their subject is elsewhere (832 tools, hooks or settings), outside a census of vendored-file commits.
- **T-638, 654, 662** are declared in the register, so a re-apply was owed under T-1005. Whether it happened is a Spike B question.

So the gap is not one blind spot. It is three: an unconfirmed "to confirm", a deliberate usability triage, and two populations outside the census's frame.

### Spike B (2026-10-04)

Method: each tool run once (`timeout 300`, output in `/tmp/t1035-spikeb/_t6NN-*.out`). The behaviour was then tested on today's tree (1.7.740) with the real gate (`check-active-task.sh` fed a JSON payload against a sandbox project whose focus I control), the real `update-task.sh` on a synthetic `PROJECT_ROOT`, and `safe-commands.sh` predicates. Helpers: `/tmp/t1035-spikeb/{g.sh,g2.sh,t634.sh}`. "Safety" means an unguarded write or bypass; "usability" means over-blocking or an unreachable remedy.

| Fix | Behaviour protected (and how the fix delivered it) | Today's check and result | Verdict | Class |
|---|---|---|---|---|
| T-628 | A G-020 block's printed remedy must be runnable from the blocked state (metadata-only `fw task update` exemption). | Placeholder-AC build task: `fw task update T-9002 --type inception` and `--horizon later` → rc 0 with NOTE "(T-3299)". A different id → FOCUS-DRIFT rc 2. A payload (`&& echo hi > f`), `sed -i` on the task file and a Write to source → rc 2. Tool: 5/11. Its red legs assert the old "T-628 NOTE" string and the old message wording. | **ADOPTED** by upstream (T-3299/OBS-353 added the same exemption, narrower, and the message now says "Write/Edit TOOL … shell writes stay blocked"). | n/a |
| T-629 | A G-067 block's remedies must be reachable (task file editable, override works). | Inception with empty Open Questions: Edit tool on the task file → rc 0. Write to source → rc 2. A filed IW → rc 0. `FW_ALLOW_INCEPTION_OPEN_QUESTIONS_DRIFT=1` in the hook env → rc 0 (tool leg PASS). Shell forms are refused, as the tooth expects. | **ADOPTED** by upstream code (task-file exemption). Cosmetic residue: G-067 remedies 1–2 still say "Edit …" without naming the Edit tool, so the two message-text legs stay red. | n/a (cosmetic usability) |
| T-631 | The Tier-0 approval route is reachable, and no Bash hook prints a remedy it refuses. | `fw tier0 approve` typed through the gate → refused. Upstream added a deliberate "TIER 0 SELF-APPROVAL … human-only" rule (`check-tier0.sh:298-304`). The block message still prints the operator's `cd … && fw tier0 approve` and the Watchtower URL, and an operator terminal runs no PreToolUse hooks. Population leg: `check-bare-import` has no probe (a coverage gap, not a behaviour). | **OBSOLETE.** The tooth's premise (the agent surface can run the approval) is superseded by upstream's intentional hardening. The operator's route is intact. | n/a |
| T-632 | Read-only commands are not refused as writes: `2>/dev/null)` inside `$(…)`, and sed/sort/cut/tr/diff in the allowlist. | No focus: the exact `/resume` step-5 line, `sed -n '340,420p' …`, `cat f \| sed -n 1,20p`, `sort \| cut \| tr`, `diff`, `$(ls 2>&1)` → rc 0. `sed -i`, `echo $(ls > f)` → rc 2. `curl -o/-O/--output`, `wget` → not safe. `curl -sS`, `curl -o /dev/null -w …`, `wget -qO-` → safe. Tool: cannot build its mutant (redirect anchor gone). | **ADOPTED** by upstream code. The register has no entry for it and T-1020 judged it present. | n/a |
| T-633 | Our tools and verification loops never use a fixed shared-`/tmp` sink (`curl -o /tmp/.pg -w …`; `_t631` stopped writing fixed `/tmp` files). | Tool 6/8; both red legs are census over-matches. Leg 2's one hit is a prose example in a vendored prompt doc, `policy/prompts/landing-mode.md:182`. Leg 3's hits (`_t842`, `_t845`, `_t936`) are strings inside classifier fixtures that are never executed. A grep for real `>`/`-o`/`tee`/`rm` on fixed `/tmp` names in `tools/` and the hooks found only fixtures. | **ADOPTED** by the 832 fix (the sandboxed `_t631` holds). The census regex now needs to skip fixtures and docs. | n/a |
| T-634 | A P-011 guard's verdict reaches the caller: a malformed Verification block must stop completion. Pinned dependency: errexit at a bare call site. | Real `update-task.sh` on a synthetic root: control completes (rc 0); `if true; then` → rc 1 and stays in `active/`; unterminated quote → rc 1; `--skip-verification` → rc 1; `false` → rc 1. Tool: the banner text changed ("contains line(s) bash cannot parse"), and its call-site grep now also matches the function definition (found 2). | **ADOPTED** by upstream code (guard rewritten with a Tier-2 bypass flag). The call site `update-task.sh:2445` is still a bare call. | n/a |
| T-636 | A framework verb's free-prose argument is not vetoed by `rm`/`tee` inside the prose (`fw note`, `context add-*`, `task create`, `git commit`). | No focus: `fw note "…rm and tee"`, `add-learning "rm -rf > x && tee y"`, `add-pattern`, `add-decision`, `task create`, `handover` → rc 0. Widening checks (`&& rm -rf`, `$(rm …)`, `sh -c`) → rc 2. Tool 13/15. Red legs: `fw git commit -m "drop the rm -rf call"` refused with no task, and the exemption-assignment anchor is gone. | **ADOPTED** by 832 re-apply (T-1005 `27ba4c0e`, `_sc_is_framework_prose_verb`). The `fw git commit` spelling is not admitted with no task. That is the T-650 gap below, not a prose veto. | n/a here; see T-650 |
| T-637 | Every undecided inception reaches a reader (the scan, structurally parsed, plus the brief). | `_t627-undecided-defer.py` covers all 13 undecided inceptions; the frontmatter selector rejects body mentions. The single red leg: the frozen brief `docs/reports/T-637-inception-blockers.md` omits T-1010, T-1035, T-811, T-898, which were opened or became undecided after it was written. | **ADOPTED** (an 832 tool/report fix, not a framework hook). The red leg compares a frozen snapshot with a moving population. | n/a |
| T-638 | The null-focus commit exemption is judged per clause, not by the words "git commit" appearing anywhere. | No focus: `echo "git commit -m x" > f`, `echo "…git commit later" && rm -rf …`, `git commit … && rm -rf`, `git commit … $(touch …)`, `git commit -m "T-1: $(touch …)"`, `--no-verify`, `git commit … > out`, `bash -c "git commit …"`, `echo hi > f && git commit` → all rc 2. `git commit -m …` and `git add -A && git commit -m …` → rc 0. | **ADOPTED** by upstream code (T-3221 `is_commit_checkpoint_command`, which credits 832's T-638). The tool cannot find the old predicate call to mutate. | n/a |
| T-639 | The drift gate reads the task a command targets, not task ids it merely mentions. | Tool's behavioural legs all PASS today (genuine drift blocked; 6 mention-only fixtures allowed; both bypasses work). Only the teeth leg is red (the mutation target, a function name, no longer exists). `_t1005-drift-target-clause-scoped.py` → 18/18, rc 0. | **OBSOLETE.** Superseded by `_t1005` (passes), as its header states. Behaviour is also ADOPTED via the 832 re-apply (T-1005). | n/a |
| T-650 | An alias is the command it aliases: `fw git commit` ≡ `git commit`, `fw fix-learned` ≡ `fw context add-learning`. | No focus: `fw fix-learned T-1 "x"` → rc 2 while `fw context add-learning "x" --task T-1` → rc 0. `fw git commit -m "T-1: x"` and `bin/fw git commit …` → rc 2 ("not on the read-only allowlist") while `git commit -m "T-1: x"` → rc 0. With a valid focus both aliases pass. `fw git status`/`log` → rc 0. T-1005 re-applied the prose-verb list (it contains `fix-learned` and `git commit`) but not the no-task allowlist entries, so the half that decides the verdict is missing. | **LOST** | usability |
| T-654 | Two fixes. (1) Detections of the T-522 completion watchdog must surface, via audit Check 1b. (2) The partial-complete recheck branch must null `horizon:` on archive. | (1) The watchdog is intact (`update-task.sh:2058-2110`, re-applied by T-1005). Its consequence, a completed task with no episodic, is flagged by upstream audit Check 1 ("Completed task X has no episodic summary", `audit.sh:5269`), and the register already records T-654 as superseded there. (2) Upstream's archived-horizon invariant (T-3235, "peer 832 T-654 BUG 1") is at `audit.sh:3160`. The tool cannot find "Check 1b", which is why it is red. | **ADOPTED** (watchdog by 832 re-apply; surfacing by upstream Check 1; horizon by upstream T-3235). | n/a |
| T-662 | Under null focus the post-completion commit path works and is named in the block message. | Path works: `git add -A && git commit -m …` → rc 0 (upstream T-2054/T-3221 admit `git commit` directly). Message gone: `git commit -m "T-1: $(touch …)"` → rc 2 with the generic "No active task" block and no cause. `fw git commit` → rc 2 with no mention of the way through. `check-active-task.sh` has 0 occurrences of T-662, although the register still lists the divergence (a stale entry). The tool's "commit is blocked" premise is itself outdated. | **LOST** (the advisory only; the path itself works) | usability |

**Summary.**
- **Counts:** ADOPTED 9 (T-628, 629, 632, 633, 634, 636, 637, 638, 654), OBSOLETE 2 (T-631, T-639), LOST 2 (T-650, T-662), UNDECIDED 0. LOST by class: 0 safety, 2 usability.
- **IW-1 (per-fix status):** 11 of 13 behaviours hold, 2 are lost, and none of the losses leaves an unguarded write or bypass. Upstream absorbed or superseded 6 (T-628, 629, 631, 632, 634, 638) and 832's re-apply or own fix holds for 5 (T-633, 636, 637, 639, 654). Both losses sit in the null-focus `fw …` spelling family: `fw git commit` and `fw fix-learned` are refused with no task, and the block message no longer says why or names the way through (bare `git commit` works). The other 11 red tools are red because of stale teeth (anchors, banner strings, frozen snapshots), not lost behaviour. Fixing T-650 means adding the `fw git commit` and `fw fix-learned` spellings to the no-task allowlist, as the T-1005 comment already describes for `fix-learned`. T-662's message is a separate small re-apply. Before v1.8.0, fix those two and record the T-662 register entry as stale.
- **IW-3:** `_t632`, `_t638`, `_t639` and `_t654` are stale teeth, not gone subjects. Each reports COULD-NOT-MEASURE because its mutation anchor is missing from 1.7.740 (renamed predicate, function or audit block). The behaviours were verified directly: T-632 (curl/wget/sed matrix), T-638 (clause matrix), T-639 (legs PASS, `_t1005` 18/18) and T-654 (watchdog plus upstream Check 1). Re-anchor them against `is_commit_checkpoint_command`, `_fw_extract_drift_target` and audit Check 1, or retire `_t639` in favour of `_t1005`.
- **Side effects:** none of my runs touched tracked files outside `/tmp`. The gate wrote `.context/working/.tier0-approval.pending` once, because one probe's command text contained the approval phrase; it is a runtime artifact and I did not restore it. The other `.context/` and `.editor-versions/` modifications in `git status` come from other sessions and hooks, and I left them alone.

## Dialogue Log

- 2026-10-04: the operator approved the plan (T-1013 report → "yes" to: wire, restore hooks, then this census before the v1.8.0 upgrade).
