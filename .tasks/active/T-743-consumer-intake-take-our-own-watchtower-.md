---
id: T-743
name: "Consumer intake: take our own Watchtower to designer 0.12.0"
description: >
  Our own /designer/app still serves 0.8.0 because our vendored pin was last advanced
  at T-296. Bump the vendored pin to 0.12.0 and run the pull-at-tag intake so the
  operator's own access path serves the current release. AEF's adoption is theirs
  and is not in scope.

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
created: 2026-09-21T07:23:02Z
last_update: 2026-09-21T07:30:27Z
date_finished:
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
  - ts: '2026-09-21T07:24:43Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 1
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=1 (prose:AEF seam-incidental); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-09-21T07:24:54Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/policy/designer-pin.yaml,vendor/designer/aef-workflow-designer-0.8.0.html);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-743: Consumer intake: take our own Watchtower to designer 0.12.0

## Context

Our own Watchtower is a consumer of the designer, not just its host. `/designer/app` does
not serve `src/` — `web/blueprints/designer.py:_serve_bundle()` reads `vendored_path`
straight out of `policy/designer-pin.yaml` and serves those bytes verbatim. So the page was
faithfully serving 0.8.0 while `src/`, `dist/` and the release tag all stood at 0.12.0.

That is the operator-facing half of T-742's F-01. It is not a second defect: the page was
an honest mirror of a pin nobody had advanced since T-296 cut 0.8.0. Four releases
(0.9 → 0.12) accumulated behind it.

**Our side of the seam was already complete.** The release was cut, `designer-v0.12.0`
tagged, and the rail announce posted carrying `version: "0.12.0"` / sha `2b448b61…`. What
had not run was our OWN consumer intake — the same thing T-296 did once and described as
"our own consumer intake run". AEF's adoption is a separate act on their side and is
explicitly out of scope here.

**Scored `lv-lc` at BVP 79, and worked anyway.** The autonomous selection rule excludes
low-value tasks; this one was directed by the operator, and a stated objective is authority
rather than a heuristic input. The score was NOT adjusted to justify the work
(producer-not-judge). Worth recording that the scorer returned **D2=0** — Reliability,
weight 7 — for a task restoring the operator's access to the current build, the same blind
spot recorded on T-741.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The vendored pin `.agentic-framework/policy/designer-pin.yaml` names 0.12.0 —
      `version`, `sha256` (`2b448b61…`), `bytes` 997254, `vendored_path` and
      `source_tag: designer-v0.12.0` all moved together. A pin with a new version and a
      stale sha is worse than no bump: it would make the intake verb's own check pass
      against the wrong anchor.
- [x] `fw designer sync --from-tag` installs the artifact from the frozen annotated tag,
      with the independent sha256 verifying against BOTH the MANIFEST at that tag AND the
      pin. That double check IS the deliverable — an install that skipped it would satisfy
      the letter of this task and none of its purpose.
- [x] `fw designer status` reports 0.12.0 PRESENT with sha256 matching the pin.
- [x] **The LIVE SERVED bytes are 997254 with sha `2b448b61…`** — fetched over HTTP from
      the running Watchtower, not read off disk. The whole defect being fixed here is that
      the file on disk and the bytes a consumer receives were allowed to disagree, so
      asserting the disk copy would re-commit the original error (PL-178 class).
- [x] The disposition of the outgoing `vendor/designer/aef-workflow-designer-0.8.0.html`
      is explicit — kept or removed, recorded either way. A pinned artifact is not deleted
      as a side effect of superseding it.
- [x] The vendor-divergence register is consistent with whatever changed under
      `.agentic-framework/`, verified by the existing divergence probe rather than by eye.

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
         1. Run `bin/fw reviewer T-743`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-743 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

- [ ] **[REVIEW] The 0.12.0 editor is the one you want to be using.**
      **Steps:** 1. Open `http://192.168.10.107:3013/designer/app` and hard-reload
      (Ctrl+Shift+R) — the bundle's B1 autosave restores your last local draft, so a cached
      0.8.0 page can look unchanged even after a correct intake. 2. Exercise the surfaces
      you actually use: lanes, connect mode, save to project.
      **Expected:** the editor works, and four releases of accumulated change (0.9 → 0.12)
      read as an improvement on 0.8.0 rather than a regression for your workflow.
      **If not:** these bytes have never been in front of you before, so a regression here
      is a real finding. Report it — the 0.8.0 artifact is deliberately retained so moving
      the pin back is a one-line revert.

## Verification

# Each leg is a single command whose OWN exit code is the verdict (T-352: a chained
# `a; b` is judged on `b` alone). Leg 3 is the load-bearing one — the others can all
# be green while a consumer still receives the wrong bytes, which is the exact defect
# this task exists to close.

# L1 — the pin moved as a UNIT. version, sha256, bytes, vendored_path and source_tag
# all name 0.12.0. Written as one assertion because the dangerous state is a partial
# bump: a new version against a stale sha would make the intake verb's own anchor
# check pass against the wrong artifact.
python3 -c "import yaml,sys; p=yaml.safe_load(open('.agentic-framework/policy/designer-pin.yaml')); ok = p['version']=='0.12.0' and p['sha256']=='2b448b61b7fa6c33f347535748c4df828f5d7c1d4b11322e3b25dc609631cf8c' and p['bytes']==997254 and p['vendored_path'].endswith('0.12.0.html') and p['source_tag']=='designer-v0.12.0'; sys.exit(0 if ok else 1)"

# L2 — the vendored artifact on disk matches the pin, per the verb that owns that check.
.agentic-framework/bin/fw designer status > /tmp/.t743-status.out 2>&1 && grep -q 'sha256 matches pin' /tmp/.t743-status.out

