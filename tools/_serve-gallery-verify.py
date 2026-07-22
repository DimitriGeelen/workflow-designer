#!/usr/bin/env python3
"""_serve-gallery-verify.py — T-231 lifecycle guard for serve-gallery.sh.

Reproduces the committed!=serving race and asserts the hardening holds:
  A. double-start on the SAME port -> exactly ONE FRESH listener answers /api/health
     (clean-stop-before-bind stopped the old server; no dual-process shadow).
  B. a SIGINT/SIGTERM-deaf holder on the port -> serve-gallery.sh fails LOUD
     (non-zero exit + FATAL "still held" message) and starts NO shadow server.

Fully isolated: GALLERY_DIR -> temp dir, ephemeral ports; never touches the live
:8834 gallery. Dependency-free (stdlib only). Exit 0 = all pass; exit 1 = any fail
(the P-011 completion gate reads this).
"""
import os
import re
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SCRIPT = os.path.join(HERE, 'serve-gallery.sh')

results = []
_spawned = []          # (label, Popen) — killed in the finally sweep


def check(name, cond, detail=''):
    results.append((name, bool(cond), detail))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def free_port():
    s = socket.socket()
    s.bind(('127.0.0.1', 0))
    p = s.getsockname()[1]
    s.close()
    return p


def health_ok(port, path='/api/health'):
    try:
        urllib.request.urlopen('http://127.0.0.1:%d%s' % (port, path), timeout=0.5)
        return True
    except Exception:
        return False


def wait_health(port, timeout=25):
    end = time.time() + timeout
    while time.time() < end:
        if health_ok(port):
            return True
        time.sleep(0.1)
    return False


def listeners(port):
    """Set of PIDs listening on TCP `port` (via ss)."""
    try:
        out = subprocess.run(['ss', '-ltnpH', 'sport = :%d' % port],
                             capture_output=True, text=True, timeout=5).stdout
    except Exception:
        out = ''
    return set(re.findall(r'pid=(\d+)', out))


def start_server(port, gdir, label):
    """Launch serve-gallery.sh in its own session (so we signal it deterministically)."""
    env = dict(os.environ, GALLERY_DIR=gdir)
    proc = subprocess.Popen(['bash', SCRIPT, str(port)], env=env,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                            start_new_session=True)
    _spawned.append((label, proc))
    return proc


def stop_proc(proc):
    if proc is None or proc.poll() is not None:
        return
    try:
        proc.send_signal(signal.SIGINT)      # serve-gallery forwards INT to its child
        proc.wait(timeout=8)
    except Exception:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            proc.wait(timeout=3)
        except Exception:
            pass


def scenario_a(gdir):
    """Double-start on one port -> one fresh listener, no dual-process."""
    port = free_port()
    a = start_server(port, gdir, 'A-first')
    check('A: first server up', wait_health(port), 'port=%d' % port)
    pids_a = listeners(port)
    check('A: first server has exactly one listener', len(pids_a) == 1,
          'pids=%s' % (pids_a or '{}'))

    # Start a SECOND server on the SAME port; clean-stop-before-bind must take over.
    # Wait for B to become the SOLE serving process (a single FRESH pid answering
    # health) — B first rebuilds + clean-stops A + binds, so this can take a moment.
    b = start_server(port, gdir, 'A-second')
    fresh = None
    end = time.time() + 30
    while time.time() < end:
        now = listeners(port)
        if len(now) == 1 and not (now & pids_a) and health_ok(port):
            fresh = next(iter(now))
            break
        time.sleep(0.1)
    check('A: one FRESH listener answers health after double-start (no dual-process shadow)',
          fresh is not None, 'first=%s last_seen=%s' % (pids_a or '{}', listeners(port) or '{}'))
    check('A: still exactly one listener (no lingering shadow)', len(listeners(port)) == 1,
          'pids=%s' % (listeners(port) or '{}'))
    check('A: first script process exited (its server was cleanly stopped)', a.poll() is not None)

    stop_proc(b)
    stop_proc(a)


def deaf_holder(port):
    """A process that binds+listens on `port` and ignores SIGINT/SIGTERM."""
    code = (
        'import socket,signal,time\n'
        'signal.signal(signal.SIGINT, signal.SIG_IGN)\n'
        'signal.signal(signal.SIGTERM, signal.SIG_IGN)\n'
        's=socket.socket(socket.AF_INET,socket.SOCK_STREAM)\n'
        's.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)\n'
        's.bind(("127.0.0.1",%d)); s.listen(8)\n'
        'time.sleep(600)\n' % port
    )
    proc = subprocess.Popen([sys.executable, '-c', code], start_new_session=True)
    _spawned.append(('B-holder', proc))
    return proc


def scenario_b(gdir):
    """A deaf holder on the port -> serve-gallery.sh fails loud, no shadow."""
    port = free_port()
    holder = deaf_holder(port)
    for _ in range(60):                      # wait until the holder is actually listening
        if listeners(port):
            break
        time.sleep(0.05)
    held_before = listeners(port)
    check('B: deaf holder is listening', len(held_before) >= 1, 'pids=%s' % (held_before or '{}'))

    r = subprocess.run(['bash', SCRIPT, str(port)],
                       env=dict(os.environ, GALLERY_DIR=gdir),
                       capture_output=True, text=True, timeout=60)
    msg = r.stderr + r.stdout
    check('B: serve-gallery exits non-zero (fail-loud)', r.returncode != 0, 'rc=%d' % r.returncode)
    check('B: loud message names the still-held port',
          'FATAL' in msg and 'still held' in msg, 'tail=%r' % msg[-160:])

    held_after = listeners(port)
    check('B: no shadow server started (only the holder listens)',
          held_after == held_before, 'before=%s after=%s' % (held_before, held_after))

    # The holder ignores INT/TERM by design -> SIGKILL it (own test child; not the
    # interactive `pkill -9` the Tier-0 hook guards).
    try:
        os.killpg(os.getpgid(holder.pid), signal.SIGKILL)
        holder.wait(timeout=5)
    except Exception:
        pass


def main():
    gdir = tempfile.mkdtemp(prefix='t231-gallery-')
    try:
        scenario_a(gdir)
        scenario_b(gdir)
    finally:
        for _label, proc in _spawned:
            try:
                if proc.poll() is None:
                    os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
            except Exception:
                pass

    passed = sum(1 for _, ok, _ in results if ok)
    total = len(results)
    print('\n%d/%d checks passed' % (passed, total))
    sys.exit(0 if passed == total else 1)


if __name__ == '__main__':
    main()
