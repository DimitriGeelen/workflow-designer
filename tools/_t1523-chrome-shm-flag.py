#!/usr/bin/env python3
"""T-1523: every tool that starts Chrome passes --disable-dev-shm-usage.

Headless Chrome keeps shared memory in /dev/shm, which is small in containers; a larger page then crashes the
renderer. T-1504's harness, launched without the flag, crashed on pool node ring20-live three runs in a row (recorded
as Inspector.targetCrashed at 4b6fcb8ee) and went green with it. About 20 harnesses had been copied from one that
lacked the flag.

A tool "starts Chrome" when its text passes `--headless` or `--remote-debugging-port` (the two flags every launch line
here carries). Files that only attach to a running browser (`_cdp-attach.mjs`, `_cdp-client.mjs`) carry neither.

  python3 tools/_t1523-chrome-shm-flag.py            exit 0 when every launcher has the flag, 1 naming each that has not
  python3 tools/_t1523-chrome-shm-flag.py --teeth    proves the check bites: a launcher without the flag is refused, the
                                                     same launcher with it is admitted, and the live tree is non-empty
"""
import os
import re
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
LAUNCH = re.compile(r'--headless|--remote-debugging-port')
FLAG = '--disable-dev-shm-usage'
SELF = os.path.basename(__file__)


def launchers(tools_dir):
    out = []
    for name in sorted(os.listdir(tools_dir)):
        p = os.path.join(tools_dir, name)
        if name == SELF or not os.path.isfile(p) or not name.endswith(('.mjs', '.js', '.py', '.sh')):
            continue
        try:
            text = open(p, encoding='utf-8', errors='replace').read()
        except OSError:
            continue
        if LAUNCH.search(text):
            out.append((name, FLAG in text))
    return out


def check(tools_dir):
    found = launchers(tools_dir)
    missing = [n for n, ok in found if not ok]
    return found, missing


def teeth():
    with tempfile.TemporaryDirectory() as d:
        line = "spawn(chrome, ['--headless=new', '--no-sandbox', '--remote-debugging-port=0'])\n"
        open(os.path.join(d, '_x-bad-cdp.mjs'), 'w').write(line)
        open(os.path.join(d, '_x-good-cdp.mjs'), 'w').write(line.replace("'--no-sandbox'", f"'--no-sandbox', '{FLAG}'"))
        open(os.path.join(d, '_x-attach.mjs'), 'w').write("export const ws = 'ws://127.0.0.1';\n")
        found, missing = check(d)
        names = [n for n, _ in found]
    live, _ = check(os.path.join(ROOT, 'tools'))
    ok = missing == ['_x-bad-cdp.mjs'] and sorted(names) == ['_x-bad-cdp.mjs', '_x-good-cdp.mjs'] and len(live) > 0
    print(('PASS' if ok else 'FAIL') + f'  teeth: refused {missing}, launchers seen {sorted(names)}, live launchers {len(live)}')
    return 0 if ok else 1


def main():
    if '--teeth' in sys.argv[1:]:
        return teeth()
    found, missing = check(os.path.join(ROOT, 'tools'))
    if not found:
        print('NOT EVALUATED: no tool under tools/ starts Chrome (the launch pattern matched nothing)')
        return 2
    if missing:
        for n in missing:
            print(f'FAIL  tools/{n} starts Chrome without {FLAG}')
        print(f'{len(missing)} of {len(found)} Chrome launchers lack {FLAG} (T-1523)')
        return 1
    print(f'OK: all {len(found)} Chrome launchers under tools/ pass {FLAG}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
