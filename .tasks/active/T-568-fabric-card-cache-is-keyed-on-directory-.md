---
id: T-568
name: "Fabric card cache is keyed on directory mtime, so every edit to a card is invisible to Watchtower"
description: >
  Watchtower's _load_components() caches component cards on os.stat(COMP_DIR).st_mtime. POSIX bumps a directory's mtime on entry create/delete/rename, not on a write to a file already inside it, so 'fw fabric register' invalidates and 'fw fabric enrich' — which our own audit WARN actively instructs operators to run — never does. The page then serves the stale card for the life of the process at HTTP 200 with no signal. Reported by 001-CashWeb-Lightspeed-Ecwid-integration with a ten-second reproduction; confirmed by reading our vendored copy at .agentic-framework/web/blueprints/fabric.py:33.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-20T12:40:20Z
last_update: 2026-08-20T12:40:20Z
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

# T-568: Fabric card cache is keyed on directory mtime, so every edit to a card is invisible to Watchtower

## Context

Reported by **001-CashWeb-Lightspeed-Ecwid-integration** (agent-chat-arc, thread T-064,
2026-08-20) as the first of two Watchtower findings, and rated by them as their highest
priority — above the `note` rendering ask they have been waiting on for longer. Their
reproduction, which they ran rather than reasoned: the card YAML on disk said
`subsystem: designer-carrier` with a full purpose while `/fabric/<id>` rendered `unknown`
and "TODO: describe what this component does" across repeated fetches; `touch` on the
`.fabric/components` **directory** — nothing else changed — and the correct content
appeared on the very next request.

Confirmed in our own vendored copy by reading, before any test:
`.agentic-framework/web/blueprints/fabric.py:33` keys `_comp_cache` on
`os.stat(COMP_DIR).st_mtime`. POSIX bumps a directory's mtime when an entry is created,
deleted or renamed — **not** when a file already inside it is written. So the two fabric
verbs split cleanly:

- `fw fabric register <path>` creates a card file → directory mtime moves → cache
  invalidates → the page is correct. This is the path anyone testing the feature takes
  first, which is why the defect reads as "works".
- `fw fabric enrich` rewrites cards **in place** → directory mtime is untouched → the
  cache never invalidates → the page serves the pre-enrichment card for the entire life
  of the server process, HTTP 200, no warning, no log line.

The second bullet is the one that stings, and it is ours, not theirs: our audit emits
`[WARN] Fabric: 42/65 cards have no edges — Mitigation: Run: fw fabric enrich` on **every
run**, and has done for eleven consecutive audits. An operator who obeys our own priority
action lands exactly on the invisible half of this bug. Their words: it "cost us a wrong
diagnosis" — they concluded Watchtower was serving a different checkout and only found
the real cause on the second pass.

This is the week's shape again, from the outside this time: **the failure renders as
health.** A stale card is not a broken page. It is a confident, well-formatted,
HTTP-200 answer about the shape of the codebase that happens to be out of date, and
nothing in the response distinguishes it from a fresh one.

The file is vendored framework (G-008): fixed here in-tree, declared in
`.vendor-divergence.yaml` as `upstream: fix` with GENERIC debt, and reported to AEF —
Watchtower is theirs, every consumer project ships this file, and every one of them has
this bug.

## Acceptance Criteria

### Agent
- [x] `_load_components()` invalidates on an **in-place edit** to a card while the
      directory mtime is unchanged — the case the shipping key cannot see
- [x] The new key still covers the three cases the old one did get right: create,
      delete, and **rename** (a rename moves neither the file's mtime nor its content,
      so a content-only key would regress what the directory key handled)
- [x] The reproduction is a test, not a claim: a mutant arm restores the directory-mtime
      key and the test must go **red** on it. Without that arm, "the cache invalidates"
      is also what a cache that never caches reports
- [x] Caching is still real — a probe asserts the card files are **not** re-parsed when
      nothing changed, so the fix is not "delete the cache and call it correct" (PL-220:
      a repair must not convert the defect into a quieter one)
