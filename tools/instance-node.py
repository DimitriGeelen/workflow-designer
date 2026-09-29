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

Moving (T-882, arc-005 S3). A recorded position moves ONLY along a sequenceFlow the
template of record carries — read from the artefact, never from a table in this file:
  REFUSED-TRANSITION        `advance` asked for a hop the template has no flow for
                            (out of order, backwards, past an end event, across
                            templates, or a first hop that is not onto a startEvent).
                            Names current, target, template file and legal successors.
  REFUSED-PLACED            `set` on an entity that already has a position. `set` is
                            PLACEMENT — one shot, for entities that predate this
                            mechanism — not a move. Without this refusal `set` would be
                            a bypass beside `advance` and the guard would be decoration.
Every exclusiveGateway in the bound templates branches on its outgoing flows, so any
ONE outgoing flow is a legal hop. No token semantics for parallel/inclusive gateways:
a sequenceFlow is treated as a legal single-token transition, nothing more.

Usage:
  instance-node.py bind  <workflow_type>            resolved template file(s), or NO-TEMPLATE
  instance-node.py nodes <template-id>              node ids in the rendered artefact
  instance-node.py get   <T-XXX>                    one of the four states above
  instance-node.py set   <T-XXX> <node-id>          PLACE (first position only); REFUSED if the node
                                                    is not in the entity's bound template(s), naming
                                                    them; REFUSED-PLACED if a position is recorded
  instance-node.py advance <T-XXX> <node-id>        MOVE along a sequenceFlow of the template of record;
                                                    from NO-POSITION only onto a startEvent;
                                                    REFUSED-TRANSITION otherwise (exit 1)
  instance-node.py walk  <T-XXX> <node-id>          the FRAMEWORK's verb (T-923): shortest path over the
                                                    template of record's flows, taken one validated hop
                                                    at a time and printed as HOP a -> b; from NO-POSITION
                                                    it starts at the startEvent of the template that
                                                    contains the target (printed as START <id>); no path
                                                    → REFUSED-TRANSITION, nothing written; already there
                                                    → exit 0, nothing written
  instance-node.py resolve <T-XXX>                  forward resolution (T-881): TEMPLATE <file> per bound
                                                    template, then NODE <id> <template> | NO-POSITION
  instance-node.py instances <template-id>          reverse resolution (T-881): every LIVE entity bound
                                                    to the template with its node — computed over the
                                                    task corpus, no index. States, never a bare empty
                                                    list: INSTANCES <t> <n> (examined <m>) ·
                                                    NO-INSTANCES <t> (examined <m>) ·
                                                    TEMPLATE-UNKNOWN <t>
  instance-node.py roundtrip [template-id ...]      for every entity the reverse query returns, forward
                                                    resolution must name the same template; any
                                                    disagreement is ROUNDTRIP-FAIL (exit 1)
  instance-node.py refused <T-XXX> --case C --rule R --node N [--target T] [--detail D] [--actor A]
                                                    the FRAMEWORK's verb (T-883): record a refusal this
                                                    tool did not make itself (a gate in update-task.sh
                                                    refusing a transition) in the same audit log, same
                                                    shape, same single writer. REFUSAL-RECORDED, exit 0;
                                                    an empty --case/--rule is refused (WARNING, exit 1)
  instance-node.py refusals [T-XXX]                 read the audit log back: one REFUSAL <ts> <task>
                                                    <case> <rule> <node>[ -> <target>] per line, or
                                                    NO-REFUSALS [<task>] — a state, never a bare empty list

Audit log (T-883, arc-005 S3/B9 — V7: "each refused and each lands in the audit log").
Every refusal this tool emits (REFUSED / REFUSED-PLACED / REFUSED-TRANSITION) appends ONE
JSON line to <root>/.context/audits/instance-refusals.jsonl — beside the framework's other
append-only audit records (arc-abandon.jsonl, arc-bypass.jsonl, ...). Keys:
  ts task case rule kind node target template detail actor
