# Bundle D: allowlisted reads that write (832 T-1005 → AEF T-3746, security)

**Verified against:** AEF `bleeding-edge` 914326e0 (2026-10-03, via the GitHub mirror), on 2026-10-04. Your `agents/context/lib/safe-commands.sh` there is byte-identical to 1.7.740.
**Apply:** `git am docs/upstream-pickups/D-t3746-allowlisted-writes/*.patch` (1 commit, applies cleanly, independent of A, B and C).
**Probe:** `bash tests/unit/test_t3746_allowlisted_writes.sh` → **21/21**. Your unpatched tree scores **10/21**.
**No regressions:** your 8 safe-commands bats suites (`context_safe_commands`, `drift_gate_not_shadowed_by_safelist`, `safe_commands_chain`, `safe_commands_env_prefix`, `t3096_safe_commands_wrappers`, `t3344_readonly_allowlist_gaps`, `t3425_sidecar_read_allowlist`, `t3536_judge_verbs_allowlist`) give the same result before and after the patch. One test fails on both sides: test 42 of `context_safe_commands`, "no unclassified git verb is used by our own tooling (T-2888)". It is not caused by this patch.

## The matrix (your requested regression fixture)

The fixture composes the gate exactly as `check-active-task.sh` does: a command is **allowed** if and only if `has_bash_write_pattern` says no **and** `is_bash_safe_command` says yes.

| Must be refused (writes) | Unpatched | Patched |
|---|---|---|
| `echo x > out.txt` (control) | refused | refused |
| `grep p f 2> err.log` | **allowed** | refused |
| `grep p f &> all.log` | refused | refused |
| `sed -n 'w out.txt' f`, `sed -n '/x/w out.txt' f` | **allowed** | refused |
| `sort -o out.txt f`, `sort --output=out.txt f` | **allowed** | refused |
| `awk '{print > "o.txt"}' f` | refused | refused |
| `awk '{print \| "sh"}' f`, `awk 'BEGIN{system("touch x")}'` | **allowed** | refused |
| `uniq in.txt out.txt` | **allowed** | refused |

| Must be allowed (reads) | Unpatched | Patched |
|---|---|---|
| `grep -n ">>" f`, `echo "a > b"`, `grep -c "x>y" f` | **refused** | allowed |
| `2>/dev/null`, `2>&1`, plain `sort`/`uniq`/`awk`/`sed -n p`/`cat` | allowed | allowed |

On the unpatched tree, 8 writes pass the no-task gate as reads, and 3 reads are refused because a quoted `>` reads as a redirect.

## What changed in `safe-commands.sh`

832 made five commits: 6fc8e737, c31857a3, 6c3cbd39, 27ba4c0e and b87b1409. They are squashed here into one diff against 1.7.740.
- **New write checks:** `2>` or `&>` to a file, sed's `w`, `sort -o` / `--output`, awk's in-program `print >`, `print |` and `system()`, and `uniq IN OUT`.
- **Redirects, `rm` and `tee` are judged on `_fw_strip_quoted`'s view** (your helper). The raw command is used only where stripping fails, for unbalanced quotes or substitutions.
- **`rm` or `tee` named inside framework prose verbs** (`fw note "…"`, `fw context add-*`) is data, not a write. `bash -c "rm -rf x"` stays a write.

## Not included, recorded

832's restored oracle `web/test_safe_commands.py` still has 30 failing tests against 1.7.740. They test function names you replaced (`_sc_is_commit_only_command`, `_sc_drift_target`), test fetchers your allowlist now refuses earlier (an equivalent gate), or concern usability (`| tac`, `curl --output-dir`). None of them is an unguarded write, and none is shipped here.