- [x] The LIVE dashboard reflects an in-place edit, not merely the loader in isolation
      (PL-148: the wiring must be asserted by something other than the instrument)
- [x] Teeth AND the live probe wired into `tests/run-bridge-tests.sh`; the unwired-guard
      ratchet returns to its baseline rather than being re-baselined; suite floor 118 → 121
- [x] Divergence declared for `.agentic-framework/web/blueprints/fabric.py`; the
      declaration checker stays green
- [x] Reported upstream to AEF on `framework:pickup`, and answered to CashWeb on
      agent-chat-arc thread T-064 with a yes/no/not-soon on all three of their items

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
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

bash tools/_t568-fabric-card-cache-teeth.sh > /tmp/.t568-teeth 2>&1 && grep -q "4/4 teeth legs passed" /tmp/.t568-teeth
python3 tools/_t568-live-card-visibility-probe.py > /tmp/.t568-live 2>&1 && grep -q "PASS: an in-place card edit is visible" /tmp/.t568-live
grep -qF "digest.update(os.path.basename(path).encode(" .agentic-framework/web/blueprints/fabric.py
grep -qF "digest.update(raw)" .agentic-framework/web/blueprints/fabric.py
python3 -c "import sys; sys.path.insert(0,'.agentic-framework'); import web.blueprints.fabric as f; sys.exit(0 if len(f._load_components()) >= 60 and f._comp_cache['key'] is not None else 1)"
python3 tools/_t517-vendor-divergence.py > /tmp/.t568-vendor 2>&1 && grep -q "every diverged path is declared" /tmp/.t568-vendor
bash tests/run-bridge-tests.sh > /tmp/.t568-suite 2>&1 && python3 -c "import re,sys; m=re.search(r'(\d+) passed, 0 failed', open('/tmp/.t568-suite').read()); sys.exit(0 if m and int(m.group(1)) >= 121 else 1)"

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom.** `/fabric/component/<id>` renders a component card that no longer matches the
YAML on disk — `subsystem: unknown`, "TODO: describe what this component does" — and keeps
rendering it for the life of the server process. HTTP 200, no warning, no log line.
Reported by 001-CashWeb-Lightspeed-Ecwid-integration; reproduced here against our own
running Watchtower at `http://192.168.10.107:3013` before anything was changed.

**Root cause.** `_load_components()` keyed its cache on `os.stat(COMP_DIR).st_mtime` —
the mtime of the **directory**, while the data being cached is the **contents of the files
inside it**. POSIX moves a directory's mtime when an entry is created, deleted or renamed,
and not when a file already inside it is written. Measured here rather than recalled:
in-place edit → dir mtime unchanged; create, delete and rename → changed. So the key was
correct for exactly the operations that change the *set* of cards and blind to the one that
changes their *content*.

**Why structurally allowed.** Three things had to line up, and they did:

1. *The first thing anyone does works.* `fw fabric register` creates a file, so the very
   first test of the feature — register a card, look at the page — invalidates correctly.
   The blind path is `fw fabric enrich`, which rewrites in place, and nobody reaches for
   enrich until they already trust the page.
2. *The framework routes operators straight at the blind path.* Our audit has emitted
   `[WARN] Fabric: 42/65 cards have no edges — Mitigation: Run: fw fabric enrich` on every
   run for eleven consecutive audits, and prints it under "PRIORITY ACTIONS". Following our
   own advice is what exposes the defect.
3. *Staleness has no failure mode.* This is the week's shape for the fourth time — T-560,
   T-561, T-567, now T-568 — **the failure renders as health**. A stale card is a
   confident, well-formatted, HTTP-200 answer about the shape of the codebase. There is no
   exception, no red, and nothing in the response that distinguishes it from a fresh one,
   so the only way to notice is to already know the answer and disagree with the page. That
   is what happened to CashWeb, and it cost them a wrong diagnosis first: they concluded
   Watchtower was serving a different checkout, which is a *reasonable* inference from the
   evidence available.

**Prevention** (distinct from the fix):

