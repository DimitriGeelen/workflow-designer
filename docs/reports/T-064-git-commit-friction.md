# T-064 — git-commit-flow friction catalogue

**Map:** `examples/aef-processes/git-commit-flow.workflow.yaml` (12 nodes, 13 edges, 3 lanes)
**Ground truth:** `.agentic-framework/agents/git/{git.sh, lib/commit.sh, lib/hooks.sh, lib/bypass.sh, lib/{secret,large-file,dup-task}-scan.sh}`
**Dogfood role:** the GIT enforcement gate — the fifth "constitutional gate" alongside the
T-054 series (task-gate, verification-gate, context-memory, error-ladder).

## Findings

### FC-14 (NEW) — one logical constraint, two enforcement sites, no notation for it
The P-002 "every commit carries a T-XXX" rule is enforced **twice**:
- **agent level** — `commit.sh` `extract_task_id "$message"` blocks before `git commit`
  (mapped as `g_taskref`, agent lane);
- **framework level** — the installed `commit-msg` git hook (`hooks.sh` `VERSION=1.9`)
  re-checks the same pattern at commit time (folded into `g_hooks`, framework lane).

This is deliberate defense-in-depth, but the BPMN subset can only draw it as **two
independent gateways in two lanes**. There is no construct for "the same constraint,
enforced redundantly at two points" — a reader can't tell `g_taskref` and the commit-msg
half of `g_hooks` are the *same rule*. **Gap:** no shared-constraint / cross-reference
annotation. Candidate future affordance: a `constraintId` that several gates can cite.

### FC-11 (RECURRENCE — now partially mitigated) — collapsed gate constituents
`g_hooks` collapses four real gates (secret-scan T-1844, dup-task-scan G-052, large-file
T-1845, commit-msg task-ref) into one node — the same "a collapsed node can't declare its
constituents" friction first logged in T-056/T-058. **This time it was mitigable:** the
constituents are declared in `aef.x-checks` — the explicit passthrough channel built in
**T-061/T-062**. So a friction the corpus kept hitting is now *survivable* (the data reaches
the BPMN and renders) even though a first-class "sub-gate list" construct still doesn't
exist. Dogfooding validated the x-* channel's reason for being.

### FC-10 (RECURRENCE) — guard chain drawn as a routing tree
The pre-commit scan chain (secret → dup-task → large-file → commit-msg) is a linear
sequence of independent blocking gates, each `exit 1` on hit. Drawn faithfully it is a
routing tree of exclusive gateways to a shared block end — the same shape flagged in
T-055/T-056. Here it is collapsed into `g_hooks` to stay readable; the collapse is the
FC-11 workaround above.

## Upstream observation (framework logic, not a Designer-schema friction)
`commit.sh` `--bypass` (lines 78-79) calls `git commit -m … "${git_args[@]}"` **without
`--no-verify`**, so a bypass commit **still fires the installed hooks** — including the
commit-msg task-ref gate. A `--bypass` commit whose message lacks a `T-XXX` would therefore
be blocked by the hook even though the agent-level gate was intentionally skipped. The
agent-level bypass and the hook-level gate are not reconciled. Recorded here because it was
surfaced by mapping the flow; the git agent is vendored (read-only), so this is flagged for
the framework maintainers, not fixed here.

## Clean signals
- 0 unknown-key / cannot-ride WARNs (authored entirely in clean post-T-062/T-063 vocabulary).
- Converts + validates clean; geometry band gate clean; corpus 20 → 21; suite 28/28.