`case` is the V7 case (out-of-order-advance · skipped-human-gateway · unmet-input-contract,
plus the tool's own re-placement / stale-position / unknown-node / malformed-entity), `rule`
names WHICH rule refused (template-flow, R-033, P-010, P-011, placement-one-shot, ...).
A line that names no rule cannot be written. A failed write never changes the refusal:
the stdout line and exit code stand and a WARNING on stderr says the line was not written.
Options:
  --root DIR         project root (default: parent of tools/)
  --tasks-dir DIR    where to find T-*.md (default: <root>/.tasks/active and completed);
                     LIVE entities for instances/roundtrip are the FIRST dir given (default .tasks/active)
  --binding FILE     derivation table (default: <root>/examples/aef-processes/template-binding.yaml)
  --rendered-dir DIR template artefacts (default: <root>/examples/aef-processes/rendered)
  --log FILE         audit log (default: $FW_INSTANCE_REFUSAL_LOG, else
                     <root>/.context/audits/instance-refusals.jsonl); the flag wins over the env

Exit codes: 0 ok (NODE / NO-POSITION / recorded / advanced / INSTANCES / NO-INSTANCES / ROUNDTRIP-OK)
            1 REFUSED / REFUSED-PLACED / REFUSED-TRANSITION / STALE / ROUNDTRIP-FAIL
            2 NO-ENTITY · 3 NO-TEMPLATE / TEMPLATE-UNKNOWN
"""
import argparse
import datetime
import glob
import json
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


def _bpmn_iter(path, wanted):
    if not os.path.isfile(path):
        sys.exit(f"template artefact not found: {path}")
    for el in ET.parse(path).getroot().iter():
        if not isinstance(el.tag, str) or not el.tag.startswith("{" + BPMN_NS + "}"):
            continue
        if el.tag.split("}", 1)[1] == wanted:
            yield el


def template_flows(path):
    """source node id -> [target node ids], read from the artefact's sequenceFlow elements.
    This is the ONLY source of legitimacy for a move (T-882): no successor table lives here."""
    flows = {}
    for el in _bpmn_iter(path, "sequenceFlow"):
        src, tgt = el.get("sourceRef"), el.get("targetRef")
        if src and tgt:
            flows.setdefault(src, []).append(tgt)
    return flows


def template_start_events(path):
    return [el.get("id") for el in _bpmn_iter(path, "startEvent") if el.get("id")]


AUDIT_LOG = None  # resolved in main(): --log, else $FW_INSTANCE_REFUSAL_LOG, else <root>/.context/audits/instance-refusals.jsonl

# What each refusal kind is, when the caller does not say more precisely.
_DEFAULT_CASE = {
    "REFUSED-TRANSITION": ("out-of-order-advance", "template-flow"),
    "REFUSED-PLACED": ("re-placement", "placement-one-shot"),
    "REFUSED": ("malformed-entity", "frontmatter"),
}


def _now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _append_line(path, row):
    """The one place a byte reaches the audit log. Raises OSError; the caller decides what that means."""
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(path, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, ensure_ascii=False, sort_keys=False) + "\n")
    return True


def _audit_append(row, path=None):
    """Append one refusal line. Returns True if written. Never raises: a refusal that cannot be
    audited is still a refusal, and the caller's exit code must not change because a directory
    was unwritable — but the failure is said out loud, never swallowed."""
    path = path or AUDIT_LOG
    if not row.get("case") or not row.get("rule"):
        print(f"WARNING: audit line not written for {row.get('task', '?')}: a refusal must name its case and rule "
              f"(case={row.get('case')!r} rule={row.get('rule')!r})", file=sys.stderr)
        return False
    if not path:
        print(f"WARNING: audit line not written for {row.get('task', '?')}: no audit log path", file=sys.stderr)
        return False
    try:
        # MUTATION-ANCHOR refusal-audit (teeth disable the append here)
        written = _append_line(path, row)
    except OSError as e:
        print(f"WARNING: audit line not written for {row.get('task', '?')} to {path}: {e}", file=sys.stderr)
        return False
    return written


def refuse(kind, task, detail, case=None, rule=None, node="", target="", template="", actor="cli"):
    """Single emission path for every refusal: the stdout line, exit 1, and ONE audit-log line (T-883)."""
    print(f"{kind} {task}: {detail}")
    dcase, drule = _DEFAULT_CASE.get(kind, ("refusal", kind.lower()))
    _audit_append({
        "ts": _now(), "task": task, "case": case or dcase, "rule": rule or drule, "kind": kind,
        "node": node or "", "target": target or "", "template": template or "", "detail": detail,
        "actor": actor,
    })
    return 1


def _write_node(path, text, fm_start, fm_end, node):
    lines = text.split("\n")
    new_line = f"current_node: {node}"
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
    placed = fields.get("current_node", "").strip().strip("'\"")
    if placed:
        # T-882: set is placement, and placement is one-shot. A recorded position moves
        # only along a flow (advance); a setter that re-placed freely would be a bypass.
        return refuse("REFUSED-PLACED", a.task,
                      f"position already recorded ({placed}); move it with: advance {a.task} <node>",
                      node=placed, target=a.node, template=",".join(tpls))
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
        return refuse("REFUSED", a.task,
                      f"node '{a.node}' is not in the bound template(s) checked: {', '.join(checked)}",
                      case="unknown-node", rule="template-membership", target=a.node, template=",".join(checked))
    _write_node(path, text, fm_start, fm_end, a.node)
    print(f"NODE {a.node} {valid_in} (recorded in {os.path.relpath(path, a.root)})")
    return 0


def cmd_advance(a, table):
    """Move along a sequenceFlow of the template of record (T-882). The refusal is the deliverable."""
    def announce(prev, node, tpl, path):
        print(f"NODE {node} {tpl} (advanced from {prev}, recorded in {os.path.relpath(path, a.root)})")
    return _advance_core(a, table, a.node, announce)


def _advance_core(a, table, node, announce, prefer=None):
    """One validated hop. Shared by advance and walk so a walk cannot take a hop advance would refuse.

    Template of record: the bound template(s) containing the current node. Two bound templates may
    share a node id (an inception binds both lifecycles and both carry a start-work script task), so
    every candidate is consulted and the hop is legal if ANY of them carries the flow; `prefer` (the
    template a walk is on) is consulted first so a walk never changes template mid-route."""
    path = find_task(a.tasks_dirs, a.task)
    if not path:
        print(f"NO-ENTITY {a.task}")
        return 2
    text = open(path, encoding="utf-8").read()
    fields, fm_start, fm_end = frontmatter(text)
    if fm_start < 0:
        return refuse("REFUSED", a.task, "no frontmatter block")
    wt, tpls = bound_templates(fields, table)
    if not tpls:
        print(f"NO-TEMPLATE {wt or '(none)'}: nothing to advance against")
        return 3
    current = fields.get("current_node", "").strip().strip("'\"")
    if not current:
        # An instance starts at the start. Placing a legacy entity mid-flow is `set`'s job.
        starts = {t: template_start_events(template_file(a.rendered_dir, t)) for t in tpls}
        for t, ids in starts.items():
            if node in ids:
                _write_node(path, text, fm_start, fm_end, node)
                announce("NO-POSITION", node, t, path)
                return 0
        legal = "; ".join(f"{', '.join(ids)} in {os.path.relpath(template_file(a.rendered_dir, t), a.root)}"
                          for t, ids in starts.items())
        return refuse("REFUSED-TRANSITION", a.task,
                      f"no position recorded and '{node}' is not a startEvent — an instance starts at the start; "
                      f"legal first hop: {legal} (to place a pre-existing entity mid-flow use: set {a.task} <node>)",
                      node="NO-POSITION", target=node, template=",".join(tpls))
    candidates = [t for t in tpls if current in template_nodes(template_file(a.rendered_dir, t))]
    if prefer in candidates:
        candidates.remove(prefer)
        candidates.insert(0, prefer)
    if not candidates:
        return refuse("REFUSED-TRANSITION", a.task,
                      f"recorded position '{current}' is STALE — not in {', '.join(tpls)}; nothing to advance from",
                      case="stale-position", rule="template-membership", node=current, target=node, template=",".join(tpls))
    legal_by_tpl = []
    for of_record in candidates:
        tfile = template_file(a.rendered_dir, of_record)
        succ = template_flows(tfile).get(current, [])
        # MUTATION-ANCHOR successor-check (teeth disable the flow test here)
        if node in succ:
            _write_node(path, text, fm_start, fm_end, node)
            announce(current, node, of_record, path)
            return 0
        legal_by_tpl.append((os.path.relpath(tfile, a.root), succ))
    detail = "; ".join(f"legal successor(s) of {current} in {f}: " + (", ".join(succ) if succ else "(none — an end event has no outgoing flow)")
                       for f, succ in legal_by_tpl)
    return refuse("REFUSED-TRANSITION", a.task,
                  f"{current} -> {node} is not a sequenceFlow of {legal_by_tpl[0][0]}; {detail}",
                  node=current, target=node, template=legal_by_tpl[0][0])


def _shortest_path(flows, src, dst):
    """BFS over sequenceFlows; returns [src, ..., dst] or None. src == dst returns [src]."""
    if src == dst:
        return [src]
    prev = {src: None}
    queue = [src]
    while queue:
        cur = queue.pop(0)
        for nxt in flows.get(cur, []):
            if nxt in prev:
                continue
            prev[nxt] = cur
            if nxt == dst:
                out = [dst]
                while prev[out[-1]] is not None:
                    out.append(prev[out[-1]])
                return list(reversed(out))
            queue.append(nxt)
    return None


def cmd_walk(a, table):
    """The framework's verb (T-923): reach a target node by the shortest legal path, one validated hop at a time."""
    path = find_task(a.tasks_dirs, a.task)
    if not path:
        print(f"NO-ENTITY {a.task}")
        return 2
    fields, fm_start, _ = frontmatter(open(path, encoding="utf-8").read())
    if fm_start < 0:
        return refuse("REFUSED", a.task, "no frontmatter block")
    wt, tpls = bound_templates(fields, table)
    if not tpls:
        print(f"NO-TEMPLATE {wt or '(none)'}: nothing to walk against")
        return 3
    current = fields.get("current_node", "").strip().strip("'\"")
    target = a.node
    if current:
        of_record = next((t for t in tpls if current in template_nodes(template_file(a.rendered_dir, t))), None)
        if of_record is None:
            return refuse("REFUSED-TRANSITION", a.task,
                          f"recorded position '{current}' is STALE — not in {', '.join(tpls)}; nothing to walk from",
                          case="stale-position", rule="template-membership", node=current, target=target, template=",".join(tpls))
        tfile = template_file(a.rendered_dir, of_record)
        if target not in template_nodes(tfile):
            return refuse("REFUSED-TRANSITION", a.task,
                          f"'{target}' is not a node of the template of record {os.path.relpath(tfile, a.root)}",
                          node=current, target=target, template=os.path.relpath(tfile, a.root))
        route = _shortest_path(template_flows(tfile), current, target)
        if route is None:
            return refuse("REFUSED-TRANSITION", a.task,
                          f"no path from {current} to {target} in {os.path.relpath(tfile, a.root)}",
                          node=current, target=target, template=os.path.relpath(tfile, a.root))
        if len(route) == 1:
            print(f"NODE {target} {of_record} (already there, nothing written)")
            return 0
        hops = route[1:]
    else:
        # An instance starts at the start — of the template that contains the target.
        of_record = next((t for t in tpls if target in template_nodes(template_file(a.rendered_dir, t))), None)
        if of_record is None:
            return refuse("REFUSED-TRANSITION", a.task,
                          f"'{target}' is not a node of any bound template ({', '.join(tpls)})",
                          node="NO-POSITION", target=target, template=",".join(tpls))
        tfile = template_file(a.rendered_dir, of_record)
        flows = template_flows(tfile)
        best = None
        for start in template_start_events(tfile):
            r = _shortest_path(flows, start, target)
            if r is not None and (best is None or len(r) < len(best)):
                best = r
        if best is None:
            return refuse("REFUSED-TRANSITION", a.task,
                          f"no path from any startEvent to {target} in {os.path.relpath(tfile, a.root)}",
                          node="NO-POSITION", target=target, template=os.path.relpath(tfile, a.root))
        hops = best

    def announce(prev, node, tpl, _path):
        print(f"START {node}" if prev == "NO-POSITION" else f"HOP {prev} -> {node}")

    for hop in hops:
        rc = _advance_core(a, table, hop, announce, prefer=of_record)
        if rc != 0:
            return rc
    print(f"NODE {target} {of_record} (walked {len(hops)} hop(s), recorded in {os.path.relpath(path, a.root)})")
    return 0


def cmd_resolve(a, table):
    """Forward resolution (T-881): name the template FILE(s) and the recorded node."""
    path = find_task(a.tasks_dirs, a.task)
    if not path:
        print(f"NO-ENTITY {a.task}")
        return 2
    fields, _, _ = frontmatter(open(path, encoding="utf-8").read())
    wt, tpls = bound_templates(fields, table)
    if not tpls:
        print(f"NO-TEMPLATE {wt or '(none)'} (workflow_type not in {os.path.relpath(a.binding, a.root)})")
        return 3
    for t in tpls:
        print(f"TEMPLATE {os.path.relpath(template_file(a.rendered_dir, t), a.root)}")
    return cmd_get(a, table)


def _live_entities(a):
    """Every T-*.md in the LIVE dir (first tasks dir). Returns [(id, path, fields)]."""
    out = []
    for f in sorted(glob.glob(os.path.join(a.tasks_dirs[0], "T-*.md"))):
        fields, _, _ = frontmatter(open(f, encoding="utf-8").read())
        tid = fields.get("id", "").strip().strip("'\"") or os.path.basename(f).split("-fixture")[0]
        m = re.match(r"^(T-\d+)", os.path.basename(f))
        out.append((m.group(1) if m else tid, f, fields))
    return out


def _reverse(a, table, template):
    """Reverse resolution core. Returns (state, rows, examined) where rows is
    [(id, status_word, node)] and state in {INSTANCES, NO-INSTANCES, TEMPLATE-UNKNOWN}."""
    tfile = template_file(a.rendered_dir, template)
    if not os.path.isfile(tfile):
        return "TEMPLATE-UNKNOWN", [], 0
    nodes = set(template_nodes(tfile))
    rows = []
    entities = _live_entities(a)
    for tid, f, fields in entities:
        wt, tpls = bound_templates(fields, table)
        # MUTATION-ANCHOR binding-filter (teeth disable the membership test here)
        if not tpls or template not in tpls:
            continue
        node = fields.get("current_node", "").strip().strip("'\"")
        if not node:
            rows.append((tid, "NO-POSITION", ""))
        elif node in nodes:
            rows.append((tid, "NODE", node))
        else:
            rows.append((tid, "STALE", node))
    state = "INSTANCES" if rows else "NO-INSTANCES"
    return state, rows, len(entities)


def cmd_instances(a, table):
    state, rows, examined = _reverse(a, table, a.template)
    if state == "TEMPLATE-UNKNOWN":
        print(f"TEMPLATE-UNKNOWN {a.template} (no {os.path.relpath(a.rendered_dir, a.root)}/{a.template}.bpmn)")
        return 3
    bound_kinds = [k for k, v in table.items() if a.template in v]
    if state == "NO-INSTANCES":
        note = "" if bound_kinds else " — no workflow_type binds to it"
        print(f"NO-INSTANCES {a.template} (examined {examined} live entities{note})")
        return 0
    print(f"INSTANCES {a.template} {len(rows)} (examined {examined} live entities)")
    for tid, word, node in rows:
        print(f"  {tid} {word} {node}".rstrip())
    return 0


def cmd_roundtrip(a, table):
    templates = a.templates or sorted({t for v in table.values() for t in v})
    bad = 0
    for template in templates:
        state, rows, examined = _reverse(a, table, template)
        if state == "TEMPLATE-UNKNOWN":
            print(f"TEMPLATE-UNKNOWN {template}")
            bad += 1
            continue
        disagree = []
        for tid, _, _ in rows:
            path = find_task(a.tasks_dirs, tid)
            fields, _, _ = frontmatter(open(path, encoding="utf-8").read())
            _, tpls = bound_templates(fields, table)
            if not tpls or template not in tpls:
                disagree.append(tid)
        if disagree:
            print(f"ROUNDTRIP-FAIL {template}: reverse listed {', '.join(disagree)} but forward resolution does not bind them to it")
            bad += 1
        else:
            print(f"ROUNDTRIP-OK {template} {len(rows)} (examined {examined} live entities)")
    return 1 if bad else 0


def cmd_refused(a, table):
    """The framework's verb (T-883): a gate outside this tool refused a transition; record it here, same writer."""
    if not a.case or not a.rule:
        print(f"WARNING: audit line not written for {a.task}: a refusal must name its case and rule "
              f"(case={a.case!r} rule={a.rule!r})", file=sys.stderr)
        return 1
    template = ""
    path = find_task(a.tasks_dirs, a.task)
    if path:
        fields, _, _ = frontmatter(open(path, encoding="utf-8").read())
        _, tpls = bound_templates(fields, table)
        template = ",".join(tpls or [])
    row = {"ts": _now(), "task": a.task, "case": a.case, "rule": a.rule, "kind": "REFUSED-BY-GATE",
           "node": a.node or "", "target": a.target or "", "template": template, "detail": a.detail or "",
           "actor": a.actor}
    written = _audit_append(row)
    tgt = f" -> {a.target}" if a.target else ""
    print(f"REFUSAL-RECORDED {a.task} {a.case} {a.rule} {a.node}{tgt}" if written
          else f"REFUSAL-NOT-RECORDED {a.task} {a.case} {a.rule} {a.node}{tgt}")
    return 0


def cmd_refusals(a, table):
    """Read the audit log back as states: REFUSAL lines, or NO-REFUSALS."""
    rows = []
    if AUDIT_LOG and os.path.isfile(AUDIT_LOG):
        for line in open(AUDIT_LOG, encoding="utf-8"):
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except ValueError:
                print(f"WARNING: unparseable audit line skipped: {line[:80]}", file=sys.stderr)
                continue
            if a.task and r.get("task") != a.task:
                continue
            rows.append(r)
    if not rows:
        print(f"NO-REFUSALS {a.task}".rstrip())
        return 0
    for r in rows:
        tgt = f" -> {r['target']}" if r.get("target") else ""
        print(f"REFUSAL {r.get('ts', '?')} {r.get('task', '?')} {r.get('case', '?')} {r.get('rule', '?')} {r.get('node', '')}{tgt}".rstrip())
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    default_root = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    p.add_argument("--root", default=default_root)
    p.add_argument("--tasks-dir", action="append", default=None)
    p.add_argument("--binding", default=None)
    p.add_argument("--rendered-dir", default=None)
    p.add_argument("--log", default=None)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("bind"); s.add_argument("workflow_type"); s.set_defaults(fn=cmd_bind)
    s = sub.add_parser("nodes"); s.add_argument("template"); s.set_defaults(fn=cmd_nodes)
    s = sub.add_parser("get"); s.add_argument("task"); s.set_defaults(fn=cmd_get)
    s = sub.add_parser("set"); s.add_argument("task"); s.add_argument("node"); s.set_defaults(fn=cmd_set)
    s = sub.add_parser("advance"); s.add_argument("task"); s.add_argument("node"); s.set_defaults(fn=cmd_advance)
    s = sub.add_parser("walk"); s.add_argument("task"); s.add_argument("node"); s.set_defaults(fn=cmd_walk)
    s = sub.add_parser("resolve"); s.add_argument("task"); s.set_defaults(fn=cmd_resolve)
    s = sub.add_parser("instances"); s.add_argument("template"); s.set_defaults(fn=cmd_instances)
    s = sub.add_parser("roundtrip"); s.add_argument("templates", nargs="*"); s.set_defaults(fn=cmd_roundtrip)
    s = sub.add_parser("refused"); s.add_argument("task")
    s.add_argument("--case", default=""); s.add_argument("--rule", default=""); s.add_argument("--node", default="")
    s.add_argument("--target", default=""); s.add_argument("--detail", default=""); s.add_argument("--actor", default="cli")
    s.set_defaults(fn=cmd_refused)
    s = sub.add_parser("refusals"); s.add_argument("task", nargs="?", default=""); s.set_defaults(fn=cmd_refusals)
    a = p.parse_args(argv)
    a.root = os.path.abspath(a.root)
    a.binding = a.binding or os.path.join(a.root, "examples", "aef-processes", "template-binding.yaml")
    a.rendered_dir = a.rendered_dir or os.path.join(a.root, "examples", "aef-processes", "rendered")
    a.tasks_dirs = a.tasks_dir or [os.path.join(a.root, ".tasks", "active"), os.path.join(a.root, ".tasks", "completed")]
    global AUDIT_LOG
    AUDIT_LOG = a.log or os.environ.get("FW_INSTANCE_REFUSAL_LOG") or os.path.join(a.root, ".context", "audits", "instance-refusals.jsonl")
    table = load_binding(a.binding)
    return a.fn(a, table)


if __name__ == "__main__":
    sys.exit(main())