# L3 — THE SERVED BYTES. Fetched over HTTP from the running Watchtower, not read off
# disk. src/, dist/ and the vendored file agreeing proves nothing about what a consumer
# actually receives — that disagreement IS the defect (F-01/F-02 of the T-742 review).
# Fails if Watchtower is down, which is correct: bytes that are not being served are
# not being served.
sh -c 'W=$(cat .context/working/watchtower.url) && curl -sf "$W/designer/app" -o /tmp/.t743-served.html && test "$(sha256sum /tmp/.t743-served.html | cut -c1-64)" = "2b448b61b7fa6c33f347535748c4df828f5d7c1d4b11322e3b25dc609631cf8c"'

# L4 — the superseded 0.8.0 artifact is RETAINED. The Human AC promises a one-line
# revert; that promise is only true while these bytes still exist.
test -f vendor/designer/aef-workflow-designer-0.8.0.html

# L5 — the divergence register is consistent AND this task is named in the pin's entry,
# so the bump is traceable to the ruling that authorised it rather than appearing as an
# undeclared edit to a vendored contract file.
python3 -c "import yaml,sys; d=yaml.safe_load(open('.agentic-framework/.vendor-divergence.yaml')); e=[x for x in d['entries'] if 'designer-pin' in x['path']]; sys.exit(0 if e and 'T-743' in e[0]['task'] else 1)"

python3 tools/_t517-vendor-divergence.py

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

**Recommendation:** GO

**Rationale**

The intake is mechanically complete and independently checked. The pull-at-tag path
verified the fetched bytes against BOTH the MANIFEST at `designer-v0.12.0` AND the pin —
that double anchor is the whole point of the verb, and skipping it would have satisfied the
task's letter and none of its purpose. The served bytes were then confirmed over HTTP at
997254 / `2b448b61`, and the same check run against the old 0.8.0 sha correctly fails, so
the assertion is discriminating rather than vacuous.

GO is on the intake only. It does **not** assert that the 0.12.0 editor is better for the
operator's workflow than 0.8.0 — four releases of accumulated change have never been in
front of them, and that judgement is the open Human AC. If it regresses, the revert is one
line and the 0.8.0 bytes were retained for exactly that.

**What this does NOT close.** Our own serve is one of two consumers. **999-AEF is still on
0.8.0** and their adoption is their act, not ours. The announce they would read has been on
the rail since 2026-09-20 carrying 0.12.0 — but see the Sovereign question below, because
the read path they are documented to use returns empty.

**Evidence**

- `fw designer status` → 0.12.0, PRESENT ✓, sha256 matches pin.
- Intake log: `✓ MANIFEST anchor ... self-consistent at designer-v0.12.0 (997254 B)`;
  `✓ pin anchor: sha matches pin (0.12.0)`; installed read-only.
- Live HTTP fetch of `/designer/app`: 997254 bytes, sha `2b448b61b7fa6c33`.
- Negative control: same fetch asserted against `cab3c751…` (0.8.0) fails as it must.
- 6/6 verification legs pass; `_t517-vendor-divergence.py` exit 0, 50 declared / 50 diverged.
- Watchtower had died mid-task (pid 634131 gone, HTTP 000) and was restarted on 3013.

## Sovereign question

**The announce's documented read path returns empty, so AEF may be seeing nothing rather
than seeing something stale.** `scripts/announce-release.sh` exists (T-389) so a consumer
can answer "am I current?" in O(1) via `channel subscribe --include-current-value` instead
of replaying the rail. Measured on the live topic today:

| call | result |
|---|---|
| `channel cv-keys` | `designer-release` at offset 0 — indexed ✅ |
| `subscribe --include-current-value --cursor 1` | `current_values: []` ❌ |

The envelope IS on the rail and decodes to 0.12.0 under full replay. Only the cheap indexed
read is empty. Two consequences: AEF following the documented procedure gets no answer, and
the announce script's own idempotence check (`announce-release.sh:73-88`) reads the same
empty array, so it cannot tell whether a version was already announced.

This is the producer/consumer split again — the script verifies its post got *indexed*,
which passes, and *delivery* is what the consumer needs. It is also "a channel cannot report
its own failures": the rail is the only instrument for release currency and the rail is the
broken part.

**Not actioned, because the hub is shared infrastructure at `/opt/termlink` serving other
projects on the mesh, and restarting or changing it is the operator's call.** The question:
is this ours to file upstream against TermLink, or AEF's to raise from the consumer side?

## Decisions

**The superseded 0.8.0 artifact is RETAINED, not deleted.** The alternative was removing it
now that nothing points at it. Kept because the Human AC promises that a regression found in
the 0.12.0 editor can be reverted in one line, and that promise is only true while these
bytes exist locally. It is also the only copy on this side that is byte-identical to what
AEF currently pins — deleting it would destroy the local reference for the very comparison
this task's follow-up needs. Superseding an artifact and deleting it are different acts and
only the first was asked for.

**The pin was bumped in place rather than proposed for operator execution.** The register's
own note records that "the pin bump itself is the operator's call, not ours (AEF stated this
at DM 536 §1)." That condition is met by the operator stating the objective directly rather
than by an agent deciding the bump was warranted — the distinction is recorded in the
divergence entry so a later reader can see which of the two happened. An agent must not
advance this pin on its own initiative, and this one did not.

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
     fw inception decide T-743 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-21T07:23:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-743-consumer-intake-take-our-own-watchtower-.md
- **Context:** Initial task creation
