Inspected all 48 screenshots at full resolution, with enlarged crops for small text. Filename braces below expand to every listed alternative; paths are relative to `docs/reports/T-1241-evidence/`. Counts represent grouped findings.

1. **Files:** `t1241-{business,logical,technical,all}-1024-{panel,panel-bottom}.png`. **Element:** “do the work; tick Agent ACs progressively”. **Problem:** The right properties panel cuts through the task; almost all its name and shape are outside the visible canvas. **Severity: blocks the criterion.**

2. **Files:** `t1241-{business,logical,technical,all}-1024-{panel,panel-bottom}.png`. **Element:** “Handoff → dispatch loop”. **Problem:** Only the beginning of the caption is visible at the right canvas edge; the panel-collapse tab overlaps that remaining fragment. The event itself is outside the visible canvas. **Severity: blocks the criterion.**

3. **Files:** `t1241-{business,logical,technical,all}-1440-{panel,panel-bottom}.png`. **Element:** “resolved at gate — complete directly (issues → work-completed)”. **Problem:** The label runs behind the properties panel and is cut off. The downstream flow, including “gates pass?”, “unchecked Human ACs?”, and the archive/end nodes, is outside the captured canvas. **Severity: blocks the criterion.**

4. **Files:** `t1241-{business,logical,technical,all}-{1024,1440,1920}-panel.png`; additionally `t1241-{business,logical}-{1024,1440,1920}-panel-bottom.png` and `t1241-{technical,all}-1920-panel-bottom.png`. **Element:** Name field, “create task — fw work-on (status: captured)”. **Problem:** The single-line field visibly cuts the value after approximately “captu”. The complete value is available in the details dialog, but the panel presentation is clipped. **Severity: blocks the criterion.**

5. **Files:** `t1241-{business,logical,technical,all}-{1024,1440,1920}-{panel,panel-bottom}.png`. **Elements:** “HANDOFFS”, “TYPED EVENTS”, “LANES”. **Problem:** The left palette extends below the viewport: at 1024 the handoff controls are absent below their heading; at 1440 “TYPED EVENTS” is sliced at the bottom; at 1920 “LANES” reaches the bottom with its controls absent. The supplied bottom captures do not expose this palette content, so its reachability is unverified. **Severity: blocks the criterion as evidenced.**

6. **Files:** `t1241-{business,logical,technical,all}-{1024,1440,1920}-{panel,panel-bottom}.png`. **Elements:** Task names, particularly “create task — fw work-on (status: captured)” and “parked in backlog (horizon: next/later)”; at 1440/1920, “completion gates: Agent ACs (P-010) + ## Verification commands (P-011)”. **Problem:** Text is compressed into tiny multiline lettering at the captured 78% zoom. The completion task is particularly difficult to read without enlargement. **Severity: blocks the criterion.**

7. **Files:** `t1241-{business,logical,technical,all}-{1024,1440,1920}-{panel,panel-bottom}.png`. **Elements:** “shelved — horizon next/later auto-demotes to captured (T-1068)”, “promoted — fw work-on T-XXX”, and lane captions “AGENT · INITIATIVE” / “HUMAN SOVEREIGNTY”. In technical/All, also captions such as “agt_1_create”, “agt_gw_ready”, and “agt_2_parked”. **Problem:** Very small, low-contrast lettering makes these labels difficult to distinguish at native resolution. **Severity: blocks the criterion.**

8. **Files:** `t1241-business-{1024,1440,1920}-{panel,panel-bottom}.png`. **Elements:** “T-1068” in the shelved-flow label and “fw work-on T-XXX” in the promoted-flow label. At 1440/1920, also “P-010”, “## Verification commands”, and “P-011” in the completion task. **Problem:** Technical identifiers and command/document syntax remain visible in the business flow. **Severity: blocks the criterion.**

9. **Files:** `t1241-business-{1024,1440,1920}-{panel,panel-bottom,details,details-bottom}.png`. **Element:** Note, “G-020 blocks source edits until real ACs exist”. **Problem:** The business panel and business details retain a technical rule identifier and implementation-oriented wording. Under the requested literal “without ids” criterion, this is another leak. **Severity: blocks the criterion.**

10. **Files:** `t1241-business-{1024,1440,1920}-{panel,panel-bottom}.png`. **Elements:** Palette descriptions “startEvent”, “endEvent”; at 1920, “on status:issues”, “cron / horizon”, and “on bus topic”. **Problem:** Technical type names and execution terminology remain exposed in the business interface. **Severity: blocks the criterion.**

11. **Files:** `t1241-{business,logical,technical,all}-{1024,1440,1920}-{details,details-bottom}.png`, where the corresponding fields are visible. **Elements:** Helper text including “free notes · multi-line”, “derived from lane (initiative)”, “task workflow_type”, and “paths · comma-separated”. **Problem:** Small, muted helper text has weak contrast. Enlargement makes it readable; main labels and values remain distinguishable. **Severity: cosmetic.**

No visible flow-to-text crossings or text-to-text collisions were found. Toolbar controls and dialog Close buttons are contained. Technical/All bottom captures demonstrate access to lower form controls; ordinary scrolling boundaries were not counted as unreachable controls. Temporary crops were deleted; no repository files or ledger were changed.

ADVISORY: 10 blocking, 1 cosmetic
