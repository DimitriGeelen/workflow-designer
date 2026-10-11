#!/usr/bin/env python3
"""field-suggestion.py — the OPERATOR's side of field suggestions (T-1126, T-1118 B3).

The designer can only SUGGEST that an unknown aef: key become a field (POST /api/field-suggestions). Turning a
suggestion into a field is the operator's decision (T-347 ruling, 2026-10-10: "on suggestion ... with operator"),
so it happens here, run through a runme job, never from the editor:

  list    [--status pending|approved|rejected]
  approve --type T --key K --label L [--hint H] --by NAME
          writes K into the project field profile's `fields` section (label, element types, approved_by,
          approved_at) through the same write path as Settings (validated whole, history logged, refused if
          the profile changed meanwhile), then marks the suggestion approved
  reject  --type T --key K --reason R --by NAME     marks it rejected (kept, with the reason)

  --repo DIR   the gallery repository (default: this repository)
Exit 0 = done; 1 = refused (the reason is printed); 2 = usage.
"""
import argparse
import importlib.util
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))


def load_server(repo):
    """gallery-serve.py is import-safe (arguments are parsed in main()); point its REPO at `repo`."""
    spec = importlib.util.spec_from_file_location('gallery_serve', os.path.join(HERE, 'gallery-serve.py'))
    if spec is None or spec.loader is None:
        raise SystemExit('cannot load tools/gallery-serve.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    setattr(mod, 'REPO', os.path.abspath(repo))
    return mod


def main(argv=None):
    ap = argparse.ArgumentParser(description='Approve or reject field suggestions (operator, via runme).')
    ap.add_argument('--repo', default=os.path.abspath(os.path.join(HERE, '..')))
    sub = ap.add_subparsers(dest='cmd', required=True)
    ls = sub.add_parser('list')
    ls.add_argument('--status', choices=['pending', 'approved', 'rejected'])
    a = sub.add_parser('approve')
    a.add_argument('--type', required=True)
    a.add_argument('--key', required=True)
    a.add_argument('--label', required=True)
    a.add_argument('--hint', default='')
    a.add_argument('--by', required=True)
    r = sub.add_parser('reject')
    r.add_argument('--type', required=True)
    r.add_argument('--key', required=True)
    r.add_argument('--reason', required=True)
    r.add_argument('--by', required=True)
    args = ap.parse_args(argv)
    gs = load_server(args.repo)

    if args.cmd == 'list':
        doc = gs.read_suggestions()
        rows = [s for s in doc['suggestions'] if not args.status or s.get('status') == args.status]
        if not rows:
            print('no suggestions%s' % (' with status ' + args.status if args.status else ''))
        for s in rows:
            print('%-9s %s.%s  on %s of %s  e.g. %s  maps: %s' % (
                s.get('status'), s.get('type'), s.get('key'), s.get('count', '?'), s.get('total', '?'),
                ', '.join(s.get('examples') or []) or '-', ', '.join(s.get('maps') or []) or '-'))
        return 0

    if args.cmd == 'reject':
        ent = gs.set_suggestion_status(args.type, args.key, 'rejected', args.by, args.reason)
        print('rejected %s.%s by %s: %s' % (args.type, args.key, args.by, ent.get('reason')))
        return 0

    # approve: profile first (the field), then the suggestion's status — so a refused profile write leaves
    # the suggestion pending rather than claiming an approval that wrote nothing.
    code, cur = gs.read_field_profile(None)
    if code == 404:
        prof, base = {'version': 1, 'types': {}}, 'none'
    elif code == 200:
        prof, base = cur['profile'], cur['base']
    else:
        print('REFUSED: the project field profile cannot be read: %s' % cur.get('error'))
        return 1
    fields = prof.setdefault('fields', {})
    spec = fields.get(args.key, {})
    types = sorted(set(spec.get('types', [])) | {args.type})
    fields[args.key] = {k: v for k, v in {
        'label': args.label, 'hint': args.hint or spec.get('hint'), 'types': types,
        'approved_by': args.by, 'approved_at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
    }.items() if v}
    code, res = gs.write_field_profile(None, prof, base, 'field-suggestion approve %s.%s by %s' % (args.type, args.key, args.by))
    if code != 200:
        print('REFUSED (%d): %s' % (code, res.get('error')))
        return 1
    gs.set_suggestion_status(args.type, args.key, 'approved', args.by)
    print('approved %s.%s as "%s" by %s — now a field for %s in this project' % (
        args.type, args.key, args.label, args.by, ', '.join(types)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
