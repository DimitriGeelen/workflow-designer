#!/usr/bin/env python3
"""_t1303-corpus-impact — which tracked maps would mapping v1.1's lint rules R1-R3 flag (832 T-1303; read-only).

Run before a rule ships: an ERROR on a map that saves today is a behaviour change to decide first. Saving is never
refused on a finding (save-time validation is advisory, T-956), so a hit here means a new finding, not a lost save.
Scans every tracked *.bpmn / *.xml outside .agentic-framework/ and .context/working/; prints totals, then one line
per flagged map. Exit 0 always (a report, not a gate).

R1 ERROR: an io (aef:input/aef:output) with operation update|upsert|delete and no child aef:field role="match".
R2 ERROR: a CURIE prefix in fieldRef/typeRef/conceptRef (io attribute or aef:field) not declared in the process
          aef:meta's aef:prefixes (http/https/urn exempt; `ref` exempt). Same test as the designer's ioUndeclaredPrefix.
R3 WARN:  an aef:field role="match" with neither fieldRef nor path.
"""
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

AEF_LOCAL = {'input', 'output'}
CURIE = re.compile(r'^([A-Za-z_][\w.-]*):(?!//)')


def local(tag):
    return tag.rsplit('}', 1)[-1]


def scan(path):
    try:
        root = ET.parse(path).getroot()
    except ET.ParseError as e:
        return {'parse_error': str(e)}
    declared = set()
    for el in root.iter():
        if local(el.tag) == 'prefix' and el.get('name'):
            declared.add(el.get('name'))
    out = {'io': 0, 'v11': False, 'R1': [], 'R2': [], 'R3': []}
    for el in root.iter():
        if local(el.tag) == 'meta' and el.get('mappingVersion'):
            out['v11'] = True
        if local(el.tag) not in AEF_LOCAL or 'aef' not in el.tag.split('}', 1)[0].lower():
            continue
        out['io'] += 1
        name = el.get('name', '?')
        fields = [c for c in el if local(c.tag) == 'field']
        if (el.get('operation') or '') in ('update', 'upsert', 'delete') and not any(f.get('role') == 'match' for f in fields):
            out['R1'].append(name)
        for holder in [el] + fields:
            for k in ('fieldRef', 'typeRef', 'conceptRef'):
                m = CURIE.match(holder.get(k) or '')
                if m and m.group(1).lower() not in ('http', 'https', 'urn') and m.group(1) not in declared:
                    out['R2'].append('%s %s=%s' % (name, k, holder.get(k)))
        for f in fields:
            if f.get('role') == 'match' and not f.get('fieldRef') and not f.get('path'):
                out['R3'].append(name)
    return out


def main():
    files = subprocess.run(['git', 'ls-files', '*.bpmn', '*.xml'], capture_output=True, text=True).stdout.split()
    files = [f for f in files if not f.startswith(('.agentic-framework/', '.context/working/'))]
    totals = {'maps': 0, 'maps_with_io': 0, 'io': 0, 'v11': 0, 'R1': 0, 'R2': 0, 'R3': 0, 'errors': 0}
    hits = []
    for f in files:
        r = scan(f)
        if 'parse_error' in r:
            totals['errors'] += 1
            continue
        totals['maps'] += 1
        if r['io']:
            totals['maps_with_io'] += 1
        totals['io'] += r['io']
        totals['v11'] += r['v11']
        for k in ('R1', 'R2', 'R3'):
            if r[k]:
                totals[k] += 1
                hits.append((k, f, r[k][:3]))
    print(totals)
    for h in hits:
        print(*h)


if __name__ == '__main__':
    sys.exit(main())
