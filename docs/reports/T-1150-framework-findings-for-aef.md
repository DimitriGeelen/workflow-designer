# T-1150 — framework findings for AEF, from 832's observation inbox

832 triaged its 138 pending observations on 2026-10-13 (T-1149, docs/reports/T-1149-observation-triage.md).
These 25 are framework defects that were still open and, as far as 832 could find, never reported to AEF.
Each was re-checked on 2026-10-13 against 832's vendored copy (bleeding-edge ed683536a, 1.8.9+227) and against
AEF's repo at the bleeding-edge tip 1146a745, by read-only workers (code reading and harmless probes; nothing
mutating was run). The OBS ids are 832's own register, not AEF's.

Where a section says FILED AT AEF, AEF already has a task; the section says what that task does not cover.
Please tell us which you take, which you already have under another id, and which you think are not defects.

| # | 832 obs | finding | status 2026-10-13 |
|---|---|---|---|
| 1 | OBS-346 | fw bvp cost axis is blind to governance tasks (no blast_radius derived), leaving them without a quadrant | FILED AT AEF |
| 2 | OBS-355 | fw bvp quadrant split uses a running median over the ranked population, so scoring other tasks moves a task's quadrant (selection laundering) | FILED AT AEF |
| 3 | OBS-356 | fw build has no dependency-bootstrap step (lib/ts/node_modules never provisioned) and doctor's 'TypeScript build stale' WARN hides the real js-yaml resolve failure | STILL TRUE |
| 4 | OBS-360 | fw task archive-eligible cannot sweep CTL-029 'all ACs ticked but started-work' tasks (only work-completed) | STILL TRUE |
| 5 | OBS-369 | fw bvp estimate-cost all --dry-run reports every task as skipped (cannot preview its own writes) | STILL TRUE |
| 6 | OBS-370 | inception template tells the agent to change voi_score/target_blast_radius, which are operator-owned, with no *_proposed channel | STILL TRUE |
| 7 | OBS-375 | focus-drift gate (T-1730) strands closure commits — no focus value satisfies it once the referenced task is in completed/ | STILL TRUE |
| 8 | OBS-380 | audit WARN mitigations name repo-relative bin/fw, which does not exist in shared-tooling consumers | STILL TRUE |
| 9 | OBS-381 | audit needs a per-project NOT_APPLICABLE scope for checks whose corpus is structurally absent (4 of 15 warnings permanently vacuous) | STILL TRUE |
| 10 | OBS-387 | termlink_spawn/termlink_dispatch return ok:true with workers_registered:0 and execute nothing | COULD NOT CHECK |
| 11 | OBS-392 | BVP estimator scores no-signal drivers at mid-scale 2, so contentless stubs rank hv-hc (should abstain / NOT_EVALUATED) | STILL TRUE |
| 12 | OBS-409 | bvp-estimator gives stub tasks an identical D1-D4 vector from template idiom, so it cannot rank them | STILL TRUE |
| 13 | OBS-413 | fw handover pushes to origin without a flag or any warning; add --no-push or announce the push first | STILL TRUE |
| 14 | OBS-414 | fw bvp estimate-cost prints [wrote] and exits 0 when it wrote no blast_radius; the ranker shows the same bare dash for a missing cost axis and a missing value axis | STILL TRUE |
| 15 | OBS-417 | add Verification-block guidance to the task template (anchor cross-task legs across active/ and completed/; prefer find over ls; control negated greps) | STILL TRUE |
| 16 | OBS-420 | fw fabric register prints REFUSED yet writes the card (type script, TODO purpose) for files outside the watch patterns | STILL TRUE |
| 17 | OBS-426 | deleting a task file recycles its id (generate_id is max+1 over files); add a high-water mark or a task disposal verb | STILL TRUE |
| 18 | OBS-427 | inception decide fallback says 'Unknown error' when operator_facing_stderr filtered a non-empty refusal to nothing | STILL TRUE |
| 19 | OBS-449 | Tier 0 passes a destructive command inside a script; approvals keyed to a hash of the command text | PARTLY FIXED (force-push now caught at pre-push; destructive commands inside a script still unseen) |
| 20 | OBS-452 | handover.sh emits a complete-looking handover with no session content | STILL TRUE |
| 21 | OBS-453 | fw task update cannot set related_tasks or unlocks_inception_decision | STILL TRUE |
| 22 | OBS-454 | severe and deterministic reviewer static-scan findings do not block work-completed | STILL TRUE |
| 23 | OBS-458 | episodic generator ignores decisions.yaml and concludes "no decisions to record" | STILL TRUE |
| 24 | OBS-462 | no audit rail for a child task closing another task's IW or unpriced item | STILL TRUE |
| 25 | OBS-466 | reviewer destructive-action scanner matches prose and comments in Verification and AC text | STILL TRUE |

## Findings

