# T-142 — In-editor "Open from project" browser for workflow files

**Type:** Inception (exploration) · **Status:** spikes complete · **Recommendation at filing:** DEFER → **post-spike: GO** (human decides)
**Question (one):** Should the editor gain an in-editor "Open from project" browser
(backed by a new read-only `/api/list` endpoint + a picker modal), and what is the
minimal endpoint shape + modal UX that makes it worth building?

> C-001: this file is the durable thinking trail. It is created before research and
> updated incrementally as the exploration produces findings. Conversations are
> ephemeral; this file is permanent.

---

## 1. Problem statement

Browsing and opening existing workflow maps from the editor is weak. Today an operator
who wants to open a different project map must leave the editor, go to the gallery index
page, and click a link that full-reloads the editor. Nothing lets them browse/open another
map from within the editor, and their own saved work is not discoverable at all.

## 2. Current state (evidence gathered 2026-07-07, pre-spike)

Two disconnected surfaces, neither a real project browser:

| Surface | What it is | Limitation |
|---|---|---|
| Gallery index (`/` on :8834) | Static server-generated `<ol>` of 24 text links (`serve-gallery.sh:32-41`) | No thumbnails/descriptions/search; full-page reload to open; regenerated only at server start |
| "Switch workflow" picker (`workflow-picker`) | `<select>` populated from the in-memory `library` Map (`refreshLibraryUI`, `src:1909`) | Seed-only at Init; session-scratch, not the corpus; misleading name |
| "Load…" button (`btn-load`, `src:6984`) | OS file dialog to import a local `.bpmn` | Not project-aware |
| "Versions" (`btn-versions`) | History for the *currently open* map (`/api/versions?id=`) | Single-map scope |

Key structural facts:
- **No enumeration endpoint.** Server routes are `/api/health`, `/api/versions`,
  `/api/version`, `/api/thumb`, `/api/save` (`gallery-serve.py:27-31`). There is **no
  `/api/list`** — the editor cannot enumerate the corpus even if it wanted to.
- **Saved work is invisible.** "Save to project" writes `.editor-versions/<id>/`, but the
  gallery index lists only `rendered/*.bpmn` snapshotted at server start
  (`serve-gallery.sh:37`) — saves never appear without a server restart.
- **Rich metadata is unused.** The server already has `/api/thumb` (per-version PNG) and
  each BPMN carries `aef:` description metadata — neither is surfaced in the list.
- Corpus size today: **24 rendered maps**.

## 3. Constraints & invariants (must not break)

- **Single-file editor mirror:** `src/aef-workflow-designer.html` must stay byte-identical
  to `build/gallery/designer.html` (sync via `cp`).
- **Portability (Directive 4):** any new endpoint must degrade gracefully on the *static*
  gallery (plain `python -m http.server`), exactly as `Save`/`Versions` already hide when
  `/api/health` is absent (`detectSaveApi`, `src:6747`).
- **Read-only safety:** a list endpoint must not write, must resolve ids through the same
  `_valid_id` guard used by the read routes, and must not leak paths outside the repo.
- **T-138 corpus gate:** listing must not resurrect the existing/promotion distinction —
  it reads, it does not publish.
- No new heavyweight deps — `gallery-serve.py` is stdlib-only by design.

## 4. Exploration plan (spikes) — TO BE REVIEWED BEFORE EXECUTION

**Spike 1 — endpoint shape + latest-version resolution (`/api/list`).** Prototype a
read-only endpoint in `gallery-serve.py` returning, for each map: `id`, `title`/description
(parsed from the BPMN `aef:` metadata or filename fallback), source (`rendered` vs `saved`),
and **latest version + timestamp** (read from `.editor-versions/<id>/index.json`) + thumb
availability. This is what makes "open latest" possible — the list must know each map's
newest version. Decide: one merged list or two sections (corpus vs your saved maps)?
Measure response shape/size for 24 maps. *Deliverable: JSON schema + sample payload.*

**Spike 2 — modal UX + open-latest.** Prototype an in-editor "Open…" modal mirroring the
existing Versions modal pattern (`openVersionsModal`, `src:6867`) — grid of thumbnail +
title + source badge + **latest-version label**, with a client-side filter box. Decide:
does opening a map reuse the existing `?load` fetch path (in-memory, no reload) via
`adoptImportedXml`, avoiding the full-page reload? **Default the open target to the latest
saved version** (`/api/version?id=&v=<latest>`), falling back to the `rendered/` baseline
when a map has no saved versions; older versions remain reachable via the existing Versions
modal. *Deliverable: interaction sketch + which code path it reuses.*

> **Why latest-version matters (added 2026-07-07 on human steer):** today `?load` always
> fetches `rendered/<id>.bpmn` — the stale baseline — so opening a map you have saved edits
> on silently discards them from view. The browser must resolve and default to the latest
> saved version, or it reintroduces the very confusion it aims to remove.

**Spike 3 — saved-work visibility & static fallback.** Confirm `.editor-versions/*` can be
enumerated cheaply and that the whole feature hides cleanly on the static gallery.
*Deliverable: fallback behavior confirmed against `python -m http.server`.*

## 5. Open questions (mirror of task `## Open Questions`)

- **IW-1** — `/api/list` shape (fields incl. latest-version; merged vs corpus/saved split). *deferred → Spike 1.*
- **IW-2** — in-place open reusing `?load`/`adoptImportedXml` (no reload). *deferred → Spike 2.*
- **IW-3** — clean hide on the static gallery (detectSaveApi precedent). *deferred → Spike 3.*
- **IW-4** — build decomposes into ≤2–3 bounded tasks. *deferred → confirmed at decide.*
- **IW-5** — Open defaults to a map's latest saved version (baseline fallback), older
  versions via the Versions modal. *deferred → Spike 1 (resolve) + Spike 2 (wire).*

