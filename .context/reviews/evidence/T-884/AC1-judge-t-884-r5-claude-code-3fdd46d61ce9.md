# T-884 Human AC#1 — evidence (seat claude-code, dispatch judge-t-884-r5-claude-code-3fdd46d61ce9)

Revision reviewed: 7bee46bd12d06b8fe6d003a9488386e07ccb7734. Verdict: **amber** (criterion literal out of date).

## 1. The steps as written (default docroot, headless Chromium via Playwright, 1900x1100)

- `python3 tools/gallery-serve.py 8961 --bind 127.0.0.1` (docroot defaults to `build/gallery`); `/designer.html` 200, `/rendered/task-lifecycle.bpmn` 200.
- Opened `/designer.html?load=rendered/task-lifecycle.bpmn&instance=T-885`.
- Result: header picker reads **"instance not found: T-885"**; zero `g.node[data-instance]`; no `●` or `⛔` badge anywhere; no console error, no page error.
  Screenshot: `literal-T-885-judge-t-884-r5-claude-code-3fdd46d61ce9.png`.

## 2. The criterion's own "If not" branch

`python3 tools/instance-node.py snapshot task-lifecycle`: state INSTANCES, 171 examined, **T-885 not listed** at any node, and no T-885 refusal in `refusals` (3 rows: T-1212 P-010, T-286 R-033, T-1212 P-011). So "the corpus moved", for three separate reasons:

1. T-885 is completed: `.tasks/completed/T-885-*.md` has `status: work-completed`, `current_node: frw_end_task`, `owner: agent`. It is no longer a live instance.
2. `frw_6_run` no longer exists: T-1168 (commit a09c7e722) renamed node ids; `docs/reports/T-1168-node-id-map.md:360` maps `frw_6_run` -> `frw_3_run` (and the gateway `frw_9_human` -> `frw_gw_human`). The picker can never again read `T-885 · frw_6_run`.
3. T-885's one audit line (`.context/audits/instance-refusals.jsonl:2`, 2026-09-29, R-033 at `frw_9_human`) names the old node id and is not returned by the snapshot.

## 3. Is the overlay itself the defect? (equivalent live instance: T-286)

T-286 is live at `frw_3_run` ("Run completion gate battery"), owner human, with a real R-033 refusal at `frw_gw_human` (jsonl line 65, 2026-11-12) — the same situation the criterion describes for T-885.

**3a. Steps as written, `instance=T-286`, default docroot:** picker reads `T-286 · frw_3_run · started-work` but **nothing is drawn** (0 marked nodes, 0 badges). Cause: the default docroot `build/gallery/` is a gitignored build dated 2026-10-05 (designer v0.15.3) whose `rendered/task-lifecycle.bpmn` still carries the pre-T-1168 ids (`frw_6_run`, `frw_9_human`), while the snapshot now reports the new ids. Screenshot: `stale-build-T-286-judge-t-884-r5-claude-code-3fdd46d61ce9.png`.

**3b. Current source:** temp docroot outside the repo holding `src/aef-workflow-designer.html` (as `designer.html`, v0.43.0) and `examples/aef-processes/rendered/task-lifecycle.bpmn`, served by `tools/gallery-serve.py 8962 --docroot <tmp>`, same URL with `instance=T-286`:

- picker: `T-286 · frw_3_run · started-work`
- `data-instance="current"` on "Run completion gate battery", badge `● T-286`
- `data-instance="done"` on Task captured, Build-ready?, Start work, Perform the work, Outcome?, Request completion (green halo + tick)
- `data-instance="refused"` on "Human-owned with unchecked Human ACs?", badge `⛔ R-033`, red outline
- console: two 404 resource loads (assets absent from my minimal temp docroot), no script error.

Screenshots (read by me): `current-src-T-286-map-judge-t-884-r5-claude-code-3fdd46d61ce9.png` (whole map, 3000x1200), `current-src-T-286-current-judge-t-884-r5-claude-code-3fdd46d61ce9.png`, `current-src-T-286-refused-judge-t-884-r5-claude-code-3fdd46d61ce9.png`.

So the overlay in the current source does answer "where is it and why was it refused" from the picture alone. Note the badges are small at whole-map zoom; they are legible in the close-ups.

## 4. Conclusion

- As written: not reproducible (T-885 closed, `frw_6_run` renamed). Not green; not a defect in the overlay code either -> amber with a restatement.
- Separate thing needed: on this machine the documented steps serve the stale 2026-10-05 `build/gallery`, where even a live instance draws no overlay. The gallery must be rebuilt (or the steps must name a current docroot) before the restated criterion can be seen by following its steps.

Not done: I did not rebuild `build/gallery`, did not recreate a refusal, and touched nothing outside this evidence directory. Both servers were stopped.