### OBS-346 — fw bvp cost axis is blind to governance tasks (no blast_radius derived), leaving them without a quadrant
- **Status:** FILED AT AEF (T-3471, captured, horizon later). Partly: T-3471 names the same cost-axis gap for open tasks, but its remedy (derive blast_radius before work-completed) does not cover task records with no `components:`, and no task covers the missing quadrant cell.
- **What is wrong:** A task gets a cost only when blast_radius, tier and effort are all present, and blast_radius comes only from the `components:` count. Governance task records have no components, so their quadrant is `-` and no cell exists for them.
- **Evidence (re-checked 2026-10-13):** `.agentic-framework/lib/bvp.sh:281-292` (cost is `absent` unless all three terms, or a T-shirt `size`, are present); `.agentic-framework/agents/termlink/bvp-estimator/estimator.py:3409-3425` and `:3592-3599` (blast_radius is `null` with no components); `.agentic-framework/lib/bvp.sh:332-333` (`quadrant()` returns `-` when cost is None); `.agentic-framework/lib/bvp.sh:433-440` (T-3068 NOTE counts the unplaced tasks, a disclosure rather than a cell). AEF `.tasks/active/T-3471-*.md:12` is `status: captured`. Whether the 35 tasks carry a `size` was not checked.
- **Effect on a consumer project:** In 832, a governance task with tier and effort but no `components:` shows COST and QUAD as `-`, so a Q1/Q2 selection rule cannot pick it.

### OBS-355 — fw bvp quadrant split uses a running median over the ranked population, so scoring other tasks moves a task's quadrant (selection laundering)
- **Status:** FILED AT AEF (T-3839, captured). Same root (a population-relative median), but T-3839 names the viewer filter, not the scoring-neighbours case.
- **What is wrong:** The exact hazard in the observation (costing low-BVP neighbours lowers the BVP median) no longer happens, because the BVP median is now taken over every bvp-scored task. The running-median root remains: the cost median is taken over whichever tasks happen to be costed, so costing a neighbour can flip another task between lc and hc.
- **Evidence (re-checked 2026-10-13):** `.agentic-framework/lib/bvp.sh:399-404` (every bvp-scored task enters `rows`, cost or not); `.agentic-framework/lib/bvp.sh:414-416` (`bvp_median` over all rows, `cost_median` over known costs only, T-3068); `.agentic-framework/lib/bvp.sh:421` (quadrant uses both medians). AEF `lib/bvp.sh:385-386` is identical; AEF `.tasks/active/T-3839-*.md:9` is `status: captured`.
- **Effect on a consumer project:** A task's hv-lc membership in 832 can change when another task is costed, even though its own value and cost are unchanged.

### OBS-356 — fw build has no dependency-bootstrap step (lib/ts/node_modules never provisioned) and doctor's 'TypeScript build stale' WARN hides the real js-yaml resolve failure
- **Status:** STILL TRUE, but latent: the failure cannot occur in 832 today. Not filed at AEF.
- **What is wrong:** The framework still has no dependency bootstrap, and the doctor WARN still blames staleness instead of the resolve failure. The observation's premise that `package.json` and `package-lock.json` are vendored is out of date.
- **Evidence (re-checked 2026-10-13):** 832 `.agentic-framework/lib/build.sh:11-14` exits 0 when `lib/ts/src` is absent; `lib/ts` holds only `dist/` and there is no `node_modules`; `.agentic-framework/bin/fw:3859-3874` runs the doctor TS check only when `lib/ts/src` exists, WARN text unchanged. AEF `.tasks/completed/T-2849-*.md:129-136` says `lib/ts/src/*`, `package.json` and `package-lock.json` are excluded from the vendored tree by design. AEF (bleeding-edge 1146a745): `lib/build.sh:40-52` runs `npx --yes esbuild` with no npm install; `bin/fw:3880` WARN text unchanged; `lib/ts/src/fw-util.ts:19` imports js-yaml. No AEF task found (searched js-yaml, node_modules, npm install, lib/ts).
- **Effect on a consumer project:** None in 832 today: `fw build` exits 0 with no sources and doctor skips the TS check. A consumer that vendors `lib/ts/src` would get a silent build failure and a "stale" WARN pointing at the wrong cause.
- **Suggested fix:** Have doctor surface the real npm resolve error, and have `build.sh` bootstrap its dependencies or fail loudly.

