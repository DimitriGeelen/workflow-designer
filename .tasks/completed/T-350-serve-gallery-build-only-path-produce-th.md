---
id: T-350
name: "serve-gallery build-only path: produce the serve root without binding a port
  (G-015 remedy leg 2)"
description: >
  serve-gallery build-only path: produce the serve root without binding a port (G-015
  remedy leg 2)

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: ["arc:designer-authoring-surface", "tooling", "G-015"]
components: []
related_tasks: ["T-093", "T-102", "T-105", "T-231", "T-252", "T-253", "T-309", "T-351"]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T21:56:07Z
last_update: '2026-08-16T12:33:52Z'
date_finished: 2026-08-02T22:27:39Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:52Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-350: serve-gallery build-only path: produce the serve root without binding a port (G-015 remedy leg 2)

## Context

G-015's decision trigger has two legs. Leg 1 — narrowing the 75 `diff src/… build/gallery/…`
verification lines — is a **convention change across other owners' tasks** and stays with the
operator. Leg 2 is mechanical and ours: `tools/serve-gallery.sh` had **no build-only path**. It
does a recursive delete of `$OUT`, reassembles, then unconditionally binds a port, starts
`gallery-serve.py` and refuses to report success until the running server answers `/api/health`.
So the only sanctioned way to refresh the serve root coupled a per-task verification line to
**starting a server** — and its default port `:8834` is retired behind ufw (T-253), which the
agent must not change. This task removes that coupling and nothing else.

**What this task deliberately does NOT do:** it does not narrow anyone's verification lines, does
not rebuild-and-declare-victory on G-015, and does not flip G-015's status. Rebuilding the gallery
is not closure — the diff line goes red again on the next edit to `src`, which is the property
being reported.

**The hazard this must avoid** is named in G-015 itself: *"hand-copying only designer.html would
green all 75 lines while leaving build/gallery/rendered/ stale — a green that asserts less than it
says."* A build-only path that is not a **full** rebuild would manufacture exactly that false
green, at scale, for 75 gates at once. AC2 exists to make that impossible.

## Acceptance Criteria

### Agent
- [x] **AC1 — build-only starts no server.** `tools/serve-gallery.sh --build-only` exits 0 and
      prints no `LIVE on :` line. The flag is positional-order-independent: `--build-only PORT`
      and `PORT --build-only` behave identically, and bare `--build-only` still works without a
      port argument. Both conditions are proven red by teeth leg (a).
      **AMENDED before ticking:** originally also required "leaves the listener set on the target
      port exactly as it found it". A before/after listener comparison can only catch a server
      that OUTLIVES the run, and nothing this script backgrounds does — measured in isolation
      (inner shell sees the listener, outer sees none; `timeout --foreground` identical). Teeth
      leg (f) was written specifically to make that check fire and could not. So the check would
      have reported "unchanged" for a subject that had just started a server: green by
      construction. The **check was removed from the probe**, with the measurement recorded there
      and here, rather than the leg being quietly dropped to leave a passing assertion behind.
- [x] **AC2 — the build-only root is COMPLETE, not designer-only.** After a build-only run, in the
      assembled root: `designer.html` is byte-identical to `src/aef-workflow-designer.html`; the
      count of `rendered/*.bpmn` equals the corpus count (`examples/aef-processes/rendered/*.bpmn`
      + `examples/app-processes/rendered/*.bpmn`); and `index.html` carries one
      `<li><a href="designer.html?load=rendered/…">` entry per rendered map. This is the criterion
      that separates the remedy from the false green G-015 warns about.
      **AMENDED before ticking:** originally written against the literal `build/gallery/`. The
      probe runs against a throwaway `GALLERY_DIR` instead, because rebuilding the real serve root
      as a *side effect of a test* would flip all 75 G-015 verification lines green in passing —
      manufacturing exactly the "closed because we rebuilt it" reading the gap explicitly rejects.
      Refreshing the real serve root is a separate, visible decision, not test fallout.
- [x] **AC3 — the serve path is unchanged, and the probe cleans up after itself.** Invoked with a
      port and no flag, the script still assembles, binds, passes the T-231 `/api/health`
      behaviour probe and prints `LIVE on :PORT`. Proven against a port discovered free at runtime
      (never a literal). The probe then stops that server and **asserts the port was released** —
      added after the first revision leaked a python process per run, invisibly, because nothing
      checked. See T-351 for why SIGINT could never have worked.
