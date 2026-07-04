# rendered/ — generated BPMN-XML views of the corpus

**These files are generated, not hand-authored.** Each `*.bpmn` here is produced from the
canonical `../*.workflow.yaml` by the YAML→BPMN bridge (`tools/yaml-to-bpmn.py`, T-040) so
the mappings can be opened in the diagram editor (`src/aef-workflow-designer.html`), which
reads BPMN-XML rather than the canonical YAML.

Regenerate any file:

```
cd /opt/832-Workflow-designer && python3 tools/yaml-to-bpmn.py examples/aef-processes/inception-review.workflow.yaml --out examples/aef-processes/rendered/inception-review.bpmn
```

Browse the whole corpus interactively (T-041): `tools/serve-gallery.sh [PORT]` assembles a
self-contained serve root (gallery index + designer + these files) under `build/gallery/`
and serves it on the LAN. Each gallery entry opens the designer with
`?load=rendered/<name>.bpmn` — the editor fetches and opens the map on startup.

The canonical source of truth is always the `.workflow.yaml`. Do not edit these `.bpmn`
files by hand — changes will be overwritten on the next render. (Round-trip BPMN→YAML
write-back is deliberately out of scope; see T-038 Tier-3, deferred.)
