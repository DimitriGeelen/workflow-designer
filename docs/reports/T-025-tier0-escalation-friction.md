# T-025 — tier0-escalation: v2-schema friction report

```yaml
task: T-025
type: dogfood-friction-report
generated: examples/aef-processes/tier0-escalation.workflow.yaml
ground_truth: agents/context/check-tier0.sh
validator: tools/validate-workflow.py  # exit 0, no findings
authored: 2026-07-03
prior_slices: [T-021 inception, T-022 task, T-023 healing]
synthesis: docs/reports/dogfood-v3-design-inputs.md
```

## What this is

Fourth dogfood slice. We generated a workflow for **Tier-0 enforcement** — the
ambient guard that intercepts every Bash command, blocks destructive ones, and
requires single-use human approval — from `check-tier0.sh`, and validated it
(exit 0). Four processes mapped, four clean validations, zero generation
failures.

Tier-0 has a shape none of the first three did: it is an **ambient / cross-
cutting guard**, not a step in an authored process. It fires on *every* command.
That mismatch is the headline new friction (F11). A second new friction is the
**single-use approval token** (F12) — an expiring, hash-bound capability grant.
Four frictions recur, and two of them are now saturated: **F3 (determinism) and
F1 (human decision→edge) are 4/4** across every process mapped.

## The process (ground truth)

`check-tier0.sh` (PreToolUse:Bash): intercept → match against high-confidence
destructive PATTERNS → **no match** ⇒ run; **match** ⇒ require a valid one-time
approval token (`.context/working/.tier0-approval`, whitespace-normalized hash,
T-1500; or Watchtower `.context/approvals/`, T-612) ⇒ **present** ⇒ consume
(single-use `rm -f`, `.consumed` sentinel for the 5 s duplicate-fire window) +
log + run; **absent** ⇒ BLOCK (exit 2) ⇒ human runs `fw tier0 approve` (writes
the token) and the agent re-issues, or abandons. Authority → swimlanes: human
approves (Tier-0 is human-only), framework intercepts/matches/consumes/logs,
agent proposes + executes. Mapped cleanly; gaps below.

## NEW friction

### [F11] No ambient / boundary-interrupting guard construct — r3 §3.2 (new SD candidate) · seam S4
Tier-0 is not a node the process author places; it is a **policy that intercepts
any command**. In BPMN terms it is an event-subprocess / boundary interrupting
event that can fire on any activity. v2 has only plain sequence flow, so we had
to inline the guard as explicit nodes (`intercept → match → …`) in one workflow —
which mis-represents it as a step specific to this flow rather than a cross-
cutting rule applying to all of them. There is no way to declare "this guard
wraps every consequential node in every workflow."
- **v3 need:** an ambient/boundary-guard construct (a policy attached to a node
  class or tier, not hand-placed), so enforcement is declared once and applies
  everywhere. This is the *enforcement* half of the Process-layer thesis.

### [F12] No single-use / expiring capability (approval-token) construct — r3 SD-4 / §3.2 · seam S4
The approval is a **stateful capability**: issued by a human for one specific
command hash, consumed on first use (`rm -f`), and short-lived (the `.consumed`
sentinel expires in 5 s). v2 has no notion of a capability/grant with a lifecycle
(issued → matched → consumed → expired). We carried it as free-form `aef.sources`
+ `aef.sideEffect`. The single most safety-critical mechanic in the framework —
a one-time, hash-bound, expiring authorization — is structurally invisible.
- **v3 need:** a capability/authorization-token type with `{scope (hash/target),
  single_use, ttl, issuer}` that a strict runner honours and consumes.

## RECURRING friction

- **[F3↺ 4/4] determinism marker** — intercept/match/consume/block are
  deterministic fw-logic; propose + execute are stochastic agent actions.
  **Present in all four processes.** Non-negotiable v3 field.
- **[F1↺ 4/4] human decision → edge** — the approve/abandon authorization is a
  4th distinct human-decision shape (after go/no-go/defer, partial-complete,
  ladder-rung). One missing construct, four gateways. **All four processes.**
- **[F4↺] Tier-0 human-gate as a first-class gate property** — this slice IS the
  canonical F4 process. The human-only, cannot-be-agent-driven property is
  carried only as `lane: human` + `tier: 0`; a strict runner has nothing binding
  to enforce. Reinforces that F4 (and its generalisation F8) are essential.
- **[F8↺] transition guard / gate** — the match+approval sequence is a guard on
  the "execute" transition; same gate-set gap generalised in T-022 F8.

## Map to r3 SDs and the T-020 seam catalogue

| Friction | Status | r3 anchor | seam | Slices |
|---|---|---|---|---|
| F11 ambient/boundary guard | new | §3.2 (new SD) | S4 | T-025 |
| F12 single-use capability token | new | SD-4 / §3.2 | S4 | T-025 |
| F3 determinism marker | ↺ **4/4** | P4 | S3/S1 | all |
| F1 human decision→edge | ↺ **4/4** | SD-11 | S6 | all |
| F4 Tier-0 gate property | ↺ | §3.2 | S4/S6 | T-021, T-025 |
| F8 transition guard/gate-set | ↺ | §3.2/SD-8 | S4/S3 | T-022, T-025 |

## Conclusion

The ambient-guard shape validated as cleanly as the flow, state-machine, and
advisory shapes before it — the generator is robust across four structurally
distinct process kinds. Two new frictions (F11 ambient guard, F12 capability
token) are both on the *enforcement* side of the Process-layer thesis and both
map to §3.2 / SD-4 (seam S4), reinforcing that governance-enforcement is where
v2 is thinnest. Meanwhile F3 and F1 reaching 4/4 removes any doubt that they are
universal.

**Feeds:** the consolidated synthesis (docs/reports/dogfood-v3-design-inputs.md)
— add F11/F12 to the register and note F3/F1 now 4/4. **Next candidates:**
arc-lifecycle, assumption validation, session handover, decommission — continue
until the friction register goes dry.
