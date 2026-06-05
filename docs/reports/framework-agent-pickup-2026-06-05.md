# Pickup → Framework Agent: upstream-framework findings from 832-Workflow-designer init

**From:** Claude Code agent in consumer project `832-Workflow-designer`
(`/opt/832-Workflow-designer`, vendored AEF mode).
**Date:** 2026-06-05
**Reach:** termlink (this host) / framework repo maintainer.
**Nature:** This is a **proposal / pickup request**, not build authorization.
Each item below should become its own task upstream (one bug = one task).
The consumer-side tracking inceptions are noted where they exist (T-006, T-007).

---

## TL;DR

Five findings surfaced while bootstrapping a fresh consumer project. Four are
concrete defects (one new this session, two already filed as consumer
inceptions, one a silent-skip). The fifth is a **governance meta-issue**: the
onboarding gate makes it impossible to *act on* an upstream-framework failure
discovered mid-onboarding — exactly when these are most often found. Please
prioritise the meta-issue (F5): it is the one that suppresses all the others.

| # | Finding | Severity | Directive at stake |
|---|---------|----------|--------------------|
| F1 | CSRF stale-token dead-ends on a bare "Forbidden" page | High (UX) | Usability, Reliability |
| F2 | `fw vendor` omits `orchestrator-mcp-baseline.yaml` (consumer audit FAILs) | Medium | Portability, Reliability |
| F3 | `fw init` seeds `patterns.yaml` with `origin_task`; canonical is `learned_from` | Medium | Reliability |
| F4 | Pre-commit `secret-scan.sh` missing from vendor → silently skipped | Medium | Reliability (no silent failures) |
| **F5** | **Onboarding gate blocks recording/working upstream-failure tasks** | **High** | **Antifragility, Reliability** |
| **F6** | **Greenfield onboarding inception is undecidable (self-referential AC, no auto-tick marker)** | **High** | **Usability, Reliability** |

---

## F5 (META — please read first): upstream failures cannot be recorded mid-onboarding

**Symptom.** While onboarding is incomplete, the active-task hook blocks
focusing or working **any** task that is not tagged `onboarding`. A newly
discovered upstream-framework bug (a "pickup request") can have a task *file*
created, but cannot be **focused, worked, verified, or committed** — the gate
fires on every Write/Edit/Bash. Onboarding completion can itself depend on a
**human inception decision** (here: T-002, `owner: human`) that may be delayed
arbitrarily. Net effect: framework-stabilisation signals discovered during
onboarding are stranded until a human acts — a silent suppression of exactly
the failure class AEF most wants to capture.

**Evidence.**
`agents/context/check-active-task.sh:417-463` (T-535 / policy T-532). The gate:
1. fires when `.context/working/.onboarding-complete` is absent **and** any
   active task is tagged `onboarding` and not completed;
2. allows the request **only if** the *currently focused* task is itself tagged
   `onboarding` (`CURRENT_IS_ONBOARDING` check, lines 439-444);
3. otherwise blocks with `Policy: T-532`.

Reproduced this session: `fw task create … --start` for an upstream-bug
investigation (T-008) → blocked on the first Bash/Edit because T-008 is not an
onboarding task; the only escape offered is `fw onboarding skip` (a blunt,
all-or-nothing bypass the autonomous-mode boundary forbids agents from using).

**Why it matters (directives).** *Antifragility* — "failures are learning
events"; the gate drops them on the floor. *Reliability* — "no silent failures";
an unrecordable defect is the definition of a silent failure.

**Requested fix (exemption).** Add an OR-branch to the gate so the onboarding
block does **not** apply to defect-capture tasks. Concretely, at
`check-active-task.sh:439-444`, treat the focused task as exempt when it is
tagged `upstream-framework` (and/or a dedicated `defect`/`pickup` tag, or a new
`workflow_type: defect`). Suggested shape:

