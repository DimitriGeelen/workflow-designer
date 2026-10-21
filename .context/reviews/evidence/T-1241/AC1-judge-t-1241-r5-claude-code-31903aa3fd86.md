# T-1241 AC1 — independent screenshot review (rung-5-panel:claude-code, judge-t-1241-r5-claude-code-31903aa3fd86)

Revision 0a166c491e611f240edb826bb793c9676a2a8c81. Source: docs/reports/T-1241-evidence/ (48 lens shots, 4 lenses x 3 widths x panel/details x top/bottom).
Note: business and logical "-bottom" shots are byte-identical to their top shots (md5) — nothing to scroll there; technical/all bottom shots differ.

## Viewed
business 1024/1440/1920 panel, business 1440 details, logical 1920 panel, technical 1920 panel (canvas crop), technical 1024 details-bottom; canvas crops at 2-4x.

## Met
- Toolbar: every control present and unclipped at 1024/1440 (two rows) and 1920 (one row, Save at right edge); lens select shows lens name.
- Business lens reads as a business view: panel header "Service task" (plain word, no id), Name/Lane/Note/Owner only; no Slug/UID/AEF:/I/O; pool label "AEF task lifecycle" without workflow id; no id captions or technical badges on the canvas. Details sheet: subtitle "business fields · edits apply to the element", Close reachable, two columns, nothing clipped.
- Logical: +4 empty fields, I/O contract, no ids. Technical: id captions + workflow id on canvas; details-bottom at 1024 reaches Other extensions / I/O contract with Close reachable.
- Gateway/event names and id captions no longer crossed (T-1256 effect visible).

## Not met — "nothing ... overlapping" on the canvas (flow/edge labels)
1. business-1920-panel (crop-b1920-status): edge label "yes — status: issues" is crossed by a vertical flow line running through "status:" (between 's' and ':'). Same in logical-1920-panel.
2. business-1920-panel (crop-b1920-shelved): edge label "next/later — backlog" sits on top of "shelved — horizon next/later auto-demotes to captured (T-1068)"; the descender of "backlog" is cut ("backloq"). Same in technical-1920 and logical-1920.
3. business-1440-panel (crop-b1440-shelved): a vertical flow line passes through the "shelved — horizon next/later auto-demotes …" label (near "later auto").

These are sequence-flow labels, which T-1256's pass (gateway/event names + id captions) did not cover. Panels, details and controls are fine.

## Verdict: amber
Needed: move sequence-flow labels clear of flows and of each other on aef-task-lifecycle (at least the three above, in every lens at 1440/1920), re-shoot, or have the operator explicitly accept edge-label overlaps as out of scope for T-1241 (pre-existing in 0.24.0 per the task's own note).
