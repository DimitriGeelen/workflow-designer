#!/usr/bin/env python3
"""set-workflow-kind — declare aef:workflowMeta/@kind across the corpus (T-876).

The rendered corpus (examples/aef-processes/rendered/*.bpmn) is EDITOR-SAVED dialect (T-288).
It must never be regenerated with tools/yaml-to-bpmn.py (G-012, T-300). And it is not at the
CURRENT editor's serialisation fixpoint either: measured 2026-11-14, a plain adopt+save of
arc-lifecycle by the current editor rewrites ~108 lines (DI shapes, exporter attribute) that have
nothing to do with kind. So this tool does NOT write the editor's whole output back. It asks the
real editor (tools/_set-workflow-kind-cdp.mjs) for two serialisations of each map, unchanged and
with the kind set, takes the editor's own delta between them, and applies exactly that delta to
the committed file. It refuses a map whose delta is anything but the single aef:workflowMeta line.

Per map it then:
  * writes rendered/<map>.bpmn (and the untracked build/gallery mirror, when present);
  * mints a .editor-versions/<map>/ version with the same bytes when the map has a store
    (the T-145 adopt gate: rendered must equal the latest store save), with the editor's thumbnail;
  * adds `kind: <kind>` under `workflowMeta:` in ../<map>.workflow.yaml (the semantic source),
    one line after `id:`, when absent.

Usage:
  tools/set-workflow-kind.py <documentation|work-plan> [--dry-run|--check] [map ...]
    (no maps -> every rendered/*.bpmn)
  --dry-run  report what would change, write nothing
  --check    exit 0 when every map already declares <kind> in both forms, 1 when not
Exit codes: 0 done/ok, 1 --check found maps without the kind, 2 refused (nothing written).
Needs Node >= 22 on PATH (the CDP driver uses Node's native WebSocket).
"""
import base64
import difflib
import json
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.path.join(ROOT, "examples", "aef-processes")
RENDERED = os.path.join(CORPUS, "rendered")
GALLERY = os.path.join(ROOT, "build", "gallery")
DRIVER = os.path.join(ROOT, "tools", "_set-workflow-kind-cdp.mjs")
KINDS = ("documentation", "work-plan")
WM_LINE = re.compile(r"^\s*<aef:workflowMeta\b")


def refuse(msg):
    sys.stderr.write("REFUSING: " + msg + "\nNothing was written.\n")
    raise SystemExit(2)


def changed(a, b):
    return [l for l in difflib.unified_diff(a.splitlines(), b.splitlines(), lineterm="", n=0)
            if l[:1] in "+-" and l[:3] not in ("+++", "---")]


def kind_delta(name, res, kind):
    """The editor's own change for setting the kind: exactly one workflowMeta line, old -> new."""
    if not res.get("ok"):
        refuse("%s: the editor could not process the map: %s" % (name, res.get("error")))
    d = changed(res["xmlUnchanged"], res["xml"])
    minus = [l[1:] for l in d if l[0] == "-"]
    plus = [l[1:] for l in d if l[0] == "+"]
    if len(minus) != 1 or len(plus) != 1 or not WM_LINE.match(minus[0]) or not WM_LINE.match(plus[0]):
        refuse("%s: setting kind changed more than the aef:workflowMeta line (%d lines)" % (name, len(d)))
    if ('kind="%s"' % kind) not in plus[0]:
        refuse("%s: the editor's new workflowMeta line does not carry kind=\"%s\"" % (name, kind))
    return minus[0], plus[0]


def patch_bpmn(name, text, old, new):
    if text.count(old + "\n") + (1 if text.endswith(old) else 0) != 1:
        refuse("%s: the committed file does not hold the editor's workflowMeta line exactly once" % name)
    return text.replace(old, new, 1)


def yaml_has_kind(text, kind):
    m = re.search(r"^workflowMeta:\n((?:[ \t]+.*\n?)*)", text, re.M)
    return bool(m and re.search(r"^  kind: %s\s*$" % re.escape(kind), m.group(1), re.M))


def patch_yaml(name, text, kind):
    if yaml_has_kind(text, kind):
        return text
    lines = text.split("\n")
    try:
        start = lines.index("workflowMeta:")
    except ValueError:
        refuse("%s.workflow.yaml has no top-level workflowMeta: block" % name)
    for i in range(start + 1, len(lines)):
        if not lines[i].startswith("  "):
            break
        if re.match(r"^  kind:", lines[i]):
            refuse("%s.workflow.yaml already declares a different kind: %s" % (name, lines[i].strip()))
        if re.match(r"^  id:", lines[i]):
            lines.insert(i + 1, "  kind: %s" % kind)
            return "\n".join(lines)
    refuse("%s.workflow.yaml: no `id:` under workflowMeta" % name)


