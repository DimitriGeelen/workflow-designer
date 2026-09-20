# 03 — THE DELIVERY PATH: how `src/` becomes bytes a consumer pins

Gatherer leg. **Evidence only.** No classification, no recommendation. Every row
cites a path:line, command output, sha, or record id. Collected 2026-09-20,
working tree at `12ad8f9f` (master).

All commands below were run **read-only**. The one determinism probe ran in a
throwaway tree (`/tmp/relprobe`) with `RELEASE_SKIP_ANNOUNCE=1`; `dist/`,
`VERSION`, `build/gallery/`, `examples/aef-processes/rendered/` and
`docs/standards/aef-bpmn-mapping-v1.md` were **not written**.

---

## The seam in one line

```
src/aef-workflow-designer.html
  --(scripts/release-designer.sh)-->  dist/aef-workflow-designer-X.Y.Z.html + dist/MANIFEST.yaml
  --(git tag -a designer-vX.Y.Z)-->   frozen published bytes
  --(scripts/announce-release.sh)-->  rail cv_key=designer-release
  --(fw designer sync --from-tag)-->  vendor/designer/<artifact>  <-- what /designer/app SERVES
                                       pinned by .agentic-framework/policy/designer-pin.yaml
```

Three independent version numbers live on that line. Today they read
**0.12.0 / 0.12.0 / 0.8.0**.

---

## Evidence table

