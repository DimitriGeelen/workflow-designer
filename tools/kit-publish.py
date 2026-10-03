#!/usr/bin/env python3
"""kit-publish.py — post a released authoring kit to a partner topic and prove it arrived (T-1008, T-989).

0.15.1 and 0.15.2 were posted by hand: a manifest, then base64 chunks, then a manual reassembly
from the hub. This does the same thing, the same way every time, and does not call it delivered
until the bytes read back from the hub hash to what was sent.

  publish --version V --topic T [--hub H] [--supersedes OLD] [--note TEXT]
      tar the released kit dist/aef-authoring-kit-V (sorted, mtime 0: reproducible), post a manifest
      (sha256, bytes, chunk count, reassembly recipe) and the base64 chunks (8000 chars, metadata
      version=V part=NN/M), then run `verify`.
  verify --version V --topic T [--hub H]
      read the topic back, take the LATEST manifest and chunks for V, reassemble, compare sha256.
Refuses a version with no released kit in dist/ (and no tag): only released bytes travel.
"""
import argparse, base64, hashlib, io, json, os, re, subprocess, sys, tarfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
CHUNK = 8000


def tl(args, stdin=None):
    return subprocess.run(['termlink'] + args, input=stdin, capture_output=True, text=True, timeout=60)


def build_tgz(version):
    kit = os.path.join(ROOT, 'dist', 'aef-authoring-kit-%s' % version)
    if not os.path.isdir(kit):
        sys.exit('REFUSED: %s is not a released kit (dist/ has no such directory)' % kit)
    if subprocess.run(['git', '-C', ROOT, 'rev-parse', '-q', '--verify', 'refs/tags/designer-v%s' % version],
                      capture_output=True).returncode != 0:
        sys.exit('REFUSED: no tag designer-v%s: only released bytes travel' % version)
    buf = io.BytesIO()
    import gzip
    with gzip.GzipFile(fileobj=buf, mode='wb', mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode='w') as tar:
            base = os.path.basename(kit)
            for dp, dns, fns in sorted(os.walk(kit)):
                dns.sort()
                for fn in sorted(fns):
                    p = os.path.join(dp, fn)
                    ti = tar.gettarinfo(p, arcname=os.path.join(base, os.path.relpath(p, kit)))
                    ti.mtime = 0; ti.uid = ti.gid = 0; ti.uname = ti.gname = ''
                    with open(p, 'rb') as f:
                        tar.addfile(ti, f)
    return buf.getvalue()


def read_topic(topic, hub):
    r = tl(['channel', 'subscribe', topic, '--hub', hub, '--json', '--limit', '5000'])
    out = []
    for line in r.stdout.splitlines():
        if line.strip().startswith('{'):
            o = json.loads(line)
            o['text'] = base64.b64decode(o.get('payload_b64') or '').decode('utf-8', 'replace')
            out.append(o)
    return out


def verify(version, topic, hub):
    msgs = read_topic(topic, hub)
    mans = [m for m in msgs if (m.get('metadata') or {}).get('kind') == 'manifest' and (m.get('metadata') or {}).get('version') == version]
    if not mans:
        print('NOT VERIFIED: no manifest for %s on %s' % (version, topic)); return 1
    man = mans[-1]
    sha = re.search(r'sha256 ([0-9a-f]{64})', man['text']).group(1)
    n = int(re.search(r'into (\d+) chunks', man['text']).group(1))
    parts = {}
    for m in msgs:
        md = m.get('metadata') or {}
        if m.get('msg_type') == 'artifact-chunk' and md.get('version') == version and m['offset'] > man['offset']:
            parts[md.get('part')] = m['text']
    want = ['%02d/%d' % (i, n) for i in range(1, n + 1)]
    missing = [w for w in want if w not in parts]
    if missing:
        print('NOT VERIFIED: missing chunks %s' % missing); return 1
    data = base64.b64decode(''.join(parts[w] for w in want))
    got = hashlib.sha256(data).hexdigest()
    ok = got == sha
    print('%s: %s reassembled from %s (manifest offset %d, %d chunks): sha256 %s %s' % (
        'VERIFIED' if ok else 'MISMATCH', version, topic, man['offset'], n, got[:16], '== manifest' if ok else '!= ' + sha[:16]))
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('publish', 'verify'):
        p = sub.add_parser(name); p.add_argument('--version', required=True); p.add_argument('--topic', required=True)
        p.add_argument('--hub', default='192.168.10.107:9100')
        if name == 'publish':
            p.add_argument('--supersedes', default=''); p.add_argument('--note', default='')
    a = ap.parse_args()
    if a.cmd == 'verify':
        return verify(a.version, a.topic, a.hub)
    data = build_tgz(a.version)
    sha = hashlib.sha256(data).hexdigest(); b64 = base64.b64encode(data).decode()
    chunks = [b64[i:i + CHUNK] for i in range(0, len(b64), CHUNK)]
    name = 'aef-authoring-kit-%s.tar.gz' % a.version
    man = ('MANIFEST %s%s | sha256 %s | %d bytes | base64 split into %d chunks of %d chars, posted next on this topic '
           'in order with metadata version=%s part=NN/%d. Reassemble: concatenate the %s chunk payloads in part order, '
           'base64 -d > %s, sha256sum must equal %s, then tar xzf.%s' % (
               name, ' (SUPERSEDES %s)' % a.supersedes if a.supersedes else '', sha, len(data), len(chunks), CHUNK,
               a.version, len(chunks), a.version, name, sha, (' ' + a.note) if a.note else ''))
    md = lambda **kw: sum([['--metadata', '%s=%s' % kv] for kv in [('from_project', '832-Workflow-designer')] + sorted(kw.items())], [])
    r = tl(['channel', 'post', a.topic, '--hub', a.hub, '--msg-type', 'note', '--payload', man] + md(kind='manifest', version=a.version))
    if r.returncode != 0:
        sys.exit('manifest post failed: ' + (r.stdout + r.stderr)[-300:])
    print('manifest: ' + r.stdout.strip().splitlines()[-1][:120])
    for i, c in enumerate(chunks, 1):
        r = tl(['channel', 'post', a.topic, '--hub', a.hub, '--msg-type', 'artifact-chunk', '--payload', c]
               + md(part='%02d/%d' % (i, len(chunks)), version=a.version))
        if r.returncode != 0:
            sys.exit('chunk %d post failed: %s' % (i, (r.stdout + r.stderr)[-300:]))
    print('posted %d chunks, %d bytes, sha256 %s' % (len(chunks), len(data), sha))
    return verify(a.version, a.topic, a.hub)


if __name__ == '__main__':
    sys.exit(main())
