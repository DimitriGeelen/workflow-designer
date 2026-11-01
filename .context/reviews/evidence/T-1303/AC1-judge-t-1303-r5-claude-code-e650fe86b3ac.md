# T-1303 Human AC#1 — reviewer judge-t-1303-r5-claude-code-e650fe86b3ac (rung-5-panel:claude-code), revision 290281a46

Verdict: **green**

Screenshots read (from docs/reports/T-1303-evidence/, retaken at 290281a46 per its commit message):
findings-lint-{1024,1440,1920}-panel, findings-lint-1024 (full), findings-v11-{1024,1440,1920}-panel,
findings-v11-1920 (full), findings-lint-edit-1440-panel-end, findings-lint-edit-1920-panel,
v11-step-1440-panel, fields-when-1440-panel (comparison: same editor open, no Check).

Findings:
- Lint step, all three widths: output `contact` has one ERROR line directly under its name/type/× row
  (red left edge, "ERROR", message 'operation="update" with no aef:field role="match"...', rule id
  E-XML-IO-MATCH-MISSING). Output `account` has one WARN line under its row (orange edge,
  W-XML-IO-MATCH-UNRESOLVED). Each finding is followed by that io's v1.1 summary (typeRef/operation/
  targetSystem/field) and "edit attributes", unchanged. Name field, type select and × stay on the row.
  Nothing wraps outside the panel; "+ add output" and the clean inputs section ("no inputs") show no finding.
- v1.1 step (1024/1440/1920 panel): input `opp` has two ERROR lines (prefix 'sf' in typeRef, prefix 'biz'
  in conceptRef, E-XML-IO-PREFIX-UNDECLARED each) right under its row; name, type, req checkbox, × in place.
  The second input, and the outputs, show no findings (clean ios clean).
- Comparison: v11-step-1440-panel (no editor, no Check) shows opp's full summary. findings-v11-1440-panel
  has the editor open, so it shows only the summary lines not in the editor (expect/example). That matches
  fields-when-1440-panel (same editor open, no Check) line for line, so the summary is not displaced by the
  findings. The editor's own prefix hints agree with the two findings.
- Lint step with editor open (lint-edit 1440 panel-end, 1920 panel): the ERROR stays under `contact`'s row,
  above its summary and the editor; the WARN stays under `account`, not inside the editor.
- Full viewport (findings-lint-1024, findings-v11-1920): the panel's findings are legible, the toolbar is complete,
  and the Validator drawer lists the document-wide findings.
  The E-XML-NODE-UNASSIGNED rows are a fixture property, which the task already notes. They do not belong to this criterion.
- Legibility: severity and message are clearly readable. The rule id is smaller and muted grey but legible at all widths.

Gap (not affecting verdict): there is no -panel-end shot at 1920 for findings-lint / lint-edit, but the 1920 panel shot
already shows the whole I/O section down to "+ add output".