| Item | Source | Status of source | Data point (with citation) | Window | Kind |
|---|---|---|---|---|---|
| Source of truth bytes | `src/aef-workflow-designer.html` | EXISTS | `sha256 2b448b61b7fa6c33f347535748c4df828f5d7c1d4b11322e3b25dc609631cf8c`, `997254` bytes (`sha256sum`, `wc -c`, 2026-09-20). Independently confirms the orchestrator's figure. | now | structure |
| Cut artifact | `dist/aef-workflow-designer-0.12.0.html` | EXISTS | Same sha `2b448b61…`, same `997254` bytes — artifact **is** src byte-for-byte. `ls -la` mtime `Sep 20 19:02`. | now | structure |
| Release pointer | `dist/MANIFEST.yaml` | EXISTS | `latest: "0.12.0"`, `sha256: "2b448b61…"`, `bytes: 997254`, `released: "2026-09-20T16:51:03Z"`, `src_commit: "d31278fb26ffa68e22f1e7e7c21ef49246fc5d1f"`, `supersedes: "0.11.0"`, `capabilities: {annotation_seam: 1}`. All three orchestrator figures reproduce. | now | structure |
| Cut script | `scripts/release-designer.sh` | EXISTS, 253 lines | Last touched `e88dcbec 2026-08-08T21:57:51+02:00` (`git log -1`). 43 days of no change; **exercised** 2026-09-20 (produced 0.12.0). Stale by calendar, active by use. | 43d since edit, used today | structure |
| Announce script | `scripts/announce-release.sh` | EXISTS, 147 lines | Last touched `83cf8d0b 2026-08-08T19:50:14+02:00`. Exercised today — see rail row. | 43d since edit, used today | structure |
| Font embedder | `scripts/embed-fonts.py` | EXISTS, 123 lines | Last touched `b468f20e 2026-07-18T09:54:56+02:00` (T-176). **Not called by `release-designer.sh`** — `grep -n "embed-fonts" scripts/release-designer.sh` returns nothing. Only non-doc references are `.context/handovers/S-2026-0718-0956.md:371` and `.tasks/completed/T-176-…md` (an AC and a `test -f` verification line). | 64d, 0 calls in release path | usage |
| Font embedder — what it is | `scripts/embed-fonts.py:1-30` | EXISTS | Self-described as a one-shot generator: "re-run to re-fetch and re-embed after a weight/family change, instead of hand-editing base64" (`:10-12`). "Requires network to fonts.googleapis.com / fonts.gstatic.com at BUILD time only" (`:29`). | — | structure |
| Font embedder — output parity | — | UNVERIFIED | Whether re-running it today still reproduces the base64 block now inside `src/` was **not tested** — it requires a live fetch to Google, which is a network write-path I did not exercise. No local fixture or test asserts this parity (no test file references `embed-fonts`). | — | cost |
| VERSION | `VERSION` | EXISTS | `0.12.0`. Bumped `cd42385f 2026-09-20T19:00:28+02:00` (T-700). Prior bumps: `975ad482` (0.11.0), `2824e6b4` (0.10.0), `8cd0c5d3` (0.9.0), `1a13035c` (0.8.0). | 5 bumps since 2026-07-29 | structure |
| Tag exists + annotated | `refs/tags/designer-v0.12.0` | EXISTS | `git cat-file -t designer-v0.12.0` → `tag` (annotated, not lightweight). Message: "Release designer-v0.12.0 / Ten consumer-visible changes unshipped for 27 days…". | now | structure |
| Tag pushed | `origin` | EXISTS | `git ls-remote --tags origin` → `1e6277de… refs/tags/designer-v0.12.0`, peels to `cd42385f…` (the release commit). The tag resolves to a tree that carries its own VERSION and artifact — the failure mode `release-designer.sh:223-230` warns about did **not** occur. | now | structure |
| Full tag chain | `git tag -l 'designer-v*'` | EXISTS | 15 tags, `0.1.0 … 0.12.0`, unbroken. | — | structure |
| Rail announcement — live | hub topic `dm:0e7ee6cad65137fc:6a646ce8b1bc6560` | EXISTS | `termlink channel cv-keys` → `{"count":1,"entries":[{"cv_key":"designer-release","offset":0}]}`. Current value decodes to `version: "0.12.0"`, `sha256: "2b448b61…"`, `src_commit: "d31278fb…"`, `artifact: "dist/aef-workflow-designer-0.12.0.html"`. **The rail advertises the current release.** | now | usage |
| Rail history discontinuity | same topic | EXISTS (conflicting data point) | The indexed offset is **0** and `count` is **1**. Commit `2824e6b4` (T-512, 2026-08-15) records "the script announced to the DM topic at **offset 631** with cv_key=designer-release"; `8cd0c5d3` (T-393) records "announced to the rail at **offset 480**". Recorded side by side, not averaged: either this is a different/reset topic or the hub's log does not persist. **Cause UNVERIFIED.** | — | friction |
| Peer pin | `.agentic-framework/policy/designer-pin.yaml` | EXISTS | `version: "0.8.0"`, `sha256: "cab3c75183979b0e15e23192518f9360ea12fe33b6a4f78641d7e264f6110935"`, `bytes: 903600`, `source_tag: "designer-v0.8.0"`, `vendored_path: "vendor/designer/aef-workflow-designer-0.8.0.html"`. Confirms the orchestrator's 0.8.0. | now | structure |
| Peer pin — last re-vendored | same | EXISTS | `git log -- .agentic-framework/policy/designer-pin.yaml` returns **2 commits total**: `405a39d9 2026-07-29T08:24:28+02:00` (T-296, "our own consumer intake run: vendored pin 0.7.1→0.8.0") and `ebf0c721 2026-07-28`. **53 days, 4 releases (0.9.0, 0.10.0, 0.11.0, 0.12.0) cut with no re-pin.** | 53d | usage |
| Vendored bundle on disk | `vendor/designer/aef-workflow-designer-0.8.0.html` | EXISTS, tracked | `sha256 cab3c751…`, `903600` bytes — **matches the pin exactly**. Landed `405a39d9 2026-07-29`. `git ls-files` confirms tracked. | 53d | structure |
| What `/designer/app` serves | `http://192.168.10.107:3013/designer/app` | EXISTS (live, pid 634131 per `.context/working/watchtower.pid`) | `curl` → `http=200 bytes=903600`, `sha256 cab3c75183979b0e…`. **Byte-identical to `vendor/designer/aef-workflow-designer-0.8.0.html` and to `dist/aef-workflow-designer-0.8.0.html`.** Confirms the orchestrator's figure. | now | usage |
| Serve mechanism | `.agentic-framework/web/blueprints/designer.py:98-105` (`_serve_bundle`), `:28-37` (`_pin`, `_vendored_path`) | EXISTS | `_vendored_path()` reads `vendored_path` from `_PIN_FILE = FRAMEWORK_ROOT / "policy" / "designer-pin.yaml"` and resolves it against `PROJECT_ROOT`. `_serve_bundle` then does `vpath.read_text()` verbatim. **No sha256 verification at serve time** — the pin's `sha256:` is read only by `_placeholder()` (`:40-55`) for display when the file is absent. | now | structure |
| Intake tooling | `.agentic-framework/agents/designer/designer.sh:12,105-117` | EXISTS | `fw designer sync --from-tag [tag] [--dry-run]` is implemented and routed (`bin/fw:4258` → `designer)`). The mechanism to move the local serve from 0.8.0 to 0.12.0 **exists and is wired**; it has not been run since 2026-07-29. | now | usage |
| Pin↔vendored drift check — dead leg | `.agentic-framework/bin/fw:1467` | EXISTS but never fires here | Predicate: `local _dz_pin="${FW_DESIGNER_PIN_FILE:-$PROJECT_ROOT/policy/designer-pin.yaml}"` then `if [ -f "$_dz_pin" ]`. In this repo `PROJECT_ROOT=/opt/832-Workflow-designer` and `ls policy/designer-pin.yaml` → **No such file or directory** (the pin lives at `.agentic-framework/policy/…`). `bin/fw doctor 2>&1 \| grep -i designer` → **no output at all** (not even a SKIP). | now | friction |
| Prior incident of this exact class | `.tasks/active/T-293-…md:349-355` | EXISTS | "Every designer the operator CAN reach serves the pinned **0.7.1 release** (our Watchtower :3000/designer → vendor/designer/aef-workflow-designer-0.7.1.html, 0 g-handles refs; AEF's :3001/designer same pin) — 0.7.1 was cut BEFORE T-286 and T-293 landed. On 0.7.1 the endpoint-drag defect reproduces exactly as reported. **The 'field failure' was a faithful test of old code.**" | 2026-07 | value |
| Response to that incident | commit `1a13035c` (T-296) | EXISTS | Cut motive, verbatim: "motive: operator-reachable designers all serve pinned 0.7.1 — re-pin closes the T-293/T-286 retest gap". A re-pin of the local vendored copy was the recorded remedy, executed once, 2026-07-29. | 2026-07-29 | intent |
| Release-lag audit PASS | `.context/audits/2026-09-20-structure.yaml`, `.agentic-framework/agents/audit/audit.sh:2260` | EXISTS | `[PASS] Release lag: src, released artifact and peer pin are in step`. See **§ The PASS** below. | now | friction |
| Same check, 3 hours earlier | `.context/audits/cron/2026-09-20-{0830,0900,…,1600}.yaml` | EXISTS | `Release lag EXCEEDED:   - oldest unshipped product change is 27d old (>= 14d)` — 11 consecutive cron records. Flipped to PASS at the `1900` record, i.e. at the 0.12.0 cut (`cd42385f`, 19:00:28). | today | friction |
| Trend register | `.context/audits/2026-09-20-structure.yaml` (TREND ANALYSIS) | EXISTS | "Release lag EXCEEDED: - oldest unshipped product change is 27d old (>= 14d) (**8 times**)" in 14 days. | 14d | friction |
| Determinism | `scripts/release-designer.sh` (probe, see § below) | EXISTS, VERIFIED | Two consecutive runs in `/tmp/relprobe` at `VERSION=9.9.9` produced **byte-identical** artifact and **byte-identical** `MANIFEST.yaml`, `released:`/`src_commit:` included. | now | structure |
| Immutability guard | `scripts/release-designer.sh:39-72` | EXISTS | Fires before any write; refuses when `[ -f "$ARTIFACT" ] && ! cmp -s "$SRC" "$ARTIFACT"`. Registered as gap **G-007** (`status: watching`), closure condition present and renderable. | now | value |
| Render gate | `scripts/release-designer.sh:84-98`, `tests/test_designer_render.py` | EXISTS | Runs before the manifest is written; `exit 1` on failure. Bypass `RELEASE_SKIP_RENDER_CHECK=1` is stderr-loud. **Not exercised in my probe** (temp tree had no `tests/`, so the gate printed "WARNING: render test not found … render gate skipped"). Whether it passes on today's src is **UNMEASURED by me**; T-700's own record asserts "render gate PASS" for prior cuts (`2824e6b4`). | now | structure |
| Release telemetry | — | ABSENT | No product usage telemetry in this repo (operator-confirmed). Nothing records how many times `/designer/app` was loaded, by whom, or against which pin. Every "is this used?" question on this leg is **UNMEASURED**, not zero. | — | usage |
| `dist/LATEST.yaml` | — | ABSENT **by decision** | `scripts/announce-release.sh:12-19`: "The obvious fix — publish dist/LATEST.yaml — was proposed and **REFUSED by both sides** (rail 469/471 §2)." This is a **positive recorded reason** the artefact does not exist. | 2026-08 | intent |

