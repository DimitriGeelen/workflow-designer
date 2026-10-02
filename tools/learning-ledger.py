#!/usr/bin/env python3
"""learning-ledger.py — the mapping loop's memory, confirmed by evidence and a cross-vendor panel (T-984, T-1006).

The review loop writes a `lesson` and a `lesson_destination` into every correction
(CORRECTIONS.json). This tool gives them a ledger (docs/learning-ledger.yaml). A single observation
only PROPOSES. It becomes `confirmed` only when BOTH hold (T-1006):

  1. its `evidence_cmd` re-runs and exits 0 — the lesson's own claim, measured again, not asserted;
  2. reviewers from at least QUORUM distinct vendors agree, none of them the author's vendor
     (agreement inside one vendor is one view, not several), and no reviewer's disagree stands.

A disagree marks the entry `escalated`. The operator is never asked whether a lesson is TRUE: the
operator said "I cannot confirm that the lesson is right and I am not involved in that". An operator
ruling is recorded separately and only of kind value (is it worth doing) or priority (when).
L1-L15 were confirmed by operator assent before this rule; they stay valid as legacy (`legacy_until`).

  ingest <corrections.json>... [--source S] [--evidence TEXT]
  list [--status S]
  set <id> [--evidence-cmd CMD] [--proposed-change TEXT] [--author-vendor V]
  review <id> --reviewer-cmd CMD --vendor V [--name N] [--timeout SEC]
          sends lesson + evidence + evidence_cmd output + proposed change to one reviewer (the prompt
          is appended as CMD's last argument, as loop.sh does) and records its verdict
          agree | disagree | refine; a reply with no parseable verdict is recorded as no-verdict
  revise <id> --why TEXT [--learning T] [--proposed-change T] [--evidence-cmd C]
          new wording -> new revision; verdicts on the old wording stop counting
  confirm <id>      runs evidence_cmd, checks the quorum, confirms or says exactly why not
  rule <id> --kind value|priority --decision TEXT     an operator ruling (never on correctness)
  promote <id> --where FILE --marker TEXT    | --where sidecar:<client_msg_id>
  stats   per-reviewer verdict mix + results on planted-false controls (reviewer calibration)
  check   exit 1 on: a promotion without a confirmation, a missing marker, or a post-T-1006
          confirmation lacking its evidence result or its vendor quorum

--ledger PATH overrides docs/learning-ledger.yaml (tests use it).
"""
import argparse
import contextlib
import datetime
import fcntl
import json
import os
import re
import shlex
import subprocess
import sys

import yaml

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DEFAULT = os.path.join(ROOT, 'docs', 'learning-ledger.yaml')
DESTS = {'guide', 'rubric', 'validator', 'source-owner', 'tooling'}  # tooling: the kit's own scripts (T-991)
SOURCES = {'loop', 'reviewer', 'human', 'trial'}
VERDICTS = {'agree', 'disagree', 'refine'}
RULING_KINDS = {'value', 'priority'}
QUORUM = 2
AUTHOR_VENDOR = 'anthropic'


def now():
    return datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')


def norm(s):
    return re.sub(r'\s+', ' ', str(s).strip().lower())


def load(path):
    with open(path, encoding='utf-8') as f:
        d = yaml.safe_load(f) or {}
    d.setdefault('learnings', [])
    return d


def save(path, d):
    head = ''
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            for line in f:
                if not line.startswith('#'):
                    break
                head += line
    with open(path, 'w', encoding='utf-8') as f:
        f.write(head + ('\n' if head else ''))
        yaml.safe_dump(d, f, sort_keys=False, allow_unicode=True, width=100)


@contextlib.contextmanager
def locked(path):
    """Serialise read-modify-write on the ledger: reviews run in parallel and each takes minutes."""
    with open(path + '.lock', 'w') as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lk, fcntl.LOCK_UN)


def next_id(d):
    nums = [int(x['id'][1:]) for x in d['learnings'] if re.fullmatch(r'L\d+', str(x.get('id')))]
    return 'L%d' % (max(nums, default=0) + 1)


def num(i):
    m = re.fullmatch(r'L(\d+)', str(i))
    return int(m.group(1)) if m else 10 ** 9


def is_legacy(d, x):
    lu = d.get('legacy_until')
    return bool(lu) and num(x.get('id')) <= num(lu) and bool(x.get('confirmed_by'))


def latest_verdicts(x):
    """The newest verdict per reviewer on the CURRENT revision. A verdict judged a wording; once
    the lesson is revised (`revise`), verdicts on the old wording no longer count."""
    rev = int(x.get('revision', 0))
    last = {}
    for v in x.get('verdicts') or []:
        if int(v.get('revision', 0)) != rev:
            continue
        last[v.get('reviewer')] = v
    return list(last.values())


