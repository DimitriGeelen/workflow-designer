# T-743 Human AC#1 — reviewer evidence (judge-t-743-r3-db593ce3399d)

Revision reviewed: b78ba73d74836d178da5d6d28e0525f80f30a320
Criterion: "[REVIEW] The 0.12.0 editor is the one you want to be using."

## What I checked

1. **Live served bytes (Steps 1).** `curl $(cat .context/working/watchtower.url)/designer/app`
   (http://192.168.10.107:3013) returns 1176028 bytes, sha256 `a42f16b3…`, which is
   **0.24.0**, not 0.12.0. At b78ba73d the pin `.agentic-framework/policy/designer-pin.yaml`
   says `version: "0.24.0"`. Because the 0.12.0 bytes are no longer what /designer/app serves,
   the steps as written cannot be carried out against 0.12.0.
2. **Pin history.** `git log -- .agentic-framework/policy/designer-pin.yaml`: c1129bcc (T-743, 0.12.0,
   2026-09-21), then T-1007 (0.15.2), T-1008 (0.15.3), T-1105 (0.16.0), … T-1197 (0.22.0),
   T-1202 (0.23.0), T-1225 (0.24.0). The pin was **never moved back** to 0.8.0, although that
   revert was the documented one-line "If not" path. The pin has only moved forward since 0.12.0.
3. **The 0.12.0 artifact works (headless Chromium, Playwright, file://).** The retained
   `vendor/designer/aef-workflow-designer-0.12.0.html` and `0.8.0.html` both render with no
   page exceptions. The only console error in each is the expected `file:///api/health` fetch,
   which is a file:// artefact. 0.12.0 shows the lanes ("+ Add Lane", "Add another lane", lane
   headers), Connect mode, Save, Load…, View XML, Clean layout and Settings, with the sample
   `investigate` workflow drawn across lanes.
   Screenshots: AC1-judge-t-743-r3-db593ce3399d-0.12.0.png, AC1-judge-t-743-r3-db593ce3399d-0.8.0.png.

## What I could NOT check

- "Save to project" for 0.12.0 against the live server. The server now serves 0.24.0, and I did
  not change the pin or the server (read-only role).
- Whether 0.9→0.12 "reads as an improvement for *your* workflow". That needs the operator's
  hands-on use of the editor, and the bytes it asks about have since been replaced.

## Assessment

The 0.12.0 editor loads and its main surfaces are there. The operator was never driven to the
documented revert, and later moved the pin forward eleven more times. Together these show
0.12.0 was not a regression. The criterion is now **superseded**: the live editor is 0.24.0,
so the requested live exercise of 0.12.0 can no longer be done as written.

Verdict: **amber**. Retire the criterion as superseded by the later intakes (T-1007…T-1225),
or re-scope it to the currently pinned 0.24.0 if a live hands-on check is still wanted.