---

## § The PASS: what the release-lag check actually compares

### Where it is emitted

`.agentic-framework/agents/audit/audit.sh:2251-2268`:

```bash
check_release_lag() {
    local _probe="$PROJECT_ROOT/tools/_t382-release-lag.py"
    [ -f "$_probe" ] || return 0
    local _out _rc
    _out=$(python3 "$_probe" 2>&1); _rc=$?
    local _l1 _l2
    _l1=$(printf '%s' "$_out" | grep -m1 'oldest unshipped product change' || true)
    _l2=$(printf '%s' "$_out" | grep -m1 'peer pin behind' || true)
    case "$_rc" in
        0) pass "Release lag: src, released artifact and peer pin are in step" ;;
        1) warn "Release lag: ${_l1:-${_l2:-below threshold}}" ...
```

Two things to note in that `case`:

1. The exit-0 arm prints a **hardcoded string**. It does not interpolate `_l1` or
   `_l2`. The probe's reasons list is discarded on exit 0.
2. `_l2` — the "peer pin behind" line — is computed but is only ever reachable as
   a **fallback** (`${_l1:-${_l2:-…}}`). Whenever leg 1 also has something to say,
   the peer-pin fact is shadowed out of the audit record entirely.

### The predicate

`tools/_t382-release-lag.py`, `verdict()` (leg 2 only, verbatim):

