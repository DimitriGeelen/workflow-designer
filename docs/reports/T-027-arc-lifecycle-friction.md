# T-027 — arc-lifecycle: v2-schema friction report

```yaml
task: T-027
type: dogfood-friction-report
generated: examples/aef-processes/arc-lifecycle.workflow.yaml
ground_truth: lib/arc.sh, lib/arc_membership.{sh,py}, check-arc-id.py, evolution_log.sh
validator: tools/validate-workflow.py  # exit 0 (after the judge caught a real YAML error)
authored: 2026-07-03
prior_slices: [T-021 inception, T-022 task, T-023 healing, T-025 tier0]
synthesis: docs/reports/dogfood-v3-design-inputs.md
```

## What this is

Fifth dogfood slice. We generated a workflow for the **arc lifecycle** — AEF's
unit of grouped multi-task work (epic/theme) — and validated it (exit 0; the
judge again caught a genuine YAML error first, 2/5 slices). Five processes
mapped, five clean validations.

The arc slice was run specifically to probe the **composition** question, and it
produced the campaign's most architecturally consequential single finding (F13),
which *corrects* an earlier assumption. It also hardened an unusually large set of
recurrences — arc touches F1, F4, F6, F7, F8, F9, F11 — because it is a
governance-rich process (human-only close/abandon, immutable status lifecycle,
advisory BVP, ambient membership guard).

## The process (ground truth)

An arc is a registry-backed grouping of related tasks targeting one headline
mechanic, with a linear status state machine **draft → in-progress →
closed/abandoned** (`arc.sh:101/411`). Operations: `create` (draft, immutable
`arc-NNN`, `--headline-mechanic` required, G-062), `start`, `tag` (membership),
`rescore`/`approve-driver` (BVP), `review` (emit Watchtower surface), `close`
(requires wire-level demo evidence, human-only), `abandon` (reason ≥30 chars,
human-only). Membership is **task-side** (`arc_id` frontmatter or `arc:` tag),
resolved on demand by `arc_tasks_for()`, gated by `check-arc-id.py`. Every
arc-member build task must carry a substantive Evolution log (audited,
`evolution_log.sh:86`). Ownership → swimlanes: agent create/start/tag/rescore/
review; human close/abandon/driver-approval (§ACD/G-062); framework enforces
membership + evolution + immutability. Mapped cleanly; gaps below.

## NEW friction

### [F13] No grouping / container construct (unordered, by-reference, computed membership) — r3 §2.6 / SD-9 · seam S8 (refines it)
An arc is a **tag-set / label container, not a graph and not a sequenced
sub-process.** Its members are computed on demand from task frontmatter
(`grep arc_id: / tags: arc:`) — unordered, with no edges, no parent-child
nesting, and **never stored authoritatively** (the member list is a *query*, not
a list). v2 has no grouping construct at all (no BPMN Group artifact, no ad-hoc
unordered sub-process), so we approximated the whole member set as a single
representative node (`n_work`) carrying `aef.grouping`.

This **refines seam S8 / the F5 finding**: composition is not one need but two —
1. **sequenced sub-workflow** (callActivity with control-flow edges) — what F5
   covers (DEFER sub-process, healing invoked-on-transition); and
2. **unordered grouping container** (a label-set over members, no edges) — what
   arcs need, and what F13 names.
Conflating them would over-engineer arcs into a control-flow graph they are not.
- **v3 need:** a first-class *group/container* type whose membership is a
  by-reference set (optionally a computed/query membership), distinct from
  callActivity. It carries group-scoped metadata (status lifecycle, BVP) and
  group-scoped constraints (see F11 below) but imposes **no ordering** on members.

## RECURRING friction (arc hardened seven)

- **[F7↺ 3/5] state machine vs flow** — arc status draft→in-progress→closed/
  abandoned, with `abandon` a side-exit reachable from multiple states. Same
  state/transition gap; `aef.state` carried out of band again.
- **[F6↺ 2/5] governance status + immutability** — arc has a first-class `status`
  and a hard immutability invariant (arc YAML never moved/deleted, `arc-NNN`
  never reused). First recurrence of F6 since inception; confirms definitions
  need a governance-lifecycle + immutability field.
- **[F1↺ 5/5] human decision → edge** — close vs abandon is a human decision
  routing the branch. **5th distinct shape; now in every slice.**
- **[F4↺ 3/5] human-only gate** — close/abandon/driver-approval are agent-blocked
  (§ACD/G-062, `--i-am-human`/`--from-watchtower` only). Carried as lane+tier.
- **[F8↺ 3/5] guard with required evidence** — `close` requires wire-level demo
  evidence; a transition guard with an evidence precondition (the gate-set family).
- **[F9↺ 2/5] advisory vs binding** — BVP `rescore` writes **proposed** scores
  (advisory); `approve-driver` binds them (human). The advisory/binding split
  again, now on scoring.
- **[F11↺ 2/5] ambient guard, group-scoped variant** — `check-arc-id.py`
  intercepts task writes (must resolve to a real arc), and the evolution-log
  audit applies to *every arc member*. This is F11 (ambient guard) **parameterised
  by group membership** — a guard that applies to "all members of group X."
  Notable interaction: F11 × F13.

## Map to r3 SDs and the T-020 seam catalogue

| Friction | Status | r3 anchor | seam | Slices |
|---|---|---|---|---|
| F13 grouping/container | new | §2.6 / SD-9 | S8 (refined) | T-027 |
| F1 human decision→edge | ↺ **5/5** | SD-11 | S6 | all |
| F7 state-machine vs flow | ↺ 3/5 | SD-2 | S2 | T-022,23,27 |
| F4 human-only gate | ↺ 3/5 | §3.2 | S4/S6 | T-021,25,27 |
| F8 guard/evidence | ↺ 3/5 | §3.2/SD-8 | S4/S3 | T-022,25,27 |
| F6 status/immutability | ↺ 2/5 | SD-4 | S4 | T-021,27 |
| F9 advisory/binding | ↺ 2/5 | §3.2/SD-8 | S4 | T-023,27 |
| F11 ambient guard (group-scoped) | ↺ 2/5 | §3.2 | S4 | T-025,27 |

## Conclusion

Arc validated the composition probe decisively: the compositional need is **two
constructs, not one** — callActivity (sequenced, F5) *and* a grouping container
(unordered, by-reference, F13). Seam S8 should split accordingly in v3. The slice
also hardened seven recurrences — most notably F1 reaching **5/5** (every process)
and F6 recurring — while surfacing the F11 × F13 interaction (group-scoped ambient
constraints), a construct v3 will want once both F11 and F13 exist.

**Feeds:** docs/reports/dogfood-v3-design-inputs.md — add F13; split seam S8 into
sequenced-sub-workflow vs grouping-container; bump F1 to 5/5, F4/F7/F8 to 3/5,
F6/F9/F11 to 2/5. **Remaining candidates:** assumption-validation,
session-handover, decommission — nearing the friction-dry signal (this slice
produced only one new friction vs the register's growing recurrence mass).
