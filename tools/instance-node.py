#!/usr/bin/env python3
"""instance-node.py — a governed entity's position on its process template (T-880, arc-005 S2).

What this is. T-878 (GO, 2026-09-27) split "process instance" into two halves:
  - WHICH TEMPLATE: derivable from `workflow_type` (examples/aef-processes/template-binding.yaml)
  - WHICH NODE:     not derivable (15 lane-prefixed node ids against ~5 statuses, no mapping)
                    so it is RECORDED, as `current_node:` in the entity's own frontmatter.

What this is not. No new identifier is minted (T-878 IW-3): the entity's existing id
(T-873) IS the instance identity. There is no instance file, no uuid, no registry.

States, kept distinct on purpose (T-878 IW-5; NOT EVALUATED is not PASSED):
  NODE <id> <template>      position recorded and valid
  NO-POSITION <templates>   template known, nothing recorded — the common case for
                            every entity that predates this mechanism
  NO-TEMPLATE <type>        workflow_type maps to no template — a different absence
  NO-ENTITY <id>            no task file for that id

Usage:
  instance-node.py bind  <workflow_type>            resolved template file(s), or NO-TEMPLATE
  instance-node.py nodes <template-id>              node ids in the rendered artefact
  instance-node.py get   <T-XXX>                    one of the four states above
  instance-node.py set   <T-XXX> <node-id>          record; REFUSED if the node is not in the
                                                    entity's bound template(s), naming them
Options:
  --root DIR         project root (default: parent of tools/)
  --tasks-dir DIR    where to find T-*.md (default: <root>/.tasks/active and completed)
  --binding FILE     derivation table (default: <root>/examples/aef-processes/template-binding.yaml)
  --rendered-dir DIR template artefacts (default: <root>/examples/aef-processes/rendered)

Exit codes: 0 ok (NODE / NO-POSITION / recorded) · 1 REFUSED · 2 NO-ENTITY · 3 NO-TEMPLATE
"""
import argparse
import glob
import os
import re
import sys
import xml.etree.ElementTree as ET

BPMN_NS = "http://www.omg.org/spec/BPMN/20100524/MODEL"
# Flow nodes an instance can stand on. Structural containers are deliberately absent:
# a position "on a lane" or "on the pool" is not a position.
FLOW_NODE_TAGS = {
    "startEvent", "endEvent", "intermediateCatchEvent", "intermediateThrowEvent",
    "boundaryEvent", "task", "serviceTask", "userTask", "scriptTask", "manualTask",
    "sendTask", "receiveTask", "businessRuleTask", "subProcess", "callActivity",
    "exclusiveGateway", "parallelGateway", "inclusiveGateway", "eventBasedGateway",
    "complexGateway",
}


def load_binding(path):
    """Tiny reader for the binding table: `  key: [a, b]` lines under `bindings:`."""
    if not os.path.isfile(path):
        sys.exit(f"binding table not found: {path}")
    table = {}
    in_block = False
    for line in open(path, encoding="utf-8"):
        s = line.rstrip("\n")
        if s.startswith("bindings:"):
            in_block = True
            continue
        if not in_block or not s.strip() or s.lstrip().startswith("#"):
            continue
        m = re.match(r"^\s+([A-Za-z0-9_-]+):\s*\[([^\]]*)\]\s*$", s)
        if not m:
            sys.exit(f"binding table line not understood: {s!r}")
        table[m.group(1)] = [x.strip() for x in m.group(2).split(",") if x.strip()]
    return table


def template_file(rendered_dir, template_id):
    return os.path.join(rendered_dir, f"{template_id}.bpmn")


def template_nodes(path):
    if not os.path.isfile(path):
        sys.exit(f"template artefact not found: {path}")
    root = ET.parse(path).getroot()
    ids = []
    for el in root.iter():
        if not isinstance(el.tag, str) or not el.tag.startswith("{" + BPMN_NS + "}"):
            continue
        tag = el.tag.split("}", 1)[1]
        if tag in FLOW_NODE_TAGS and el.get("id"):
            ids.append(el.get("id"))
    return ids


def find_task(tasks_dirs, task_id):
    for d in tasks_dirs:
        hits = sorted(glob.glob(os.path.join(d, f"{task_id}-*.md")))
        if hits:
            return hits[0]
    return None


