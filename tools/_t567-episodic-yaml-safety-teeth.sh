#!/usr/bin/env bash
# _t567-episodic-yaml-safety-teeth.sh — the episodic generator must survive a commit
# message containing arbitrary bytes.
#
# The defect: mine_git_timeline's subjects were written into a DOUBLE-quoted YAML scalar
# with only `"` escaped. A double-quoted YAML scalar interprets a fixed escape set, so any
# backslash before a non-escape character makes the whole file unparseable. Two of 488
# episodics were already dead this way — T-431 since 2026-08-11 (`\|` from a regex
# alternation) and T-562 (`\-` from a character class) — and nothing noticed, because the
# error is raised at GENERATION time and the file is never parsed again.
#
# The fix is not novel: the `challenges` and `artifacts` blocks in the same file mine the
# SAME `git log --format=%s` subjects and have always used single-quoted YAML with `''`
# doubling. T-562's own episodic held the offending message safely in `challenges` on
# line 37 while line 61 killed the file. This test pins that the timeline block keeps its
# siblings' form.
#
# WHY THE ROUND TRIP AND NOT JUST "IT PARSES". A generator that emitted nothing, or that
# stripped every backslash, would produce a perfectly parseable file. Leg 1 requires the
# stored string to be BYTE-EQUAL to the commit subject, which is the property that
# actually matters for episodic memory: the record must say what happened.
#
# Everything runs against a COPY of the framework in a tmpdir, so no mutant ever touches
# the tree (T-560 precedent).
#
# Usage: bash tools/_t567-episodic-yaml-safety-teeth.sh
# Exit 0 = control round-trips AND both mutants are killed.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

pass=0; fail=0
report() {
  if [ "$1" = PASS ]; then pass=$((pass+1)); else fail=$((fail+1)); fi
  printf '%s  %s — %s\n' "$1" "$2" "$3"
}

# The adversarial subject. Every character class here is one that has appeared, or could
# appear, in this project's commit messages: a character-class regex, an alternation, a
# double quote, an apostrophe, a colon-space (YAML's mapping indicator), a hash, and a
# trailing backslash.
python3 - "$SCRATCH/msg.txt" <<'PY'
import sys
msg = ("T-901: regex /[^a-z0-9_\\-]/g and alternation \\| and a \"double quote\" and an "
       "apostrophe's tail and colon: space and #hash and [bracket] and {brace} and a "
       "trailing backslash \\")
open(sys.argv[1], 'w', encoding='utf-8').write(msg + "\n")
PY

setup_project() { # setup_project <dir>
  local P="$1"
  mkdir -p "$P/.tasks/completed" "$P/.context/episodic"
  cat > "$P/.tasks/completed/T-901-adversarial.md" <<'EOF'
---
id: T-901
name: "Adversarial commit-message fixture"
description: fixture
status: work-completed
workflow_type: build
owner: agent
horizon: now
created: 2026-08-20T00:00:00Z
last_update: 2026-08-20T00:00:00Z
date_finished: 2026-08-20T00:00:00Z
---

# T-901

## Context
fixture
EOF
  git -C "$P" init -q 2>/dev/null
  git -C "$P" config user.email t567@local
  git -C "$P" config user.name t567
  git -C "$P" add -A
  git -C "$P" commit -q -F "$SCRATCH/msg.txt"
}

run_generator() { # run_generator <fwdir> <projdir> -> episodic path on stdout
  local FW="$1" P="$2"
  ( cd "$P" && PROJECT_ROOT="$P" bash "$FW/agents/context/context.sh" \
      generate-episodic T-901 ) > "$SCRATCH/gen.out" 2>&1
  echo "$P/.context/episodic/T-901.yaml"
}

check_roundtrip() { # check_roundtrip <episodic> -> 0 if byte-equal to the subject
  python3 - "$1" "$SCRATCH/msg.txt" <<'PY'
import sys, yaml
try:
    d = yaml.safe_load(open(sys.argv[1], encoding='utf-8'))
except Exception as e:
    print("UNPARSEABLE: %s" % str(e).split('\n')[0]); sys.exit(1)
want = open(sys.argv[2], encoding='utf-8').read().rstrip('\n')
tl = (d or {}).get('git_timeline') or []
acts = [e.get('action') for e in tl if isinstance(e, dict) and e.get('action')]
if not acts:
    print("NO TIMELINE ENTRY"); sys.exit(1)
if acts[0] != want:
    print("NOT BYTE-EQUAL\n  got : %r\n  want: %r" % (acts[0][:90], want[:90])); sys.exit(1)
print("byte-equal (%d chars)" % len(acts[0]))
PY
}

# ── control ───────────────────────────────────────────────────────────────────────
cp -r "$ROOT/.agentic-framework" "$SCRATCH/fw"
setup_project "$SCRATCH/proj"
EP="$(run_generator "$SCRATCH/fw" "$SCRATCH/proj")"
if [ ! -f "$EP" ]; then
  report FAIL "control (real generator)" "no episodic produced: $(tail -3 "$SCRATCH/gen.out" | tr '\n' ' ')"
  echo; echo "$pass passed, $fail failed"; exit 1
