# T-1445 — 832's answer to AEF T-4649 (project extension points)

AEF asked (sidecar msg f475ad73, 2026-11-19): (a) which of our local changes to vendored framework files the six proposed
extension points would let us remove, and which would remain; (b) what is missing or shaped wrong; (c) would an
operator-owned list work for CSRF exemptions. Source: `.agentic-framework/.vendor-divergence.yaml`, every entry,
classified by `docs/reports/T-1445-spikes/classify.py` (the class of each task id decided by reading its reason).

## Answer

**(a) The six points would retire 7 of our 60 entries (6 tighten-only gates, 1 project page). 44 remain, because they
are fixes to AEF's own behaviour: no extension point can carry a fix, only adoption upstream can.** The remaining 8
need extension points the proposal does not have (b). One entry is the manifest itself.

What retires, if the shapes fit:
- (6) tighten-only gates, 6 entries: our T-866 GO-hypothesis gate (task-audit.sh, inception.sh, inception-readiness.sh),
  the T-843 verification-absence detector, the T-936 bare-import detector, and the T-659 pre-commit guard on audit
  deletions. Condition: (6) must let a project add a check that **a framework verb runs** (`fw inception decide`,
  P-011 at `work-completed`, a git hook), not only a regex on a Bash command. Our gates are functions those verbs call.
- (1) project page, 1 entry: `/designer/open` (T-1172/T-1175).

What remains as fixes (44): the full list is below. The biggest groups: the P-011 verification runner
(update-task.sh: T-391/T-394/T-522, T-561, T-574, T-654, T-658), the task generator (create-task.sh: T-660, T-767,
T-774-T-776, partly adopted by your render_task.py at be.60), the Bash read-only classifier (safe-commands.sh: T-390,
T-404, T-405, T-650, T-1047), focus-drift (check-active-task.sh: T-386, T-662, T-1023), and Watchtower (app.py T-544/T-545,
fabric.py T-568, shared.py T-569, bvp.py T-547, tasks.py T-606, approvals.html T-772). Many are marked GENERIC in our
manifest: AEF's own Watchtower has the same defect. Adopting them upstream retires more of our divergence than any
extension point.

**(b) Missing or shaped wrong:**
1. **Project verbs** (4 entries): `fw external` (T-887, a new verb plus one dispatch case in bin/fw), and two
   subcommands added to `fw note` (promote T-912, resolve T-914). A supported way for a project to add a verb or a
   subcommand (dispatching to a project script) would retire all four.
2. **Project libraries the framework loads** (2 entries): `lib/instance-position.sh` (T-880/T-883) and
   `lib/task-ownership.sh` (T-931) live in the vendored tree only because framework code sources them from there.
   A project lib path the framework searches would retire both.
3. **Additions to an existing AEF page** (2 entries): thumbnails on the /designer landing page and blueprint
   (T-1048, T-1171). (1) offers new pages only; an extension slot in an AEF page (a template block a project fills)
   would cover it.
4. (6) as stated above: tighten-only checks must be callable from verbs, not only command patterns.
5. Declining (5), project text in the reviewer brief: we agree, the reviewed party must not steer its reviewer.

**(c) CSRF list:** 832 has no CSRF exemption today, so we cannot report practice. In principle yes: a committed list
the operator owns, shown by `fw audit`, is the right shape. Our only request: each entry names the test that proves the
endpoint's own authentication, so the list cannot hold an exemption nothing checks.

## Every entry

Entries classified: 60 of 60 (paths: 44)

### Fix to AEF behaviour: belongs upstream, no extension point can carry it — 44