### OBS-360 — fw task archive-eligible cannot sweep CTL-029 'all ACs ticked but started-work' tasks (only work-completed)
- **Status:** STILL TRUE. Not filed at AEF.
- **What is wrong:** `is_archive_eligible` accepts only `work-completed`, so no verb sweeps started-work tasks whose ACs are all ticked. CTL-029 only tells the reader to run the status verb task by task.
- **Evidence (re-checked 2026-10-13):** `.agentic-framework/bin/fw:5880-5882` (returns False unless status is `work-completed`); `.agentic-framework/agents/audit/audit.sh:6657-6659` (CTL-029 mitigation is `bin/fw task update <id> --status work-completed`). AEF (bleeding-edge 1146a745) has the same check at `bin/fw:5882`; the CTL-029 searches found T-2055 (detector) and T-1903 (work-completed sweep) and no started-work sweep. Re-measured in 832: of the eight tasks, T-681 is now work-completed; T-041, T-101, T-102 and T-293 have 2 unchecked criteria; T-105, T-309 and T-357 are still started-work with no unchecked criteria (counted over the whole AC section, Human criteria included).
- **Effect on a consumer project:** T-105, T-309 and T-357 can only be closed one at a time through the status verb, which the focus and sovereignty gates control. No sweep reaches them.
- **Suggested fix:** Extend `is_archive_eligible` to started-work tasks whose ACs are all ticked.

### OBS-369 — fw bvp estimate-cost all --dry-run reports every task as skipped (cannot preview its own writes)
- **Status:** STILL TRUE. Not filed at AEF. Checked by reading the code; I did not run the dry-run.
- **What is wrong:** The dry-run path returns `wrote=False`, and the sweep counts every `wrote=False` as skipped. The summary has no would-write count.
- **Evidence (re-checked 2026-10-13):** `.agentic-framework/agents/termlink/bvp-estimator/estimator.py:3710-3711` (`if dry_run: return False, "dry-run"`); `estimator.py:4075-4107` (`cmd_cost_all`: `if wrote: n_wrote += 1 else: n_skip += 1`, then prints "wrote, skipped"). AEF's `agents/termlink/bvp-estimator/estimator.py` has the same counting and no would-write counter.
- **Effect on a consumer project:** The documented preview says "0 wrote, 777 skipped" when the real run writes 214. The real run is correct, so this misleads a reader rather than corrupting state.
- **Suggested fix:** Count would-write separately from skipped in the dry-run summary.

### OBS-370 — inception template tells the agent to change voi_score/target_blast_radius, which are operator-owned, with no *_proposed channel
- **Status:** STILL TRUE. Not filed at AEF. The nearest AEF tasks are T-3496 (captured, a sovereign question on voi_score being a constant) and T-3522 (completed); neither names the missing channel.
- **What is wrong:** No `voi_score_proposed` or `target_blast_radius_proposed` channel exists, and the estimator computes those values but never persists them. The "CHANGE THIS … abstains" text the observation quotes no longer exists in either copy.
- **Evidence (re-checked 2026-10-13):** `.tasks/templates/inception.md:19-22` (defaults 3 and 0.5, marked "Required", no "CHANGE THIS"); grep for `voi_score_proposed|target_blast_radius_proposed` over `lib agents bin tools` returns zero hits; the AEF repo returns zero hits. `estimator.py:2824-2850` (`propose_inception_inputs` returns `estimated`); its only caller, `cmd_one` at `estimator.py:3745-3746`, puts it into the result and writes nothing.
- **Effect on a consumer project:** An agent that cannot write operator-owned fields has nowhere to put its voi or target estimate, so inceptions keep the planted defaults and the estimator's values go nowhere.
- **Suggested fix:** Persist `voi_score_proposed` and `target_blast_radius_proposed` the way `bvp_scores_proposed` is written.

### OBS-375 — focus-drift gate (T-1730) strands closure commits — no focus value satisfies it once the referenced task is in completed/
- **Status:** STILL TRUE. Not filed at AEF.
- **What is wrong:** The drift gate blocks any command whose target task differs from focus, and has no exemption for a completed target. For a completed target it offers only Tier-2 bypasses. The T-2054 exemption applies only when focus is null.
- **Evidence (re-checked 2026-10-13):** `.agentic-framework/agents/context/check-active-task.sh:843` (drift block fires on any target ≠ focus); `:912-919` (completed-target message offers only options 2 and 3); `:655-685` (T-2054 exemption, null focus only). AEF (bleeding-edge 1146a745): `agents/context/check-active-task.sh:739` is identical and `:813` has the same message; T-2875 (completed) changed only the message text. Not re-checked: the sub-claim that bare `git commit` is not hooked by the drift gate. COULD NOT CHECK for that part.
- **Effect on a consumer project:** A closure commit for a just-closed task, made while focus is on a live task, is refused. The only remedies offered are Tier-2 bypasses or misattribution.

