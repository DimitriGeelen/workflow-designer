#!/usr/bin/env python3
"""T-1445: classify every declared local change in .agentic-framework/.vendor-divergence.yaml against AEF T-4649's
six proposed extension points. The class of each task id was decided by reading its entry's reason (agent judgement);
anything not listed is a fix to AEF's own behaviour, which no extension point can carry. Prints Markdown."""
import collections
import os
import sys
import yaml

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
d = yaml.safe_load(open(os.path.join(ROOT, '.agentic-framework', '.vendor-divergence.yaml')))
items = d.get('declared') or d.get('paths') or d.get('entries')
CLASS = {
    'T-866': '6', 'T-1123': '6', 'T-843': '6', 'T-659': '6', 'T-936': '6',   # add a refusal, never remove one
    'T-1175': '1',                                                            # a new Watchtower page of ours
    'T-887': 'M-verb', 'T-912': 'M-verb', 'T-914': 'M-verb',                  # new fw verbs / subcommands
    'T-880': 'M-lib', 'T-931': 'M-lib',                                       # project libraries the framework calls
    'T-1048': 'M-page', 'T-1171': 'M-page', 'T-1172': 'M-page',               # additions to AEF's existing pages
    'T-517': 'self',
}
NAMES = {'U': 'Fix to AEF behaviour: belongs upstream, no extension point can carry it',
         '6': '(6) tighten-only gate pattern',
         '1': '(1) project Watchtower page',
         'M-verb': 'MISSING: a project-defined fw verb or subcommand',
         'M-lib': 'MISSING: a project library the framework loads (hooks/gates call it)',
         'M-page': 'MISSING: a project addition to an existing AEF page (not a new page)',
         'self': 'The manifest itself'}


def cls(e):
    if e['path'].endswith('templates/designer_open.html'):   # an ADDED page of ours (kind: added), not an edit
        return '1'
    for t in (x.strip() for x in str(e.get('task', '')).split(',')):
        if t in CLASS:
            return CLASS[t]
    return 'U'


rows = collections.defaultdict(list)
for e in items:
    rows[cls(e)].append((str(e['task']), e['path'].replace('.agentic-framework/', ''),
                         (e.get('reason') or '').split('\n')[0].strip()[:110]))
total = sum(len(v) for v in rows.values())
print(f'Entries classified: {total} of {len(items)} (paths: {len({e["path"] for e in items})})\n')
for k in ['U', '6', '1', 'M-verb', 'M-lib', 'M-page', 'self']:
    print(f'### {NAMES[k]} — {len(rows[k])}\n')
    for t, p, r in rows[k]:
        print(f'- {t} `{p}` — {r}')
    print()
sys.exit(0 if total == len(items) else 1)
