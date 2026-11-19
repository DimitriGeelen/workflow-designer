#!/usr/bin/env python3
"""T-1452 step 4: a shard plan balanced by measured leg time (trial 2 split by count: 879 vs 395 leg-seconds).

  python3 docs/reports/T-1452-spikes/shard-plan.py <whole-run job name> <k> > tests/shard-plan-<tier>-<k>.tsv

Reads build/pool/results/<job>/legs.tsv (a whole tier, one line per leg attempt; a leg's time is the sum of its
attempts) and places legs into k shards, slowest first, each into the shard with the least time so far (LPT). Legs
that must share a shard (_T1288_SHARD_WITH in tools/_t1288-tiers.sh, read from there) are placed as one unit.
Prints the plan (a comment header with the source run and each shard's planned seconds, then "<leg>\t<shard>").
"""
import os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))


def main(argv):
    if len(argv) != 3:
        print(__doc__, file=sys.stderr); return 2
    job, k = argv[1], int(argv[2])
    secs, tier = {}, None
    for line in open(os.path.join(ROOT, 'build/pool/results', job, 'legs.tsv'), encoding='utf-8'):
        p = line.rstrip('\n').split('\t')
        if len(p) != 6:
            continue
        tier = p[0]
        secs[p[1]] = secs.get(p[1], 0) + int(p[5])
    tiers_src = open(os.path.join(ROOT, 'tools/_t1288-tiers.sh'), encoding='utf-8').read()
    m = re.search(r'declare -A _T1288_SHARD_WITH=\((.*?)\)\n', tiers_src)
    with_ = dict(re.findall(r'\[([^\]]+)\]=([^\s)]+)', m.group(1))) if m else {}
    units = {}   # unit head -> [legs]
    for leg in secs:
        head = with_.get(leg, leg)
        units.setdefault(head, []).append(leg)
    order = sorted(units, key=lambda h: -sum(secs.get(l, 0) for l in units[h]))
    load = [0] * k
    plan = {}
    for h in order:
        i = min(range(k), key=lambda j: (load[j], j))
        for l in units[h]:
            plan[l] = i + 1
        load[i] += sum(secs.get(l, 0) for l in units[h])
    print(f"# T-1452 shard plan: tier {tier}, k={k}, from {job} (leg-seconds per shard: {', '.join(map(str, load))})")
    for l in sorted(plan):
        print(f"{l}\t{plan[l]}")
    print(f"planned leg-seconds per shard: {load}", file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