## 6. Go/No-Go criteria (decision at end of exploration)

- **GO** if: `/api/list` has a clean, stdlib-only shape; the modal opens a map in-place
  (no reload) reusing existing paths; the feature hides on the static gallery; and the
  build decomposes into ≤2–3 bounded build tasks (endpoint, modal, saved-work surfacing).
- **NO-GO / narrow to B+D** if: the endpoint or modal proves disproportionate, or in-place
  open can't reuse existing paths safely — fall back to enhancing the gallery index page
  (thumbnails + search) + surfacing saved work, which needs no new editor modal.

## 8. Spike findings (2026-07-07) — all IW resolved

Prototypes run in scratch (`scratchpad/spike1_api_list.py`) and against the live gallery
(:8834) via headless browser; production `gallery-serve.py` and `src/` were NOT modified.

**Spike 1 — `/api/list` shape + latest-version (IW-1, IW-5).** A read-only prototype over the
real repo produced a merged list of **24 maps in a 6,065-byte payload in 4.2 ms** — stdlib
only, trivially synchronous. Shape per map: `{id, title, sources:[rendered|saved], latest:
{v,ts,count}|null, openTarget:{kind:'version',v}|{kind:'rendered'}}`. Title comes from the
BPMN `<bpmn:process name>`; `latest` is resolved from `.editor-versions/<id>/index.json`.
**Key evidence: 11 of 24 maps already carry saved versions (v1–v4)** — arc-lifecycle(v4),
assumption-validation(v3), context-memory(v2), error-escalation-ladder(v3),
fabric-blast-radius(v2), git-commit-flow(v3), harvest-pipeline(v3), healing-loop(v2),
resume-status(v1), task-gate(v2), tier0-escalation(v2). Today's `?load` opens the stale
`rendered/` baseline for all of them, silently ignoring that saved work. IW-5 is real for
~46% of the corpus.
> Note (not part of this inception): whether those 11 saved sets are intentional corpus work
> or test residue is a separate question — flag to the human, do not act on it here.

**Spike 2 — in-place open + open-latest (IW-2).** In the live editor, `adoptImportedXml(text)`
swapped the active map `investigate → audit-process` with **no page reload** (URL unchanged,
14 nodes loaded). Fetching the latest saved version via `/api/version?id=arc-lifecycle&v=4`
returned **HTTP 200** and loaded in-place the same way. Both the rendered-baseline path and
the saved-version path open in-place through existing code — no new load machinery needed.
*Build detail noted:* the "Open" action should use replace semantics (not the
collision-append `_v2` branch of `adoptImportedXml`) so re-opening a map doesn't spawn
`<id>_v2` library entries.

**Spike 3 — static fallback (IW-3).** `detectSaveApi()` (`src:6747`) already reveals
Save/Versions only when `/api/health` answers; both buttons ship `display:none`. A new
"Open from project" button reuses this verbatim — hidden on the static gallery, where the
existing index page (plain `?load` links) remains the fallback.

**Decomposition (IW-4).** GO would authorise a bounded build split:
1. **`/api/list` endpoint** in `gallery-serve.py` (read-only, the Spike-1 shape) + verifier.
2. **In-editor "Open…" modal** on the `openVersionsModal` pattern — thumbnail + title +
   source badge + latest-version label + filter box; opens in-place via `adoptImportedXml`
   (replace semantics), defaulting to `openTarget`; gated by `detectSaveApi`.
3. *(optional, foldable into 2)* older-version affordance handing off to the existing
   Versions modal.
Two-to-three bounded tasks, no new subsystem. Mirror invariant + T-138 gate untouched (read
path only).

**Recommendation: GO.** All GO criteria met — clean stdlib endpoint, in-place open proven,
version-aware default proven against real saved data, graceful static fallback, bounded
decomposition. Decision is the human's (owner: human) via `fw task review T-142`.

## 7. Dialogue log (C-001 extension)

### 2026-07-07 — inception opened
- **Human:** "open inception" (after reviewing the browsing reflection + options A–D).
- **Agent:** Filed T-142 with DEFER; recommended Option A (in-editor browser) as the real
  fix but flagged it as inception-sized (new API route + modal) per G-020. Plan below
  presented for review before any spike executes.
- **Pending:** await human approval of the exploration plan (§4) before executing Spike 1.

### 2026-07-07 — human steer: version-awareness
- **Human:** "looks good; need to consider version — suggests to load latest version."
- **Agent:** Added IW-5 and a fourth assumption. Threaded latest-version resolution into
  Spike 1 (endpoint returns latest-per-map from `.editor-versions/<id>/index.json`) and
  Spike 2 (Open defaults to latest saved version, baseline fallback, older versions via the
  existing Versions modal). Updated Scope Fence and GO criteria. Root friction named: today
  `?load` opens the stale `rendered/` baseline, ignoring saved edits.

### 2026-07-07 — spikes executed (human: "1", "2")
- **Human:** approved executing the spikes and bringing a GO/NO-GO.
- **Agent:** Ran all three spikes without touching production (`gallery-serve.py`/`src`).
  Findings in §8; every IW answered (confidence 3). Recommendation revised DEFER → **GO**.
  Decision remains the human's via `fw task review T-142`. On GO, will file 2–3 build tasks.
- **Surfaced (separate concern):** 11/24 maps already carry saved versions — may be
  intentional corpus work or test residue; flagged for the human, not acted on here.