def frontmatter(text):
    """Return (fields, fm_start, fm_end) for the leading --- block; fields is a dict of
    top-level scalar keys only (enough for workflow_type and current_node)."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return {}, -1, -1
    fields = {}
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return fields, 0, i
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*(.*?)\s*$", lines[i])
        if m:
            fields[m.group(1)] = m.group(2)
    return {}, -1, -1


def bound_templates(fields, table):
    wt = fields.get("workflow_type", "").strip().strip("'\"")
    return wt, table.get(wt)


def cmd_bind(a, table):
    tpls = table.get(a.workflow_type)
    if not tpls:
        print(f"NO-TEMPLATE {a.workflow_type} (not in {os.path.relpath(a.binding, a.root)})")
        return 3
    for t in tpls:
        print(os.path.relpath(template_file(a.rendered_dir, t), a.root))
    return 0


def cmd_nodes(a, table):
    for n in template_nodes(template_file(a.rendered_dir, a.template)):
        print(n)
    return 0


def cmd_get(a, table):
    path = find_task(a.tasks_dirs, a.task)
    if not path:
        print(f"NO-ENTITY {a.task}")
        return 2
    fields, _, _ = frontmatter(open(path, encoding="utf-8").read())
    wt, tpls = bound_templates(fields, table)
    if not tpls:
        print(f"NO-TEMPLATE {wt or '(none)'}")
        return 3
    node = fields.get("current_node", "").strip().strip("'\"")
    if not node:
        print(f"NO-POSITION {','.join(tpls)}")
        return 0
    for t in tpls:
        if node in template_nodes(template_file(a.rendered_dir, t)):
            print(f"NODE {node} {t}")
            return 0
    # Recorded but no longer in any bound template (template re-rendered under it).
    print(f"NODE {node} STALE (not in {','.join(tpls)})")
    return 1


def cmd_set(a, table):
    path = find_task(a.tasks_dirs, a.task)
    if not path:
        print(f"NO-ENTITY {a.task}")
        return 2
    text = open(path, encoding="utf-8").read()
    fields, fm_start, fm_end = frontmatter(text)
    if fm_start < 0:
        print(f"REFUSED {a.task}: no frontmatter block")
        return 1
    wt, tpls = bound_templates(fields, table)
    if not tpls:
        print(f"NO-TEMPLATE {wt or '(none)'}: nothing to record a position against")
        return 3
    checked = []
    valid_in = None
    for t in tpls:
        f = template_file(a.rendered_dir, t)
        checked.append(os.path.relpath(f, a.root))
        # MUTATION-ANCHOR node-validation (teeth disable the membership test here)
        if a.node in template_nodes(f):
            valid_in = t
            break
    if valid_in is None:
        print(f"REFUSED {a.task}: node '{a.node}' is not in the bound template(s) checked: "
              f"{', '.join(checked)}")
        return 1
    lines = text.split("\n")
    new_line = f"current_node: {a.node}"
    for i in range(fm_start + 1, fm_end):
        if re.match(r"^current_node:", lines[i]):
            lines[i] = new_line
            break
    else:
        for i in range(fm_start + 1, fm_end):
            if re.match(r"^workflow_type:", lines[i]):
                lines.insert(i + 1, new_line)
                break
        else:
            lines.insert(fm_end, new_line)
    open(path, "w", encoding="utf-8").write("\n".join(lines))
    print(f"NODE {a.node} {valid_in} (recorded in {os.path.relpath(path, a.root)})")
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    default_root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    p.add_argument("--root", default=default_root)
    p.add_argument("--tasks-dir", action="append", default=None)
    p.add_argument("--binding", default=None)
    p.add_argument("--rendered-dir", default=None)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("bind"); s.add_argument("workflow_type"); s.set_defaults(fn=cmd_bind)
    s = sub.add_parser("nodes"); s.add_argument("template"); s.set_defaults(fn=cmd_nodes)
    s = sub.add_parser("get"); s.add_argument("task"); s.set_defaults(fn=cmd_get)
    s = sub.add_parser("set"); s.add_argument("task"); s.add_argument("node"); s.set_defaults(fn=cmd_set)
    a = p.parse_args(argv)
    a.root = os.path.abspath(a.root)
    a.binding = a.binding or os.path.join(a.root, "examples", "aef-processes", "template-binding.yaml")
    a.rendered_dir = a.rendered_dir or os.path.join(a.root, "examples", "aef-processes", "rendered")
    a.tasks_dirs = a.tasks_dir or [os.path.join(a.root, ".tasks", "active"), os.path.join(a.root, ".tasks", "completed")]
    table = load_binding(a.binding)
    return a.fn(a, table)


if __name__ == "__main__":
    sys.exit(main())
