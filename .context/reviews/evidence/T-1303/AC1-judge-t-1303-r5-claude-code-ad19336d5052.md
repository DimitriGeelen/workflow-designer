# T-1303 Human AC#1, independent review (rung-5-panel:claude-code, dispatch judge-t-1303-r5-claude-code-ad19336d5052)
Revision reviewed: f5fd98ac04ac2bd4fec73646e8401af3f2ee7673. The screenshots I read are in docs/reports/T-1303-evidence/.

## What I looked at
- findings-lint-1024/-1440/-1920 panel shots, plus the 1024 full viewport.
- findings-v11-1024/-1440/-1920 panel shots.
- findings-lint-edit-1440-panel-end and findings-lint-edit-1920-panel.
- For comparison: v11-step-1440-panel, v11-step-1440-panel-end and fields-edit-1024-panel.

## Findings
- **Lint step.** Output `contact` has one ERROR block directly under its name/type/× row. It has a red left edge, the word "ERROR", the full message and E-XML-IO-MATCH-MISSING. Output `account` has one WARN block with an orange edge and W-XML-IO-MATCH-UNRESOLVED. "(no inputs)" shows no finding. The typeRef/operation/targetSystem/field summary and "edit attributes" follow each finding, unchanged. This holds at 1024, 1440 and 1920. Nothing is clipped and nothing overflows the panel. At 1024 the full viewport shows the toolbar, the drawer listing the findings and the panel all intact.
- **v1.1 step.** Input `opp` has two ERROR blocks, E-XML-IO-PREFIX-UNDECLARED for sf: and for biz:, under its row. The name, type, the "req" checkbox and × are in place. The second input and the outputs have no finding.
- **Lint step with an editor open.** The ERROR stays under `contact` and above its summary and editor. The WARN stays under `account`, not under the editor.
- **Rule id.** It is small and in the muted label grey, but readable in every shot. The severity word and the message carry the meaning.

## Caveat on comparison step 2
findings-v11-1440-panel has opp's editor open ("close editor"); v11-step-1440-panel does not. So in findings-v11 the summary shows only expect/example lines, and the ref/typeRef/cardinality/field lines are missing. The task notes say the editor was "open from an earlier state". fields-edit-1024-panel and findings-lint-edit show the same pattern: with the editor open, the summary leaves out the attributes the editor shows. That behaviour comes from the editor, not from the findings. The summary lines that do show sit right after the findings and are readable. The comparison would be cleaner with the editor closed, but this does not affect the criterion.

## Verdict
green. Every finding sits under the io it names, none appears under a clean io, the text is readable, and the io rows and summaries are in place at all three widths.