def calibrated_reviewers(controls_path):
    """Reviewers that have answered at least one PLANTED-FALSE control and agreed with none (T-1006).
    Returns (passed, fooled, untested_ok) as sets of reviewer names. A reviewer that has never seen a
    control is not calibrated: its agree is a claim nobody has checked it can withhold."""
    passed, fooled = set(), set()
    if controls_path and os.path.exists(controls_path):
        for x in load(controls_path)['learnings']:
            for v in latest_verdicts(x):
                if v.get('verdict') == 'agree':
                    fooled.add(v.get('reviewer'))
                elif v.get('verdict') in ('disagree', 'refine'):
                    passed.add(v.get('reviewer'))
    return passed - fooled, fooled


CONTROLS = os.path.join(ROOT, 'docs', 'learning-ledger-controls.yaml')


def quorum_state(x, controls_path=None):
    author = str(x.get('author_vendor') or AUTHOR_VENDOR).lower()
    vs = latest_verdicts(x)
    calibrated, _fooled = calibrated_reviewers(controls_path)
    agree_vendors = sorted({str(v.get('vendor')).lower() for v in vs
                            if v.get('verdict') == 'agree' and str(v.get('vendor')).lower() != author
                            and (controls_path is None or v.get('reviewer') in calibrated)})
    against = [v for v in vs if v.get('verdict') in ('disagree', 'refine')]
    return agree_vendors, against, author


def run_evidence(cmd, timeout=600):
    try:
        r = subprocess.run(['bash', '-c', 'set -o pipefail; ' + cmd], cwd=ROOT, capture_output=True,
                           text=True, timeout=timeout)
        return r.returncode, (r.stdout + r.stderr)[-3000:]
    except subprocess.TimeoutExpired:
        return 124, 'evidence command timed out after %ss' % timeout


def problems(d):
    out = []
    for x in d['learnings']:
        i = x.get('id', '?')
        if x.get('destination') not in DESTS:
            out.append('%s: destination %r not in %s' % (i, x.get('destination'), sorted(DESTS)))
        for r in x.get('rulings') or []:
            if r.get('kind') not in RULING_KINDS:
                out.append('%s: operator ruling of kind %r; rulings are value or priority, never correctness' % (i, r.get('kind')))
        if x.get('status') in ('confirmed', 'promoted') and not is_legacy(d, x):
            c = x.get('confirmation') or {}
            if c.get('evidence_rc') != 0:
                out.append('%s: %s without a green evidence re-run (T-1006)' % (i, x['status']))
            if len(c.get('vendors') or []) < QUORUM:
                out.append('%s: %s without agreement from %d vendors other than the author (T-1006)' % (i, x['status'], QUORUM))
            elif 'reviewers_calibrated' not in c:
                out.append('%s: %s before reviewers had to pass planted-false controls; re-run `confirm %s`' % (i, x['status'], i))
        if x.get('status') == 'promoted':
            if not x.get('confirmed_by') and not x.get('confirmation'):
                out.append('%s: promoted without a confirmation' % i)
            p = x.get('promoted') or {}
            where = str(p.get('where', ''))
            if where.startswith('sidecar:'):
                continue
            f = os.path.join(ROOT, where)
            if not where or not os.path.isfile(f):
                out.append('%s: promoted into %r, which does not exist' % (i, where))
            elif not p.get('marker') or p['marker'] not in open(f, encoding='utf-8').read():
                out.append('%s: promoted into %s but its marker %r is not in that file' % (i, where, p.get('marker')))
    return out


PROMPT = """You are one of several independent reviewers, each from a different AI vendor, asked whether a
proposed LESSON is correct before it changes a BPMN authoring kit (its guide, rubric, validator or scripts).
The lesson was written by another AI agent. Do not defer to it; your value is an independent view.
Judge only the claim and the proposed change, on the evidence given and your own knowledge of BPMN 2.0
and of shell/CLI behaviour. If the evidence does not support the claim, say so.

LESSON {id}: {learning}
DESTINATION: {destination}
EVIDENCE (how it was observed): {evidence}
PROPOSED CHANGE: {proposed_change}
EVIDENCE COMMAND (re-runs the claim): {evidence_cmd}
ITS OUTPUT JUST NOW (exit {rc}):
{output}

Do not run commands or read files: everything you are given is above, and the evidence command
has already been run for you. If what is above is not enough to judge, that is a "disagree" with the
reason "evidence insufficient: <what is missing>".

Answer with ONE line of JSON and nothing after it:
{{"verdict": "agree" | "disagree" | "refine", "reason": "<one or two sentences>", "refinement": "<the corrected lesson, only for refine>"}}
agree = the lesson is right and the change should ship as written. refine = right in substance, wrong in
scope or wording (give the corrected text). disagree = wrong, or not supported by the evidence."""


