# T-091 — Upstream Fix Bundle: Shared-Tooling-Mode Bugs in the Agentic Engineering Framework

**Task:** T-091 (build) · **Date:** 2026-07-05 · **Audience:** framework maintainers (delivery via ring20 cascade, T-016 channel)

Two confirmed bugs share one root class: **framework code that resolves framework-owned assets via `PROJECT_ROOT` (or inherits project-scoped state across project boundaries) breaks silently in shared-tooling mode**, i.e. whenever `PROJECT_ROOT != FRAMEWORK_ROOT`. Both are invisible in the framework's own repo, where the two roots coincide — which is why they shipped. Patches attached; both verified with `git apply --check` against the vendored copy in this consumer repo (framework tree untouched).

- Bug 1 (this repo's gap **G-004**, found by T-090): every Watchtower `/review/T-XXX` page returns 500 in shared mode.
- Bug 2 (this repo's inception **T-015**, operator-decided GO 2026-07-04): exported `TASKS_DIR`/`CONTEXT_DIR` contaminate nested `fw` invocations in other projects.

Local learning PL-010 records the class. First instance was T-015; second was G-004 — two independent hits in one consumer repo within a month, so the prevention section below (a shared-mode smoke test) is the part with the highest leverage.

---

## Bug 1 — `review.py` inserts `PROJECT_ROOT/lib` on `sys.path` (G-004)

**Symptom.** In shared-tooling mode, every `/review/T-XXX` Watchtower page 500s with `ModuleNotFoundError: No module named 'dispatch_pause'`. The review queue — the primary human-in-the-loop surface — is entirely down for consumers.

**Root cause.** `web/blueprints/review.py:18`:

```python
from web.shared import PROJECT_ROOT, parse_frontmatter
...
# T-1810: paused-dispatch helpers live in lib/ (CLI parity with `fw pause list`).
sys.path.insert(0, str(PROJECT_ROOT / "lib"))
```

`dispatch_pause.py` is a **framework** module: it lives at `FRAMEWORK_ROOT/lib/dispatch_pause.py`. In the framework repo the two roots coincide and the import works; in a consumer, `PROJECT_ROOT/lib` either doesn't exist or holds product code, and the deferred import inside `_load_paused_for_task()` raises at request time.

**Why it shipped.** T-1810 was developed and tested where `PROJECT_ROOT == FRAMEWORK_ROOT`. No test exercises the blueprint with the roots split.

**Fix** (2 lines — `docs/patches/T-091-0001-review-py-lib-path-framework-root.patch`):

```diff
-from web.shared import PROJECT_ROOT, parse_frontmatter
+from web.shared import FRAMEWORK_ROOT, PROJECT_ROOT, parse_frontmatter
 
 # T-1810: paused-dispatch helpers live in lib/ (CLI parity with `fw pause list`).
-sys.path.insert(0, str(PROJECT_ROOT / "lib"))
+sys.path.insert(0, str(FRAMEWORK_ROOT / "lib"))
```

`FRAMEWORK_ROOT` is already defined in `web/shared.py` (`APP_DIR.parent`), so no new plumbing is needed. Note the data-side call `list_paused_dispatches_for_task(task_id, PROJECT_ROOT)` is **correct** as-is — paused-dispatch *state* is project data; only the *module path* is framework-owned.

**Consumer-side workaround currently deployed here** (delete on your fix): a shim at `PROJECT_ROOT/lib/dispatch_pause.py` that re-exports the real module by absolute file path. It sits at the exact path the buggy line adds. When this patch lands upstream and is re-vendored, we remove the shim and close G-004.

---

## Bug 2 — `TASKS_DIR`/`CONTEXT_DIR` exports leak across project boundaries (T-015)

**Symptom.** `fw test-onboarding` consistently creates tasks and writes focus into the **calling** project instead of the temp target project. Generally: any nested `fw` invocation that sets `PROJECT_ROOT` for another project (onboarding tests, cross-project scripting, multi-project agents) silently reads and writes the caller's `.tasks/` and `.context/`.

**Root cause.** `lib/paths.sh`:

```bash
# line 49-50 — inherited env values win unconditionally
TASKS_DIR="${TASKS_DIR:-$PROJECT_ROOT/.tasks}"
CONTEXT_DIR="${CONTEXT_DIR:-$PROJECT_ROOT/.context}"
...
# line 74 — and every fw invocation exports them to all children
export FRAMEWORK_ROOT PROJECT_ROOT TASKS_DIR CONTEXT_DIR
```

The combination is the bug: the export makes every child inherit project-A values; the `:-` default makes the child trust them even when its own `PROJECT_ROOT` is project B. Data flows to the wrong repository with zero errors — a reliability-directive violation (silent failure).

**Evidence it's known-but-worked-around:** `agents/onboarding-test/test-onboarding.sh:258` and `:455` already carry `env -u TASKS_DIR -u CONTEXT_DIR` — the workaround is vendored into the very test that found the bug.

**Fix** (`docs/patches/T-091-0002-paths-sh-cross-project-env-guard.patch`): stamp the export with the project it was computed for, and re-derive whenever the stamp doesn't match the current `PROJECT_ROOT`:

```bash
# Inherited TASKS_DIR/CONTEXT_DIR exports are trusted only when they were
# exported for this same PROJECT_ROOT (FW_PATHS_FOR stamp below).
if [[ "${FW_PATHS_FOR:-}" != "$PROJECT_ROOT" ]]; then
    TASKS_DIR="$PROJECT_ROOT/.tasks"
    CONTEXT_DIR="$PROJECT_ROOT/.context"
fi
TASKS_DIR="${TASKS_DIR:-$PROJECT_ROOT/.tasks}"
CONTEXT_DIR="${CONTEXT_DIR:-$PROJECT_ROOT/.context}"
...
export FRAMEWORK_ROOT PROJECT_ROOT TASKS_DIR CONTEXT_DIR
export FW_PATHS_FOR="$PROJECT_ROOT"
```

**Why a stamp instead of dropping the export or always re-deriving:**

- *Always re-derive* would break any deliberate same-project relocation of `.tasks`/`.context` passed through the environment.
- *Dropping the export* changes behaviour for every existing child-process consumer at once — larger blast radius than the bug.
- The stamp is surgical: same-project inheritance (including custom locations) is preserved; only **cross-project** inheritance — which is always contamination — is severed.

Behaviour verified against three scenarios (parent-A→child-B re-derives; same-project custom location preserved; cold start unchanged) — all pass; `bash -n` clean. Once merged, the two `env -u` workarounds in `test-onboarding.sh` can be deleted — which is also the regression test: onboarding passes without them only if this fix works.

---

## Prevention: shared-mode smoke test (recommended)

Both bugs come from the same blind spot, and the class will recur as long as CI only runs with `PROJECT_ROOT == FRAMEWORK_ROOT`. Recommended: one CI job that exercises the split-root configuration —

1. Create a temp consumer: empty git repo + `.framework.yaml` pointing at the framework checkout (vendored-layout variant: symlink the checkout in as `.agentic-framework/`).
2. From the consumer root, run the CLI surface: `fw context init`, `fw work-on "smoke" --type build`, `fw task update ... --status work-completed`, `fw doctor` — assert every artifact lands under the **consumer** root and nothing appears under the framework checkout (`git -C $FRAMEWORK_ROOT status --porcelain` stays empty).
3. Start Watchtower against the consumer and `curl -sf` every registered blueprint route (a task page, a `/review/T-XXX` page, the dashboard). Any 500 fails the job — this alone would have caught Bug 1 at T-1810's merge.
4. Nested-invocation probe: from inside the consumer, invoke `fw` against a second temp project with `PROJECT_ROOT` set and assert writes land in the second project — catches Bug 2 and any future env-inheritance leak.

Grep-level lint to go with it: flag any new `PROJECT_ROOT / "lib"`-style resolution of framework-owned assets (`lib/`, `web/`, `agents/`, `templates/` lookups belong under `FRAMEWORK_ROOT`).

## Delivery

- Patches: `docs/patches/T-091-0001-review-py-lib-path-framework-root.patch`, `docs/patches/T-091-0002-paths-sh-cross-project-env-guard.patch` (git-apply format, paths relative to framework repo root; both verified here with `git apply --check --directory=.agentic-framework`).
- Channel: ring20 cascade once T-016 (OneDev → GitHub provisioning) unblocks; this report + the two patch files are the payload.
- Consumer follow-ups on upstream merge: re-vendor, delete `lib/dispatch_pause.py` shim, close gap G-004 in `.context/project/concerns.yaml`, drop the `env -u` lines if upstream hasn't already.
