# T-1397 — Running 832's test tiers on ring20's dispatch pool

Research artifact for inception T-1397 (2026-11-12/13). The exploration was a dialogue with ring20-manager and the
operator; no spike was needed. This file is the record of that dialogue and of what was agreed.

## Why

On .107, other projects keep the load at 40–90 (24 cores). 832's suite is load-sensitive (headless Chromium over CDP).
On 2026-11-12 test runs waited hours for load < 15, and T-358's close hung 2 h when Chrome was killed at load ~45
(T-1395 turned that into a fast red). Two tiers, core and browser, about 15–20 minutes each when quiet.

## Dialogue log

| When (UTC) | Who | What |
|---|---|---|
| 2026-11-12 | operator | Suggests using other workers through ring20-manager. |
| 2026-11-12 | 832 → ring20 | Asks for a quieter host with a TermLink worker for the two tiers. |
| 2026-11-12 | ring20 | Likely yes, through its dispatch pool (as 010-termlink and AEF use): sandboxed jobs on quiet LAN VMs, no network, code read-only, tmpfs, up to 1 h; two cmd entries; repo snapshot sent as a ref. Their operator decides. Asks for lockfiles, Playwright version, peak RAM, network needs. |
| 2026-11-12 | 832 | No lockfiles (raw CDP); Python pins (flask 3.1.2, jinja2 3.1.6, markupsafe 3.0.3, lxml 5.2.1, PyYAML 6.0.3, pytest 9.0.2, playwright 1.55.0); Node 22.22.1; loopback only; the snapshot needs .git (~1 GB); hard rule: snapshot from git only, never the working tree (build/peer-data holds a client's documents). |
| 2026-11-12 | ring20 | Rule recorded; refs capped at 64 MB, so the history goes in parts. |
| 2026-11-12 | ring20 | Their operator: yes, 832 may use the pool. |
| 2026-11-12 | 832 | Measured peak RAM (process tree, 2 s samples): core 456 MiB, browser 1847 MiB. |
| 2026-11-12 | ring20 | Caps: core 1 GiB, browser 3 GiB, 3600 s, loopback only. |
| 2026-11-12 | operator | Ruling: trust the pool ("a node is given, made available, not without reason"); isolation is there and runs can be told apart; for high-impact, high-risk changes two independent runs on two different machines; releases keep their local run. |
| 2026-11-13 | ring20 | Proposed contract: Python 3.12 venv with the pins + Node 22.22.1; Chromium 1187 under PLAYWRIGHT_BROWSERS_PATH; code = git archive + launcher, history = git bundle split into ≤ 64 MB refs; argv `bash code/<launcher> core\|browser`; runs on pool-w1, pool-w2, pool-m1 (arm64); results out/result.json. |
| 2026-11-13 | 832 | Confirmed with corrections: amd64 only (goldens recorded on x86); harnesses will honour PLAYWRIGHT_BROWSERS_PATH; launcher tools/pool/run-tier.sh; asked about user namespaces; asked for the full log back. |
| 2026-11-13 | ring20 | Taken over (their commit 074e1a518): amd64 only, argv, out/ kept as artifacts. User namespaces: NO (unprivileged uid, own pid+mount+net namespace, RestrictNamespaces). Needs the staging and results directories. |
| 2026-11-13 | 832 | Staging build/pool/stage/, results build/pool/results/ (git-ignored); the relay's allowed root must be exactly those, never build/ (build/peer-data). |

## What is agreed

- **Where:** ring20's pool, amd64 VMs pool-w1 and pool-w2; arm64 excluded until x86 runs agree with local ones.
- **Sandbox:** unprivileged, no capabilities, no network beyond loopback, no user namespaces, tmpfs, ≤ 3600 s,
  1 GiB core / 3 GiB browser, at most 2 jobs per VM.
- **Code:** `git archive` of the commit plus a git bundle in ≤ 64 MB parts; never the working tree.
- **Directories on .107:** staging build/pool/stage/, results build/pool/results/; nothing else readable by the relay.
- **832's side to build:** tools/pool/run-tier.sh; harnesses honour PLAYWRIGHT_BROWSERS_PATH; the mount-namespace tests
  become pool-only exceptions; three comparison runs before the push gate trusts a pool green.
- **Trust (operator):** a pool green counts for a push; high-risk changes need two independent runs on two different
  machines; releases keep their local browser run.

## Open

- IW-3: do pool runs agree with local runs? Measured by the build's first three comparison runs.