```python
    if res["adopt_behind"]:
        a = res["adopt_days"]
        if a is None:
            reasons.append("peer behind (%s) by an unmeasurable amount" % res["adopt_behind"])
            esc("fail")
        elif a >= FAIL_DAYS:
            reasons.append("peer pin behind (%s), release %dd old (>= %dd)" % (res["adopt_behind"], a, FAIL_DAYS))
            esc("fail")
        else:
            reasons.append("peer pin behind (%s), release %dd old" % (res["adopt_behind"], a))
            if a >= WARN_DAYS:
                esc("warn")
```

and the measurement it reads, from `measure()`:

```python
    peer_v = yaml_scalar(PEER_PIN, "version") if os.path.exists(PEER_PIN) else None
    ...
    if peer_v and peer_v != version:
        res["adopt_behind"] = "%s -> %s" % (peer_v, version)
        rel_tag = "designer-v%s" % version
        if git("tag", "-l", rel_tag):
            res["adopt_days"] = days_since(git("log", "-1", "--format=%cI", rel_tag))
```

**`adopt_days` is the age of OUR OWN LATEST RELEASE TAG.** It is not the age of the
peer's pin, not the age of the release the peer skipped, and not a count of skipped
releases. `adopt_behind` — the only value that carries the *distance* (`"0.8.0 ->
0.12.0"`) — is used **exclusively to build the message string**. It never enters a
comparison.

