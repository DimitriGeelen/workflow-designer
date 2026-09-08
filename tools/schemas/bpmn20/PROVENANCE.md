# BPMN 2.0 XSDs — vendored, unmodified

Fetched 2026-09-08 for T-423's remaining acceptance criterion, which requires validating an
exported map **against the BPMN 2.0 DI schema — not by grepping for the element names**.

Source: the OMG canonical spec host, `https://www.omg.org/spec/`.

| file | URL | sha256 |
|---|---|---|
| `BPMN20.xsd`   | `/spec/BPMN/20100501/BPMN20.xsd`   | `a07c159cb0594573dd7c97b1370dd116112378f377e43c89a8bf512ac5030705` |
| `Semantic.xsd` | `/spec/BPMN/20100501/Semantic.xsd` | `c4318842f7d2bbc262d7954c9452c501db16f0868eac0b8732ec5d7fb384d9a7` |
| `BPMNDI.xsd`   | `/spec/BPMN/20100501/BPMNDI.xsd`   | `f0dff1cd559d1514d8ebfc8c646f58402bcaced27ec22e2aa6456c2dcc80b038` |
| `DC.xsd`       | `/spec/BPMN/20100501/DC.xsd`       | `a2f90e5ad9bb48c6915e4e034b4e27ac838264a1d4f27bfc70dbdfc69351312d` |
| `DI.xsd`       | `/spec/BPMN/20100501/DI.xsd`       | `8220b179c175572df74e08a51bffabe957867962035cee7b5fee0b6acb4c4498` |

**Files are byte-identical to what the OMG served. Nothing here is hand-edited**, so a future
reader can re-fetch and diff. `tools/_t423-di-schema-validate.py --verify-schemas` re-checks
these digests, so a silent local edit to a schema — which would quietly weaken every validation
run downstream — fails rather than passes.

## Two retrieval details worth recording, because both cost time

- `DC.xsd` and `DI.xsd` are **not** at the `/spec/DD/20100524/` path their target namespaces
  suggest; that path returns HTTP 404. `BPMNDI.xsd` imports them with *relative*
  `schemaLocation="DC.xsd"`, so they are colocated with it under `/spec/BPMN/20100501/`. The
  namespace URI and the retrieval URL are different things here.
- All five `schemaLocation` references are relative, so the set resolves purely from this
  directory with no network access and no catalog. That is why they are vendored together
  rather than individually.

## Why vendored rather than fetched at check time

A validation gate that reaches the network fails when the network does, and reports that as a
schema violation. It would also mean the thing being validated against could change without a
commit. These bytes are pinned so a red result means the document changed.
