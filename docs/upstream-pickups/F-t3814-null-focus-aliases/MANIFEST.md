# Bundle F: null-focus aliases and a block that says why (832 T-1037, T-1038 → AEF T-3814)

**You asked for these** on 2026-10-04 (sidecar @499), to fold into T-3814.
**Built on:** AEF **v1.8.0** (dcf619ab3). Both target files are byte-identical in v1.8.0 and 1.7.740.

**Apply:** `git am docs/upstream-pickups/F-t3814-null-focus-aliases/*.patch` (2 commits). **Apply bundle D first.**
- With D: both apply cleanly on a fresh clone of v1.8.0, and both probes pass, 16/16 and 9/9.
- Without D: they still apply cleanly, but the alias probe is 15/16. Its prose-argument leg needs D's `_sc_is_framework_prose_verb` (`fw git commit -m "drop the rm -rf call"` with no task).

| Patch | What | Probe | v1.8.0 → applied |
|---|---|---|---|
| 0001 | `safe-commands.sh`: with no task, `fw fix-learned` and `fw git commit` get the verdict of `fw context add-learning` and `git commit`. Only the real fw spellings count (`fw`, `bin/fw`, `.agentic-framework/bin/fw`, an absolute `…/.agentic-framework/bin/fw`); a planted `/tmp/x/bin/fw` is refused. Every commit-checkpoint guard still applies | `tests/unit/test_t1040_alias_is_its_target.sh` (+ `_t1040_mutation_assert.sh`) | 10/16 → 16/16 (with D) |
| 0002 | `check-active-task.sh`: a refused null-focus commit line names WHICH part voided the exemption (substitution, `--no-verify`/`-n`, a write, or the offending clause) and the way through. It prints only for commit lines. The WM-001..003 hint prints only where WM-* tasks exist | `tests/unit/test_t1040_null_focus_commit_discoverable.sh` | 4/9 → 9/9 (includes a mutation leg) |

**Your suites, before = after** (baseline: an independent clone at v1.8.0 + D):
- `check_active_task.bats`: 20 ok.
- `test_pretooluse_gates.bats`: 6 and 12 fail on both sides.
- `context_safe_commands.bats`: 42 fails on both sides, as bundle D recorded.
- `drift_gate_not_shadowed_by_safelist`, `safe_commands_chain`, `safe_commands_env_prefix`, `t3096_safe_commands_wrappers`, `t3344_readonly_allowlist_gaps`, `t3425_sidecar_read_allowlist`, `t3536_judge_verbs_allowlist`: all ok.

**Extra controls run in 832** on `is_commit_checkpoint_command`, all as intended:
- admitted: bare, `fw`, relative, absolute and `git add &&` forms;
- refused: `/tmp/x/bin/fw`, `/tmp/x/fw`, `bash -c`, `> out`, `-n`, `fw git push`, `fw git commitx`, `PATH=/tmp fw …`.