### Why it passes over a four-release gap

`WARN_DAYS = 7`, `FAIL_DAYS = 14`. `designer-v0.12.0` was tagged
`2026-09-20T19:00:28+02:00` — **today**. So `adopt_days = 0`, which is `< 7`, so
neither `esc()` fires and `level` stays `"ok"` → exit 0 → the hardcoded PASS.

Live probe output, run read-only today, states the contradiction in its own words:

```
-- leg 2: ADOPTION LAG (release ahead of the peer's pin) --
   peer pin behind: 0.8.0 -> 0.12.0   (our release is 0 days old)
...
verdict: OK
  - peer pin behind (0.8.0 -> 0.12.0), release 0d old
EXIT=0
```

The probe **knows** the peer is four releases behind, prints it, and grades it OK.

### The gauge's direction, demonstrated

Driving `verdict()` directly on constructed inputs (read-only, no git, no writes):

| Input | Verdict |
|---|---|
| peer **4** behind (`0.8.0 -> 0.12.0`), our tag **0d** old | **ok** |
| peer **3** behind (`0.8.0 -> 0.11.0`), our tag **28d** old | **fail** |
| peer **11** behind (`0.1.0 -> 0.12.0`), our tag **0d** old | **ok** |

Tag ages measured today: `designer-v0.9.0` 43d, `v0.10.0` 36d, `v0.11.0` 28d,
`v0.12.0` **0d**.

So: **cutting a release resets the adoption clock to zero.** Had 0.12.0 not been
cut today, leg 2 would have read `adopt_days = 28 >= FAIL_DAYS` → fail. The act
that widened the peer's gap from 3 releases to 4 is the same act that turned the
adoption gauge from red to green. Leg 2 can never report an adoption problem for
the first 7 days after any cut, and any new cut restarts that window.

### The teeth do not cover the live shape

`teeth()` leg 5 (`:322-323`):

```python
    lv5, _ = verdict({**base, "adopt_behind": "0.1.0 -> 0.8.0", "adopt_days": 99})
    leg("stale peer pin ALONE -> fail", lv5 == "fail", "-> %s" % lv5)
```

`base` has `adopt_behind: None`. The only adoption leg tested sets `adopt_days: 99`.
**There is no teeth leg that sets `adopt_behind` with a small `adopt_days`** — i.e.
the exact configuration the production path reports today is untested. The self-test
passes and the gauge still reads green over a four-release gap.

### Scope note the tool states about itself

`tools/_t382-release-lag.py:28-35` — the peer pin is read from a **vendored** copy,
so leg 2 "is therefore a LOWER BOUND: a stale vendored pin makes it report LESS
adoption lag, never more, so the single direction it errs in is the reassuring one."
Recorded as the tool's own stated bound. Separately: in this repo the "peer" file
and the file that drives our **own** `/designer/app` serve are **the same file**, so
here the number is not a bound on a remote party — it is an exact statement about
what this host serves.

---

## § Determinism of `release-designer.sh`

### From the script text

The build step is `cp "$SRC" "$ARTIFACT"` (`:74`), followed by a `diff -q` assertion
(`:77-80`). The artifact is therefore a byte-copy of src — no minification, no
templating, no date injection, no font fetch. Deterministic by construction.

The only wall-clock and repo-state inputs are in the manifest, and both are guarded
(`:112-127`):

