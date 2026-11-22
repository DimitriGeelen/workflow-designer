#!/usr/bin/env python3
"""T-1452 lever B, shadow comparison (1409 rule ii: 'the same' means every test the same result).

  python3 docs/reports/T-1452-spikes/compare-shards.py <full job name> <shard job name> [<shard job name> ...]

Reads build/pool/results/<job>/legs.tsv (tier, name, attempt, passes, fails, seconds; one line per leg attempt) and
result.json. A leg's outcome is its LAST attempt (a browser leg may be retried once). Checks, each printed:
  C1 the shards together ran every leg the full run ran, and nothing else
  C2 no leg ran in two shards
  C3 every leg has the same outcome (green/red) in its shard as in the full run
  C4 the shards are all for the same commit as the full run
Then the times: full run compute; each shard's compute and the slowest; leg-seconds per shard (balance).
Exit 0 only when C1-C4 hold.
"""
import json, os, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))


def load(job):
    d = os.path.join(ROOT, 'build/pool/results', job)
    res = json.load(open(os.path.join(d, 'result.json')))
    legs = {}
    infra = set()   # T-1482: (leg, attempt) whose red was the infrastructure's (legs.tsv.infra, written by the tier engine)
    try:
        for line in open(os.path.join(d, 'legs.tsv.infra'), encoding='utf-8'):
            p = line.rstrip('\n').split('\t')
            if len(p) == 3:
                infra.add((p[1], p[2]))
    except FileNotFoundError:
        pass
    try:
        for line in open(os.path.join(d, 'legs.tsv'), encoding='utf-8'):
            p = line.rstrip('\n').split('\t')
            if len(p) == 6:
                tier, name, attempt, dp, df, secs = p
                legs[name] = {'ok': int(df) == 0, 'secs': int(secs), 'attempt': attempt,
                              'infra': (name, attempt) in infra, 'node': res.get('node')}
    except FileNotFoundError:
        pass
    return res, legs


def main(argv):
    if len(argv) < 3:
        print(__doc__); return 2
    full_res, full = load(argv[1])
    shards = [(j,) + load(j) for j in argv[2:]]
    ok = True

    def check(cond, label, detail=''):
        nonlocal ok
        print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + detail) if detail else ''}")
        ok = ok and cond

    if not full:
        check(False, 'the full run delivered legs.tsv', argv[1]); return 1
    union, seen_twice = {}, []
    for j, _, legs in shards:
        for n, v in legs.items():
            if n in union:
                seen_twice.append(n)
            union[n] = v
    missing, extra = sorted(set(full) - set(union)), sorted(set(union) - set(full))
    check(not missing and not extra, 'C1 the shards together ran exactly the full run\'s legs',
          f'{len(full)} in full, {len(union)} in shards; missing {missing[:5]}, extra {extra[:5]}')
    check(not seen_twice, 'C2 no leg ran in two shards', str(seen_twice[:5]))
    differ = [n for n in full if n in union and full[n]['ok'] != union[n]['ok']]
    # T-1482 (operator's option 2): a difference whose red side did not run (its last attempt red by timeout or no
    # DevTools port) is a NOTE, counted per node, not a disagreement; every other difference stays a C3 FAIL.
    red_side = lambda n: full[n] if not full[n]['ok'] else union[n]
    not_run = [n for n in differ if red_side(n)['infra']]
    real = [n for n in differ if n not in not_run]
    check(not real, 'C3 every leg has the same outcome in its shard as in the full run',
          ', '.join(f"{n}: full {'green' if full[n]['ok'] else 'RED'} / shard {'green' if union[n]['ok'] else 'RED'}" for n in real[:6]))
    for n in not_run:
        r = red_side(n)
        print(f"NOTE  C3i {n}: did not run on {r['node']} ({'full run' if r is full[n] else 'shard'}: timeout or no DevTools port), green on the other side")
    commits = {full_res.get('commit')} | {r.get('commit') for _, r, _ in shards}
    check(len(commits) == 1 and None not in commits, 'C4 every job is for the same commit', str(commits))
    print(f"full: compute {full_res.get('duration_s')} s on {full_res.get('node')}, {len(full)} legs, leg-seconds {sum(v['secs'] for v in full.values())}")
    for j, r, legs in shards:
        print(f"shard {r.get('shard')}: compute {r.get('duration_s')} s on {r.get('node')}, {len(legs)} legs, leg-seconds {sum(v['secs'] for v in legs.values())}")
    slow = max((r.get('duration_s') or 0) for _, r, _ in shards)
    if full_res.get('duration_s'):
        print(f"slowest shard {slow} s = {slow / full_res['duration_s']:.0%} of the full run's compute")
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
