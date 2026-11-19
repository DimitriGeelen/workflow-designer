#!/usr/bin/env python3
"""T-1452 (1409's circle, steps 2-3): how long the test gate takes, from what it already records.

Sources (all on this machine, nothing new is written by the gate):
  build/tiergate/tier-browser.runs.log     browser gate: a start line and a verdict line per run
  .context/working/prepush-core.runs.log   core gate (pre-push): the same
  build/pool/wait/*/pool-result.json       every pool job: node, outcome, node_times (queued/started/finished, wait_s,
                                           run_s), so each job is cut into sections (1409 lesson iv)
  build/pool/results/*/result.json         our launcher's own result: commit, tier, exit code, compute seconds

Prints, per gate: runs, median/min/max wall time, split by kind (high-risk = pool AND here, normal = pool alone);
per pool job: queue wait, run time, our compute, overhead (run - compute: clone and setup on the node), outcome.
Flags (five questions, Q1): a gate start without a verdict within 60 min (an aborted or hung run, which leaves no
other trace), and every pool job that was refused or failed before testing, with its reason.

  python3 docs/reports/T-1452-spikes/gate-times.py [--since 2026-11-19T20:00] [--json]
"""
import argparse, datetime as dt, glob, json, os, statistics as st, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
GATES = {'browser': 'build/tiergate/tier-browser.runs.log', 'core': '.context/working/prepush-core.runs.log'}
STARTS = ('side by side', 'runs on the pool', 'runs locally only')   # the gate's start lines; every other line is a verdict (T-1452)


def ts(s):
    return dt.datetime.fromisoformat(s.replace('Z', '+00:00'))


def gate_runs(path, since):
    """One run = a start line and every line after it for the same commit, up to the next start; its verdict is its
    LAST line (some paths write an informational line before the verdict). A run with no line after its start, older
    than 60 min, is reported as having no verdict."""
    try:
        lines = open(os.path.join(ROOT, path), encoding='utf-8').read().splitlines()
    except FileNotFoundError:
        return [], []
    runs, current = [], {}
    for l in lines:
        p = l.split('\t')
        if len(p) < 3:
            continue
        t, commit, msg = ts(p[0]), p[1], p[2]
        if since and t < since:
            continue
        if any(k in msg for k in STARTS):
            current[commit] = {'commit': commit, 'kind': 'high' if 'AND here' in msg else ('local' if 'locally only' in msg else 'normal'),
                               'start': t, 'last': None, 'verdict': None}
            runs.append(current[commit])
        elif commit in current:
            current[commit]['last'], current[commit]['verdict'] = t, msg
    now = dt.datetime.now(dt.timezone.utc)
    out = [{'commit': r['commit'], 'kind': r['kind'], 'start': r['start'].isoformat(),
            'minutes': round((r['last'] - r['start']).total_seconds() / 60, 1), 'verdict': r['verdict']} for r in runs if r['last']]
    hung = [{'commit': r['commit'], 'start': r['start'].isoformat(), 'kind': r['kind']} for r in runs
            if not r['last'] and (now - r['start']).total_seconds() > 3600]
    return out, hung


def pool_jobs(since):
    out = []
    for f in sorted(glob.glob(os.path.join(ROOT, 'build/pool/wait/*/pool-result.json'))):
        try:
            d = json.load(open(f))
        except Exception:
            continue
        name = d.get('name') or os.path.basename(os.path.dirname(f))
        nt = d.get('node_times') or {}
        q = nt.get('queued_at')
        if not q:   # jobs from before ring20 sent node_times: the submit time is in the job's own name
            stamp = name.rsplit('-', 1)[-1]
            try:
                q = dt.datetime.strptime(stamp, '%Y%m%dT%H%M%S').replace(tzinfo=dt.timezone.utc).isoformat()
            except ValueError:
                q = None
        if since and q and ts(q) < since:
            continue
        res = os.path.join(ROOT, 'build/pool/results', name, 'result.json')
        ours = {}
        if os.path.exists(res):
            try:
                ours = json.load(open(res))
            except Exception:
                pass
        run_s, compute = nt.get('run_s'), ours.get('duration_s')
        out.append({'name': name, 'node': d.get('node'), 'outcome': d.get('outcome'), 'reason': d.get('reason') or ours.get('error'),
                    'queued_at': q, 'wait_s': nt.get('wait_s'), 'run_s': run_s, 'compute_s': compute,
                    'overhead_s': (run_s - compute) if isinstance(run_s, (int, float)) and isinstance(compute, (int, float)) and compute else None,
                    'result': ours.get('result_line')})
    return out


def summary(xs):
    return {'n': len(xs), 'median': round(st.median(xs), 1), 'min': min(xs), 'max': max(xs)} if xs else {'n': 0}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--since')
    ap.add_argument('--json', action='store_true')
    a = ap.parse_args()
    since = ts(a.since + ('' if a.since.endswith('Z') or '+' in a.since else 'Z')) if a.since else None
    report = {'gates': {}, 'hung': {}, 'pool_jobs': pool_jobs(since)}
    for g, path in GATES.items():
        runs, hung = gate_runs(path, since)
        report['gates'][g] = {k: summary([r['minutes'] for r in runs if r['kind'] == k and not str(r['verdict']).startswith(('REFUSED', 'ENDED'))]) for k in ('high', 'normal')}
        report['gates'][g]['red_or_ended'] = sum(1 for r in runs if str(r['verdict']).startswith(('REFUSED', 'ENDED')))
        report['gates'][g]['runs'] = runs
        report['hung'][g] = hung
    if a.json:
        json.dump(report, sys.stdout, indent=1, default=str)
        return 0
    for g, s in report['gates'].items():
        print(f"{g} gate (green runs) — pool AND here: {s['high']}   pool alone: {s['normal']}   red/ended: {s['red_or_ended']}")
    for g, h in report['hung'].items():
        for r in h:
            print(f"  NO VERDICT  {g} gate started {r['start']} for {r['commit']} ({r['kind']}): aborted or hung, look")
    print('pool jobs:')
    for j in report['pool_jobs']:
        bad = j['outcome'] not in ('succeeded', 'failed') or (j['outcome'] == 'failed' and not j['result'])
        print(f"  {'!!' if bad else '  '} {j['name']}  {j['node']}  {j['outcome']}  wait {j['wait_s']} s  run {j['run_s']} s"
              f"  compute {j['compute_s']} s  overhead {j['overhead_s']} s  {j['result'] or j['reason'] or ''}"[:220])
    return 0


if __name__ == '__main__':
    sys.exit(main())