```bash
if [ -f "$MANIFEST" ]; then
  _prev_version="$(sed -n 's/^latest: *"\(.*\)"/\1/p' "$MANIFEST" | head -1)"
  _prev_sha="$(sed -n 's/^sha256: *"\(.*\)"/\1/p' "$MANIFEST" | head -1)"
  if [ "$_prev_version" = "$VERSION" ] && [ "$_prev_sha" = "$SHA" ]; then
    RELEASED="$(sed -n 's/^released: *"\(.*\)"/\1/p' "$MANIFEST" | head -1)"
    SRC_COMMIT="$(sed -n 's/^src_commit: *"\(.*\)"/\1/p' "$MANIFEST" | head -1)"
  fi
fi
[ -n "$RELEASED" ]   || RELEASED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
[ -n "$SRC_COMMIT" ] || SRC_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")"
```

i.e. a re-run at an unchanged VERSION with a byte-identical artifact **re-reads its
own previous values** rather than re-stamping them.

`SUPERSEDES` (`:134-137`) is derived from `ls "$DIST"/aef-workflow-designer-*.html`
— **directory state, not an input**. It is deterministic for a given `dist/`, but a
consumer reproducing the cut from `src` + `VERSION` alone in an empty tree would get
`supersedes: ""`. Recorded as a scope limit on the word "deterministic", not as a
failure.

### Measured