- [x] **AC4 — an unknown option is refused, not swallowed as a port.** `--build-onlyy` (and any
      other `-`-prefixed token) exits non-zero with a message that says `unknown option` **and**
      names the token. Both halves are required: with the guard removed the typo lands in the PORT
      slot and the resulting bind failure echoes the token back, so a check that looked only for
      the token would pass over the broken form.
- [x] **AC5 — the recursive delete has a destructive guard.** With `GALLERY_DIR` set to `/` or the
      repo root, the script refuses and exits non-zero **before** deleting anything, and the repo
      tree is intact afterwards. The empty case is **not** in the executed population and the probe
      says so: `${GALLERY_DIR:-…}` substitutes the default on empty, so that guard arm is
      unreachable by construction; the probe asserts the `:-` mechanism instead of pretending to
      test a refusal that cannot occur.
- [x] **AC6 — every check above is proven able to fail, by mutation, and each failure NAMES its own
      condition** (a leg that asserts only `rc != 0` banks syntax errors as proof — T-338 leg (d),
      T-343 leg (d), T-348 leg (c)). The four legs, described by **what they actually emit**, not
      by what they were planned to emit: (a) build-only falls through to the serve path → AC1 red
      with *"printed a 'LIVE on :' line — it started a server instead of stopping after the
      build"*; (b) build copies one corpus map → AC2 red with *"carries 1 rendered maps but the
      corpus has 25 — the build is partial"*; (c) option arm removed → AC4 red with *"exited 124
      but the message does not say 'unknown option'"* (the mistyped flag becomes the PORT, the
      bind hangs, and the discriminating fact is that no refusal happened — **not** "was
      ACCEPTED", which is what this AC said before the harness contradicted it); (d) `$OUT` guard
      removed → AC5 red with *"was ACCEPTED (exit 0) — the script would recursively delete that
      path"*. Legs (a) and (c) were first specified with predicted strings and reported RED FOR
      THE WRONG REASON until corrected against emitted text.
- [x] **AC7 — the teeth harness refuses to execute an armed mutant, and that refusal is itself
      proven.** No mutant runs unless *guard intact OR delete stubbed* holds; leg (e) constructs a
      mutant that violates it and requires the precondition to refuse. This exists because the
      first version of leg (d) **deleted this repository** — see `## RCA`. A safety measure that is
      never verified to have applied is not a safety measure, so the check that enforces it needs
      teeth of its own.
- [x] **AC8 — this task's own `## Verification` block commits no G-015 subject error.** It contains
      no `diff`/`cmp` of `src/` against `build/gallery/`, and no hard-coded port literal. The
      remedy task must not carry the defect it remedies.

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

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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
#
# G-015 NOTE (AC8): every line below asserts a property of THIS task's deliverable and
# re-derives its own inputs. No line diffs src/ against build/gallery/ and no line names
# a port — those are the two recorded carriers of the subject error this task remedies,
# and the last line enforces their absence mechanically rather than by my care.
bash tools/_t350-build-only-probe.sh
bash tools/_t350-teeth.sh
bash -n tools/serve-gallery.sh
out=$(bash tools/serve-gallery.sh --help 2>&1); echo "$out" | grep -q -- "--build-only"
python3 tools/_t350-verification-hygiene.py T-350

## RCA

Not a bug-class task by title, but this section is filled because building it destroyed the
repository, and that belongs on the record where the artifact lives rather than in a session log.

**Symptom.** Teeth leg (d) ran and `/opt/832-Workflow-designer` was left containing one empty
directory. `git`, `src/`, `.agentic-framework/`, `.tasks/`, `.context/` — all gone.

**Root cause.** Leg (d) removes the new `GALLERY_DIR` refusal guard so the probe can observe its
absence, and stubs the recursive delete so that absence is not dangerous. The stub was
`s.replace('rm -rf "$OUT"', <stub>, 1)` — replace **first** occurrence. The first occurrence in
the file was inside the comment I had written three lines above the guard, quoting the command in
order to explain what the guard protects. The comment was stubbed; the live command survived. The
probe then invoked that mutant with `GALLERY_DIR=$ROOT`, which is precisely the input the removed
guard existed to refuse.

**Why structurally allowed.** Nothing verified the safety measure had applied. The reasoning was
right — "remove the guard, but defang the delete" is the correct design for this leg — and it was
implemented with a text substitution whose success was assumed rather than asserted. This is the
same failure shape the whole arc has been cataloguing, pointed inward: a *check* that cannot fail
is a check that proves nothing, and a *safeguard* that is never confirmed to have landed is a
safeguard that protects nothing. The arc had five recorded instances of the first form and none of
the second, because until now no instrument here was destructive.

