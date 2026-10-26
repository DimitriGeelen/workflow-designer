---
id: T-1281
name: "Upgrade AEF be.8 -> v1.8.15-be.9 or later (batched): T-4689 runtime ignores, T-4690/T-4694 episodic not dirtied, T-4691/T-4692 upgrade summary, T-4693 watchtower current"
description: >
  AEF cut v1.8.15-be.9 at e9fb67bc9 (msg 710fe81b) while 832 was mid-suite on be.8. None of its fixes blocks 832, so it is batched with whatever tag is newest when this task starts, instead of a fourth operator upgrade run in one day. Same path as T-1280 (job 081). After upgrading, run fw git install-hooks (AEF's note for T-4690) and check our three pre-commit gates survive it.

status: captured
workflow_type: build
owner: agent
horizon: next
tags: [upgrade, framework]
components: []
related_tasks: []
# write_set:                      # T-3512: optional — globs (relative to PROJECT_ROOT)
#                                 # naming the files this task intends to write. Declared
#                                 # at CAPTURE, unlike components: which the framework
#                                 # resolves from git history at close. Feeds TWO things:
#                                 #   1. `fw write-set check T-A T-B` — without it the
#                                 #      comparison has nothing to compare and every real
#                                 #      pair exits 2 (undecidable). 0 of 3032 tasks
#                                 #      declared it, so that gate has never had an input.
#                                 #   2. BVP blast_radius before close — the 0.6-weighted
#                                 #      cost term, unavailable for 85% of rankable tasks
#                                 #      because components: only exists once the task is
#                                 #      finished (T-3471).
#                                 # Example: write_set: ["lib/bvp.sh", "tests/unit/t*_bvp*"]
#                                 # An EMPTY list is a real declaration ("writes nothing"),
#                                 # which is not the same as omitting the field. Omitted
#                                 # means unknown, and unknown must never score as cheap.
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-1281` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-10-23T13:55:00Z
last_update: 2026-10-23T13:55:00Z
date_finished: null
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-1281: Upgrade AEF be.8 -> v1.8.15-be.9 or later (batched): T-4689 runtime ignores, T-4690/T-4694 episodic not dirtied, T-4691/T-4692 upgrade summary, T-4693 watchtower current

## Context

Tags to batch (take the newest when this starts):
- **be.9** e9fb67bc9 (msg 710fe81b): T-4689-T-4694. Run `fw git install-hooks` afterwards (T-4690), and check that
  our three pre-commit gates survive.
- **be.10** e82e3d9a7 (msg 3bb22588):
  - T-4699/T-4700: the session-silent-scanner stays inside this project and rotates its log;
  - T-4697: the upgrade's "files to commit" list names only the files it wrote;
  - T-4695: cron outputs are committed or untracked;
  - T-4696: bats refuses a TMPDIR inside the repo, which matches our 2026-10-23 Chromium socket lesson.
  Open: T-4701. 832 tracks no `.session-silent-scanner.log` (checked 2026-10-23), so nothing needs untracking.
- **be.11** 42086fee3 (msg 7decaad1):
  - T-4704/T-4705: the upgrade's next steps and files-to-commit list;
  - T-4707: the printed close-commit works with focus cleared;
  - T-4708: doctor accepts `[ … ] || exec` hooks;
  - T-4706: Watchtower runs in its own systemd scope, with a 5-minute keep-alive cron that restarts it and records
    outages.
  After upgrading, run `fw cron install` as an OPERATOR job step (it writes `/etc/cron.d`) and `fw git install-hooks`;
  check that our three pre-commit gates survive both.
- **be.12** 4f906e6a3 (msg f0ecc89b):
  - T-4712: the files-to-commit list includes vendored files left dirty by an earlier upgrade;
  - T-4710: the close hint names `.tasks/active/<file>` only when tracked;
  - T-4703: release dirs are pruned, and doctor WARNs on a large `.context/scratch`;
  - T-4709/T-4713: fixes.
  AEF says the be.11 Watchtower keep-alive is NOT seeded to consumers until their T-4711, so `fw cron install` may add
  nothing yet. Check what it adds before running it.
- **be.13** c9ec9459e (msg 2828c473): T-4714. claude-fw's duplicate-conversation guard no longer counts the Claude
  Code background daemon as the conversation holder, so a resume after the session stops works. This matters for the
  operator's pending relaunch (`claude-fw` + `/resume`, which clears T-1275's identity FAIL). If the relaunch on be.8
  is refused as a duplicate, take this batch first, then relaunch.
- **be.14** 965dbcdc5 (msg b158a34d): T-4711. The Watchtower keep-alive and `watchtower.sh start/restart` defer to a
  systemd-managed Watchtower. A new key, `WATCHTOWER_ENSURE` (default 1; `fw config set WATCHTOWER_ENSURE 0` opts a
  project out). The keep-alive is still not seeded to consumers. 832's Watchtower is started by `fw watchtower
  restart`, not by a systemd unit, so check after the batch that restart still works here.
- **be.15** 31afaf383 (msg 57627423):
  - T-4717: the files-to-commit helper runs beside the upgrade code;
  - T-4716/T-4718: Watchtower `/designer` opens 832's designer at `/designer/app?browse=1`, with one Designer nav
    entry;
  - T-4715: the old card list gets thumbnails.
  This changes what OUR Watchtower's `/designer` shows once we take the batch: it goes to the designer's project
  browser, which needs designer 0.26.0 for the browser to open on load. Take the batch after 0.26.0 is pinned
  (T-1283).
- **0.26.0 pinned** (2026-10-24, AEF T-4732, commit 83ca46345; msg a08bd2c3): `_t1187-aef-pin-lag.sh` reads CURRENT. The
  precondition above is met.
- **be.16** ae71b4f0c (msg 5d467553):
  - T-4723: the upgrade file-list snapshot stays bounded on huge trees;
  - T-4724: the file list (or its reason line) prints under "N change(s) applied";
  - T-4733: the budget gauge decodes a transcript as strict UTF-8 under any locale;
  - T-4732: the designer 0.26.0 pin;
  - T-4725: test-only.
- **be.17** 165039bb4 (msg d40f0435):
  - T-4719: the close hint pushes `HEAD` to the upstream (or the only remote, origin, or the first remote), and leaves
    the push out when there is no remote;
  - T-4720: `fw vendor` and `fw upgrade` write only files whose content changed (a no-op re-vendor leaves `web/` mtimes
    alone). Check after the batch that our 37 re-applied local fixes still land, since they rely on a rewrite;
  - T-4726: the inception review hint takes the decide verb from the Recommendation.
- **After be.17** (AEF notice msg 0d60e494, 2026-10-25, going offline): five v1.8.15 release blockers (AEF T-4744..T-4748)
  are fixed on AEF's bleeding-edge but in no be tag yet; the v1.8.15 master release waits on AEF's operator. Prefer the tag
  that carries them (be.18 or v1.8.15) over be.17 for this batch.
- **be.27** eea53bb06 (msg 465d0f7b): carries BOTH of 832's 2026-10-26 reports: T-4777 (update-task.sh close-path git
  writes only when PROJECT_ROOT is the top of its own repo; 832 T-1313 nested-sandbox staging) and T-4779 (stale-review
  ignores release-artifact dist/ copies and content-identical paths; a withdrawn tick prints WITHDRAWN:; 832's T-1304/
  T-1301/T-1302 withdrawals). Also T-4778 (reviewer auto-tick needs positive evidence), T-4775/T-4776 (dispatch claude
  path, watchdog TERM->KILL), T-4774 (arc-focus age warning), T-4782 (hook-script quoting lint), T-4780 (designer 0.29.0).
  be.26 53f7dd171 (msg cf93f55a): T-4773 stale replayed doorbell flagged. **Newest at this note; the upgrade target.**
- **be.25** 2ffe3a27e (msg 75880fb7): T-4768 `fw inception decide` commits the Human-tick provenance row with the decision;
  T-4769 the ticks audit names an uncommitted provenance row. **Reconcile with 832's rule** "the agent never `git add`s
  `.context/reviews/*.jsonl`": after this upgrade the framework itself commits that row on a decide (an operator action),
  which is consistent; check our pre-commit/pathspec guards do not refuse it. Newest at this note.
- **be.24** 43de42eae (msg eab22ef6): T-4766 (`fw sidecar waiting` no longer lists consults the retry ladder closed),
  T-4767 (designer 0.28.0 pinned). Newest at this note.
- **be.23** 6cf7977aa (msg 25e38e25): T-4757 `fw sidecar settle-sent <client_msg_id> --reason` settles one's own
  outstanding consult (useful for our long-unanswered greenfield sends); T-4752 worker-contract conformance mapping.
  Newest at this note.
- **be.22** 7a64947c5 (msg b82385f8): T-4762/T-4763 (shell-write guard: backticks in single quotes, unparsable
  substitutions refused), T-4756/T-4754, T-4764 (designer 0.27.0 pinned), nightly-caught regressions T-4759..T-4761,
  T-4765. Newest at this note.
- **be.21** c8a660297 (msg 38ebeb12; be.20 never published): T-4753 (sidecar/receiver start|stop refuse an inherited
  PROJECT_ROOT naming another project), suite health T-4640..T-4646 (fw_self_test 606 s to 140 s). Newest at this note.
- **be.19** ec1bdf64a (msg 139f4895, 2026-10-25): was the target (be.18 + T-4698 self-deferral gate ignores
  other projects' task ids; T-4701 fw upgrade lists still-tracked runtime files with the exact `git rm --cached`, never
  untracks silently; T-4721 reference launcher install/launcher/aef-start.sh; T-4722 claude-fw / fw termlink find the hub
  runtime dir when TERMLINK_RUNTIME_DIR is unset (relevant to our TermLink identity FAIL); T-4751
  BOUNDARY_EXTRA_READ_PATHS). Take the latest tag at job time.
- **be.18** 5259a14be (msg 8769c438, 2026-10-25): carries the five blockers (T-4744..T-4748),
  plus T-4727 (decide warns when the verdict differs from the Recommendation), T-4729/T-4730/T-4731 (dispatch gate per
  session, `fw termlink` subcommands answer --help, boundary allows ~/.termlink), T-4734, T-4736 (superseded designer
  builds pruned at the consumer root), T-4738 (CLOSE_HINT_PUSH=0), T-4740 (vendor rewrites the designer build only when
  changed), T-4741, T-4742/T-4749 (Watchtower Anthropic provider), T-4750. Check after the batch: T-4736/T-4740 touch the
  designer build AEF vendors into consumers (our own dist/ is not theirs, but look).
- **Before this batch's job:** T-1298 changed the rehearsal (lock, `--git-dir`, config in the compare). This job's dry-run is
  the first real job rehearsed on it, and also T-1286 AC4.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] [First criterion]
- [ ] [Second criterion]

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-1281`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-1281 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

<!--
  Render-touching build tasks (web/templates, web/static, web/blueprints, web/shared.py,
  web/app.py …) add a section headed "Visual Verification" (level-2 heading) after
  Verification, with one checklist table — the check-visual-verification gate reads it
  at commit time (T-4213; T-4202 GO):

    | state | control | 1024 | 1440 | 1920 | note |
    |-------|---------|------|------|------|------|
    | toolbar | Load | ok | ok | ok | |

  Cells: ok / clipped / hidden / overlap / unreachable (non-ok needs a note). Each
  listed state needs screenshots at every UX_SHOT_WIDTHS width:
  fw ux shots <T-ID> <state>=<URL>. This comment is inert: the gate ignores it.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
# Build/refactor/decommission tasks with NO command here are refused. If nothing can be
# run, add the line `# verification: none — <why nothing can be run>`; it is serviced
# (queued for review: add a check / other evidence / accept). See docs/reports/T-4024-servicing-loop.md.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.
#
# Vendored-path hint (T-3236, T-4419): if you edited bin/fw, lib/, agents/, policy/,
# web/, tools/ or .tasks/templates/, run `bin/fw vendor self` and add
#     bin/fw vendor self --check --task T-1281X
# (your own task id). It checks only the files your commits changed, so another
# worker's uncommitted edit does not block your close; that drift is listed as
# "in flight, not this task". The whole-tree `--check` stays for audit/pre-push.

## RCA

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
-->

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-1281 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-10-23T13:55:00Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-1281-upgrade-aef-be8---v1815-be9-or-later-bat.md
- **Context:** Initial task creation
