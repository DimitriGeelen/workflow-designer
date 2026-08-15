#!/usr/bin/env python3
"""
T-520 — read aef:uid values from a BPMN document using a CONFORMING XML parser.

Why this exists as a separate reader. The probe that needs it (_t520-uid-xml-safety.mjs) drives
the editor in a browser, and the obvious way to read the result back is the browser's own
DOMParser. That produced a false green: the editor emits a RAW newline inside the
`<aef:uid value="..."/>` attribute, Chrome's DOMParser hands it back unchanged, and the value
looked byte-identical across a full round-trip.

XML 1.0 §3.3.3 says otherwise. Attribute-value normalisation replaces every literal newline,
carriage return and tab in an attribute value with a SPACE before the application ever sees it.
A value must be written as a numeric character reference (&#10;) to survive. expat does this;
so does lxml, so does Java, so does every conforming parser — including whatever reads the
document on AEF's side.

So the divergence is not cosmetic. It means a uid containing whitespace reads back one way in
the editor and a different way in every conforming consumer, silently, with no error on either
side. Measuring the seam with the browser's parser alone would certify exactly the corruption
the probe exists to find — the instrument would agree with the defect.

Reads a document on stdin, writes {"parsed":bool,"error":str|null,"uids":[...]} on stdout.
Exit 0 always: an unparseable document is a RESULT, not a failure of this reader.
"""
import json
import sys
import xml.etree.ElementTree as ET

AEF = "http://anchorpoint.framework/aef/extensions"


def main():
    raw = sys.stdin.buffer.read()
    try:
        root = ET.fromstring(raw)
    except ET.ParseError as e:
        print(json.dumps({"parsed": False, "error": str(e)[:200], "uids": []}))
        return 0
    uids = [el.get("value") for el in root.iter("{%s}uid" % AEF)]
    print(json.dumps({"parsed": True, "error": None, "uids": uids}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
