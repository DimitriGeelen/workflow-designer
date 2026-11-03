ADVISORY: independent visual read of a designer change, before the official review. Report findings only; change no files.

Change (832 T-1381): the AEF Workflow Designer now draws BPMN data stores (bpmn:dataStoreReference) as cylinders with
their name, under the task that writes them (else the first that reads them), side by side with that task's documents,
with dotted links to the tasks; the lane grows to hold them. A store no task links to is not drawn (the import notice
names it).

Read these screenshots in /opt/832-Workflow-designer/docs/reports/T-1381-evidence/ (fixture:
tests/fixtures/t1381/data-stores.bpmn, made up):
- stores-1024.png, stores-1440.png, stores-1920.png: the whole window at three widths, opening state;
- stores-1024-zoom.png, stores-1440-zoom.png, stores-1920-zoom.png: the pool, 2x;
- stores-1920-zoom-before.png: the same map on the previous source (stores not drawn), for comparison.

What to check, control by control:
1. Each cylinder reads as a BPMN data store (top ellipse, body, rims) and is distinct from the document page beside it.
2. Order book and the Order confirmation document under "Record the order": do shapes or labels touch or overlap?
3. Labels: readable, centred under their shape, not clipped, enough contrast.
4. The four dotted links: can a reader tell their direction? Especially Stock -> "Check stock", whose arrowhead lands
   where the task's id badge (war_1_check) sits: is the arrowhead visible, and does the line collide with the badge text?
5. The Warehouse lane grew to hold Stock: does anything sit on or across a lane border? Is the extra lane height
   reasonable?
6. Anything else a person would notice at any of the three widths (toolbar, panels, clipping, overlap).

Return a numbered list of findings, each with: the screenshot file, what you see, severity (blocker / should-fix /
nit), and a suggested fix. Say plainly if you find nothing at a check.