def mint_store_version(base, xml, thumb_data_url, kind):
    store = os.path.join(ROOT, ".editor-versions", base)
    idx_path = os.path.join(store, "index.json")
    if not os.path.exists(idx_path):
        return None
    with open(idx_path) as fh:
        idx = json.load(fh)
    latest = max(e["v"] for e in idx)
    with open(os.path.join(store, "v%d.bpmn" % latest), "rb") as fh:
        if fh.read() == xml.encode():
            return None
    v = latest + 1
    with open(os.path.join(store, "v%d.bpmn" % v), "w") as fh:
        fh.write(xml)
    entry = {"v": v, "ts": int(time.time() * 1000),
             "note": "T-876 kind=%s backfill (editor-derived delta)" % kind, "bytes": len(xml.encode())}
    if thumb_data_url and thumb_data_url.startswith("data:image/png;base64,"):
        with open(os.path.join(store, "v%d.png" % v), "wb") as fh:
            fh.write(base64.b64decode(thumb_data_url.split(",", 1)[1]))
        entry["thumb"] = "v%d.png" % v
    idx.append(entry)
    with open(idx_path, "w") as fh:
        json.dump(idx, fh, indent=2)
    return v


def main(argv):
    flags = {"--dry-run", "--check"}
    bad = [a for a in argv if a.startswith("-") and a not in flags]
    if bad:
        refuse("unknown flag(s): %s" % " ".join(bad))
    args = [a for a in argv if not a.startswith("-")]
    if not args or args[0] not in KINDS:
        refuse("first argument must be one of %s" % ", ".join(KINDS))
    kind, names = args[0], args[1:]
    if not names:
        names = sorted(f[:-5] for f in os.listdir(RENDERED) if f.endswith(".bpmn"))
    for n in names:
        for p in (os.path.join(RENDERED, n + ".bpmn"), os.path.join(CORPUS, n + ".workflow.yaml")):
            if not os.path.exists(p):
                refuse("%s does not exist" % os.path.relpath(p, ROOT))

    if "--check" in argv:
        missing = []
        for n in names:
            bpmn = open(os.path.join(RENDERED, n + ".bpmn")).read()
            yml = open(os.path.join(CORPUS, n + ".workflow.yaml")).read()
            wm = [l for l in bpmn.splitlines() if WM_LINE.match(l)]
            if len(wm) != 1 or ('kind="%s"' % kind) not in wm[0] or not yaml_has_kind(yml, kind):
                missing.append(n)
        print("kind=%s declared in both forms: %d of %d" % (kind, len(names) - len(missing), len(names)))
        for n in missing:
            print("  missing: %s" % n)
        return 1 if missing else 0

    proc = subprocess.run(["node", DRIVER, kind] + names, cwd=ROOT, capture_output=True, text=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        refuse("the editor driver failed (exit %d)" % proc.returncode)
    results = json.loads(proc.stdout)

    plan = []
    for n in names:
        res = results.get(n) or {}
        if res.get("kindBefore") == kind:
            plan.append((n, None, None, res))
            continue
        old, new = kind_delta(n, res, kind)
        bpmn_path = os.path.join(RENDERED, n + ".bpmn")
        yaml_path = os.path.join(CORPUS, n + ".workflow.yaml")
        bpmn = patch_bpmn(n, open(bpmn_path).read(), old, new)
        yml = patch_yaml(n, open(yaml_path).read(), kind)
        plan.append((n, bpmn, yml, res))

    todo = [p for p in plan if p[1] is not None]
    print("%d map(s); %d already kind=%s; %d to change" % (len(plan), len(plan) - len(todo), kind, len(todo)))
    if "--dry-run" in argv:
        for n, *_ in todo:
            print("  would set kind=%s: %s" % (kind, n))
        return 0
    for n, bpmn, yml, res in todo:
        with open(os.path.join(RENDERED, n + ".bpmn"), "w") as fh:
            fh.write(bpmn)
        if os.path.isdir(GALLERY):
            shutil.copyfile(os.path.join(RENDERED, n + ".bpmn"), os.path.join(GALLERY, n + ".bpmn"))
        with open(os.path.join(CORPUS, n + ".workflow.yaml"), "w") as fh:
            fh.write(yml)
        v = mint_store_version(n, bpmn, res.get("thumb"), kind)
        print("  set kind=%s: %s%s" % (kind, n, "" if v is None else " (store v%d)" % v))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