def parse_verdict(text):
    for m in reversed(list(re.finditer(r'\{[^{}]*"verdict"[^{}]*\}', text or ''))):
        try:
            o = json.loads(m.group(0))
        except ValueError:
            continue
        v = str(o.get('verdict', '')).strip().lower()
        if v in VERDICTS:
            return v, str(o.get('reason', '')).strip(), str(o.get('refinement', '') or '').strip()
    return 'no-verdict', '', ''


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--ledger', default=DEFAULT)
    sub = ap.add_subparsers(dest='cmd', required=True)
    g = sub.add_parser('ingest'); g.add_argument('files', nargs='+')
    g.add_argument('--source', default='loop', choices=sorted(SOURCES)); g.add_argument('--evidence', default='')
    l = sub.add_parser('list'); l.add_argument('--status')
    s = sub.add_parser('set'); s.add_argument('id'); s.add_argument('--evidence-cmd')
    s.add_argument('--proposed-change'); s.add_argument('--author-vendor')
    r = sub.add_parser('review'); r.add_argument('id'); r.add_argument('--reviewer-cmd', required=True)
    r.add_argument('--vendor', required=True); r.add_argument('--name'); r.add_argument('--timeout', type=int, default=900)
    rv = sub.add_parser('revise'); rv.add_argument('id'); rv.add_argument('--learning')
    rv.add_argument('--proposed-change'); rv.add_argument('--evidence-cmd'); rv.add_argument('--why', required=True)
    c = sub.add_parser('confirm'); c.add_argument('id')
    c.add_argument('--controls', default=CONTROLS, help='planted-false controls; only reviewers that passed them count')
    c.add_argument('--by', help=argparse.SUPPRESS)
    u = sub.add_parser('rule'); u.add_argument('id'); u.add_argument('--kind', required=True)
    u.add_argument('--decision', required=True)
    p = sub.add_parser('promote'); p.add_argument('id'); p.add_argument('--where', required=True); p.add_argument('--marker')
    st = sub.add_parser('stats'); st.add_argument('--controls', default=os.path.join(ROOT, 'docs', 'learning-ledger-controls.yaml'))
    sub.add_parser('check')
    a = ap.parse_args(argv)
    d = load(a.ledger)
    by_id = {x['id']: x for x in d['learnings']}

    def get(i):
        return by_id.get(i) or sys.exit('no such learning %s' % i)

    if a.cmd == 'ingest':
        added = bumped = 0
        for fn in a.files:
            for item in json.load(open(fn, encoding='utf-8')):
                lesson, dest = item.get('lesson'), item.get('lesson_destination')
                if not lesson or dest in (None, 'none'):
                    continue
                hit = next((x for x in d['learnings'] if norm(x['learning']) == norm(lesson)), None)
                if hit:
                    hit['occurrences'] = int(hit.get('occurrences', 1)) + 1
                    bumped += 1
                else:
                    d['learnings'].append({'id': next_id(d), 'learning': lesson,
                                           'evidence': a.evidence or '%s (%s %s)' % (fn, item.get('category'), item.get('element')),
                                           'source': a.source, 'destination': dest if dest in DESTS else 'guide',
                                           'status': 'proposed', 'occurrences': 1})
                    added += 1
        save(a.ledger, d)
        print('ingested: %d new proposed, %d occurrence(s) added to existing' % (added, bumped))
        return 0
    if a.cmd == 'list':
        for x in d['learnings']:
            if a.status and x.get('status') != a.status:
                continue
            ag, against, _ = quorum_state(x)
            print('%-4s %-9s %-12s x%-2s agree:%-18s %s' % (x['id'], x.get('status'), x.get('destination'),
                  x.get('occurrences', 1), ','.join(ag) or '-', x['learning'][:90]))
        return 0
    if a.cmd == 'set':
        x = get(a.id)
        for k, v in (('evidence_cmd', a.evidence_cmd), ('proposed_change', a.proposed_change), ('author_vendor', a.author_vendor)):
            if v is not None:
                x[k] = v
        save(a.ledger, d); print('%s updated' % a.id); return 0
    if a.cmd == 'review':
        x = get(a.id)
        if not x.get('evidence_cmd') or not x.get('proposed_change'):
            print('REFUSED: %s needs evidence_cmd and proposed_change before review (set them first)' % a.id, file=sys.stderr)
            return 1
        rc, out = run_evidence(x['evidence_cmd'])
        prompt = PROMPT.format(id=x['id'], learning=x['learning'], destination=x.get('destination'),
                               evidence=x.get('evidence', ''), proposed_change=x['proposed_change'],
                               evidence_cmd=x['evidence_cmd'], rc=rc, output=out or '(no output)')
        try:
            rr = subprocess.run(shlex.split(a.reviewer_cmd) + [prompt], capture_output=True, text=True, timeout=a.timeout)
            reply = rr.stdout + '\n' + rr.stderr
        except subprocess.TimeoutExpired:
            reply = ''
        except OSError as e:
            reply = 'reviewer could not start: %s' % e
        v, reason, refinement = parse_verdict(reply)
        rec = {'reviewer': a.name or a.reviewer_cmd.split()[0], 'vendor': a.vendor.lower(), 'verdict': v,
               'revision': int(x.get('revision', 0)),
               'reason': reason or reply.strip()[-300:], 'evidence_rc': rc, 'at': now()}
        if refinement:
            rec['refinement'] = refinement
        with locked(a.ledger):  # the reviewer took minutes; re-read so a parallel review's verdict survives
            d = load(a.ledger)
            x = next(e for e in d['learnings'] if e['id'] == a.id)
            x.setdefault('verdicts', []).append(rec)
            save(a.ledger, d)
        print('%s: %s (%s) says %s: %s' % (a.id, rec['reviewer'], rec['vendor'], v, rec['reason'][:200]))
        return 0 if v != 'no-verdict' else 3
    if a.cmd == 'revise':
        x = get(a.id)
        if x.get('status') not in ('proposed', 'escalated'):
            sys.exit('%s is %s; only a proposed or escalated learning can be revised' % (a.id, x.get('status')))
        if not (a.learning or a.proposed_change or a.evidence_cmd):
            sys.exit('revise needs at least one of --learning / --proposed-change / --evidence-cmd')
        x.setdefault('history', []).append({'revision': int(x.get('revision', 0)), 'learning': x['learning'],
                                            'proposed_change': x.get('proposed_change'), 'why_revised': a.why, 'at': now()})
        for k, v in (('learning', a.learning), ('proposed_change', a.proposed_change), ('evidence_cmd', a.evidence_cmd)):
            if v:
                x[k] = v
        x['revision'] = int(x.get('revision', 0)) + 1
        x['status'] = 'proposed'
        save(a.ledger, d)
        print('%s revised to revision %d; earlier verdicts no longer count' % (a.id, x['revision'])); return 0
    if a.cmd == 'confirm':
        if a.by:
            print('REFUSED: confirm takes no --by. A lesson is confirmed by its evidence and a cross-vendor panel, '
                  'not by a person vouching for it (T-1006); use `review`, then `confirm %s`' % a.id, file=sys.stderr)
            return 2
        x = get(a.id)
        recheck = x.get('status') == 'confirmed'  # re-confirm under the current rule; demoted if it fails
        if x.get('status') not in ('proposed', 'escalated', 'confirmed'):
            sys.exit('%s is %s; only a proposed, escalated or confirmed learning can be (re)confirmed' % (a.id, x.get('status')))
        why = []
        rc = None
        if not x.get('evidence_cmd'):
            why.append('no evidence_cmd')
        else:
            rc, out = run_evidence(x['evidence_cmd'])
            if rc != 0:
                why.append('evidence_cmd exits %d:\n    %s' % (rc, out.strip().replace('\n', '\n    ')[-600:]))
        ag, against, author = quorum_state(x, a.controls)
        calibrated, fooled = calibrated_reviewers(a.controls)
        uncounted = sorted({'%s (%s)' % (v.get('reviewer'), 'fooled by a planted-false control' if v.get('reviewer') in fooled
                            else 'no control result yet') for v in latest_verdicts(x)
                            if v.get('verdict') == 'agree' and v.get('reviewer') not in calibrated})
        if uncounted:  # information, not a blocker: the quorum count below already excludes them
            print('note: agree not counted from: ' + ', '.join(uncounted))
        if against:
            x['status'] = 'escalated'
            why.append('standing %s: %s' % ('/'.join(sorted({v['verdict'] for v in against})),
                       '; '.join('%s (%s): %s' % (v['reviewer'], v['vendor'], v.get('reason', '')[:160]) for v in against)))
        if len(ag) < QUORUM:
            why.append('agree from %d vendor(s) other than %s (%s), need %d' % (len(ag), author, ','.join(ag) or 'none', QUORUM))
        if why:
            if recheck:
                x['status'] = 'escalated' if against else 'proposed'
                x.setdefault('history', []).append({'revision': int(x.get('revision', 0)), 'demoted_from': 'confirmed',
                                                    'why_revised': 'failed re-check: ' + '; '.join(why)[:300], 'at': now()})
                x.pop('confirmation', None)
            save(a.ledger, d)
            print('NOT CONFIRMED %s (%s):' % (a.id, x['status']))
            for w in why:
                print('  - ' + w)
            return 1
        x['status'] = 'confirmed'
        x['confirmation'] = {'evidence_cmd': x['evidence_cmd'], 'evidence_rc': rc, 'vendors': ag,
                             'reviewers_calibrated': sorted(calibrated), 'at': now()}
        save(a.ledger, d); print('%s confirmed: evidence green, agree from %s' % (a.id, ', '.join(ag))); return 0
    if a.cmd == 'rule':
        x = get(a.id)
        if a.kind not in RULING_KINDS:
            print('REFUSED: an operator ruling is of kind value or priority. Whether a lesson is correct is settled '
                  'by its evidence and the reviewer panel, not by the operator (T-1006)', file=sys.stderr)
            return 2
        x.setdefault('rulings', []).append({'kind': a.kind, 'decision': a.decision, 'at': now()})
        save(a.ledger, d); print('%s: operator %s ruling recorded' % (a.id, a.kind)); return 0
    if a.cmd == 'promote':
        x = get(a.id)
        if x['status'] != 'confirmed':
            print('REFUSED: %s is %s; it must be confirmed first (evidence + panel)' % (a.id, x['status']), file=sys.stderr)
            return 1
        if not a.where.startswith('sidecar:'):
            f = os.path.join(ROOT, a.where)
            if not a.marker or not os.path.isfile(f) or a.marker not in open(f, encoding='utf-8').read():
                print('REFUSED: %s: marker %r not found in %s; promote after the change is in the file' % (a.id, a.marker, a.where), file=sys.stderr)
                return 1
        x['status'] = 'promoted'
        x['promoted'] = {'where': a.where} if a.where.startswith('sidecar:') else {'where': a.where, 'marker': a.marker}
        save(a.ledger, d); print('%s promoted into %s' % (a.id, a.where)); return 0
    if a.cmd == 'stats':
        # Reviewer calibration (T-1006): verdict mix on real lessons, and what each reviewer said to the
        # PLANTED-FALSE controls. A reviewer that agrees with a plant does not discriminate.
        rows = {}
        for x in d['learnings']:
            for v in x.get('verdicts') or []:
                r = rows.setdefault((v.get('reviewer'), v.get('vendor')), {'agree': 0, 'refine': 0, 'disagree': 0, 'no-verdict': 0, 'plants': []})
                r[v.get('verdict')] = r.get(v.get('verdict'), 0) + 1
        if os.path.exists(a.controls):
            for x in load(a.controls)['learnings']:
                for v in latest_verdicts(x):
                    r = rows.setdefault((v.get('reviewer'), v.get('vendor')), {'agree': 0, 'refine': 0, 'disagree': 0, 'no-verdict': 0, 'plants': []})
                    r['plants'].append('%s:%s' % (x['id'], v.get('verdict')))
        print('%-10s %-8s %5s %6s %8s %10s  %s' % ('reviewer', 'vendor', 'agree', 'refine', 'disagree', 'no-verdict', 'planted-false controls'))
        for (name, vendor), r in sorted(rows.items(), key=lambda kv: str(kv[0])):
            n = r['agree'] + r['refine'] + r['disagree']
            fooled = [p_ for p_ in r['plants'] if p_.endswith(':agree')]
            flag = '  FOOLED by %s: its agrees carry no weight' % ','.join(fooled) if fooled else ''
            print('%-10s %-8s %5d %6d %8d %10d  %s%s' % (name, vendor, r['agree'], r['refine'], r['disagree'], r['no-verdict'],
                  ' '.join(r['plants']) or '-', flag))
            if n and r['agree'] / n > 0.9:
                print('%-10s agreed with %d of %d judged verdicts: low discrimination unless the controls say otherwise' % ('', r['agree'], n))
        return 0
    if a.cmd == 'check':
        ps = problems(d)
        for p_ in ps:
            print('LEDGER: ' + p_)
        print('ledger: %d learnings, %d problem(s)' % (len(d['learnings']), len(ps)))
        return 1 if ps else 0


if __name__ == '__main__':
    sys.exit(main())
