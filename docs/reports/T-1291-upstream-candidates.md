# T-1291 — 832's local framework patches: candidates to upstream to AEF

Generated 2026-10-24 from `.agentic-framework/.vendor-divergence.yaml` (60 entries). Every framework upgrade
re-applies these by hand (37 patches at be.3, be.5 and be.8; 5 needed hand merges at be.3). Each one upstreamed is
one fewer to carry. Order of work: the ones touching files AEF changes most often first (they conflict), then the
rest. **Nothing has been sent to AEF from this list yet.**

| # | Path | Kind | Task | Upstream | Reason (first 140 chars) |
|---|---|---|---|---|---|
| 1 | `lib/external_consult.py` | added | T-887 | fix | NEW VERB, operator-directed 2026-09-27: `fw external` — consult differently-trained models for the strongest objection. The UNCORRELATED cou |
| 2 | `bin/fw` | content | T-887 | fix | One dispatch case for the `external` verb, in the same shape as its `peer` and `sidecar` siblings (single exec into lib/, no logic in the sh |
| 3 | `agents/observe/observe.sh` | content | T-557 | fix | T-1005 (1.7.740): upstream now refuses the payload-losing calls itself (better than ours: it names the discarded words and the correct form) |
| 4 | `agents/termlink/bvp-estimator/estimator.py` | content | T-1005 | fix | T-1005 re-apply on 1.7.740, per-fix outcome. T-541 (three product-driver handlers, 788a5103) SUPERSEDED in project-owned policy: T-864 moved |
| 5 | `lib/delegation_cli.py` | content | T-1009 | fix | T-931 (0a00d59d, operator ruling 2026-09-29): `fw task delegate` flips owner human -> agent when no Human criterion is open, not only when t |
| 6 | `agents/fabric/lib/traverse.sh` | content | T-908, T-1025 | fix | T-908 (547fb9eb) re-applied by T-1025 after the 1.7.740 re-vendor erased it silently (never declared; found by the T-1020 census). 24 of 704 |
| 7 | `lib/task-audit.sh` | content | T-866, T-1026 | fix | audit_inception_hypothesis (T-866 4b6693d9 + research exemption 02bd9201): a GO requires a ## Hypothesis whose success clause names somethin |
| 8 | `lib/inception.sh` | content | T-866, T-1026 | fix | The GO path of fw inception decide calls audit_inception_hypothesis and fails CLOSED if the function did not load (a gate whose absence look |
| 9 | `agents/observe/observe.sh` | content | T-912, T-1027 | fix | do_promote (T-912, 33964b83) ported onto 1.7.740 by T-1027 after the re-vendor erased it silently (found by the T-1020 census). 1.7.740 wrot |
| 10 | `agents/observe/observe.sh` | content | T-914, T-1028 | fix | `fw note resolve OBS-N --carrier <T-NNN/path> [--reason]` (T-914, d1dfb3ea) re-applied by T-1028 after the 1.7.740 re-vendor erased it silen |
| 11 | `web/blueprints/designer.py` | content | T-1048, T-1172 | fix | Operator request: preview thumbnails on the /designer corpus page. Each project gains `thumb_url` (/api/thumb?id=&v=<latest>) only when <sto |
| 12 | `web/templates/designer_open.html` | added | T-1172, T-1175 | fix | The inline page for /designer/open (T-1172): Watchtower's base layout, a bar (back to the maps, title, version, "Open alone", fullscreen tog |
| 13 | `web/templates/designer_landing.html` | content | T-1048, T-1171 | fix | The card shows a 120px preview tile above its title, or a dashed "no preview" box. It is a plain <img>, deliberately not a link: the card's  |
| 14 | `lib/ts/dist/loop-detect.js` | content | T-1036 | fix | loop-detect was dead in every live session. Claude Code gives PostToolUse hooks a unix SOCKET as stdin; readFileSync('/dev/stdin') reopens / |
| 15 | `agents/context/lib/safe-commands.sh` | content | T-1047 | fix | The /resume skill's step 7 (AEF T-3327) runs scripts/session-start-alerts.sh at session start, before any task is focused, and the no-task g |
| 16 | `agents/context/lib/safe-commands.sh` | content | T-650, T-1037 | fix | T-650 (3032e3e2) re-applied by T-1037 after the T-1035 census found it lost on 1.7.740 (T-1005 had restored only its prose-verb half). With  |
| 17 | `lib/arc.sh` | content | T-1005 | fix | T-1005 re-apply on 1.7.740. T-467 (78cf7d75) ADOPTED: upstream T-2955 makes `fw arc tag` write the canonical arc_id: and refuse a different  |
| 18 | `lib/bvp.sh` | content | T-1005 | fix | T-1005 re-apply on 1.7.740. T-542 (help line for `fw bvp estimate-cost`) SUPERSEDED: upstream usage lists the verb. T-856 (48e03e08) PARTLY  |
| 19 | `web/app.py` | content | T-544 | fix | GENERIC upstream debt — AEF's own Watchtower carries this bug identically and is in fact one of the two colliding instances. app.py sets SES |
| 20 | `web/app.py` | content | T-545 | fix | GENERIC upstream debt — same file, second defect, and AEF's Watchtower has it too. The 403 handler chose its body by WHY the request failed  |
| 21 | `agents/audit/audit.sh` | content | T-1005 | fix | Consolidated by T-1005 after the AEF 1.7.740 re-vendor; the six per-task entries this replaced are in git history. Classification of all 24  |
| 22 | `agents/context/checkpoint.sh` | content | T-849 | fix | T-1005 re-apply on 1.7.740. What remains local is ONE block in the `budget` safe reader: a level without a credible token count is not a gau |
| 23 | `agents/audit/completed-task-scan.py` | content | T-674 | fix | CTL-012 matched `- [ ]` on raw lines, so an AC that had been COMMENTED OUT still counted as outstanding. The warn therefore fired on the hon |
| 24 | `agents/context/lib/safe-commands.sh` | content | T-404, T-405, T-390 | fix | The Bash gate mis-classified read-only commands as writes (quote-aware redirect predicate), base-command extraction judged only the first wo |
| 25 | `web/test_safe_commands.py` | added | T-404, T-405 | fix | Tests for the above. |
| 26 | `agents/context/check-active-task.sh` | content | T-1005, T-1023 | fix | Focus-drift target extraction (_fw_extract_drift_target), re-applied/repaired on 1.7.740. T-639 (clause-scoped: only a clause that IS a comm |
| 27 | `agents/context/check-active-task.sh` | content | T-386 | fix | The focus-drift gate recommended a command it then refused. |
| 28 | `agents/task-create/update-task.sh` | content | T-391, T-394, T-522 | fix | P-011 refused multi-line verification constructs — diagnosed from AEF's OBS-201. T-394 states the guard boundary in the code (bash -n catche |
| 29 | `agents/fabric/lib/drift.sh` | content | T-524 | fix | `do_validate()` was a stub that printed "Deep validation not yet implemented" for every card and then `return 0`. The banner was honest; the |
| 30 | `agents/handover/handover.sh` | content | T-862 | fix | T-1005 re-apply on 1.7.740, two local changes remain. T-862: the Suggested First Action is the one authored section, and it is carried forwa |
| 31 | `.vendor-divergence.yaml` | content | T-517 | local-config | This file. It lives inside the tree it measures, so it is itself divergence and declares itself rather than being special-cased out. Noticed |
| 32 | `web/blueprints/bvp.py` | content | T-547 | fix | GENERIC upstream debt — AEF's own Watchtower serves these routes. Two endpoints take an operator's policy-decision rationale from the browse |
| 33 | `agents/task-create/update-task.sh` | content | T-561 | fix | GENERIC upstream debt — this crashes every inception completion in any project, AEF's own included. The `inception_decisions` reachability g |
| 34 | `web/blueprints/fabric.py` | content | T-568 | fix | GENERIC — every consumer project ships this file and every one of them has this bug. _load_components() cached the parsed component cards un |
| 35 | `web/shared.py` | content | T-569 | fix | GENERIC — render_markdown_safe's ImportError branch returned the RAW text. Its own docstring three lines above says "Caller must mark return |
| 36 | `web/templates/fabric_detail.html` | content | T-569 | fix | GENERIC — companion to the fabric.py/shared.py entries. Line 35 rendered `<p>{{ component.purpose }}</p>` under Jinja autoescape, so a markd |
| 37 | `agents/task-create/update-task.sh` | content | T-574 | fix | GENERIC — the P-011 completion gate could report success on a task whose every verification leg was UNRUN, and printed nothing to say so. ru |
| 38 | `web/blueprints/tasks.py` | content | T-606 | fix | /approvals rendered 205 escaped `&lt;code&gt;` sequences to the operator for as long as that page had existed. `_render_markdown` and its AC |
| 39 | `agents/task-create/update-task.sh` | content | T-654 | fix | A task archived through the PARTIAL-COMPLETE RECHECK branch reached .tasks/completed/ still storing `horizon: now`. update-task.sh has two b |
| 40 | `agents/audit/active-task-scan.py` | content | T-656 | fix | Each D2 review-queue entry now carries `unticked`: how many acceptance criteria are still unchecked, with HTML comments stripped first. Prev |
| 41 | `bin/fw` | content | T-643, T-645, T-739 | fix | Three defects on one file. (3, T-739) DECISION_RE at the DECISIONS predicate listed DEFER alongside GO and NO-GO, and a MATCH is used as an  |
| 42 | `web/conftest.py` | content | T-648 | fix | Adds the shared `document_shell` fixture. It lives in conftest rather than test_app.py because test_costs.py importing from a sibling test m |
| 43 | `web/test_app.py` | content | T-645, T-648 | fix | The fragment tests asserted `"<!DOCTYPE" not in html` — a CHARACTER SCAN standing in for a STRUCTURAL property. HTML tag names are case-inse |
| 44 | `web/test_costs.py` | content | T-648 | fix | Third call site of the same substring scan described under test_app.py, converted to the shared `document_shell` fixture. Found by grepping  |
| 45 | `agents/task-create/update-task.sh` | content | T-658 | fix | The P-011 verification runner rendered every non-zero exit as `FAIL: <cmd> (exit N)`. A command that RAN and returned a verdict of "wrong" a |
| 46 | `agents/git/lib/hooks.sh` | content | T-659 | fix | Adds a pre-commit guard refusing staged DELETIONS under .context/audits/cron/ when running under agent control ($CLAUDECODE=1). A retention  |
| 47 | `agents/task-create/create-task.sh` | content | T-660 | fix | Substituted the task id in exactly two places — `id: T-XXX` in the frontmatter and the H1 heading — and nowhere else in the instantiated tem |
| 48 | `agents/context/check-active-task.sh` | content | T-662, T-1038 | fix | T-662 (72588583) re-applied by T-1038 after the T-1035 census found its advisory gone from the 1.7.740 hook (the old entry here described co |
| 49 | `web/templates/approvals.html` | content | T-772 | fix | GENERIC upstream debt — the 10s htmx poll silently reverts the operator's own disclosure choice, so a feature upstream deliberately shipped  |
| 50 | `agents/task-create/create-task.sh` | content | T-774 | fix | GENERIC upstream debt — the task generator corrupts tasks whose NAME contains one of its own frontmatter keys, and silently empties the fiel |
| 51 | `agents/task-create/create-task.sh` | content | T-775 | fix | GENERIC upstream debt — the generator emits frontmatter that YAML refuses to parse when a name or description contains a line break, and rep |
| 52 | `agents/task-create/create-task.sh` | content | T-776 | fix | GENERIC upstream debt — the generator rewrote the operator's own task NAME when that name contained the id placeholder token, on both templa |
| 53 | `lib/inception.sh` | content | T-996 | fix | `fw inception decide` refused the HUMAN at the moment of deciding with "Task review required before decision" (15 hits in 832 transcripts, 2 |
| 54 | `lib/verification-port.sh` | content | T-943, T-1005 | fix | extract_verification_block returns 3 when a heading-shaped line names Verification but none is exactly '## Verification' (glued to another l |
| 55 | `agents/context/check-bare-import.sh` | added | T-936, T-1005, T-1009 | fix | Detector added by T-936. Undeclared, so deleted silently by the 1.7.740 re-vendor; restored. T-1009 (2026-10-04): wiring checked -- NOT enab |
| 56 | `lib/instance-position.sh` | added | T-880, T-883, T-1005, T-1168, T-1185 | fix | Instance-node position library (T-880) and its refusal audit (T-883). Undeclared, deleted by the 1.7.740 re-vendor; restored. Callers in upd |
| 57 | `lib/task-ownership.sh` | added | T-931, T-1005 | fix | Ownership reverts through the R-033 gate (T-931). Undeclared, deleted by the 1.7.740 re-vendor; restored. |
| 58 | `lib/verification-absence.sh` | added | T-843, T-1005 | fix | Absence-assertion detector for P-011 Verification blocks (T-843). Undeclared, deleted by the 1.7.740 re-vendor; restored. Its call site in u |
| 59 | `agents/context/lib/extract_decisions.py` | content | T-516, T-1005 | fix | Upstream's extractor (T-3015) terminates a value at an unknown bolded label, but its label regex was \w+, so a multi-word label ("**Also rej |
| 60 | `lib/inception-readiness.sh` | content | T-1123 | fix | Companion to OUR T-866 hypothesis gate (lib/task-audit.sh, lib/inception.sh entries above; not upstream, proposed as bundle E patch 0010). i |