Two aggravating details worth naming, because they are the generalisable part:
1. **The comment quoting the dangerous command is what made the substitution ambiguous.** Prose
   about code sits in the same byte-space as code. `serve-gallery.sh` no longer quotes the command
   in its guard comment ("the recursive delete below"), and `assert_safe()` excludes comment lines
   from its scan, so prose can neither satisfy nor trip the check.
2. **A destructive teeth leg is categorically different from a non-destructive one**, and I treated
   it as just another leg. Every other mutation on this arc could at worst produce a wrong verdict.

**Prevention** (distinct from the fix): `_t350-teeth.sh` now enforces *guard intact OR delete
stubbed* before any mutant executes, stated as a disjunction so it does not spuriously abort the
legs that legitimately keep the delete; anchors are exact and a mutation that fails to apply
reports `LEG BROKEN` instead of running; the start-of-line regex in `mut_d` cannot match a comment
and requires exactly one substitution (`n != 1` → abort); and **leg (e) proves the precondition
itself refuses an armed mutant**, so the safety check is not the one unverified thing in a harness
built to verify. Recovery was clean — origin had `041765c`, re-cloned in place, zero committed work
lost — which is itself only true because of the commit cadence rule (P-009).

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

### 2026-08-02 — the safety stub that was never checked
- **What changed:** teeth leg (d) deleted the repository. The stub meant to defang the recursive
  delete matched a comment quoting the command instead of the command, and nothing asserted it had
  landed. Full account in `## RCA`.
- **Plan impact:** AC7 added (the harness must refuse an armed mutant, and that refusal must
  itself be proven by leg (e)). `serve-gallery.sh`'s guard comment no longer quotes the command it
  guards, so prose and code stop sharing a byte-space.
- **Triggered:** re-clone from origin `041765c`; zero committed work lost. The arc's standing
  lesson generalises: it applies to safeguards, not only to checks.

### 2026-08-02 — SIGINT could never have worked
- **What changed:** the probe's own cleanup leaked a `gallery-serve.py` per run. `/proc/PID/status`
  shows `SigIgn` includes SIGINT — bash sets it to `SIG_IGN` for `&` children and python inherits
  it across `exec`. `serve-gallery.sh`'s trap forwards INT only, and its comment asserts the
  inverse of both facts.
- **Plan impact:** AC3 extended to assert the port is *released*, not merely that it was bound.
  A check that starts servers and never confirms their death is how five orphans from July
  accumulated on this host unnoticed.
- **Triggered:** T-351 filed (one bug, one task — different root cause, different fix).

### 2026-08-02 — two expected values written from the plan
- **What changed:** teeth legs (a) and (c) went red naming *correct* conditions that were not the
  substrings I had predicted when writing the harness. The harness reported RED FOR THE WRONG
  REASON, which is it working.
- **Plan impact:** substrings corrected against emitted text rather than intention, and the
  correction recorded in the file. Same defect as an AC ticked from the memory of the plan.
- **Triggered:** leg (f) added — leg (a) never exercised AC1's listener-delta check, leaving it
  unexercised and therefore indistinguishable from unable-to-fire.

### 2026-08-02 — the listener-delta check could not fire, so it left
- **What changed:** leg (f) was built to make AC1's listener-delta check fire — a mutant that
  binds the port and returns cleanly, no blocking, nothing for the timeout to catch. It still did
  not fire. Isolated outside the harness: nothing a script backgrounds survives its own exit under
  this invocation; the inner shell sees the listener and the outer sees none, unchanged by
  `timeout --foreground`. Two intermediate false starts on the way, both the same shape as the
  RCA one level down — the mutation applied *textually* and did nothing (a `python3 -c` whose
  source carried literal backslash-n, hidden by a `/dev/null` redirect), so the injected code was
  made to assert its own effect before the leg was believed.
- **Plan impact:** AC1 amended and the **check deleted from the probe**. A before/after listener
  comparison can only catch a server that outlives the run; here that is impossible, so it would
  have returned "unchanged" for a subject that had just started a server.
- **Triggered:** nothing further — the two conditions that do discriminate (`LIVE on :` line,
  non-return timeout) are proven red by leg (a). Recorded because deleting the leg and keeping the
  green check would have been the easy, wrong move: an inert assertion reads as coverage.

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

### 2026-08-02T21:56:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-350-serve-gallery-build-only-path-produce-th.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-7f88d784
- **Timestamp:** 2026-08-02T22:31:04Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-02T22:27:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
