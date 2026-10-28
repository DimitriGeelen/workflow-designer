# T-1329: the seven job-C findings still open after T-1322 — one page to rule on

Source: cloud job C's bug hunt (`docs/reports/T-2466-cloud-job-C-bughunt.md`, F1-F13, on 8909a9b1). T-1322's GO
(job 099) and its slices T-1325-T-1327 closed six (F1, F2, F5, F7, F10, F11). Its report
(`docs/reports/T-1322-third-party-passthrough.md` §3, §5) left these seven as separate decisions. Each was re-checked
against the current source (bleeding-edge, 2026-10-28); line numbers are `src/aef-workflow-designer.html`.

**Who is exposed, in one line:** AEF's own maps are written by the designer, so they already carry `aef:uid`,
`Process_<id>`, designer DI, flat lanes and no subprocess contents. None of the seven changes an AEF map today. All
seven hit a file made in another tool (Camunda, bpmn-js, Bizagi, …) on its first save. That is also why each costs
little to leave for now.

| # | task | what a save does today | exposed | recommend | size |
|---|---|---|---|---|---|
| F4 | T-1262 | rewrites process id, `isExecutable`, definitions id, `targetNamespace`, collaboration id | third-party; the process id is the engine's deployment key | **keep the file's own values** | small |
| F12 | T-1270 | second file with the same process id is saved with `_v2` ids | anyone opening two `Process_1` files (5 of our 11 fixtures) | **suffix the library key only, never the saved ids** | small |
| F13 | T-1271 | nodes reordered by kind | third-party; cosmetic, noisy diffs | **keep document order** | small |
| F3 | T-1261 | original node/flow ids replaced by display ids, unrecoverable | third-party; anything referring to an id | **record the original id** (keep the display-id rule) | small-medium |
| F6 | T-1264 | shape sizes, labels, waypoints, pool/lane shapes redrawn | third-party; layout only | keep imported geometry until the person moves the element | medium |
| F8 | T-1266 | subprocess contents moved up into the process (2 start events, different meaning) | third-party with subprocesses (5 of 11 fixtures) | inception: write contents back inside the subprocess, drawn flat | medium-large |
| F9 | T-1267 | nested lanes flattened; nodes move to the parent lane (responsibility changes) | rare (0 of 11 fixtures) | defer; the import notice already says it | large |

Three of them (F6, F8, F9) are named by the import notice since T-1327. F3, F4, F12 and F13 are still silent, and
they are also the cheapest to fix.

## F4 · T-1262 — process and definitions identity (recommend: keep the file's own)

**Today:** `:13779` writes a fixed `targetNamespace`; `:13821` writes `Process_<workflowId>` and
`isExecutable="true"`; definitions and collaboration ids are derived the same way. T-1326 now keeps every *other*
root and process attribute (`PROC_READ_ATTRS`, `ROOT_READ_ATTRS` at `:14323`), so these few are the only ones still
replaced. **Why it matters:** a Camunda/Zeebe process id is what callers (`calledElement`) and deployments refer to;
a changed id breaks them. `isExecutable="false"` becoming `true` changes what an engine will deploy.
**Options:** (a) keep the original values when the file had them, derive them as today when it did not;
(b) leave as is. **Recommend (a).** Designer-written maps are unaffected (their original *is* `Process_<id>`).
**One check before building:** that nothing in AEF finds the workflow id by parsing `Process_<id>` rather than
reading `aef:workflowMeta` — a question for AEF, asked with the build.

## F12 · T-1270 — `_v2` ids on a second file with the same process id (recommend: library key only)

**Today:** `adoptImportedXml` (`:13046-13050`) appends `_v<n>` to `workflowMeta.id` on a library collision, and that
id feeds definitions, process, collaboration and DI ids, so the *saved file* changes. Project opens (`replace: true`,
how AEF opens maps) do not do this; plain file imports and gallery opens do. **Options:** (a) keep the suffix in the
designer's library key only and write the file's ids unchanged; (b) ask on collision (replace / keep both);
(c) leave as is. **Recommend (a)**: two open maps can share a process id without either file changing; (b) adds a
dialog for a case that needs no decision.

## F13 · T-1271 — node order (recommend: keep document order)

**Today:** import collects nodes one kind at a time (`nodeWork`, `:14879`: start events, then end events, tasks,
gateways), and export writes nodes and `flowNodeRef`s in that order (`:13864`). **Why it matters:** no meaning
changes, but every first save of a third-party file reorders it, which buries real changes in a diff.
**Options:** (a) collect in document order; (b) leave as is. **Recommend (a)**. Designer-written maps re-save
byte-identically either way (their order is already the designer's); the third-party goldens change once, checked
line by line as for T-1325.

## F3 · T-1261 — original ids (recommend: record them; keep the display-id rule)

**Today:** a node without `aef:uid` gets `deriveUid('n', id)` (`:14916`, flows `:15219`), a one-way hash, and is
saved under the designer's lane-prefixed display id (`app_1_approve`), a deliberate rule since 0.20. `Task_Approve`
appears nowhere in the output. **Options:** (a) record the original id (for example `aef:origin id="Task_Approve"`),
keep the display id; (b) keep original ids as the saved ids until the person renames or moves the element, which
breaks the lane-prefix rule for imported maps; (c) leave as is. **Recommend (a)**: it makes the id recoverable and
lets a tool map old to new, without reopening a rule people already rely on. If a third-party file must keep
deploying under its own ids, that is (b), and it is your call.

## F6 · T-1264 — imported geometry (recommend: keep it until the person moves the element)

**Today:** import reads only each shape's x/y; export writes default sizes and recomputed edge routes, and drops
`isMarkerVisible`, label bounds and pool/lane shapes. The notice says "shape sizes and line bends are NOT kept".
**Options:** (a) keep each element's imported DI until it is moved or resized, then redraw that element only;
(b) leave as is, notice stays. **Recommend (a), after F4/F12/F13.** It is layout only, so nothing breaks
meanwhile, but it is the most visible loss when a modeler user opens the saved file back in their tool.

## F8 · T-1266 — subprocess contents (recommend: an inception)

**Today:** contents are collected as if they were in the process (`foreignContainers`, `:14887`) and written there:
the saved process has two start events and an empty subprocess, which an engine runs differently. The notice names
it. **Options:** (a) remember each node's parent subprocess and write it back inside, still drawn flat; (b) a real
subprocess model (drawn nested); (c) leave as is with the notice. **Recommend an inception for (a)**: it restores the
meaning without a drawing change, but lanes, flows across the boundary and validation all need thought first.

## F9 · T-1267 — nested lanes (recommend: defer)

**Today:** child lanes become siblings and their nodes move to the parent lane. In AEF a lane carries authority
(mapping v1, IW-9: owner is the lane), so this silently changes who is responsible. The notice names it.
**Options:** (a) a lane hierarchy model; (b) refuse or warn louder on save; (c) defer. **Recommend (c)** until a real
file with nested lanes arrives: none of our fixtures or AEF's maps has one, and the model question (what authority a
child lane has) is yours and AEF's together.

## Suggested ruling

1. **GO on F4, F12, F13** as one small build each (in that order).
2. **GO on F3 option (a)** (record the original id).
3. **F6 next, after those.**
4. **Inception for F8; defer F9.**
