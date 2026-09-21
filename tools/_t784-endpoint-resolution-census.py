#!/usr/bin/env python3
"""T-784: do the workflows the Designer authors reach anything that runs?

Under the confirmed yardstick — "iterate from the workflow to actual working
applications" — an authored workflow is only load-bearing if its aef:endpoint
references resolve to code that exists. An endpoint pointing at nothing means the
authoring surface produces a document that cannot drive anything.

Resolution is attempted against BOTH roots, because a vendored consumer legitimately
references framework paths:
    <project>/<path>            e.g. tools/validate-workflow.py
    <project>/.agentic-framework/<path>   e.g. lib/notify.sh

Read-only.
"""
import glob, os, re, sys
from collections import Counter

ROOT = "/opt/832-Workflow-designer"
FW = os.path.join(ROOT, ".agentic-framework")
os.chdir(ROOT)

ENDPOINT_RE = re.compile(r"aef:endpoint[^>]*>([^<]+)<", re.S)


def resolve(ref):
    """(status, resolved_path_or_None). Status: project | framework | MISSING | opaque."""
    ref = ref.strip()
    if not ref:
        return "empty", None
    path = ref.split(":", 1)[0].strip()
    if not path:
        return "empty", None
    # Non-path endpoints (a bare verb, a URL) are not file references.
    if path.startswith(("http://", "https://")):
        return "opaque", path
    if "/" not in path and not path.endswith((".sh", ".py", ".js", ".mjs", ".html")):
        return "opaque", path
    for base, label in ((ROOT, "project"), (FW, "framework")):
        p = os.path.join(base, path)
        if os.path.isfile(p):
            return label, p
    return "MISSING", path


def main():
    files = sorted(set(glob.glob("**/*.bpmn", recursive=True)))
    per_ref = Counter()
    status_of = {}
    files_with = 0
    for fn in files:
        try:
            text = open(fn, encoding="utf-8", errors="replace").read()
        except Exception:
            continue
        refs = ENDPOINT_RE.findall(text)
        refs = [r.strip() for r in refs if r.strip()]
        if refs:
            files_with += 1
        for r in refs:
            per_ref[r] += 1
            if r not in status_of:
                status_of[r] = resolve(r)

    total_refs = sum(per_ref.values())
    by_status = Counter(status_of[r][0] for r in per_ref)
    weighted = Counter()
    for r, n in per_ref.items():
        weighted[status_of[r][0]] += n

    print("=== aef:endpoint resolution census ===")
    print("  .bpmn files scanned           : %d" % len(files))
    print("  files carrying an endpoint    : %d" % files_with)
    print("  endpoint references (total)   : %d" % total_refs)
    print("  distinct endpoint values      : %d" % len(per_ref))
    print()
    print("  by DISTINCT value :", dict(by_status))
    print("  by REFERENCE count:", dict(weighted))

    missing = sorted([r for r in per_ref if status_of[r][0] == "MISSING"],
                     key=lambda r: -per_ref[r])
    if missing:
        n_miss = sum(per_ref[r] for r in missing)
        print("\n=== MISSING — endpoint names a path that exists in NEITHER root ===")
        print("  %d distinct values, %d references (%.0f%% of all references)"
              % (len(missing), n_miss, 100.0 * n_miss / max(1, total_refs)))
        for r in missing[:25]:
            print("   %4dx  %s" % (per_ref[r], r[:90]))

    opaque = sorted([r for r in per_ref if status_of[r][0] == "opaque"],
                    key=lambda r: -per_ref[r])
    if opaque:
        print("\n=== opaque — not a file reference (verb/URL/identifier) ===")
        for r in opaque[:12]:
            print("   %4dx  %s" % (per_ref[r], r[:90]))

    resolved = sorted([r for r in per_ref if status_of[r][0] in ("project", "framework")],
                      key=lambda r: -per_ref[r])
    if resolved:
        print("\n=== resolves (top) ===")
        for r in resolved[:12]:
            print("   %4dx  [%s] %s" % (per_ref[r], status_of[r][0], r[:80]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
