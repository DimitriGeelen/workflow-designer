# Pick up here (usage limit, 2026-10-21)

**Do NOT push yet.** The full bridge run on the scrubbed tree (after job 065, f10e8355) is 298/10, against 308/0
before. Output: session scratchpad bridge24.txt (gone with the session; re-run). Failing legs and likely causes:
1. _t1066 [REVIEW] criterion without **Why you:** — probably T-1242 or T-1209/T-1241 new criteria.
2. T-949 triage — T-281 GO now flagged (add a verdict to docs/reports/T-949-go-scope-triage.md; T-1241 builds it).
3/5. episodic readable / commit message vs episodic — the scrub rewrote .context/episodic/*.yaml timelines that
   quote commit subjects containing LAN addresses, so they no longer match git; fix the checker to compare after
   scrubbing, or exempt; decide.
4. T-568 card edit reaches live dashboard — probably Watchtower just restarted (job 064) / unreachable; re-run.
6. G-015 carrier in a ## Verification block — a new task (T-1239/T-1240/T-1242?) asserts a moving property.
7. _t509 instrument sweep — read which probe.
8. fabric coverage warning — new tools without cards (scrub/gate/installer/tests from T-1239/T-1240).
9. _t611 every unchecked [REVIEW] renders Steps — a new [REVIEW] lacks a Steps block (T-1242/T-1241?).
10. _t345 retired guard — successor _t344 leg 8 red (audit count vs independent count; likely the fabric change).
Then: commit docs/reports/T-1242 updates (done below), close T-1239/T-1240 (ACs), T-669 verification legs,
re-dispatch T-1064/T-1065 with a longer --timeout, apply T-209 verdict, close T-1223, T-1238 needs 3 green runs.