Probe (throwaway tree only — `/tmp/relprobe/{scripts,src,VERSION}`, `dist/` created
inside that temp dir; the repo's `dist/` was never touched):

```
$ cd /tmp/relprobe && RELEASE_SKIP_ANNOUNCE=1 scripts/release-designer.sh   # run 1
Release 9.9.9: CUT but NOT ANNOUNCED — NOT YET TAGGED
$ sleep 2
$ cd /tmp/relprobe && RELEASE_SKIP_ANNOUNCE=1 scripts/release-designer.sh   # run 2
Release 9.9.9: CUT but NOT ANNOUNCED — NOT YET TAGGED
$ diff run1-shas run2-shas   -> no differences
BYTE-IDENTICAL: artifact+manifest reproduced
MANIFEST identical incl. released/src_commit
```

**Verdict: deterministic, verified, across a 2-second wall-clock separation.** The
`sleep 2` matters — a naive `date -u` stamp would have diverged there.

Two caveats on what the probe did *not* prove:
- The render gate did not run (no `tests/` in the temp tree; the script printed
  "WARNING: render test not found … render gate skipped"). Determinism of the gate
  itself is **UNMEASURED**.
- Announce was suppressed. The idempotence path in `announce-release.sh:83-88`
  ("Already announced: … rail unchanged, nothing posted") is **UNMEASURED** by me,
  though the live rail read shows a single cv-key at a single offset, consistent
  with it.

---

## § Non-use diagnosis

Per the brief: evidence for each reading is recorded side by side. **Not classified.**

### Item: `scripts/embed-fonts.py` — 0 calls in the release path, 64 days since touch

- **A BROKEN** — no evidence. Not executed (would require a network fetch); no test
  exercises it; no error record references it. **UNMEASURED.**
- **B NEVER WIRED** — supported. `grep -n "embed-fonts" scripts/release-designer.sh`
  returns nothing; the only live-tree reference is its own docstring. But the origin
  task did **not** intend build-path wiring: T-176's AC reads "Generator
  `scripts/embed-fonts.py` committed — reproducibly re-fetches + re-embeds …
  **so a future weight change is one command, not hand-edited base64**"
  (`.tasks/completed/T-176-…md:102`). Designed as an on-demand generator, not a
  build step.
- **C UNDISCOVERABLE** — partial. Documented only in its own docstring
  (`scripts/embed-fonts.py:24-26`) and in a completed task file. Not in
  `CLAUDE.md`, not in the integration protocol, not in `tools/README.md`.
- **D UNMEASURED** — yes, by default: no telemetry anywhere in this repo.
- **E NOT WANTED** — no positive record found.
- **INTENT:** maps to D4 Portability (zero-network offline artifact) and D2
  Reliability. `designer-pin.yaml` still advertises the property it produced:
  `cdn_fonts: false`, "ZERO network on load … Fully self-contained for air-gapped
  deployments. This is why bytes jumped 395178 → 826643."

### Item: peer/local pin re-vendor — 0 runs in 53 days, 4 releases skipped

- **A BROKEN** — no evidence. `fw designer sync --from-tag` is implemented
  (`.agentic-framework/agents/designer/designer.sh:12,105-117`) and routed
  (`bin/fw:4258`). Not exercised by me (it writes). **UNMEASURED whether it runs
  clean today.**
- **B NEVER WIRED** — contradicted. It was run once, successfully: `405a39d9`,
  T-296, "our own consumer intake run: vendored pin 0.7.1→0.8.0".
- **C UNDISCOVERABLE** — partial, with a specific instrument gap: the one check that
  would compare served bytes against the pin never executes in this repo
  (`bin/fw:1467` looks at `$PROJECT_ROOT/policy/designer-pin.yaml`, which does not
  exist; `bin/fw doctor | grep -i designer` → empty). And the release-lag check that
  *does* see the gap grades it PASS (§ above).
- **D UNMEASURED** — yes. Nothing records `/designer/app` loads or which pin served
  them.
- **E NOT WANTED** — no positive record found. `designer-pin.yaml:1-20` describes
  re-pin as the standing contract, and `release-designer.sh:154-160` calls an
  un-learnable release "the gap itself".
- **INTENT (strong, and it has already cashed out once):** `T-293:349-355` records
  an operator field-failure report that was a faithful test of old code, because
  every reachable designer served a stale pin. `1a13035c` (T-296) records the remedy
  as an explicit re-pin. Value drivers: D2 Reliability 7 (a defect report against
  bytes nobody ships), F-RECALL 6, D1 Antifragility 9 (the gate that should catch
  the recurrence reads green).

### Item: the release-lag gate's leg 2

- **A BROKEN** — evidenced *at the predicate level*: it discriminates on
  `adopt_days` (our tag's age) while the distance it reports (`adopt_behind`) never
  enters a comparison; peer-11-behind grades `ok`. Its self-test passes because no
  teeth leg constructs the live shape.
- **C UNDISCOVERABLE** — the audit's exit-0 arm discards the probe's reasons and
  prints a hardcoded "in step"; `_l2` is shadowed by `_l1` in every warn arm. The
  fact is printed by the probe and invisible in the saved audit record.
- **D UNMEASURED** — the gate has no record of its own false-green rate.
- **INTENT:** G-024 is `status: watching` in `.context/project/concerns.yaml` with a
  renderable `decision_trigger` demanding "A standing, VISIBLE delta between `src`
  and the pinned release — number of commits, number consumer-visible in emitted
  bytes, and age of the oldest — surfaced without being asked for (fw doctor /
  audit)". The trigger names *three* quantities for leg 1 and the gate implements
  them; the adoption leg has no equivalent standing in the trigger text.

---

## § Sources expected and found ABSENT

| Expected | Finding |
|---|---|
| `dist/LATEST.yaml` or equivalent fetchable pointer | **ABSENT by recorded decision** — `announce-release.sh:12-19`, refused by both sides at rail 469/471 §2. The rail cv-key replaces it. This is category **E**, a positive reason. |
| `policy/designer-pin.yaml` at `PROJECT_ROOT` | **ABSENT.** Its absence silently disables `bin/fw:1467`'s pin↔vendored drift check in this repo. |
| Any usage telemetry on `/designer/app` | **ABSENT** (operator-confirmed repo-wide). |
| A test asserting `embed-fonts.py` output still matches `src/` | **ABSENT.** |
| A teeth leg for `adopt_behind` set with small `adopt_days` | **ABSENT** from `teeth()`. |
| A check comparing what `/designer/app` serves against `dist/MANIFEST.yaml latest` | **ABSENT.** Nothing in `audit.sh`, `bin/fw doctor`, or `tools/` joins the served bytes to the current release. The release-lag probe joins src↔dist↔pin, never pin↔served — though here pin and served happen to agree (`cab3c751…` both). |
