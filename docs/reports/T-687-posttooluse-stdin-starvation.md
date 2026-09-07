# T-687 — PostToolUse hooks starve each other on a shared stdin

**Status:** diagnosis complete, fix is upstream's to make
**Register entry:** G-050
**Reported to AEF:** `agent-chat-arc` offset 1169, 2026-09-07
**Origin:** found while grilling T-685 IW-11, chasing the operator's observation that *"I regularly
see that you repeat something ten times and then repeat it again ten times."*

---

## 1. Symptom

The PostToolUse loop detector never records. `.context/working/.hook-counter` showed
`loop-detect=341`, later `400`, later `420`. `.context/working/.loop-detect.json` held **one**
entry, sixteen hours old. Across a 59-fire window it gained **zero** organic entries; the only new
entries in the whole session were three probes this investigation fired deliberately.

The one organic entry reads `toolName: "unknown"`, `argsHash: "unknown:44136fa355b3678a"` —
SHA-256 of the literal string `{}`. Both payload fields absent.

The detector implements three detectors (no-progress, ping-pong, generic-repeat) and **blocks at
critical**. It is registered on PostToolUse with an empty matcher, i.e. every tool call. It has
been inert for its entire deployed life, and every health surface reported it firing and healthy.

## 2. Root cause

`.claude/settings.json` registers **seven** PostToolUse hooks. Three carry an empty matcher and run
in order:

| index | hook |
|---:|---|
| 0 | `checkpoint post-tool` |
| 3 | `loop-detect` |
| 6 | `audit-task-tools` |

**`agents/context/checkpoint.sh:278`**

```bash
HOOK_INPUT=$(cat 2>/dev/null || true)
```

A bare `cat`, draining all of stdin. Running first, it consumes the payload; every stdin-reading
hook registered after it receives an empty stream. `loop-detect` reads `/dev/stdin`, finds it
empty, and `exit 0`s — fail-open, silently.

### Proof

Same payload, real state file instrumented, one variable changed:

```
echo <payload> | { HOOK_INPUT=$(cat); fw hook loop-detect; }   ->  4 entries, NO CHANGE
echo <payload> | fw hook loop-detect                           ->  5 entries, RECORDED
```

The only difference is a preceding `cat` — exactly the construct at `checkpoint.sh:278`.

### Caveat, stated because it is load-bearing

The proof simulates a **shared** stdin stream across sequentially-run hooks. If Claude Code instead
gives each hook its own stdin, `checkpoint` cannot be starving `loop-detect` and the production
cause is still open. The evidence for sharing is the 420-fires-to-0-organic-records arithmetic,
which no other hypothesis currently explains.

The discriminating test — register a second stdin-reading hook on PostToolUse and see whether it
receives a payload — requires a `.claude/settings.json` change, which B-005 reserves for the
operator. **Not run.**

## 3. Two hypotheses filed and WITHDRAWN

Both were wrong, both were filed into the register before being disproved, and both are recorded
here so nobody re-chases them.

### WITHDRAWN 1 — "`fw hook` eats stdin; T-1628's `exec` → run-and-capture is the regression"

The bisect that produced this was **invalid**. `fw hook` re-resolves `PROJECT_ROOT` from cwd and
exports it (`bin/fw:7039` — *"Resolves FRAMEWORK_ROOT from symlink, PROJECT_ROOT from cwd"*),
overriding the `PROJECT_ROOT=<scratch>` the test had set. The write therefore landed in the **real**
project state file while the test watched the scratch file and saw nothing change.

Re-tested with both files instrumented: `fw hook loop-detect` **does** deliver stdin and **does**
record (real file 3 → 4 entries, containing the probe). Independently, `fw` consumes no stdin at
all — a payload piped through `fw version` survives intact to a following `cat`.

The narrative built on top of it — *"the instrumentation added to make hooks observable is what
broke the hook it observes"* — was a good story about a fact that was not true.

