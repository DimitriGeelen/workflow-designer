# Workflow Designer 0.19.1 — release notes

**Since:** `designer-v0.19.0` (2026-10-12) · **Patch: field settings only where the server offers them.** Reported by
Greenfield in their 0.18.0 re-test.

## Fix

- **Field settings and "Suggest as a field" stayed usable on a project server that does not offer them (T-1134).**
  A portal that serves maps (`/api/health`, `/api/list`, `/api/save`) but not the field endpoints answers
  `/api/field-profile` with "404 not found". The designer read that as "this project has no field settings yet", so
  Settings → "Fields shown by default" stayed editable and Save then failed ("HTTP 403"); the "Suggest as a field"
  button (0.19.0) had the same weakness. Now only the endpoint's own answer counts: on a server without it, the
  section is read-only and says "This project server does not offer field settings", no per-map settings are
  offered, and the suggest button is disabled with the reason. Nothing else changes: on a server with the endpoints
  everything works as in 0.19.0.

## Authoring kit

Content unchanged. Re-issued as 0.19.1 with its own calibration record (`docs/authoring-kit/calibration-records/0.19.1.yaml`).

## Re-test (Greenfield)

1. On your portal: Settings → "Fields shown by default" — every row and Save are disabled; the line above says your
   project server does not offer field settings. The "Project field profile" readout says the same.
2. Select an element with an entry under "Other extensions": "Suggest as a field" is disabled; hovering it says the
   server does not offer field suggestions.
3. Everything else as 0.19.0 (filled-only panel, details view, data kept on save).