- `tools/_t568-fabric-card-cache-teeth.sh` wired into the gating suite, with **mutant A =
  the shipping code**. Regressing this file to the directory-mtime key now reddens the
  suite. Each of the three mutants must redden exactly one leg, so a probe that has
  decayed into failing on everything cannot be mistaken for teeth.
- `tools/_t568-live-card-visibility-probe.py` asserts the property at HTTP level against
  the running dashboard, because a correct loader the live process never picked up is
  still a stale page (PL-148).
- The sibling caches were checked rather than assumed (PL-214): `web/shared.py:498`
  (`mtime_cached_get`) and `web/blueprints/costs.py:141` key a *file's* cache on *that
  file's* own stat, which is correct in kind. `fabric.py` was the only site keying a
  collection on a directory, so this is a singular defect and not a class-wide repair —
  a conclusion that had to be measured before the fix could be scoped to one site.

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

## Decisions

### 2026-08-20 — The unwired-guard ratchet fired mid-task; wired, not re-baselined

- **Chose:** give both orphaned checkers a live caller in `tests/run-bridge-tests.sh`.
- **Why:** this task's first full suite run came back 118 passed / **1 failed**, and the
  failure was not T-568's — the ratchet had grown by one because
  `tools/_t567-episodic-parse-check.py` lost its last live caller when T-567 moved from
  `active/` to `completed/`. Its only reference had been T-567's own `## Verification`
  block. That is a general trap, not a one-off: **a tool called only from a task's
  Verification block becomes unwired the moment that task completes**, and it was about to
  happen a second time to `_t568-live-card-visibility-probe.py` the instant this task
  closed. The census's own message says a new entry is a finding to report and must not be
  silently re-baselined, and it is right — re-baselining would have recorded the loss as
  the new normal.
- **Rejected:** re-baselining (forbidden by the instrument, and it converts a finding into
  a floor); leaving the suite red and completing under `--skip-verification` (that gate
  exists for exactly this moment); deferring to a follow-up task (the second orphan would
  have landed in the same breath as the deferral).
- **Note:** this does NOT close G-040. That gap closes when the **cron audit** parses the
  episodic corpus unattended; a commit-time suite leg is a different instrument on a
  different schedule. The gap stays open and honest.

### 2026-08-20 — Content digest, not the suggested (count, max-mtime) pair

- **Chose:** key the cache on a sha256 over each card's **filename and bytes**, reading
  each file once and using those same bytes for both the digest and the parse.
- **Why:** the reporter's suggested key — `(count, max-mtime)` — fixes the reported case
  but keeps an aliasing window, and the window is not brief. Measured on this filesystem:
  five back-to-back writes produced `st_mtime_ns` deltas of **exactly 0**, so the kernel's
  file-time clock is coarser than the gap between a write and the request that follows it.
  An edit that lands inside the current tick leaves the key unchanged — and a key that
  never changes again is never re-read, so that edit is invisible *permanently*, not until
  the next second. Cost was measured before the choice, not after: 65 cards / 61,598 bytes
  — read+sha256 **1.36 ms**, `yaml.safe_load` **98.58 ms**. The digest costs 1.4% of the
  parse it avoids, so the cache keeps its entire point while becoming exact.
- **Rejected:**
  - *(count, max-mtime)* — see above. Cheaper by ~1.1 ms; wrong in a way that cannot be
    observed after the fact.
  - *Drop the cache* — correct on every request and 72× the cost. This is mutant B, and
    it is in the teeth precisely because it is the tempting one: it would have passed any
    test that only asked "is the page fresh?" (PL-220 — a repair must not convert the
    defect into a quieter one).
  - *Digest of bytes only, no filename* — reads as a simplification and silently loses
    the rename case, which the old directory key actually handled. This is mutant C.
  - *A TTL backstop* — bounds staleness instead of eliminating it, and adds a second knob
    that has to be right. Not needed once the key is exact.

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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-20T12:40:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-568-fabric-card-cache-is-keyed-on-directory-.md
- **Context:** Initial task creation
