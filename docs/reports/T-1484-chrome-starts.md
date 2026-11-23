# T-1484 — what Chrome starts cost the browser tier

Measured 2026-11-23 on this host (load 22-26 from other projects at the time), headless `/usr/bin/google-chrome`.

## One start and stop

| run | start (to "DevTools listening") | stop |
|---|---|---|
| 1 (cold) | 0.62 s | 0.23 s |
| 2 | 0.18 s | 0.16 s |
| 3 | 0.18 s | 0.10 s |

So 0.3-0.8 s per browser. Reuse would save only this: a fresh browser context per map still loads the designer page
(1.4 MB) and initialises it, which is most of a map's time.

## How many starts

Chrome profiles (`--user-data-dir`) seen every 0.2 s while `person-sees-gate.sh --only label-clearance,sweep` ran
(186 s; the two heaviest one-browser-per-map harnesses):

| harness | starts | harness time | start cost | share |
|---|---|---|---|---|
| label-clearance (`_t1256`) | 22 (one per map) | 103 s | ~7-17 s | 7-16 % |
| sweep (`_t1278`) | 3 | 83 s | ~1-2 s | 1-3 % |

(Seven more profiles seen belonged to other programs on this desktop.)

## The tier

158 browser legs; most start Chrome once, the per-map harnesses a few dozen more: roughly 180-200 starts per tier
run, ~60-150 s of ~1,590 leg-seconds = **4-9 %**.

## Decision

Below the ~15 % the task set as the bar. A reuse trial would change up to 61 harnesses' launch code and trade some
isolation (a shared browser process across maps) for a few percent; not worth it now. Closed without building.
Revisit only if a measurement on the pool shows starts there several times slower than here.

What would lower the floor instead: making the per-map work itself cheaper (page load and init of the designer per
map), or more pool slots (ring20's T-2842 measurement).
