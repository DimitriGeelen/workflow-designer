# T-1413 Human AC#1: review of exploration findings and the go/no-go recommendation

Reviewer: independent, rung-3-termlink-single-reviewer. Revision reviewed: 1a901f14062eeb8ce547fab9d530789ec88dbeba.
Verdict: **green** (the NO-GO recommendation is supported; approve it).

## What I read
- `.tasks/active/T-1413-should-832-move-to-a-docker-style-servic.md` (all 295 lines): problem, hypothesis, IW-1..IW-5
  dispositions, go/no-go criteria, recommendation.
- `docs/reports/T-1413-docker-service-inception.md` (the research artifact).
- The code the recommendation cites.

I did not run `fw task review T-1413` (it opens Watchtower for a human); I read the same sources directly.
`fw` resolves on PATH to `.agentic-framework/bin/fw`, so the criterion's command is current.

## Checked against the code (verified)
1. **Deployment audit section is opt-in (IW-5).** `.agentic-framework/agents/audit/audit.sh:9147-9151`:
   `if [ -n "$SECTIONS" ] && should_run_section "deployment"` so it runs only when `--section` is given AND names
   `deployment`. Header line 16: "Default (no --section): all except deployment, which is opt-in (T-275, T-4410)".
   The cron lines the script installs (lines 100-120) name other sections only. The three file checks
   (`Dockerfile`, `deploy/docker-compose.swarm.yml`, `deploy/traefik-routes.yml`) are at lines ~9190-9200. Claim holds.
2. **Gallery server binds all interfaces and writes without auth (IW-2).** `tools/gallery-serve.py:399` `BIND = '0.0.0.0'`
   (`--bind` overrides, line 420). `do_PUT` (line ~1104) and `do_POST` (line ~1122: `/api/save`, `/api/delete`,
   `/api/validate`, `/api/field-suggestions`) go straight from JSON parsing to the write; a case-insensitive search of
   the file for authoriz/token/password/api-key returns 0 lines. Claim holds.
3. **No deploy files exist and none were written during the inception** (scope fence): no `Dockerfile`; `deploy/`
   holds only `systemd`. T-752, T-753, T-754 exist in `.tasks/active/` as the recommendation says.
4. **All five questions are disposed** with confidence and rationale (IW-1..4 answered, IW-5 dissolved).

## Not verified
- **The wording of the two consultation replies** (AEF msg 1d7d8b4b, ring20 msg b86d15f0). Both ids occur in the
  project's local message records (`.context/sidecar/receipts-sent.jsonl`, `direct-ack.jsonl`), so the exchanges took
  place, but my attempt to read their content was refused by the sandbox's permission layer. The quotes in the artifact
  are therefore taken as reported, not confirmed by me. This covers IW-3, IW-4, the workshop-designer precedent and the
  "no known users" answers.

## Does the recommendation follow?
Yes, and it does not depend on the unverified quotes. The task's own GO rule needs three things at once: a named user
besides AEF, a ring20 owner and cost, and safe write paths. No named user is recorded anywhere in the task or artifact,
and the write paths are verifiably unsafe today. With GO unmet on verified evidence alone, NO-GO is the result under the
task's own criteria; the quotes only strengthen it. The second reason given for acting ("the gate keeps failing") is
verifiably wrong: the section never runs unasked.

The one open point is IW-1 (confidence 2): a public audience after the SPRIND video, which only the operator can name.
It does not change this decision: per the artifact, even a public read-only designer would be a static app, not a swarm
service, and the recommendation keeps that as a separate small task.

Risk of approving: none that needs a human under the operator's ruling. NO-GO deploys nothing, publishes nothing,
changes no file in 832 and can be reopened at any time.

## Small defects (do not change the verdict)
- The artifact's line 3 still reads "Status: exploring; starting recommendation DEFER", its question table still says
  "asked AEF and ring20" / "partly answered", and its dialogue log ends at DEFER. The Synthesis section below them is
  current. A reader who stops at the top gets the old state.
- Task `## Assumptions` is empty (nothing registered), while an Agent criterion reads "Assumptions tested".
- The NO-GO rule says the deploy section "is declared not applicable"; the finding is that no declaration exists or is
  needed. T-752..T-754 should close with that wording.
- The criterion's "Expected: Decision recorded, task completed" is not yet true at this revision (`## Decision` empty,
  status started-work): recording NO-GO is the step that follows this verdict.