### OBS-380 — audit WARN mitigations name repo-relative bin/fw, which does not exist in shared-tooling consumers
- **Status:** STILL TRUE. Not filed at AEF.
- **What is wrong:** Audit mitigations print `bin/fw …`, a path that exists only inside the framework checkout.
- **Evidence (re-checked 2026-10-13):** `.agentic-framework/agents/audit/audit.sh:4352` and `:4357` (`bin/fw bvp driver --validate-scoring`), `:4613` (`bin/fw fabric enrich --describe-only`), `:6551` and `:6553` (`bin/fw task archive-eligible`), `:6657-6659` (CTL-029 `bin/fw task update`). In 832, `test -e bin/fw` is false and `bin/fw version` prints "No such file or directory". The audit already resolves its own framework path at `audit.sh:44` (`FW_PATH`). AEF (bleeding-edge 1146a745) has the same strings at `agents/audit/audit.sh` 4194, 4199, 6378 and 6380; no AEF task found whose subject is the mitigation text (searched "repo-relative", "shared-tooling", "bin/fw" with mitigation).
- **Effect on a consumer project:** Pasting the audit's own mitigations in 832 returns `bin/fw: No such file or directory`.
- **Suggested fix:** Print the resolved framework path, as `audit.sh:44` already computes it, or use bare `fw`.

### OBS-381 — audit needs a per-project NOT_APPLICABLE scope for checks whose corpus is structurally absent (4 of 15 warnings permanently vacuous)
- **Status:** STILL TRUE. Not filed at AEF.
- **What is wrong:** A rail with an empty candidate set reports a warning every run, and the audit has no per-project scope that would let it report NOT APPLICABLE instead. I re-measured only the stale-slice rail; the other three rails the observation names are not re-checked.
- **Evidence (re-checked 2026-10-13):** `.agentic-framework/agents/audit/audit.sh:766-805` (`pass_over`: a zero count warns "NOT EVALUATED: candidate set empty"); `:2156-2162` (stale-slice scans `web/templates web/blueprints lib`). In 832: `test -d web` is false, and `find web lib -name '*.py'` returns 0 files. No per-project scope exists: there is no `NOT_APPLICABLE` in `audit.sh`, and the only "not applicable" is a silent return at `:4052` that emits no status. AEF `.tasks` has no task for a NOT_APPLICABLE or per-project scope.
- **Effect on a consumer project:** The stale-slice warning appears on every audit in 832 and cannot ever fire, and it inflates the standing warning count.
- **Suggested fix:** Add a per-project scope declaration so such rails report NOT APPLICABLE once and stop counting as warnings.

### OBS-387 — termlink_spawn/termlink_dispatch return ok:true with workers_registered:0 and execute nothing
- **Status:** COULD NOT CHECK (the defect lives in the termlink binary, which is not in either framework repo; reproducing it needs a mutating spawn/dispatch)
- **What is wrong:** spawn and dispatch report `ok:true` (dispatch also `timed_out:false`) when no worker registered and nothing ran, so a caller checking `ok` is told the fan-out succeeded.
- **Evidence (re-checked 2026-10-13):** `docs/reports/T-854-procasfit-run-handback.md:20` still records the original output (`ok: true`, `workers_spawned: 1`, `workers_registered: 0`, `timed_out: false`, no file written). The binary is `/root/.local/bin/termlink` (0.12.482); no source for it is in `/opt/832-Workflow-designer` or `/opt/999-Agentic-Engineering-Framework`. A grep of AEF `.tasks/` for `workers_registered`, `spawned but timed out` and `termlink.*registration` found no task. The nearest AEF tasks are different defects: T-4067 (completed, `fw termlink dispatch` aborts silently after "Tagged:") and T-4152 (active, dispatch leaks its endpoint).
- **Effect on a consumer project:** an orchestrator that checks `ok` or `timed_out` treats a dispatch that never ran as a clean run with no results, so it reports "workers found nothing" instead of "workers never started".
- **Suggested fix:** return `ok:false` when `workers_registered < workers_spawned`, or when spawn times out waiting for registration.

### OBS-392 — BVP estimator scores no-signal drivers at mid-scale 2, so contentless stubs rank hv-hc (should abstain / NOT_EVALUATED)
- **Status:** STILL TRUE (mid-scale scoring of contentless tasks reproduced; the quadrant and weight arithmetic were not re-checked)
- **What is wrong:** a task with no real content gets mid-scale driver scores, not an abstention, so it is ranked as if it had been assessed.
- **Evidence (re-checked 2026-10-13):** `PROJECT_ROOT=/opt/832-Workflow-designer .agentic-framework/agents/termlink/bvp-estimator/bvp-estimator.sh one T-280 --dry-run --json` returns 2 for D1, D2, D3, D4, F-RECALL, F1–F4, all with evidence `voi:open-question~'assumption'` and `→2 (voi:0.40 estimated)`. T-281 and T-282 return the same vector. The word "assumption" comes from template text: `.tasks/active/T-280-*.md:89` (HTML comment) and `:139`. The VoI table is at `agents/termlink/bvp-estimator/estimator.py:2752-2761` (vendored). `_score_inception_voi` (vendored `estimator.py:3093-3125`) says "no abstention bucket" by operator direction, so the abstain ask conflicts with recorded intent. At AEF HEAD, `agents/termlink/bvp-estimator/estimator.py:2651-2653` returns 2 when `voi_score` is absent ("voi-absent-grandfathered"), which is still mid-scale. AEF task T-3494 (captured, horizon later) covers the flat value axis ("give the value axis a real inception signal"), not abstention.
- **Effect on a consumer project:** contentless stubs (T-280–T-282) sit in the middle of the value scale and can be selected by quadrant when they cannot be worked, because the G-020 gate refuses their placeholder ACs.
- **Suggested fix:** emit NOT_EVALUATED for an inception with no `voi_score` and no content, and exclude it from the quadrant denominator.

