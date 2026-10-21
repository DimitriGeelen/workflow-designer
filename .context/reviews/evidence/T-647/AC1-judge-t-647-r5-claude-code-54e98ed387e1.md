# T-647 Human AC#1: is the manifest the right governance object? (reviewer claude-code, rung-5-panel)

Revision reviewed: 8647bc1bd4e1b6144944c20d14923953ddc44131

## What I checked
1. `sed -n '/^EXPECTED_NEWLY_BLOCKED=/,/^)/p' tools/_t640-fetchers-that-write-are-writes.sh` (at 8647bc1b and in the working tree): 19 entries.
2. Ran the suite with TMPDIR set to a fresh mktemp dir: `=== 18 passed, 0 failed ===`, rc=0. NO-WIDENING leg: "19 of 36 generated commands lost admission, and every one is on the reviewed list". So the manifest is current: nothing is stale and nothing is missing.
3. Went through each entry to judge whether it really writes a file.

## Per-entry judgement
| entry | writes a file? |
|---|---|
| curl -o F / --output F / --output=F | yes (F) |
| curl -O / -sO / --remote-name | yes (remote name in cwd) |
| curl --output-dir /tmp -O | yes (/tmp/x) |
| **curl --output-dir /tmp URL** | **NO.** Without -o/-O, --output-dir has no effect and the body goes to stdout |
| wget URL / -q / -nv | yes (./x) |
| wget -P /tmp | yes (/tmp/x) |
| wget -O F / --output-document F / =F | yes (F) |
| wget -O - -o log | yes (the log file) |
| wget -o log / -a log / --output-file=log | yes (the log file, plus the download) |

## Finding
18 of the 19 entries really write a file. One does not: `curl --output-dir /tmp https://example.com/x`. The manifest says so itself (T-1205 comment: "the one entry whose answer is NO ... upstream T-3222 blocks it by design (fail toward the task gate)"). T-1205 AC retired the reader leg for it and priced it here.

The governance object is sound. It is generated rather than hand-picked, it checks for exact equality in both directions, it has teeth (the revert mutant names the stdout forms), and it already caught its author once (`curl -sfo -`). But the AC's Expected says "every one of them a genuine file-writer", and that is not literally true. The `--output-dir`-only entry is a live over-block. It is documented and deliberate, but it is still an over-block. The AC's If-not clause says to name it, which I do here.

Severity is low. It is an odd spelling (a directory option without a write flag), and blocking it only sends you to the task gate.
