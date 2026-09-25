# Auto-approval telemetry

`bvp-auto-approval.jsonl` — one JSONL row per action that an agent was permitted to take
automatically, under the operator ruling of 2026-09-25 ("BVP scoring should come automatically, no
approval from user anymore … key thing is we want to have telemetry about it. We want to collect
data so we can analyze it and improve it"). Written by `lib/bvp.sh` (T-856).

**Append-only.** Rows are not edited or removed, including the contaminated ones named below.

## Fields

| field | meaning |
|---|---|
| `ts` | UTC timestamp of the write, after it succeeded |
| `event` | `bvp_confirm_auto` |
| `verb` | the gated verb that was auto-permitted |
| `switch` | the config key that permitted it (`BVP_AUTO_CONFIRM`) |
| `target` / `task_file` | which task was scored |
| `proposal_existed` | whether the estimator had proposed anything at all |
| `proposed` | the estimator's scores, captured **before** they were cleared |
| `confirmed` | what was actually written to `bvp_scores:` |
| `overrides` | `--override Dn=N` values supplied on the call |
| `delta_vs_proposed` | per-driver difference, only for drivers that changed |
| `proposer_exact` | true when a proposal existed and was written unchanged, with no overrides |
| `os_user` | the OS account the agent ran as — **not** an approver |

## The question this is meant to answer

`proposer_exact` and `delta_vs_proposed` are the analysis payload: across many rows they show how
often the estimator's proposal was taken as-is versus corrected, and by how much per driver. That is
the signal for whether auto-confirmation is safe to keep and where the estimator needs work. It only
exists because `confirm` promotes `bvp_scores_proposed:` rather than writing scores from scratch —
had the proposed/confirmed distinction been collapsed, every row would say the same thing.

## Known contaminant — exclude from analysis

**Rows with `target: "T-9990"` are fixture artifacts, not real scoring events.** T-9990 is the
throwaway task created and deleted by `tools/_t856-auto-approval-teeth.sh`. The first run of that
suite wrote its rows here before the suite had a telemetry redirect; the ledger is append-only, so
they stay and are documented rather than removed.

Since then the suite exports `FW_BVP_TELEMETRY_PATH` to a temp file, so no further test rows can
reach this ledger. Any filter over this file should start with:

```
jq 'select(.target != "T-9990")' .context/telemetry/bvp-auto-approval.jsonl
```

## What is NOT auto-approved

The ruling covered scoring. `fw bvp weight --set`, `driver --add`, `driver --remove` and
`auto-promote --enable` remain §ACD-gated — they edit the value model itself (D8, sovereignty at
policy-edit time), which is a different authority from scoring a task against it.
`fw arc create` was already ungated for agents and needed no change; `fw arc close` remains gated,
and was not part of the ruling.
