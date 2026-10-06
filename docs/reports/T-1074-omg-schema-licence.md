# T-1074 — Licence check: the five OMG BPMN 2.0 XSDs in tools/schemas/bpmn20 (input for T-423)

Not legal advice: a reading of the published terms against our facts, so the operator can rule.

## The facts

- **What:** BPMN20.xsd, Semantic.xsd, BPMNDI.xsd, DC.xsd, DI.xsd — the normative machine-readable files of
  the OMG BPMN 2.0 specification, byte-identical to what omg.org served on 2026-09-08 (sha256 pinned in
  `tools/schemas/bpmn20/PROVENANCE.md`). Committed in 811bbed7 under T-423 without a recorded authorisation.
- **Used by:** our own validation only — `tools/_t423-di-schema-validate.py` (bridge suite) validates exported
  maps against the BPMN 2.0 DI schema. Not shipped in the designer build.
- **Notice:** the files carry **no copyright or permission notice**, and PROVENANCE.md quotes none.
- **Where the repo lives:** one remote, `origin = ssh://git@192.168.10.201:6611/workflow-designer` (our internal
  OneDev). No public mirror of this repository.

## The terms (source: ScanCode LicenseDB, "OMG BPMN 2.0", category *Proprietary Free* —
https://scancode-licensedb.aboutcode.org/omg-bpmn-2.0.html)

1. *"The owners of the copyright in this specification hereby grant you a fully-paid up, non-exclusive,
   nontransferable, perpetual, worldwide license (without the right to sublicense), to use this specification
   to create and distribute software."*
2. Copying/distributing the specification itself: *"…provided that: (1) both the copyright notice identified
   above and this permission notice appear on any copies"*; ScanCode also lists: informational use, no posting
   on network computers or broadcast, no resale, no modification.

## Reading

- **Using** the XSDs to build and run our validator fits grant 1.
- **Keeping copies** in a repository is copying the specification's files, which grant 2 conditions on the
  notice appearing on the copies — **our copies do not carry it** (the one clear gap).
- "No posting on network computers" sits awkwardly with any git hosting; an internal, access-controlled server
  is the low-risk end of that, a public mirror would not be.

## Options for the operator (T-423 ruling)

| | Option | Effect | Cost |
|---|---|---|---|
| **A (recommended)** | Keep; add the OMG copyright + permission notice (the spec's "USE OF SPECIFICATION" text, verbatim) beside the files and in PROVENANCE.md; rule that this repo stays internal | closes the notice gap; validation unchanged | small |
| B | Do not keep copies: fetch on first use into a git-ignored cache, sha256-pinned (the digests already exist) | no redistribution at all | validation needs network once; PROVENANCE's argument against network-at-check-time applies |
| C | Remove the files and amend T-423's schema criterion | no question left | loses real schema validation of exports |

Recommendation: **A**, with a standing note that if this repository is ever mirrored publicly, switch to **B**
first. The verbatim notice text is copied from the specification's front matter when A is carried out.

## Ruling (2026-10-06)

The operator asked for more background in session, then ruled **A**. Carried out:
- `tools/schemas/bpmn20/NOTICE.md`: the specification's copyright lines and its full "USE OF SPECIFICATION -
  TERMS, CONDITIONS & NOTICES" section, verbatim from https://www.omg.org/spec/BPMN/2.0/PDF (formal/2011-01-03,
  front matter), with the PDF's sha256. Two words split across lines in the PDF were rejoined as printed.
- `tools/schemas/bpmn20/PROVENANCE.md`: a "Licence and notice" section pointing to it, and the standing rule
  that this repository stays internal (switch to B before any public mirror).
- The XSDs are untouched: `tools/_t423-di-schema-validate.py --verify-schemas` still verifies all five digests.
