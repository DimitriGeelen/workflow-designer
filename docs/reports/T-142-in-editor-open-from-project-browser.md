# T-142 — In-editor "Open from project" browser for workflow files

**Type:** Inception (exploration) · **Status:** exploring · **Recommendation at filing:** DEFER
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

**Spike 1 — endpoint shape (`/api/list`).** Prototype a read-only endpoint in
`gallery-serve.py` returning, for each map: `id`, `title`/description (parsed from the
BPMN `aef:` metadata or filename fallback), source (`rendered` vs `saved`), latest version
+ thumb availability. Decide: one merged list or two sections (corpus vs your saved maps)?
Measure response shape/size for 24 maps. *Deliverable: JSON schema + sample payload.*

**Spike 2 — modal UX.** Prototype an in-editor "Open…" modal mirroring the existing
Versions modal pattern (`openVersionsModal`, `src:6867`) — grid of thumbnail + title +
source badge, with a client-side filter box. Decide: does opening a map reuse the existing
`?load` fetch path (in-memory, no reload) via `adoptImportedXml`, avoiding the full-page
reload? *Deliverable: interaction sketch + which code path it reuses.*

**Spike 3 — saved-work visibility & static fallback.** Confirm `.editor-versions/*` can be
enumerated cheaply and that the whole feature hides cleanly on the static gallery.
*Deliverable: fallback behavior confirmed against `python -m http.server`.*

## 5. Open questions (mirror of task `## Open Questions`)

- **IW-1** — `/api/list` shape (fields; merged vs corpus/saved split). *deferred → Spike 1.*
- **IW-2** — in-place open reusing `?load`/`adoptImportedXml` (no reload). *deferred → Spike 2.*
- **IW-3** — clean hide on the static gallery (detectSaveApi precedent). *deferred → Spike 3.*
- **IW-4** — build decomposes into ≤2–3 bounded tasks. *deferred → confirmed at decide.*

## 6. Go/No-Go criteria (decision at end of exploration)

- **GO** if: `/api/list` has a clean, stdlib-only shape; the modal opens a map in-place
  (no reload) reusing existing paths; the feature hides on the static gallery; and the
  build decomposes into ≤2–3 bounded build tasks (endpoint, modal, saved-work surfacing).
- **NO-GO / narrow to B+D** if: the endpoint or modal proves disproportionate, or in-place
  open can't reuse existing paths safely — fall back to enhancing the gallery index page
  (thumbnails + search) + surfacing saved work, which needs no new editor modal.

## 7. Dialogue log (C-001 extension)

### 2026-07-07 — inception opened
- **Human:** "open inception" (after reviewing the browsing reflection + options A–D).
- **Agent:** Filed T-142 with DEFER; recommended Option A (in-editor browser) as the real
  fix but flagged it as inception-sized (new API route + modal) per G-020. Plan below
  presented for review before any spike executes.
- **Pending:** await human approval of the exploration plan (§4) before executing Spike 1.
