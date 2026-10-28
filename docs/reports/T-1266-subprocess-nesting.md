# T-1266: can a save write a subprocess's contents back inside it?

**Status:** framed, research not started (2026-10-28). Inception per the operator's ruling on
`docs/reports/T-1329-open-job-c-findings-brief.md` (job C F8).

## The question (IW-1)

Today a save moves a subprocess's contents up into the process: import collects nodes from the process and from every
subProcess inside it (`foreignContainers`), and export writes them all as direct children of `<process>`. The saved
process then has two start events and an empty subprocess, which an engine runs differently. The import notice names it
(T-1327). Can the designer write the contents back inside the subprocess on save, while still drawing them flat,
without breaking lanes, flows that cross the subprocess boundary, display ids, or validation?

## Options to weigh

- **(a)** remember each node's parent subprocess at import and nest it on export, drawn flat (no canvas change);
- **(b)** a real nested subprocess model, drawn nested;
- **(c)** keep the notice only.

## What the research must establish first

- Which subprocess shapes the fixtures carry (5 of 11 third-party files have one): plain, event, transaction,
  ad-hoc; nesting depth; whether any flow crosses the subprocess boundary.
- How lanes relate: a lane's flowNodeRef may name a node inside a subprocess.
- What happens to a nested node the person moves or deletes, and to a flow drawn into or out of the subprocess.
- What AEF's importer does with nested contents (their maps carry none today).
- The duplicate display ids of events inside subprocesses (T-1102) touch the same code path.

## Dialogue Log

- 2026-10-28, operator, on the T-1329 brief: "Proceed as you should fit and suggest" — F8 becomes an inception.
