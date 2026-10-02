# audit.sh: classification of the 24 local commits against upstream AEF 1.7.740

Upstream file: .agentic-framework/agents/audit/audit.sh (8494 lines). Line numbers below are in the current upstream file unless prefixed with a sha.

Counts: SUPERSEDED 5 | PROJECT-RAIL 9 | FRAMEWORK-FIX 10 | UNCLEAR 0

| sha | task | what it did | class | evidence |
|---|---|---|---|---|
| 8892b93d | T-371 | C-002 check split into three cases (hook absent / present without the gate / present with it) so a missing hook is not reported as "missing research artifact check" | FRAMEWORK-FIX (minor) | upstream 5605-5611 still uses one `grep -q` with a single else branch, so the wording still names the wrong defect. Mitigation: 4919-4925 separately warns "No commit-msg hook", so the absence itself is detected |
| 3501d924 | T-345 | first fabric block: PROJECT_ROOT join, recursive glob, isfile guard, warn instead of pass on unregistered>0 | SUPERSEDED | T-2735 removed unregistered counting from the first block (2525-2531, output now `registered orphaned`, 2556). Counting is in the drift block through expand_patterns.py (2645-2655), which warns at 2685-2688 |
| fdf7c98a | T-344 | count the watched denominator in both fabric blocks; warn when the watch set expands to 0 files | SUPERSEDED | T-2737: `drift_watched` (2670-2675), pass_over with the zero-population message that names 832 (2689-2694), warn "matches 0 files while N card(s) exist" (2699-2708), plus carded-unwatched (2660-2712) |
| 8ad25c5a | T-374 | audit honours `exclude:` by going through expand_patterns.py; reports when the expander is unavailable | SUPERSEDED | T-2735 delegates to expand_patterns.py (2637-2654). An expander failure gives FAIL "coverage expander failed — UNMEASURED" (2676-2684) |
| 8d4077fa | T-382 | (a) check_release_lag runs tools/_t382-release-lag.py; (b) check_gap_triggers: watching gaps with no or unread decision_trigger | PROJECT-RAIL (half (b) is FRAMEWORK-FIX) | (a) depends on the 832 tool. (b) is generic: upstream 5317-5380 only evaluates `trigger_check`, and audit.sh never mentions `decision_trigger`. Split it if re-applied |
| f409b939 | T-525 | fabric unregistered WARN gets coverage %, plus the card-count direction compared with the previous daily audit (CARD LOSS / flat / grew), with a FABRIC_HISTORY_DIR seam | FRAMEWORK-FIX (needs rework) | the target line no longer exists: upstream 2686-2688 warns with the raw count and no ratio or history, so "cards deleted" and "files added" still look the same. Has to be re-designed onto the drift block |
| d6bc292c | T-534 | D2: separate fail/warn detail lists. The >30d line listed tasks that were only >14d | FRAMEWORK-FIX | upstream 6569, 6575, 6578 still append both tiers to a single `d2_details`, which 6593 prints after the >30d count |
| 2cc7ff4b | T-535 | AUDITS_DIR env-overridable; the trend counter uses a normalised key (digits become N, ids such as CTL-028 kept) and shows the latest concrete line | FRAMEWORK-FIX | upstream 24 `AUDITS_DIR="$CONTEXT_DIR/audits"` is hard-coded; 8267-8274 still use `sort \| uniq -c` on raw strings, so readings with changing numbers never recur |
| e2317ea5 | T-651 | warn on zero-byte untracked files in the repo root (shell-redirect debris) | FRAMEWORK-FIX (generic hygiene, low value) | upstream audit.sh has no "stray" or zero-byte check. Could go to the project rail if not wanted upstream |
| 3653bdbb | T-654 | Check 1b reads working/episodic-gen/*.log for "NOT REACHED" aborts that were never recovered | SUPERSEDED (in effect) | an unrecovered abort means no episodic file, and upstream Check 1 (5104-5114) already warns per task with the same remedy (generate-episodic). The watchdog only adds the cause; the log is still written (update-task.sh:2079-2082) |
| 865604bf | T-656 | D2: separate "signed off, awaiting status flip" from "awaiting judgement"; remedy points at closing; needs an `unticked` field from active-task-scan.py | FRAMEWORK-FIX | active-task-scan.py:307-319 builds review_queue from age only; audit.sh 6582-6586 reads 3 fields only. Also needs the active-task-scan.py hunk |
| 2337b7bc | T-657 | vendor-divergence guard runs tools/_t517-vendor-divergence.py | PROJECT-RAIL | 832 tool + .vendor-divergence.yaml (superseded inside the project by fded6c5a) |
| 73f7c3fd | T-660 | Human AC actionability runs tools/_t660-human-ac-actionability.py | PROJECT-RAIL | 832 tool |
| a56bc0eb | T-677 | a partial (--section) run no longer overwrites a fuller same-day record; always writes `sections:`; trends count once per day; history line shows full vs partial | FRAMEWORK-FIX | upstream 8136-8139: a manual scoped run still writes `$AUDIT_DATE.yaml` over the day's full report; 8146 writes `sections:` only when scoped |
| 2d9fdd3d | T-833 | CTL-029 completable scan skips owner:human tasks that have an unticked Human AC | SUPERSEDED | T-3444, upstream 6416-6437 (identical logic: human_unticked, then `continue`) |
| a793374e | T-873 | warn while CLAUDE.md.bak exists (an fw upgrade governance rewrite not yet reviewed) and count the lost lines | FRAMEWORK-FIX | lib/upgrade.sh:1565-1592 still writes .bak and says "remove CLAUDE.md.bak to clear"; nothing in audit.sh reads it (grep finds no CLAUDE.md.bak) |
| b86a3468 | T-931 | stale `owner: human` with no open Human criterion, via tools/_t931-ownership.py | PROJECT-RAIL | 832 tool (the idea is generic; upstream has only CTL-025 ownership 6170-6176) |
| e297fc13 | T-934 | unit-suite check reports INFO/skip when no tests/unit corpus exists (vendored consumers) | FRAMEWORK-FIX | upstream 3529-3537 warns "Unit suite NOT CHECKED" whenever the report is absent; .agentic-framework/tests/unit does not exist here, so it warns in every consumer |
| e28c41d2 | T-936 | stray ImageMagick screen captures, via tools/_t936-stray-capture-scan.py | PROJECT-RAIL | 832 tool |
| 1f81963d | T-938 | check_secret_paths_visible_to_git: tracked secrets (through project tool tracked-secret-artifacts.py) + secret paths on disk that are not gitignored (.context/secrets, api-keys.enc, .fw-secret-key, ...) | FRAMEWORK-FIX (tool call goes to the project rail) | upstream secret-scan.sh:287-400 added a filename axis for TRACKED files, but api-keys.enc does not match it, and nothing checks for unignored on-disk secrets. The framework itself writes .context/secrets (web/secrets_store.py) |
| b8aa7012 | T-939 | secret in reachable git history, via the project tool's --history | PROJECT-RAIL (the idea is generic) | depends on tools/tracked-secret-artifacts.py; upstream secret-scan.sh has no history mode (scan-tree only, :460-469) |
| 534e212a | T-941 | designer route boundary inventory, via tools/_t682-boundary-inventory.py + gallery-serve.py | PROJECT-RAIL | 832 designer |
| fded6c5a | T-945 | vendor-divergence verdict with the stale/reverted signal split from unrecorded debt | PROJECT-RAIL | tools/_t517 + .vendor-divergence.yaml |
| c38e47ac | T-952 | bridge suite failure-floor ratchet, via tools/_t952 + tests/.run-history.tsv | PROJECT-RAIL | 832 bridge suite |

## Extension point
None. Every `source`/`.` in upstream audit.sh resolves under $FRAMEWORK_ROOT:
19-23, 2871, 2895, 3039/3057, 3893, 3923, 4049, 4242, 4271, 5649, 8483.
- No `.d/` directory is read (the `.d` hits are only /etc/cron.d at 32-34, 2947-3001).
- No PROJECT_ROOT script is sourced or run as a check.
- Nothing in agents/, lib/ or bin/ matches audit.d / audit-extensions / custom_checks / AUDIT_EXT.
- Sections are a fixed list (should_run_section, 645-648).
The only project-driven hook nearby is the cron registry (.context/cron-registry.yaml, 145, 2725). It can schedule a separate project script but cannot add lines to the audit report.
