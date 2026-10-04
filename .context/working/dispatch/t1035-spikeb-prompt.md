# T-1035 Spike B — behavioural verdicts for 13 hook-fix teeth (worker brief)

You are a worker for project /opt/832-Workflow-designer, task T-1035 (an INCEPTION). Run `fw work-on T-1035` in your own focus file first if your environment requires a focused task.

## Hard limits
- Do NOT commit anything. The inception has used 1 of its 2 exploration commits; the parent commits.
- Do NOT edit any source or framework file. Write ONLY to:
  - `docs/reports/T-1035-hook-fix-census.md`, replacing the `(pending)` line under `### Spike B`;
  - scratch files under `/tmp/t1035-spikeb/`.
- Do NOT run `runme.sh` or `fw inception decide`, and use no `--force`.
- Hermetic: if a run modifies anything under `.context/`, restore it with `git checkout -- <path>` and say so in the report.
- Never print secrets.

## Context
T-1013 ran 13 never-wired "teeth" scripts for 832's framework-hook fixes on today's vendored framework (1.7.740, under `.agentic-framework/`). 9 fail and 4 report COULD-NOT-MEASURE. Spike A (already in the report: read `docs/reports/T-1035-hook-fix-census.md` first) records each fix's framework commit, what the earlier T-1020 census said about it, and its divergence-register status.

The 13 tools are in `tools/`:
- `_t628-g020-remedy-reachable.sh`
- `_t629-g067-remedy-reachable.sh`
- `_t631-tier0-approval-reachable.sh`
- `_t632-read-only-misclassification.sh`
- `_t633-shared-tmp-sinks.sh`
- `_t634-guard-verdict-reaches-caller.sh`
- `_t636-prose-verbs-vetoed-by-their-own-text.sh`
- `_t637-inception-coverage.sh`
- `_t638-commit-exemption-is-clause-scoped.sh`
- `_t639-drift-gate-reads-fixtures.sh`
- `_t650-an-alias-is-the-command-it-aliases.sh`
- `_t654-watchdog-detections-must-be-surfaced.sh`
- `_t662-null-focus-commit-path-must-be-discoverable.sh`

## For each tool, in order
1. State in ONE sentence the BEHAVIOUR it protects, and how the original fix delivered it.
   - Sources: the tool's header, the task file `.tasks/*/T-6NN-*.md` (Context, ACs, Decisions).
   - Where Spike A lists a framework commit, also read `git show <hash> --stat` and skim the diff.
2. Run the tool once (`timeout 300`, output to `/tmp/t1035-spikeb/`). Note which legs fail and why.
3. Test the BEHAVIOUR directly on today's tree, independently of the tooth's mutation mechanics. For example:
   - feed the real gate a payload: `echo '<json>' | .agentic-framework/agents/context/check-active-task.sh` with a suitable env;
   - `source .agentic-framework/agents/context/lib/safe-commands.sh`, then call `is_bash_safe_command` / `has_bash_write_pattern`;
   - check that the remedy a block message names actually works.
4. Give exactly one verdict:
   - **ADOPTED:** the behaviour holds today. Say whether by upstream code or by an 832 re-apply.
   - **LOST:** the behaviour is broken today. Give the failing command and its output.
   - **OBSOLETE:** the subject no longer exists, or the tooth is superseded by a named newer probe that passes. Give its name and result. Note that `tools/_t1005-drift-target-clause-scoped.py` states it replaces `_t639`.
   - **UNDECIDED:** only if honestly so, with what would decide it.

   For each LOST, also classify it as **safety** (an unguarded write or bypass) or **usability** (over-blocking, or a remedy that can't be reached).

## Output
Under `### Spike B` in the report:
- a table: fix | behaviour | today's check + result | verdict | safety/usability;
- then 3 to 6 lines of summary: counts per verdict, the answer to IW-1 (per-fix status), and the answer to IW-3 (are `_t632`, `_t638`, `_t639` and `_t654` stale teeth, or is their subject gone?).

Finally, write a 10-line summary to `/tmp/t1035-spikeb/SUMMARY.md` and stop.
