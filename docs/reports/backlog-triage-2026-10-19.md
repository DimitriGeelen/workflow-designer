# Backlog triage, 2026-10-19

67 tasks at started-work. Columns: id, type, owner, last update, open/total Agent criteria, open Human criteria (template comments excluded).

## A. Every Agent criterion ticked, nothing open for anyone (close through the gate: Verification re-runs)

- T-357 inception agent 2026-09-29 agent-open=0/3 human-open=0
- T-723 build agent 2026-09-29 agent-open=0/3 human-open=0
- T-102 build agent 2026-09-29 agent-open=0/4 human-open=0
- T-041 build agent 2026-09-29 agent-open=0/6 human-open=0
- T-101 build agent 2026-09-29 agent-open=0/6 human-open=0
- T-105 build agent 2026-09-29 agent-open=0/6 human-open=0
- T-293 build agent 2026-09-29 agent-open=0/6 human-open=0
- T-286 build agent '2026-09-2 agent-open=0/6 human-open=0
- T-309 inception agent 2026-10-01 agent-open=0/3 human-open=0
- T-963 build agent 2026-10-01 agent-open=0/4 human-open=0
- T-964 build agent 2026-10-01 agent-open=0/5 human-open=0
- T-965 build agent 2026-10-01 agent-open=0/5 human-open=0
- T-966 build agent 2026-10-01 agent-open=0/5 human-open=0
- T-970 build agent 2026-10-01 agent-open=0/5 human-open=0
- T-967 build agent 2026-10-01 agent-open=0/6 human-open=0
- T-971 build agent 2026-10-01 agent-open=0/6 human-open=0
- T-972 build agent 2026-10-01 agent-open=0/7 human-open=0
- T-1008 build agent 2026-10-03 agent-open=0/8 human-open=0

## B. Every Agent criterion ticked, one Human box open (classify: reviewer-judgeable goes to fw reviewer judge, not to the operator)

- T-696 build human 2026-09-26 agent-open=0/5 human-open=1
- T-702 build human '2026-09-2 agent-open=0/2 human-open=1
- T-703 build human '2026-09-2 agent-open=0/2 human-open=1
- T-209 test human '2026-09-2 agent-open=0/3 human-open=1
- T-344 build human '2026-09-2 agent-open=0/4 human-open=1
- T-345 build human '2026-09-2 agent-open=0/4 human-open=1
- T-189 build human '2026-09-2 agent-open=0/5 human-open=1
- T-402 build human '2026-09-2 agent-open=0/6 human-open=1
- T-1212 build agent 2026-10-19 agent-open=0/6 human-open=1

## C1. Group C tasks already resolved or superseded (evidence, 2026-10-19)

Each still goes through the close gate (its own criteria ticked against this evidence; Verification re-runs).
- T-749 (T-708 completable, not closed): T-708 is completed.
- T-750 (T-723) and T-709 (T-041): both are in group A; they resolve when group A closes.
- T-741 (vendored tree omits tools/): `.agentic-framework/tools` now holds 52 files; fixed upstream.
- T-1000 (gate re-vendoring): `tools/_t1000-install-hook.sh --check` installed; used in the T-1204 and T-1208 upgrades.
- T-1003 (runme signals the agent): `tools/runme-signal.sh` and `tools/runme-watch.sh` built and used throughout.
- T-669 (uncontrolled absence assertions 78→90): `_t560` census PASS at baseline 74.
- T-944 (16 standing bridge failures): bridge suite 299 passed, 0 failed (2026-10-19).
- T-700 (unshipped change 23 days old): releases through 0.23.0 since; AEF pin CURRENT.
- T-840, T-988 (old framework upgrades), T-981 (sidecar check after a bleeding-edge upgrade): superseded by
  T-1188, T-1204, T-1208.

Still to read: T-758, T-897, T-874, T-922, T-811, T-575, T-784, T-979, T-969, T-968, T-989, and the October ones.

## C. Agent criteria still open (oldest first)

- T-758 refactor agent 2026-09-21 agent-open=4/4 human-open=0
- T-749 build agent 2026-09-24 agent-open=3/3 human-open=0
- T-750 build agent 2026-09-24 agent-open=3/3 human-open=0
- T-732 build human 2026-09-26 agent-open=3/7 human-open=2
- T-897 build agent 2026-09-27 agent-open=1/8 human-open=0
- T-874 design agent 2026-09-27 agent-open=2/2 human-open=0
- T-700 build agent 2026-09-29 agent-open=1/2 human-open=0
- T-922 build agent 2026-09-29 agent-open=1/7 human-open=0
- T-709 build agent 2026-09-29 agent-open=3/3 human-open=0
- T-669 build agent 2026-09-29 agent-open=3/6 human-open=0
- T-741 build agent '2026-09-2 agent-open=1/5 human-open=0
- T-811 inception agent '2026-09-2 agent-open=3/3 human-open=1
- T-575 build agent '2026-09-2 agent-open=3/6 human-open=0
- T-784 build agent '2026-09-2 agent-open=5/5 human-open=0
- T-840 build agent '2026-09-2 agent-open=7/7 human-open=0
- T-944 build agent 2026-09-30 agent-open=4/8 human-open=0
- T-981 test agent 2026-10-01 agent-open=1/4 human-open=0
- T-979 build agent 2026-10-01 agent-open=4/4 human-open=0
- T-969 build agent 2026-10-01 agent-open=5/5 human-open=0
- T-968 build agent 2026-10-01 agent-open=6/6 human-open=0
- T-1000 build agent 2026-10-02 agent-open=5/5 human-open=0
- T-988 build agent 2026-10-02 agent-open=5/5 human-open=0
- T-1003 build agent 2026-10-03 agent-open=5/5 human-open=0
- T-989 build agent 2026-10-03 agent-open=5/5 human-open=0
- T-358 build agent 2026-10-05 agent-open=2/6 human-open=1
- T-1065 build agent 2026-10-06 agent-open=1/2 human-open=0
- T-1064 build agent 2026-10-06 agent-open=1/3 human-open=0
- T-896 build agent 2026-10-06 agent-open=1/3 human-open=0
- T-1071 build agent 2026-10-06 agent-open=2/2 human-open=0
- T-1063 build agent 2026-10-06 agent-open=3/3 human-open=0
- T-1072 build agent 2026-10-06 agent-open=3/3 human-open=0
- T-1073 build agent 2026-10-06 agent-open=7/7 human-open=0
- T-1115 inception human 2026-10-10 agent-open=3/3 human-open=1
- T-347 build human 2026-10-10 agent-open=3/4 human-open=1
- T-1139 build agent 2026-10-12 agent-open=3/3 human-open=0
- T-1107 inception human 2026-10-12 agent-open=3/3 human-open=1
- T-1136 build agent 2026-10-12 agent-open=4/4 human-open=0
- T-1203 build agent 2026-10-18 agent-open=1/6 human-open=0
- T-737 build agent 2026-10-19 agent-open=3/3 human-open=0
- T-1208 build agent 2026-10-19 agent-open=3/5 human-open=0