fi
if out="$(check_roundtrip "$EP")"; then
  report PASS "control: adversarial subject round-trips" "$out"
else
  report FAIL "control: adversarial subject round-trips" "$out"
  echo; echo "$pass passed, $fail failed"; exit 1
fi

# ── mutant A: revert the timeline block to double-quoted emission ─────────────────
cp -r "$ROOT/.agentic-framework" "$SCRATCH/fwA"
python3 - "$SCRATCH/fwA/agents/context/lib/episodic.sh" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = """                local escaped_msg=$(echo "$msg" | sed "s/'/''/g")"""
new = """                local escaped_msg=$(echo "$msg" | sed 's/"/\\\\"/g')"""
assert s.count(old) == 1, "mutant A anchor not unique: %d" % s.count(old)
s = s.replace(old, new)
old2 = """                echo "    action: '$escaped_msg'" >> "$episodic_file\""""
new2 = '''                echo "    action: \\"$escaped_msg\\"" >> "$episodic_file"'''
assert s.count(old2) == 1, "mutant A anchor2 not unique: %d" % s.count(old2)
open(p, 'w', encoding='utf-8').write(s.replace(old2, new2))
PY
if [ $? -ne 0 ]; then report FAIL "mutant A planted" "anchors not found"; else
  rm -rf "$SCRATCH/projA"; setup_project "$SCRATCH/projA"
  EPA="$(run_generator "$SCRATCH/fwA" "$SCRATCH/projA")"
  if out="$(check_roundtrip "$EPA")"; then
    report FAIL "mutant A killed (double-quoted emission)" "the pre-fix form round-tripped — this test asserts nothing: $out"
  else
    report PASS "mutant A killed (double-quoted emission)" "${out%%$'\n'*}"
  fi
fi

# ── mutant B: emit a parseable file with no action ────────────────────────────────
# "It parses" is also satisfied by dropping the content. This arm separates the two.
cp -r "$ROOT/.agentic-framework" "$SCRATCH/fwB"
python3 - "$SCRATCH/fwB/agents/context/lib/episodic.sh" <<'PY'
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
old = """                echo "    action: '$escaped_msg'" >> "$episodic_file\""""
assert s.count(old) == 1, "mutant B anchor not unique: %d" % s.count(old)
new = """                echo "    action: ''" >> "$episodic_file\""""
open(p, 'w', encoding='utf-8').write(s.replace(old, new))
PY
if [ $? -ne 0 ]; then report FAIL "mutant B planted" "anchor not found"; else
  rm -rf "$SCRATCH/projB"; setup_project "$SCRATCH/projB"
  EPB="$(run_generator "$SCRATCH/fwB" "$SCRATCH/projB")"
  if out="$(check_roundtrip "$EPB")"; then
    report FAIL "mutant B killed (parseable but empty)" "an empty action passed the round-trip check: $out"
  else
    report PASS "mutant B killed (parseable but empty)" "${out%%$'\n'*}"
  fi
fi

# ── leg 4: the live corpus parses AND its entries match git ───────────────────────
python3 - "$ROOT" > "$SCRATCH/corpus.out" 2>&1 <<'PY'
import sys, glob, yaml, subprocess, os
root = sys.argv[1]; os.chdir(root)
bad = []; checked = 0; okc = 0
for f in sorted(glob.glob('.context/episodic/*.yaml')):
    tid = os.path.basename(f)[:-5]
    try: d = yaml.safe_load(open(f, encoding='utf-8'))
    except Exception as e:
        bad.append((tid, str(e).split('\n')[0])); continue
    tl = (d or {}).get('git_timeline') or []
    if not isinstance(tl, list): continue
    acts = [e.get('action') for e in tl if isinstance(e, dict) and e.get('action')]
    if not acts: continue
    subs = subprocess.run(['git','log','--all','--grep=^%s:'%tid,'--format=%s','--reverse'],
                          capture_output=True, text=True).stdout.splitlines()
    for a, s in zip(acts, subs):
        checked += 1
        if a == s: okc += 1
        else: bad.append((tid, 'timeline entry does not match git subject'))
print("corpus: %d entries compared, %d byte-equal, %d problem(s)" % (checked, okc, len(bad)))
for t, e in bad[:5]: print("   ", t, e[:70])
sys.exit(1 if bad or checked == 0 else 0)
PY
if [ $? -eq 0 ]; then
  report PASS "live corpus parses and matches git" "$(head -1 "$SCRATCH/corpus.out")"
else
  report FAIL "live corpus parses and matches git" "$(head -3 "$SCRATCH/corpus.out" | tr '\n' ' ')"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
echo "$pass/$pass teeth legs passed"