- T-557 `agents/observe/observe.sh` — T-1005 (1.7.740): upstream now refuses the payload-losing calls itself (better than ours: it names the discard
- T-1005 `agents/termlink/bvp-estimator/estimator.py` — T-1005 re-apply on 1.7.740, per-fix outcome. T-541 (three product-driver handlers, 788a5103) SUPERSEDED in pro
- T-1009 `lib/delegation_cli.py` — T-931 (0a00d59d, operator ruling 2026-09-29): `fw task delegate` flips owner human -> agent when no Human crit
- T-908, T-1025 `agents/fabric/lib/traverse.sh` — T-908 (547fb9eb) re-applied by T-1025 after the 1.7.740 re-vendor erased it silently (never declared; found by
- T-1036 `lib/ts/dist/loop-detect.js` — loop-detect was dead in every live session. Claude Code gives PostToolUse hooks a unix SOCKET as stdin; readFi
- T-1047 `agents/context/lib/safe-commands.sh` — The /resume skill's step 7 (AEF T-3327) runs scripts/session-start-alerts.sh at session start, before any task
- T-650, T-1037 `agents/context/lib/safe-commands.sh` — T-650 (3032e3e2) re-applied by T-1037 after the T-1035 census found it lost on 1.7.740 (T-1005 had restored on
- T-1005 `lib/arc.sh` — T-1005 re-apply on 1.7.740. T-467 (78cf7d75) ADOPTED: upstream T-2955 makes `fw arc tag` write the canonical a
- T-1005 `lib/bvp.sh` — T-1005 re-apply on 1.7.740. T-542 (help line for `fw bvp estimate-cost`) SUPERSEDED: upstream usage lists the 
- T-544 `web/app.py` — GENERIC upstream debt — AEF's own Watchtower carries this bug identically and is in fact one of the two collid
- T-545 `web/app.py` — GENERIC upstream debt — same file, second defect, and AEF's Watchtower has it too. The 403 handler chose its b
- T-1005 `agents/audit/audit.sh` — Consolidated by T-1005 after the AEF 1.7.740 re-vendor; the six per-task entries this replaced are in git hist
- T-849 `agents/context/checkpoint.sh` — T-1005 re-apply on 1.7.740. What remains local is ONE block in the `budget` safe reader: a level without a cre
- T-674 `agents/audit/completed-task-scan.py` — CTL-012 matched `- [ ]` on raw lines, so an AC that had been COMMENTED OUT still counted as outstanding. The w
- T-404, T-405, T-390 `agents/context/lib/safe-commands.sh` — The Bash gate mis-classified read-only commands as writes (quote-aware redirect predicate), base-command extra
- T-404, T-405 `web/test_safe_commands.py` — Tests for the above.
- T-1005, T-1023 `agents/context/check-active-task.sh` — Focus-drift target extraction (_fw_extract_drift_target), re-applied/repaired on 1.7.740. T-639 (clause-scoped
- T-386 `agents/context/check-active-task.sh` — The focus-drift gate recommended a command it then refused.
- T-391, T-394, T-522 `agents/task-create/update-task.sh` — P-011 refused multi-line verification constructs — diagnosed from AEF's OBS-201. T-394 states the guard bounda
- T-524 `agents/fabric/lib/drift.sh` — `do_validate()` was a stub that printed "Deep validation not yet implemented" for every card and then `return 
- T-862 `agents/handover/handover.sh` — T-1005 re-apply on 1.7.740, two local changes remain. T-862: the Suggested First Action is the one authored se
- T-547 `web/blueprints/bvp.py` — GENERIC upstream debt — AEF's own Watchtower serves these routes. Two endpoints take an operator's policy-deci
- T-561 `agents/task-create/update-task.sh` — GENERIC upstream debt — this crashes every inception completion in any project, AEF's own included. The `incep
- T-568 `web/blueprints/fabric.py` — GENERIC — every consumer project ships this file and every one of them has this bug. _load_components() cached
- T-569 `web/shared.py` — GENERIC — render_markdown_safe's ImportError branch returned the RAW text. Its own docstring three lines above
- T-569 `web/templates/fabric_detail.html` — GENERIC — companion to the fabric.py/shared.py entries. Line 35 rendered `<p>{{ component.purpose }}</p>` unde
- T-574 `agents/task-create/update-task.sh` — GENERIC — the P-011 completion gate could report success on a task whose every verification leg was UNRUN, and
- T-606 `web/blueprints/tasks.py` — /approvals rendered 205 escaped `&lt;code&gt;` sequences to the operator for as long
- T-654 `agents/task-create/update-task.sh` — A task archived through the PARTIAL-COMPLETE RECHECK branch reached
- T-656 `agents/audit/active-task-scan.py` — Each D2 review-queue entry now carries `unticked`: how many acceptance criteria are
- T-643, T-645, T-739 `bin/fw` — Three defects on one file. (3, T-739) DECISION_RE at the DECISIONS predicate listed DEFER alongside GO and NO-
- T-648 `web/conftest.py` — Adds the shared `document_shell` fixture. It lives in conftest rather than test_app.py because test_costs.py i
- T-645, T-648 `web/test_app.py` — The fragment tests asserted `"<!DOCTYPE" not in html` — a CHARACTER SCAN standing in for a STRUCTURAL property
- T-648 `web/test_costs.py` — Third call site of the same substring scan described under test_app.py, converted to the shared `document_shel
- T-658 `agents/task-create/update-task.sh` — The P-011 verification runner rendered every non-zero exit as `FAIL: <cmd> (exit N)`. A command that RAN and r
- T-660 `agents/task-create/create-task.sh` — Substituted the task id in exactly two places — `id: T-XXX` in the frontmatter and the H1 heading — and nowher
- T-662, T-1038 `agents/context/check-active-task.sh` — T-662 (72588583) re-applied by T-1038 after the T-1035 census found its advisory gone from the 1.7.740 hook (t
- T-772 `web/templates/approvals.html` — GENERIC upstream debt — the 10s htmx poll silently reverts the operator's own disclosure choice, so a feature 
- T-774 `agents/task-create/create-task.sh` — GENERIC upstream debt — the task generator corrupts tasks whose NAME contains one of its own frontmatter keys,
- T-775 `agents/task-create/create-task.sh` — GENERIC upstream debt — the generator emits frontmatter that YAML refuses to parse when a name or description 
- T-776 `agents/task-create/create-task.sh` — GENERIC upstream debt — the generator rewrote the operator's own task NAME when that name contained the id pla
- T-996 `lib/inception.sh` — `fw inception decide` refused the HUMAN at the moment of deciding with "Task review required before decision" 
- T-943, T-1005 `lib/verification-port.sh` — extract_verification_block returns 3 when a heading-shaped line names Verification but none is exactly '## Ver
- T-516, T-1005 `agents/context/lib/extract_decisions.py` — Upstream's extractor (T-3015) terminates a value at an unknown bolded label, but its label regex was \w+, so a

### (6) tighten-only gate pattern — 6

- T-866, T-1026 `lib/task-audit.sh` — audit_inception_hypothesis (T-866 4b6693d9 + research exemption 02bd9201): a GO requires a ## Hypothesis whose
- T-866, T-1026 `lib/inception.sh` — The GO path of fw inception decide calls audit_inception_hypothesis and fails CLOSED if the function did not l
- T-659 `agents/git/lib/hooks.sh` — Adds a pre-commit guard refusing staged DELETIONS under .context/audits/cron/ when running under agent control
- T-936, T-1005, T-1009 `agents/context/check-bare-import.sh` — Detector added by T-936. Undeclared, so deleted silently by the 1.7.740 re-vendor; restored. T-1009 (2026-10-0
- T-843, T-1005 `lib/verification-absence.sh` — Absence-assertion detector for P-011 Verification blocks (T-843). Undeclared, deleted by the 1.7.740 re-vendor
- T-1123 `lib/inception-readiness.sh` — Companion to OUR T-866 hypothesis gate (lib/task-audit.sh, lib/inception.sh entries above; not upstream, propo

### (1) project Watchtower page — 1

- T-1172, T-1175 `web/templates/designer_open.html` — The inline page for /designer/open (T-1172): Watchtower's base layout, a bar (back to the maps, title, version

### MISSING: a project-defined fw verb or subcommand — 4

- T-887 `lib/external_consult.py` — NEW VERB, operator-directed 2026-09-27: `fw external` — consult differently-trained models for the strongest o
- T-887 `bin/fw` — One dispatch case for the `external` verb, in the same shape as its `peer` and `sidecar` siblings (single exec
- T-912, T-1027 `agents/observe/observe.sh` — do_promote (T-912, 33964b83) ported onto 1.7.740 by T-1027 after the re-vendor erased it silently (found by th
- T-914, T-1028 `agents/observe/observe.sh` — `fw note resolve OBS-N --carrier <T-NNN|path> [--reason]` (T-914, d1dfb3ea) re-applied by T-1028 after the 1.7

### MISSING: a project library the framework loads (hooks/gates call it) — 2

- T-880, T-883, T-1005, T-1168, T-1185 `lib/instance-position.sh` — Instance-node position library (T-880) and its refusal audit (T-883). Undeclared, deleted by the 1.7.740 re-ve
- T-931, T-1005 `lib/task-ownership.sh` — Ownership reverts through the R-033 gate (T-931). Undeclared, deleted by the 1.7.740 re-vendor; restored.

### MISSING: a project addition to an existing AEF page (not a new page) — 2

- T-1048, T-1172 `web/blueprints/designer.py` — Operator request: preview thumbnails on the /designer corpus page. Each project gains `thumb_url` (/api/thumb?
- T-1048, T-1171 `web/templates/designer_landing.html` — The card shows a 120px preview tile above its title, or a dashed "no preview" box. It is a plain <img>, delibe

### The manifest itself — 1

- T-517 `.vendor-divergence.yaml` — This file. It lives inside the tree it measures, so it is itself divergence and declares itself rather than be