### OBS-409 — bvp-estimator gives stub tasks an identical D1-D4 vector from template idiom, so it cannot rank them
- **Status:** STILL TRUE (the template-idiom mechanism is reproduced; the "identical vector for T-889..T-894" claim is only partly reproduced)
- **What is wrong:** the estimator matches keywords that come from the shared task template and the scorer's own prior rationale, not from the task's content.
- **Evidence (re-checked 2026-10-13):** dry-run on T-894 and T-890 both gives D1=4, D2=4, D3=3, D4=2 (identical). T-889 today gives D1=4, D2=2, D3=0, D4=0, so the original six-way identity no longer holds. D1's `body:structural-gate` on T-894 is triggered by template boilerplate: `.tasks/completed/T-894-*.md:21` ("PreToolUse hook" in the frontmatter comment), `:128` ("completion gate runs each command"), `:264` and `:303` ("completion gate (T-1550…)"). The D1 regex is at vendored `estimator.py:292` and `:298`, and AEF HEAD has the same regex at `:292`/`:298`. T-894 `:67` contains the scorer's earlier rationale text "(body:component-discoverability); D4=2 (body:env-class-handled)", so the scorer also reads its own prior output.
- **Effect on a consumer project:** every stub that carries the template boilerplate gets the same D1 structural-gate score, so the estimator cannot rank stubs against each other, and the rankings are driven by text the author never wrote.
- **Suggested fix:** strip the template comment block and any `bvp_scores_proposed` rationale before the body is scored.

### OBS-413 — fw handover pushes to origin without a flag or any warning; add --no-push or announce the push first
- **Status:** STILL TRUE
- **What is wrong:** `fw handover` commits and pushes by default, and no flag turns the push off.
- **Evidence (re-checked 2026-10-13):** vendored `agents/handover/handover.sh:231` sets `AUTO_COMMIT=true`. `:237-238` add `--commit` and `--no-commit`. `:396` calls `_push_to_remotes` in the checkpoint branch, and `:1844` in the normal branch. `:1845` is the `else` used only when there is no git agent. `grep -n 'no-push\|FW_NO_PUSH'` on the file returns nothing. AEF HEAD has the same call sites at `agents/handover/handover.sh:396` and `:1666`, with no opt-out. Related but not covering it: AEF T-3798 (active, handover pushed the real repo from a fixture; asks to refuse when HANDOVER_DIR is outside PROJECT_ROOT) and T-3734 (active, finds an unexplained pusher). Neither asks for an opt-out or an announcement.
- **Effect on a consumer project:** a routine handover publishes every local commit on the branch, including commits a previous session deliberately kept local, so a hand-off note that says "unpushed" becomes false without any action in that session.
- **Suggested fix:** add `--no-push` (or make push opt-in), and print "will push N commits to origin" before pushing.

### OBS-414 — fw bvp estimate-cost prints [wrote] and exits 0 when it wrote no blast_radius; the ranker shows the same bare dash for a missing cost axis and a missing value axis
- **Status:** STILL TRUE (the T-3068 NOTE for the cost axis is in place; the refusal exit code and the value-axis gap are not fixed)
- **What is wrong:** a refused write exits 0, and the ranker's `-` does not say which axis is missing.
- **Evidence (re-checked 2026-10-13):** vendored `agents/termlink/bvp-estimator/estimator.py:4071-4072` prints `[{reason}]` and then `return 0` whatever `wrote` is. AEF HEAD has the same at `estimator.py:3518-3519`. `lib/bvp.sh:332-333` returns `'-'` when either `bvp_norm` or `cost` is None, so a missing value axis also shows `-`. The NOTE at `lib/bvp.sh:436-437` names only the cost axis ("blast_radius unmeasured"), and no note covers a missing value score. AEF `lib/bvp.sh:302` and `:407` are the same. The fix for the cost NOTE is AEF T-3068 (completed).
- **Effect on a consumer project:** a caller that checks the exit code takes a refused blast_radius as success, and a task with no value score looks identical to one with no cost score.
- **Suggested fix:** exit non-zero (or print `REFUSED`) when `write_proposed_cost` returns `wrote=False` for a refusal, and print which axis is missing in the ranker.