```sh
# Exempt defect-capture tasks from the onboarding gate (T-XXX):
# upstream failures discovered mid-onboarding must remain recordable.
if [ "$CURRENT_IS_ONBOARDING" = false ]; then
    if head -20 "$ACTIVE_FILE" | grep -qE '^tags:.*(upstream-framework|defect|pickup)'; then
        : # exempt — allow capture/work of framework-failure tasks
    else
        # …existing block…
    fi
fi
```

Keep the exemption *narrow* (defect/upstream tags only) so it can't be used to
route around onboarding for ordinary feature work. Optionally emit a one-line
advisory ("onboarding still incomplete; exempted because tagged
upstream-framework") to preserve visibility.

---

## F1 (NEW): CSRF stale-token dead-ends on a bare "Forbidden" page

**Symptom.** A human opens the Watchtower `/approvals` page, clicks **GO** on a
pending inception decision, and lands on a featureless page titled
"Forbidden — <project>" with body "403 Forbidden / CSRF token missing or
invalid". No recovery path is offered. The human did nothing wrong — the tab's
CSRF token simply went stale (tab left open, or a stale `session` cookie for the
host:port from a previously-running Watchtower instance).

**Evidence / reproduction** (against a live consumer Watchtower):
- `GET /approvals` → **200**, renders pending decisions correctly.
- `POST /api/approvals/decide` (or `/inception/<id>/decide`) **with** a fresh
  scraped `_csrf_token` + matching session cookie → CSRF **passes** (404 on a
  bogus hash). Mechanism is sound.
- Same POST **without** a valid token → **403**, the exact "Forbidden — <project>"
  page the operator reported.
- Forms *do* embed the token (`templates/_approvals_content.html:64,176,306,479,515`).
  CSRF check: `web/app.py:92-111` (POST/PATCH/PUT/DELETE only). 403 handler:
  `web/app.py:359-370`.

**Requested fix.** Make the 403 recoverable instead of terminal:
1. In the 403 handler (`app.py:359`), detect CSRF-class failures (description
   contains "CSRF") and render a distinct page: "Your session expired — reload
   and retry," with a reload button, rather than the generic Forbidden page.
2. Better: have the htmx action endpoints return `409` + a fresh token on CSRF
   mismatch so htmx can transparently re-fetch the token and resubmit (no human
   round-trip). Or expose a tiny `GET /api/csrf` and have an htmx
   `htmx:responseError` handler refresh the hidden field.
3. Consider `SESSION_REFRESH_EACH_REQUEST`/token-rotation tuning so long-open
   approval tabs keep a valid token.

**Operator workaround (until fixed):** hard-refresh `/approvals` (Ctrl+Shift+R)
before clicking, or clear cookies for the host; or record decisions via the CLI
(`fw inception decide …`), which bypasses the web CSRF surface entirely.

---

## F2: `fw vendor` omits `orchestrator-mcp-baseline.yaml`

(Consumer tracking inception: **T-006**, tag `upstream-framework`.)

**Symptom.** `orchestrator-mcp-scan.sh` expects a baseline at
`PROJECT_ROOT/.context/audits/orchestrator-mcp-baseline.yaml`, but `fw vendor`
does not copy it into consumer projects → first audit FAILs on a fresh project.

**Requested fix.** Add the baseline copy step to `do_vendor()` in `bin/fw`
(ship the baseline as part of the vendored payload).

---

## F3: `fw init` seeds `patterns.yaml` with the wrong field name

(Consumer tracking inception: **T-007**, tag `upstream-framework`.)

**Symptom.** `lib/seeds/patterns.yaml` uses `origin_task:` (12 occurrences),
but the canonical field is `learned_from:`. Seeded patterns therefore lose their
task back-links everywhere downstream.

**Evidence.** Canonical `learned_from` is written by
`agents/context/lib/pattern.sh:112`, parsed by
`agents/healing/lib/patterns.sh:64`, and rendered by
`web/templates/patterns.html:183-184`. The seed file diverges:
`lib/seeds/patterns.yaml:15,25,35,…` use `origin_task`.

**Requested fix.** Rename `origin_task:` → `learned_from:` in
`lib/seeds/patterns.yaml` for consistency with the canonical writer/parser/view.

---

## F4: pre-commit `secret-scan.sh` missing from vendor → silent skip

**Symptom.** `fw handover --commit` (and the pre-commit hook) emit:
`secret-scan: scanner not found at .agentic-framework/agents/git/lib/secret-scan.sh (skipping)`.
The secret scan (T-1844) is silently skipped in consumer projects because the
scanner script is not shipped by `fw vendor`. A security control that silently
no-ops is worse than one that's absent — operators believe they're protected.

**Requested fix.** Either ship `agents/git/lib/secret-scan.sh` in the vendored
payload, or make the hook **hard-fail** (not skip) when the scanner is
referenced by an installed hook but missing — so the gap is loud, not silent.

---

## F6 (NEW): greenfield onboarding inception is undecidable out of the box

**Symptom.** `fw init` creates the foundational "define goals & architecture"
inception (here T-002) whose `### Agent` ACs include a self-referential
*"Go/no-go decision recorded: `fw inception decide …`"* item. Recording the
decision is blocked because that AC is unchecked — and the AC can only become
checked *by* recording the decision. Chicken-and-egg. The operator sees:
`ERROR: Cannot record decision — 1/3 agent AC unchecked`. Hits **both** the CLI
(`fw inception decide`) and the Watchtower GO button (`/inception/<id>/decide`).

**Why it deadlocks.** `lib/inception.sh` auto-ticks ceremonial agent ACs only
when they carry a `<!-- @auto-tick-on-decide -->` marker **or** match a fixed
wording regex (`AGENT_PATTERNS`: "Problem statement validated" / "Assumptions
tested" / "Recommendation written with rationale" / "[Inception decision
recorded]") — `lib/inception.sh:325-337`. The greenfield onboarding inception
template emits neither the marker nor matching wording for its "Go/no-go
decision recorded" AC. The decide gate ticks-then-counts
(`lib/inception.sh:519-526`); the unmarked self-referential AC never ticks, so
the count is always ≥1 and decide aborts.

**Severity rationale.** Every new consumer project's *foundational* inception is
undecidable on a clean install — and because it can't be decided, onboarding
never completes, so the F5 onboarding gate stays permanently engaged. F6
manufactures the deadlock that F5 then enforces.

**Requested fix (any one).**
1. In the greenfield onboarding inception template emitted by `fw init`, add
   `<!-- @auto-tick-on-decide -->` above each ceremonial agent AC (bring it in
   line with `.tasks/templates/inception.md`, which already has the markers); **or**
2. add the "Go/no-go decision recorded" wording to `AGENT_PATTERNS`; **or**
3. drop the self-referential AC entirely — `fw inception decide` *is* that AC,
   so listing it as a precondition is incoherent.

**Workaround applied in this project:** added the marker to T-002's AC manually
so the operator can record the decision.

## Suggested upstream task breakdown

- **bug (priority):** F6 greenfield onboarding inception undecidable (add
  auto-tick markers to the `fw init` template / drop the self-referential AC).
- **task (priority):** F5 onboarding-gate exemption for defect/upstream tasks.
- **bug:** F1 CSRF 403 recoverability on the approvals surface.
- **bug:** F2 vendor ships orchestrator-mcp baseline (mirrors consumer T-006).
- **bug:** F3 seed `patterns.yaml` field rename (mirrors consumer T-007).
- **bug:** F4 vendor ships secret-scan scanner / hard-fail on missing.

One task per item (one bug = one task). **F6 + F5 first** — together they are the
init deadlock: F6 makes the foundational inception undecidable, and F5 then
prevents recording any other failure while onboarding is (permanently) stuck.
Fixing the pair restores a clean bootstrap for every consumer project.
