---
id: T-410
name: "Watchtower session signing key is committed to the tracked tree and invisible
  to the secret scanner"
description: >
  Watchtower session signing key is committed to the tracked tree and invisible to
  the secret scanner

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: [tools/_t410-secret-artifact-teeth.sh, 
      tools/tracked-secret-artifacts.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-09T11:24:36Z
last_update: '2026-08-16T12:33:28Z'
date_finished: 2026-08-09T11:36:19Z
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
  - ts: '2026-08-16T12:33:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 1
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=1 
      (body/components:context-fabric-incidental); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-410: Watchtower session signing key is committed to the tracked tree and invisible to the secret scanner

## Context

`.context/working/.fw-secret-key` is **tracked in git** and has been since `2b9c8ffa`
(2026-06-04, T-001), where it was swept in by a commit whose subject is
"Configure audit cron schedule and commit cron audit files". It is 64 bytes —
`secrets.token_hex(32)` — written by `_resolve_secret_key()`
(`.agentic-framework/web/app.py:39`).

It is the **live** signing key, not a stale artifact:

| checked | result |
|---|---|
| tracked? | yes — `git ls-files` lists it |
| `FW_SECRET_KEY` in Watchtower's env (pid 1341537)? | **not set** → resolver fell through to the file |
| live cookie | `Set-Cookie: fw_session_3000=…; HttpOnly; Path=/` |
| on-disk mode | `0664` — the code `chmod 0600`s it at generation; a git checkout re-creates it under umask |
| audit verdict | `[PASS] Secret scan: tracked tree clean` |

So the key that signs `fw_session_3000` and the CSRF token inside it is published to
every reader of this repository — `origin` (OneDev `192.168.10.201:6611`) and, per
D-701, the OneDev-side `PushRepository` mirror to GitHub.

What that key authorises, if the endpoint is reachable: Watchtower's mutating routes.
`.agentic-framework/docs/reports/T-2277-watchtower-csrf-pollution.md` enumerates them —
`/tasks/<id>/update` (status flips, **AC ticks**), `/inception/<id>/decide`,
`/gaps/<id>/close`, `/approvals/<id>/<action>`. That is the sovereignty surface: the
routes by which a human ratifies things. CSRF is the only thing standing in front of
them, and CSRF is a value signed with this key.

**On reachability.** I set out to leave this unasserted — T-253 established that
agent-side probes run inside the host and bypass inbound filtering, so a `curl` from here
proves nothing about the LAN, and ufw is the operator's boundary. But the rotation
restart answered it without being asked: `fw watchtower restart` printed

```
[firewall] Port 3000 already open.
```

`watchtower.sh` checks (and can open) a ufw rule for its own port. It reported the rule
already present and changed nothing — no ufw modification was made by me or on my
behalf. So :3000 is admitted from the LAN, and the exposure was **live, not theoretical**:
a published signing key in front of a reachable endpoint.

That is also why this is the reverse of T-253's finding rather than a repeat of it. There,
:8834 was advertised on the LAN and silently unreachable because no allow rule existed.
Here the allow rule exists, added by the framework's own start-up path. Same blind spot —
nobody was reading the ufw state as part of the picture — pointing the other way.

## Acceptance Criteria

### Agent
- [x] `.context/working/.fw-secret-key` no longer appears in `git ls-files` (removed from the index; history untouched — that is Tier 0 and belongs to the operator)
- [x] Both known key paths are ignored — `git check-ignore` resolves `.context/working/.fw-secret-key` and `.agentic-framework/.context/working/.fw-secret-key`, so neither can be re-added by a `git add -A`
- [x] The published key value is dead: the sha256 of the current on-disk key differs from `ef0fbe61…` (the value committed at `2b9c8ffa` and carried until this task), and the live Watchtower serves a cookie signed by the new value
- [x] `tools/tracked-secret-artifacts.py` exists and fails (rc=1) on a tracked file whose NAME marks it as key material, naming the file and the remedy
- [x] The scanner is vacuity-guarded (PL-084): rc=2 with a stated reason when the tracked population is empty, so a clean verdict is never a statement about nothing
- [x] `tools/_t410-secret-artifact-teeth.sh` is green on every leg, including a reciprocal control proving the live tree passes after the fix
- [x] `## RCA` names why the framework's own secret scanner structurally cannot see the framework's own generated key

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

- [ ] [REVIEW] Rule on the history rewrite — the old key stays readable in git history and on the GitHub mirror until you decide

  Untracking removes the key from the *index*, not from the ~2 months of commits that
  already carry it, and not from anything already cloned or mirrored. Rewriting that
  history (`git filter-repo`) plus the force-push it requires are **Tier 0**, and
  force-pushing a mirrored repo is not a call an agent may make.

  The rotation in this task is what makes the published value harmless: the key on
  disk is new, so the committed one signs nothing. A rewrite therefore buys tidiness
  and defence-in-depth, not active protection — which is why it is your call and not
  urgent.

  **Steps:**
  1. Decide whether the old value being readable in history matters to you. It is a
     Flask session key for a LAN dev tool, now rotated — not a vendor credential.
  2. If you want the history cleaned, that is a Tier 0 approval plus a coordinated
     force-push to OneDev with the mirror in mind (a rewritten master may need the
     mirror re-seeded).
  3. If you do not, tick this and the task closes with rotation as the remedy.

  **Expected:** a recorded decision either way — "rewrite" or "rotation is sufficient".

  **If not:** leave unticked; the task stays partial-complete and nothing regresses,
  since untrack + ignore + rotation are already in effect.

- [ ] [REVIEW] Rule on whether Watchtower should be LAN-reachable at all

  Not a question about whether the port is open — `fw watchtower restart` reported
  `[firewall] Port 3000 already open`, so it is. The question is whether it should be.

  `watchtower.sh` opens a ufw rule for its own port as part of starting up. That is a
  reasonable default for a dev tool on a trusted LAN, and it means the reachability of
  every Watchtower on this host is decided by a start-up script rather than by you. The
  routes behind it are the ones that tick ACs, decide inceptions, and close gaps.

  I have not touched ufw and am not proposing a command — this is your boundary.

  **Steps:**
  1. Decide whether Watchtower should bind/admit beyond loopback on this host.
  2. If not, the change is yours to make: a ufw rule, or binding the app to `127.0.0.1`
     and reaching it over SSH forwarding.
  3. If yes — reasonable on a trusted LAN — tick this; rotation already removed the
     part that made it exploitable from the repo.

  **Expected:** a recorded position on whether a start-up script should be deciding the
  network exposure of the sovereignty surface.

  **If not:** leave unticked. Nothing regresses; the key is rotated either way.

## Recommendation

**Recommendation:** GO — with both Human ACs genuinely open, and neither of them blocking.

**Rationale:** the exploitable part is already closed. The published key signs nothing:
it was rotated before it was untracked, which is the order that matters — untracking
alone produces a repo that looks clean and a key that still works. What remains for you
is not remediation, it is two rulings that are yours by right and not urgent:

1. whether the dead key's presence in ~2 months of history is worth a Tier 0 rewrite
   plus a force-push to a mirrored remote (my read: probably not — it is a rotated LAN
   dev-tool session key, not a vendor credential, and the rewrite has real cost);
2. whether Watchtower should be LAN-admitted at all, given `watchtower.sh` opens its own
   ufw rule at start-up. That is a standing posture question this incident merely
   surfaced, not something this task changed.

I would not hold the task open for either. If you disagree on (1), the rewrite is
strictly additive — nothing here has to be undone first.

**Evidence:**
- `sha256(committed blob)` == `sha256(on-disk)` == `ef0fbe61…` before the fix — the
  published value WAS the live signing key, with `FW_SECRET_KEY` unset in the running
  Watchtower's env (pid 1341537) so the resolver had fallen through to the file
- after rotation: on-disk `51f64e07…` ≠ `ef0fbe61…`, mode back to `0600`, Watchtower
  restarted (pid 8448) and serving `fw_session_3000` signed with the new value
- `git ls-files` no longer lists it; `git check-ignore` resolves BOTH depths
- `tools/tracked-secret-artifacts.py` — clean over 5562 tracked files, empty allowlist
- `tools/_t410-secret-artifact-teeth.sh` — 13/13, incl. the actual file at its actual
  path (PL-113: the live tree passes whether or not the tool works, so that leg is the
  only thing separating "it works" from "the file is gone")
- P-011 6/6
- exposure was live, not theoretical: `fw watchtower restart` reported
  `[firewall] Port 3000 already open` — reported, not changed; no ufw rule was touched
- reported to AEF at rail 498: the generator, the vendored `.gitignore` that omits it,
  and the scanner blind spot are all framework-side, and every consumer tracking
  `.context/working/` wholesale has the same exposure

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

# 1. The key is out of the index. File-based grep, not a pipe into `grep -q` (L-387).
git ls-files > /tmp/.t410-tracked.txt && ! grep -q "fw-secret-key" /tmp/.t410-tracked.txt
# 2/3. Both depths are ignored, so `git add -A` cannot re-add either copy.
git check-ignore -q .context/working/.fw-secret-key
git check-ignore -q .agentic-framework/.context/working/.fw-secret-key
# 4. The PUBLISHED key is dead. ef0fbe61… is the sha256 of the value committed at
#    2b9c8ffa and carried until T-410; recording a hash of a rotated key is safe and is
#    the evidence. Guarded so a fresh clone (no key yet) does not report a false red.
[ ! -f .context/working/.fw-secret-key ] || [ "$(sha256sum .context/working/.fw-secret-key | awk '{print $1}')" != "ef0fbe617284fcb82e8e3ab1778f398f4926c5ac278943f2c07d9f4befa1af4c" ]
# 5. The tracked tree carries no key material by name. Own exit code is the verdict.
python3 tools/tracked-secret-artifacts.py
# 6. Teeth, pinned to the leg count so a silently-shortened harness cannot pass.
./tools/_t410-secret-artifact-teeth.sh > /tmp/.t410-teeth.txt 2>&1 && grep -q "TEETH PASS — 13/13" /tmp/.t410-teeth.txt

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

**Symptom:** `.context/working/.fw-secret-key` — byte-identical to the live key signing
`fw_session_3000` and the CSRF token inside it — was tracked in git for 2 months and
pushed to a mirrored remote, while every audit in that window reported
`[PASS] Secret scan: tracked tree clean`.

**Root cause:** two independent omissions that had to coincide, and did.

1. *It was never chosen.* `.context/working/` holds **371 tracked files** — counters,
   flags, `.reviewed-T-*` markers. Tracking that directory wholesale is deliberate
   (working memory survives a clone), and its `.gitignore` exists to carve out the
   volatile files. The key was simply never added to that carve-out, so it was swept in
   by `2b9c8ffa` — a commit about *cron audit files*. Nobody decided to publish a key;
   nobody decided not to.

2. *Nothing could see it afterwards.* `secret-scan.sh` matches **content** against
   vendor-prefixed credentials — `AKIA…`, `ghp_…`, `sk-ant-…`, `-----BEGIN … PRIVATE
   KEY-----`. The key is `secrets.token_hex(32)`: 64 bare hex characters, no prefix, no
   assignment, no vendor fingerprint. No pattern in the catalogue can match it, and the
   catalogue header says why — "prefer specific over generic; generic entropy belongs in
   gitleaks."

**Why structurally allowed:** the scanner is built to catch credentials a developer
**pastes in from a third party**. Every pattern in it is a vendor's prefix. A key the
framework **generates for itself** has no vendor and therefore no prefix — so the one
class of secret the framework is guaranteed to produce is the one class its scanner is
guaranteed to miss. The blind spot is not an oversight in the pattern list; it is the
shape of the pattern list.

Compounding it, **nothing read filenames at all.** `.fw-secret-key` announced what it was,
in its name, for two months. Detecting it needed no entropy analysis and no gitleaks —
only somebody looking at the axis nobody was looking at.

**Prevention:** `tools/tracked-secret-artifacts.py` scans `git ls-files` by NAME, in two
classes — DEFINITIVE (`.pem`, `id_rsa`, `.netrc`, `.fw-secret-key` …) and ANNOUNCED
(a secrecy word paired with a credential noun). Teeth: 13 legs, including the actual file
at its actual path, and a false-positive control on the framework's own secret-*handling*
names (`secret-scan.sh`, `secrets_store.py`) so the tool cannot be reverted for crying
wolf. The ignore rule is depth-agnostic on purpose: this tree held **two** copies of the
key, and the second was already sitting untracked-but-committable when this was found —
a path-anchored rule would have covered one and left the other.

Prevention is deliberately *not* "add a hex-entropy pattern". That was considered and
rejected: entropy scanning is what the catalogue explicitly delegates to gitleaks, it
would fire on every sha256 in this repo's task files, and it would still be a
content rule — the same axis that was already being read.

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

### 2026-08-09T11:24:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-410-watchtower-session-signing-key-is-commit.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-7636549f
- **Timestamp:** 2026-08-09T11:36:22Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `force-push`

### 2026-08-09T11:36:19Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
