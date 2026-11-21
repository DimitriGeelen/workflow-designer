# T-1478 — Faster test gates: options, risks, mitigations

Inception, 2026-11-21. Operator: "make a matrix with possible options to accelerate, with the risk, possible risk
mitigation, and then go for external consultation". Goal: shorter wall time from a commit to a green verdict, without
losing what the gates catch today.

## Where the time goes (measured 2026-11-21)

A designer change (high-risk list) passes two gates before it can be pushed, one after the other:

| gate | pool | this machine | what decides the wall time |
|---|---|---|---|
| browser tier (`tools/pool/tier-gate.sh browser`) | 4 shards on pool-w1/pool-w2: 323, 348, 347, 438 s; ~8 min submit to verdict | 1314-1779 s (22-30 min) | this machine |
| core tier (pre-push hook) | 1 job: 784 s (13 min) | 892-1291 s (15-21 min) | this machine |

So a designer round is ~45-50 min today, of which the pool needs ~21 min (8 + 13) and this machine ~40-50 min.
A release job runs the browser tier on the pool alone (operator's option 1, 2026-11-20): 8 min.

Test times (pool, release tree 1fb5dc76a):
- browser: 149 legs, 1456 leg-seconds. Two legs dominate: `person-sees-gate` 304 s (it runs six harnesses one after
  another) and `_t358-laneless-render` 224 s; then `test_t1465_label_strip` 95 s, `_t1068-corpus-labels` 64 s. **No
  split can make a shard shorter than its longest leg: 304 s today.**
- core: 231 legs, 794 leg-seconds, run as one job. Longest: `_t567-*` 83 + 75 s, `_t1039-hook-teeth` 63 s,
  `_t640-fetchers…` 60 s.

Pool (ring20): pool-w1 and pool-w2, 2 slots each, speed ~2.4 (the fast slots); pool-132, 1 slot, ~1.3;
live-huawei-one, 2 shared slots, ~1.04. The slow nodes run the non-gating unsplit shadow and nothing else.

## The options

Gain = estimated wall time saved per designer round, from the numbers above. Risk = what the gates could miss, or
what could go wrong, that they do not today.

| # | Option | Gain (estimate) | Risk | Mitigation |
|---|---|---|---|---|
| O1 | **Re-balance the browser shard plans** from today's measured leg times (part 4 carries the three legs added by hand today) | ~1 min (438 → ~370 s) | none to coverage; the plan goes stale again as legs are added | regenerate the plan from the last green run automatically; a leg missing from the plan warns |
| O2 | **Split the two longest browser legs** into their parts (`person-sees-gate`'s six harnesses as six legs; `_t358-laneless-render` by map group) | floor 304 → ~130 s: browser ~5 min with O1 | a part that relied on an earlier part's state breaks or, worse, passes for the wrong reason | the parts already run as separate processes; the unsplit shadow keeps comparing (T-1462); a census leg proves every former part still runs exactly once |
| O3 | **Split the core tier** like the browser tier (k shards, time-balanced plan, unsplit shadow) | pool core 13 → ~4-5 min | legs that use what another leg leaves behind (one known pair today); shared temp paths | `_T1288_SHARD_WITH` keeps known pairs together; the shadow compare finds unknown ones (a DIFFER refuses later gates); a one-off scan of leg bodies for shared state, as done for the browser tier |
| O4 | **Run the browser and core tiers at the same time**, not browser gate first and push gate after | round = the longer of the two instead of their sum: ~21 → ~13 min on the pool today, ~5 min with O2+O3 | both tiers compete for the 4 fast slots, so each runs slower; a red browser tier no longer saves the core run | core shards on the slow nodes (idle today but for the shadow); or ask ring20 for slots (O8); a red tier cancels the other's pending jobs |
| O5 | **Make the second independent run a second pool node instead of this machine**, for high-risk changes (the rule stays: two runs, two machines, both green) | removes this machine's 40-50 min: round ~8-13 min (pool only), ~5 min with O2-O4 | the two pool nodes are less independent than this desktop (same image, same Chrome build): a fault common to the pool image passes both; this machine's environment (the operator's own) is no longer exercised per change | run the second run on a different node class (pool-132 / live-huawei-one: other hardware); keep this machine in the release job and a scheduled daily full run, with a red one reported at session start; the disagreement rule (refuse, investigate, never retry until it agrees) unchanged |
| O6 | **Speed up the slow harnesses themselves**: the one-browser-per-map harnesses (`_t1456`, `_t1465`: 75 Chrome starts each) reuse one browser with a fresh browser context per map | browser leg-seconds −10-15 % (estimate), more on this machine where Chrome starts are slow | T-1456 moved to one browser per load because a long-lived page hung on the pool; contexts share one browser process | a fresh `Target.createBrowserContext` per map (isolated storage, separate page); crash and hang detection kept (`Inspector.targetCrashed`, the debugger stack dump); measure before and after on the pool |
| O7 | **Warm pool workers**: a kept clone updated by fetch, Node and Chrome on disk, instead of a fresh clone per job | ~0.5-1 min per job (staging) | a dirty or stale workspace gives a result for another tree | `git clean -xfd` and checkout of the exact sha each time; the job records the tree hash it tested and the gate checks it |
| O8 | **More pool capacity** (ring20): a third fast worker, or more slots per fast worker | with O2-O4, lets browser and core shards run side by side without contention | none to coverage; capacity is ring20's to give | ask ring20 (see the consultation) |
| O9 | **Run only the tests a change can affect** (per-leg input map; a designer-only change skips legs that do not read the designer) | large for small changes (minutes) | a missed dependency is a silent miss (T-876: a corpus-only change turned a browser harness red, unseen for a day); this is the riskiest option | conservative map (any `src/` change runs every browser leg); the full tiers still run in every release job and daily; a leg reading an undeclared input fails a census |
| O10 | **Cache results per leg** keyed by that leg's own inputs (finer than today's whole-tree cache) | like O9 for repeat runs (re-runs after a docs or task-file commit) | the same as O9: an input the key does not cover | the same mitigations as O9 |

Not in the matrix: lowering what is tested (fewer maps, fewer widths) — the operator asked for speed, not less
checking.

## Likely combinations (to be confirmed by the consultation)

- **Low risk, now:** O1, O2, O3, O7 — the pool part of a round from ~21 min to ~9-10 min, nothing tested less.
- **Then:** O4 (with O8 if ring20 agrees) — pool part ~5 min.
- **The operator's decision:** O5 — the only option that removes this machine's 40-50 min from every designer round;
  it changes what "two machines" means, so it is the operator's call (as T-1397/T-1408 were).
- **Not recommended yet:** O9, O10 — the gain is real but a silent miss is the failure the gates exist to prevent.

## Consultation

Asked 2026-11-21 with the report above as written (prompt: missing options, mis-estimated gains or risks, insufficient
mitigations, recommended order; under 600 words). Read-only, from an empty directory.

### codex (OpenAI), `codex exec --sandbox read-only`

- **Missing:** overlap the two tiers on the desktop with bounded concurrency (desktop 37-51 → ~22-30 min ideal, risk:
  contention); shard and profile the desktop run itself ("pool-only improvements may save almost nothing end to end");
  remove fixed sleeps and repeated setup inside harnesses (measure start-up / polling / sleeps / useful work first);
  run likely-to-fail legs first (earlier red, no green gain).
- **Mis-estimated (accepted — the report's arithmetic was wrong):** O1-O3 are pool gains, not round gains, while the
  desktop run stays mandatory. O2 cannot reach 5 min: 1456 leg-s / 4 slots = 364 s before overhead; splitting removes
  the longest-leg floor, not work. O4 with O2+O3 has a floor of (1456 + 794) / 4 = 563 s ≈ 9.4 min on four slots, not
  5. O5 doubles pool work (two full runs): ~18.8 min lower bound on the same four slots unless the second run goes to
  other nodes; hardware diversity alone gives little protection against a shared image/Chrome defect. O7 and O8 need
  measuring (oversubscribed slots add latency and flakes).
- **Insufficient mitigations:** O1's "missing leg warns" must FAIL (exact coverage, no duplicates, shard completeness);
  O2/O3 need isolated per-run workspaces and namespaces, enforced dependency groups, split-vs-unsplit compares on the
  same revision including deliberately faulted cases — "a delayed shadow failure cannot protect an already accepted
  commit"; O5's daily desktop run is weaker assurance, to be accepted explicitly or the per-change run kept, and the two
  runs must never land on one host; O6 needs bounded reuse batches with restarts and the original hang's fresh-process
  coverage kept; O7/O10 cache keys must include toolchain, browser, dependencies and configuration.
- **Order:** measure the desktop and staging first; then O1 and safe workspace reuse; then O2/O3 with isolation, on
  both locations; O6 as a separate trial; add measured capacity before promising O4. Defer O5 until the weaker
  guarantee is accepted explicitly; reject warning-only completeness and the 5-minute projections; defer O9/O10.

### GLM-5.3 (Z.AI), `opencode run -m zai-coding-plan/glm-5.3`

- **Missing:** M1 *optimistic push* — push on a green pool verdict, the desktop run verifies afterwards and a red
  reverts automatically (keeps the desktop per change, out of the blocking path; risk: a bad change lands briefly).
  M2 — browser reuse (O6) beyond the two named harnesses: the only option that cuts total leg-seconds, so it lowers
  every floor (364 s → ~310-330 s). M3 — run the shadow in reverse or random leg order and assert per-leg path
  isolation, to find shared state before it fails.
- **Mis-estimated:** the same arithmetic as codex: after O2 the floor is work ÷ slots, 1456/4 ≈ 364 s + overhead ≈
  6.5 min; "~5 min" needs O6 and/or O8. O4's slow-node mitigation defeats O4: core at speed 1.0-1.3 takes ~15-24 min
  and becomes the critical path, so O8 is a prerequisite, not a companion. O5's gain and mitigation exclude each
  other: a different node class is slow (~15-30 min), the same class is maximally correlated; what decorrelates is a
  different Chrome channel or image, not hardware; two full runs on 4 slots ≈ 19 min. O9 saves ~nothing for designer
  changes (its own conservative map runs every browser leg for any `src/` change).
- **Insufficient mitigations:** O3 — static pairs plus a reactive shadow miss a pass-for-the-wrong-reason; needs M3
  plus a permanent input/path census gate. O7 — pin and record Node/Chrome versions, fail on drift, re-image
  periodically. O5 — up to 24 h exposure to a correlated pool fault; needs a differentiated Chrome/image, the desktop as
  tie-breaker on disagreement. O6 — per-map watchdog, restart with a fresh browser, fall back to one browser per map for
  a leg that hangs twice.
- **Order:** O1 + O7; O2; O3 with M3 as an acceptance criterion; ask ring20 for O8 now (lead time), then O4 on fast
  slots only; O6 continuously, measured per leg; O5 restructured as M1 (or, if pre-push dual gating stays, a second fast
  node with a differentiated Chrome build, the correlation risk accepted in writing). Reject O9; defer O10 until its key
  covers the environment.

### Where the two agree (both independent, different vendors)

1. The report's 5-minute projections were wrong: the floor is total work ÷ slots (browser ≥ ~6.5 min on 4 slots;
   browser + core together ≥ ~9.4 min). Faster harnesses (O6) or more capacity (O8) are needed to go lower.
2. While this machine's run blocks every high-risk change, pool-only options barely shorten a designer round; the
   desktop is the bottleneck and should be measured (where its 22-30 + 15-21 min go) before anything else.
3. O5 as written is weaker than it looks (correlated pool image, doubled pool work); needs a differentiated
   Chrome/image or a different structure (GLM: optimistic push), and an explicit acceptance of the changed guarantee.
4. O1 first; O2/O3 need real isolation checks, not only the after-the-fact shadow; completeness checks must fail, not
   warn. Reject or defer O9/O10.

### ring20 (pool owner), msg 08fa79b9 (answer to a33037e4), from their measurements

1. **Capacity is bound by RAM, not TasksMax.** A browser shard peaks at 2.5 GB p50, 2.7 p90, 3.0 max, ~450 s CPU;
   pool-w1 has 8 GB, pool-w2 10 GB: 2 browser slots each is the safe maximum, a third risks OOM. The better lever: a
   third worker, **live-huawei-one** (i7-8550U, 8 threads, 15 GB, bare metal), already configured for 832 (max_parallel
   2, identical Chromium base) but not routed: ring20 can switch it on (browser capacity 4 → 6 parallel). Cost to others
   low.
2. **Mixed load:** per VM, browser 2 + core 2 and at most 4 CPU-bound jobs; 8 at once would share 8 vCPUs per VM and
   slow every shard. Better: browser on w1/w2 (+ huawei), core on pool-132 (i9-8950HK, 6 cores, 1 slot) or huawei; the
   relay already places each job on the node that finishes soonest (a free slot preferred over a queue).
3. **Warm workers: no.** Every attempt gets a fresh tree (tmpfs); a slot with leftovers is quarantined. The working
   equivalent: ship the exact-sha tree as a content-addressed ref (tar or git bundle, sha256-named), cached per node
   per sha; each job unpacks a fresh copy. (Replaces O7.)
4. **Independence: same software, different hardware.** All four nodes: Ubuntu 24.04.5, kernel 6.8.0-149 (pool-132
   -147), byte-identical Chromium base pw-1.55.0 (manifest 0ab9da62ee30). Hardware and hypervisors all differ. "If you
   need a different Chrome build, your desktop stays the independent one."

Our reading of (1): huawei runs at ~1.04 against the fast slots' ~2.4, so a browser shard placed there takes ~2.3× as
long (a 6-way shard of 1456 leg-s ≈ 243 s, ×2.3 ≈ 560 s): slower than today's slowest shard (438 s). It pays for core
shards (and for the second run, below), not for browser shards.

## What the consultation changes

- **The 5-minute figures are withdrawn.** Floors at today's throughput: browser ≥ ~6.5 min on 4 fast slots; browser
  and core together ≥ ~9.4 min if they share those slots. Lower needs less work per leg (O6) or more fast capacity,
  and fast capacity is RAM-bound at 4 slots (ring20).
- **O5 as written is dropped.** A second pool node is independent in hardware only; the Chrome build is byte-identical
  across the pool (ring20 4). The desktop is the only independent Chrome. Two shapes remain, both the operator's call:
  keep the desktop run blocking (today), or GLM's **M1 optimistic push** (push on pool-green; the desktop run still
  runs per change and a red one reverts automatically).
- **The desktop run is the bottleneck** and is measured first (both models): where its 22-30 + 15-21 min go, and
  whether it can itself run split (codex: "shard and profile the desktop run itself").
- **O7 becomes ring20's content-addressed tree refs** (fresh copy per job, transferred once per node per sha).
- **O3's core shards go to pool-132 and huawei** (ring20 2), leaving the fast slots to browser shards: then O4 runs both
  tiers at once without contention, round ≈ max(browser ~6.5 min, core on the slower nodes).
- **Mitigations tightened:** completeness checks fail instead of warn (O1-O3); a reverse-order shadow and a per-leg path
  isolation census for split tiers (M3); browser reuse (O6) with a per-map watchdog and fall back to one browser per
  map for a leg that hangs twice.
- **O9 rejected, O10 deferred** (both models).