### OBS-417 — add Verification-block guidance to the task template (anchor cross-task legs across active/ and completed/; prefer find over ls; control negated greps)
- **Status:** STILL TRUE (no AEF task found)
- **What is wrong:** the Verification guidance covers pipefail, SIGPIPE, skip counts and the `;` gate, but not the three failure shapes in the observation.
- **Evidence (re-checked 2026-10-13):** vendored `.tasks/templates/default.md:112-121` (mutable-corpus anchor), `:123-159` (pipefail/SIGPIPE), `:161-177` (skipped bats reports ok), `:203-220` (`;` judged only on the last command). `grep -n -i 'completed/\|negat\|find \|ls glob\|anchor'` returns only lines 112, 113 and 315. AEF `.tasks/templates/default.md` returns identical lines. AEF tasks searched for "went red after dependency completed", "negated grep", "find over ls" and "anchor across active/completed" turned up nothing specific. Adjacent: T-3326 (active, mutable-corpus verification lines), T-3203 (completed, gate semantics).
- **Effect on a consumer project:** a leg that goes red when its dependency task moves to `completed/`, or an `ls` glob that exits 2 on a legitimately empty match, passes or fails for reasons unrelated to the task, and the close gate refuses it.
- **Suggested fix:** add three short paragraphs to the Verification block: anchor cross-task legs across `active/` and `completed/`; use `find` for existence checks; pair every negated grep with a positive control.

### OBS-420 — fw fabric register prints REFUSED yet writes the card (type script, TODO purpose) for files outside the watch patterns
- **Status:** STILL TRUE (the card is still written after the refusal; the watch-pattern exclusion claim was not re-checked)
- **What is wrong:** the refusal is printed after the card is already written, and the function returns 0.
- **Evidence (re-checked 2026-10-13):** vendored `agents/fabric/lib/register.sh:294` sets `refusal` when no purpose is found. `:341` (`mv -f "$tmp_card" "$card_file"`) writes the card regardless. `:347` prints `REFUSED:`, and `:354` returns 0. AEF HEAD `agents/fabric/lib/register.sh:294`, `:341`, `:347`, `:354` is identical. The `watch-patterns.yaml` exclusion of `tests/fixtures/**` was not re-checked. No AEF task matched on the "REFUSED but writes" behaviour (T-1842 and T-3435 concern exclude-blindness and card quality).
- **Effect on a consumer project:** a reader who trusts the REFUSED line believes nothing was written, while a `TODO` card now exists and inflates the under-populated and orphaned-card audit WARNs.
- **Suggested fix:** check the refusal before the `mv` and write nothing when refused, or print "card written anyway" with the same line.

### OBS-426 — deleting a task file recycles its id (generate_id is max+1 over files); add a high-water mark or a task disposal verb
- **Status:** STILL TRUE (for task ids; the same defect for OBS ids was fixed at AEF HEAD)
- **What is wrong:** `generate_id` takes max+1 over the files that currently exist, so deleting the highest-numbered task file lets its number be reused.
- **Evidence (re-checked 2026-10-13):** vendored `agents/task-create/create-task.sh:308-342` scans `active/T-*.md` and `completed/T-*.md` (`:312-319`) and prints max+1 (`:341`). Quarantine logic is at `:280-292`. AEF HEAD `agents/task-create/create-task.sh:266-300` is the same. The OBS-id analogue was fixed at AEF by T-2966 (completed; commit `b8d0dbbb`, "OBS id allocator gets a high-water mark"). No AEF task covers task-id reuse.
- **Effect on a consumer project:** a deleted fixture task's id is handed to the next task, so the git history has two different tasks under one number.
- **Suggested fix:** keep a high-water counter file (or scan git history for every id ever used) and take the maximum with it in `generate_id`.

### OBS-427 — inception decide fallback says 'Unknown error' when operator_facing_stderr filtered a non-empty refusal to nothing
- **Status:** STILL TRUE (the empty-streams half is fixed at AEF HEAD and not yet vendored)
- **What is wrong:** when the filter removes every line of a non-empty refusal, the fallback says "Unknown error", which is indistinguishable from a subprocess that said nothing.
- **Evidence (re-checked 2026-10-13):** vendored `web/blueprints/inception.py:816-817` (`or "Unknown error from fw inception decide"`). The observation cited 647-648; the code has moved. `web/shared.py:2171` defines `operator_facing_stderr`, which returns `""` for empty input (`:2195-2196`) and drops lines matching the eight patterns at `:2197-2206`. AEF HEAD `web/blueprints/inception.py:817` is identical. AEF T-3539 (work-completed; AC at its line 109) added the explicit message for the empty-streams case at AEF `inception.py:754-762`, which the vendored copy does not have. T-3539 does not cover non-empty input filtered to nothing.
- **Effect on a consumer project:** an operator who hits a refusal composed only of filtered lines is told "Unknown error", so the real reason in the server log is not surfaced.
- **Suggested fix:** when the input was non-empty and the output is empty, return "the gate refused with a message written for agents; the reason is in the server log" instead of the "Unknown error" string.