> **PL-010, which we already had:** *vendored-framework code paths that resolve assets via
> `PROJECT_ROOT` break silently.* The learning that would have prevented this was in the register
> the whole time. `fw work-on` surfaced it — **after** the mistake, when the task was created.
> That timing is the argument for failure-triggered recall.

### WITHDRAWN 2 — "version regression" and "config divergence"

A read-only fleet sweep of 11 vendored instances on one host (operator-authorised, Tier 2, logged):

| instance | version | entries | `unknown` | |
|---|---|---:|---:|---|
| 1023-chromium-vault | 1.6.15 | 1 | 1 | broken |
| 0506-Voxtype | 1.6.29 | 2 | 2 | broken |
| Yellowtwig/CashWeb | 1.6.29 | 1 | 1 | broken |
| **0501-opencode-playground** | **1.6.80** | **30** | **0** | **works** |
| 0502-gemnicli | 1.6.145 | 5 | 5 | broken |
| 0503-codex-cli | 1.6.212 | 1 | 1 | broken |
| 160-new-project | 1.6.216 | 10 | 10 | broken |
| 117-android | 1.6.273 | 1 | 1 | broken |
| 832-Workflow-designer | 1.6.354 | 1 | 1 | broken |
| /home/dimitri-mint-dev | **1.6.768** | 1 | 1 | broken |
| /mame/project | dev | 1 | 1 | broken |

The single working instance sits **mid-range**, with two older instances broken beneath it. No
version cutoff produces that pattern. And 0501 registers the hook **identically** — same
`fw hook loop-detect`, same PostToolUse event, same empty matcher (`settings.json:183-189`).

**The defect is live at 1.6.768**, the newest framework on the host. `fw update` does not repair it.

## 4. Two distinct signatures — conflating them caused both dead hypotheses

- **A — payload LOST.** Nothing recorded at all. Ours: 420 fires, 0 organic entries.
- **B — payload ARRIVED FIELDLESS.** Recorded as `unknown`. Visible at 1.6.15 / 1.6.29 / 1.6.145 /
  1.6.216. stdin reached the detector; `tool_name` and `tool_input` were absent from the JSON it
  carried — a payload-**shape** problem, plausibly a Claude Code client contract change, and a
  **different defect**.

"10 of 11 broken" was one number covering two faults. G-050 is signature A. Signature B needs its
own register entry if it is still live.

## 5. Proposal — the fix is not a reorder

Reordering does not fix this. Whichever stdin reader runs first wins, so promoting `loop-detect`
above `checkpoint` merely starves the budget gate instead — trading a repetition detector for a
context-exhaustion guard.

The durable fix is a **single PostToolUse dispatcher** that reads stdin once and passes the payload
to each sub-hook by argument or environment variable. That is a framework architecture change and
belongs upstream; this project has not attempted it, and has made no change to
`.claude/settings.json` (B-005).

## 6. What we built instead, and why

`tools/_t687-hook-function-check.py` — a **function check** rather than a fire check.

It asserts what the counter cannot: that between two runs, if the fire counter advanced by at least
20 and the newest entry in the state file did **not** advance, the hook is firing without
functioning → exit 2.

Entry *count* is deliberately not the signal. `loop-detect` trims history to 30, so a healthy
long-running session sits at 30 forever and a count-based check would misread saturation as
starvation. The newest entry's **timestamp** is monotonic and does not saturate. The self-test
asserts that RED, GREEN and GREY are all reachable, and that a trimmed-but-live history reads
green.

> **PL-320: a fire counter is not a function check.** Counting invocations of a control proves it
> was entered and nothing about whether it did anything. Where a control has state, the health
> check must assert the state **moved**.
>
> This is the third register measured this session with the same defect, after `fw promote`
> (319 learnings, 41 ready, **0 promoted**) and the vendor-divergence register (46 fixes marked for
> upstream, **no delivery state in the schema at all**). A control that cannot report its own
> inertness is why a wrong cause could be filed against this hook **twice** with nothing
> contradicting it.
