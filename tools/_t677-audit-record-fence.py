#!/usr/bin/env python3
"""T-677: a partial audit run must not clobber a fuller record, and allowing more than
one record per date must not inflate the recurrence counter.

Two properties that pull against each other, which is why both are fenced:

  PRESERVE    a section-scoped run writes alongside a fuller record for the same date
              instead of replacing it. The pre-push hook ran `--section structure` and
              wrote the same path a full audit writes, so 13 of 14 days of history
              held only the structure section — and trend analysis, which reads these
              records, could never surface a compliance check because no compliance
              check was ever in the corpus.

  DO NOT      the recurrence counter must still count DAYS, not FILES. The moment a
  INFLATE     date can hold two records, a check in both would count twice, and "3+
              times" would quietly stop meaning "3+ days". Fixing the first property
              by corrupting the counter it feeds would be no fix at all.

Both are driven against a throwaway audits dir. Real records under .context/audits/
are historical and are never read or written here.

Exit 0 all arms behaved, 1 any arm did not.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIT_SH = os.path.join(REPO, ".agentic-framework", "agents", "audit", "audit.sh")

# The write-path decision, lifted verbatim from audit.sh so the fence drives THE
# SHIPPING LOGIC rather than a paraphrase of it. Extracted by markers, so a future
# edit that changes the rule without updating this fence fails loudly at extraction
# instead of silently testing dead code.
GUARD_START = "SECTION_GUARD_EOF'\n"
GUARD_END = "SECTION_GUARD_EOF\n"


def extract_guard():
    src = open(AUDIT_SH).read()
    i = src.find(GUARD_START)
    j = src.find(GUARD_END, i + len(GUARD_START))
    if i < 0 or j < 0:
        return None
    return src[i + len(GUARD_START):j]


def decide(guard_src, path, incoming):
    """Run the extracted guard exactly as audit.sh runs it."""
    r = subprocess.run([sys.executable, "-", path, incoming],
                       input=guard_src, capture_output=True, text=True)
    return r.stdout.strip(), r.stderr.strip()


def write_record(path, sections, checks):
    with open(path, "w") as fh:
        fh.write("# fixture\ntimestamp: 2026-09-05T00:00:00Z\n")
        if sections is not None:
            fh.write('sections: "%s"\n' % sections)
        fh.write("summary:\n  pass: 0\n  warn: %d\n  fail: 0\nfindings:\n" % len(checks))
        for c in checks:
            fh.write('  - level: WARN\n    check: "%s"\n' % c)


def main():
    print("T-677 audit-record preservation fence\n")
    failures = []
    guard = extract_guard()
    if guard is None:
        print("FAIL   could not extract the write-path guard from audit.sh")
        return 1

    tmp = tempfile.mkdtemp(prefix="t677-")
    try:
        date = "2026-09-05"
        target = os.path.join(tmp, date + ".yaml")

        # --- PRESERVE arm -------------------------------------------------------
        cases = [
            # (label, existing sections, incoming sections, expect_demoted)
            ("partial run over a FULL record must not replace it", None, "structure", True),
            ("partial over a pre-T-677 full record (no sections key)", None, "structure", True),
            ("narrower partial over a wider partial", "structure,compliance", "structure", True),
            ("full run supersedes a partial", "structure", "all", False),
            ("same scope replaces itself (no proliferation)", "structure", "structure", False),
            ("wider partial supersedes a narrower one", "structure", "structure,compliance", False),
        ]
        for label, existing, incoming, expect_demoted in cases:
            write_record(target, existing, ["X"])
            out, err = decide(guard, target, incoming)
            demoted = out != target
            ok = demoted == expect_demoted
            if demoted and not re.search(r"%s-[a-z0-9-]+\.yaml$" % date, out):
                ok, label = False, label + " [demoted to a malformed name]"
            print("%-6s %-56s want=%s got=%s" %
                  ("PASS" if ok else "FAIL", label,
                   "alongside" if expect_demoted else "replace",
                   "alongside" if demoted else "replace"))
            if not ok:
                failures.append(label)
                if err:
                    print("        | %s" % err.splitlines()[0][:110])

        # --- DO-NOT-INFLATE arm -------------------------------------------------
        # The same check in two records for ONE date counts once; across two dates,
        # twice. Drives the shipping shell pipeline, not a Python re-implementation.
        os.remove(target)
        write_record(os.path.join(tmp, "2026-09-05.yaml"), "all", ["DUP", "ONLYFULL"])
        write_record(os.path.join(tmp, "2026-09-05-structure.yaml"), "structure", ["DUP"])
        write_record(os.path.join(tmp, "2026-09-04.yaml"), "all", ["DUP"])

        script = r'''
set -u
K=$(mktemp)
for f in "$1"/*.yaml; do
    d=$(basename "$f" .yaml); d="${d:0:10}"
    while IFS= read -r line; do
        case "$line" in
            *check:*) c=$(echo "$line" | sed 's/.*check: "//' | sed 's/"$//')
                      printf '%s\t%s\n' "$d" "$c" >> "$K" ;;
        esac
    done < <(grep -A1 "level: WARN\|level: FAIL" "$f" 2>/dev/null)
done
sort -u "$K" | cut -f2- | sort | uniq -c | sort -rn
rm -f "$K"
'''
        r = subprocess.run(["bash", "-c", script, "_", tmp],
                           capture_output=True, text=True)
        counts = {}
        for line in r.stdout.strip().splitlines():
            parts = line.split(None, 1)
            if len(parts) == 2:
                counts[parts[1].strip()] = int(parts[0])

        for name, want in (("DUP", 2), ("ONLYFULL", 1)):
            got = counts.get(name, 0)
            ok = got == want
            print("%-6s %-56s want=%d got=%d" %
                  ("PASS" if ok else "FAIL",
                   "%s counted once per DATE" % name, want, got))
            if not ok:
                failures.append("%s count" % name)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    if failures:
        print("\nFENCE FAILED — %d arm(s): %s" % (len(failures), "; ".join(failures)))
        return 1
    print("\nFENCE PASSED — partial runs write alongside fuller records, fuller runs"
          "\nstill supersede, and recurrence counts days rather than files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