### OBS-449 — Tier 0 passes a destructive command inside a script; approvals keyed to a hash of the command text
- **Status:** FIXED IN VENDORED (partial: force-push and ref deletion are now enforced at git pre-push; destructive operations inside a script are still not seen by Tier 0)
- **What is wrong:** Tier 0 matched the typed command text, so `bash push.sh` passed while the script force-pushed, and an approval keyed to the whole command hash was voided by a cosmetic retry.
- **Evidence (re-checked 2026-10-13):** Vendored `agents/context/check-tier0.sh:621` adds an "ACTION approval path" (T-3593) that maps a command to an action such as force-push, hard-reset or recursive-delete. The legacy whole-command sha256 remains for unmapped commands (`check-tier0.sh:68-79`, `:553`). The scope boundary is documented at `check-tier0.sh:1-30` and pinned by a characterization test. Vendored `agents/git/lib/hooks.sh:828-901` (T-3594) refuses an unapproved forced ref update or ref deletion at pre-push, whichever way the push is launched. I did not run a push to watch that refusal, because it would write; the pre-push result is read from code, and I did not check whether the hook is installed in 832's `.git/hooks`. AEF HEAD `1146a745` (`.git/refs/heads/bleeding-edge`) has the same code. AEF tasks: T-3576 (inception, work-completed, GO 2026-09-30); T-3593 (build A, started-work, independent review box at line 123 still unchecked); T-3594 (build B, started-work); T-2742 (scope boundary documented, completed).
- **Effect on a consumer project:** On 832, an agent-written script that runs `rm -rf` still executes with no Tier 0 check, while an unapproved force-push through a script is now refused at pre-push.

### OBS-452 — handover.sh emits a complete-looking handover with no session content
- **Status:** STILL TRUE
- **What is wrong:** The generator writes literal `None` under Decisions, Failures and Open Questions, and `**Blockers:** None`, with no `[TODO]` marker. Empty and complete handovers look the same, and "Where We Are" is built from commit subjects.
- **Evidence (re-checked 2026-10-13):** Vendored `agents/handover/handover.sh:1262-1265` (`**Blockers:** None`, `**Next step:** See task file`, comment "119/119"); `:1623-1634` (bare `None` under three headings); `:819` ("Build 'Where We Are' from recent commits"). Reproduction: `/opt/832-Workflow-designer/.context/handovers/S-2026-1013-1728.md` lines 279, 283 and 287 are bare `None`; a grep of that file for `[TODO]` or `AUTO-MINED` finds nothing. AEF HEAD `agents/handover/handover.sh:813, 819, 1448, 1452, 1456` shows the same structure. AEF tasks: none found that covers the `None` placeholders or `[TODO]` emission. The nearest are T-393 (TODO rot, completed) and T-291, which I did not read in full, so I do not claim they cover this.
- **Effect on a consumer project:** On 832, `/resume` does not warn about an empty handover, so a session's state can go missing without any signal.
- **Suggested fix:** Emit `[TODO]` instead of `None` for narrative, decisions, failures and blockers, and mark a commit-derived "Where We Are" as `[AUTO-MINED - VERIFY]`.

### OBS-453 — fw task update cannot set related_tasks or unlocks_inception_decision
- **Status:** STILL TRUE
- **What is wrong:** `fw task update` has no flag that writes `related_tasks:` or `unlocks_inception_decision:`, so the GO-scope audit can only be satisfied by hand edits or one-off scripts.
- **Evidence (re-checked 2026-10-13):** Vendored `agents/task-create/update-task.sh:2081-2181` lists the parsed flags (`--tags`, `--add-tag`, `--horizon`, `--happiness`, the `--skip-*` family, `--i-am-human`, `--scope-reduction-acknowledged`); a grep for `--related`, `--unlocks` and `unlocks_inception` in the file finds nothing. AEF HEAD `agents/task-create/update-task.sh` has the same result. AEF tasks: no task found for a related or unlocks setter. T-1984 (active, GO-scope traceability) is about the schema and close gate and adds no setter.
- **Effect on a consumer project:** On 832, the audit's GO-scope check flags inceptions whose build tasks cannot be linked through the CLI, so the field stays empty while the work is done.
- **Suggested fix:** `fw task update T-XXX --related T-YYY[,T-ZZZ] --unlocks T-AAA`, appending rather than replacing, and refusing ids that do not resolve.

### OBS-454 — severe and deterministic reviewer static-scan findings do not block work-completed
- **Status:** STILL TRUE
- **What is wrong:** The static scan computes a FAIL verdict on severe findings but the close path treats it as advisory. Whether it should block is an operator (sovereignty) ruling; no AEF task proposes blocking.
- **Evidence (re-checked 2026-10-13):** Vendored `lib/reviewer/static_scan.py:2681-2691` (`compute_overall` returns FAIL when a severe finding is present). Vendored `agents/task-create/update-task.sh:2746-2753` prints "Reviewer static-scan (T-1443 v1.0, non-blocking)..." and runs the scan with `|| true`. AEF HEAD `update-task.sh:2321-2328` is the same. AEF tasks: no active task proposes blocking on severe findings; the `.tasks/active` matches for "static-scan" are descriptive mentions only.
- **Effect on a consumer project:** On 832, a task with a severe, deterministic finding (for example a skip-as-pass in its Verification block) can close with the finding printed and ignored.
- **Suggested fix:** After the operator rules, block on severe AND deterministic findings only, with the same logged `--force` the other gates use.

### OBS-458 — episodic generator ignores decisions.yaml and concludes "no decisions to record"
- **Status:** STILL TRUE
- **What is wrong:** `has_decisions` is derived only from the task file's Decisions section (via `extract_decisions.py "$task_file"`). The generator never reads `.context/project/decisions.yaml`, so a decision recorded through the register is missing from the episodic.
- **Evidence (re-checked 2026-10-13):** Vendored `agents/context/lib/episodic.sh:145-150` (`has_decisions` from the task file only) and `:237` ("Mechanical task — AC checked, no decisions to record"). AEF HEAD `agents/context/lib/episodic.sh:146-149` and `:237` are identical. Reproduction: `/opt/832-Workflow-designer/.context/episodic/T-925.yaml:13` says "Mechanical task -- AC checked, no decisions to record", and its line 18 explains that the generator reads only the task file. `.context/project/decisions.yaml:2605-2609` holds T-925's ruling (PD-351). AEF tasks: none found that joins episodics to decisions.yaml. T-3015 covers parsing the task file's decisions block, and T-4168 covers worktree episodic loss; neither is this.
- **Effect on a consumer project:** On 832, a decision recorded through `fw inception decide` never appears in its task's episodic memory, and T-925 needed a hand correction.
- **Suggested fix:** Join on decisions.yaml by task id, and where the register has an entry the task file lacks, say so rather than concluding absence.

### OBS-462 — no audit rail for a child task closing another task's IW or unpriced item
- **Status:** STILL TRUE
- **What is wrong:** The audit checks only the parent-to-child direction (GO recorded, but no related_tasks, back-reference or unlocks). Nothing requires a child that closes another task's IW or unpriced item to leave a back-reference, so the parent document stays stale.
- **Evidence (re-checked 2026-10-13):** Vendored `agents/audit/audit.sh:2200-2226` (the GO-scope-not-propagated detector, forward-only). AEF HEAD `agents/audit/audit.sh:2202-2223` has the same wording and no child-to-parent check. AEF tasks: none found for a child-to-parent back-reference rail.
- **Effect on a consumer project:** On 832, T-309 still reads a superseded blocker (IW-2 and IW-3 were closed in T-955 and T-956 without writing back), so the next slice could be mis-sequenced.
- **Suggested fix:** Require a back-reference when a task closes an IW or unpriced item owned by another task.

### OBS-466 — reviewer destructive-action scanner matches prose and comments in Verification and AC text
- **Status:** STILL TRUE
- **What is wrong:** The layer-1 destructive-action trigger is a bare regex over the raw Verification and AC text. Prose, backticked quotes and comments are not stripped or exempted, so describing `rm -rf` escalates a task the same as running it.
- **Evidence (re-checked 2026-10-13):** Vendored `policy/escalation-patterns.yaml:31-44` (the `verification_text` regex at line 40 matches `rm -[rfRF]`, `git push --force`, `reset --hard`; the `ac_text` at line 43 matches force-push and hard-reset unconditionally). `lib/reviewer/static_scan.py:2710-2720` runs `re.finditer` over the raw section, and `:2765` passes `extract_section(body, "Verification")` without stripping comments. AEF HEAD has the same regex at `policy/escalation-patterns.yaml:40` and the same code at `lib/reviewer/static_scan.py:2765`. AEF T-3642 (completed) added `exclude_pattern` only for the destroy/wipe/purge clause and states that "rm -rf/DROP TABLE/force-push/hard-reset stay unconditional" (its description, lines 15-16). No AEF task covers comment or prose exemption. Labels collide when filing: AEF's T-3700 uses "OBS-466" for an unrelated item. Same family, different gate: during this check, read-only Bash commands containing the literal word for the Tier 0 gate were refused by `check-tier0.sh`'s self-approval rule, which matches command text rather than action.
- **Effect on a consumer project:** On 832, a Verification comment that explains a cleanup step escalates the task to Needs Human, which pushes authors to write vague descriptions of destructive operations.
- **Suggested fix:** Scan only non-comment Verification lines for executable commands, and treat prose and backticked quotations as description.
