#!/usr/bin/env bash
# _t918-prose-edge-teeth.sh — prove _t578 now distinguishes a PROSE mention from a CALL in
# .py and .sh, and prove it still calls a call a call.
#
# THE DEFECT T-918 CLOSED. _t578 computed its stripped view `if is_js` only. The trailing else —
# .sh, .py, .yaml, .bats, .toml — did a bare substring match, so a tool named only inside a Python
# docstring or a shell `#` comment counted as an EXECUTABLE-CODE edge. The census whose entire
# subject is "a prose mention is not a call" was making that mistake in every language except the
# one it is named after. Corpus effect, measured: code-edge 175 -> 144, prose-only 219 -> 250.
#
# WHY A SCRATCH TREE. _t578 derives REPO from its own location and walks it. Pointing it at a
# fixture tree is therefore just a matter of putting it in one — no env override, no monkeypatch,
# and the tool runs exactly as it runs in production.
#
# THE SECOND HALF IS THE LOAD-BEARING ONE. "Prose is no longer a code edge" can be satisfied by a
# stripper that returns nothing. Every prose case below is paired with a CALL case for the same
# language, so a stripper that ate everything fails here.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 90
REPO="$PWD"
WORK="$(mktemp -d)"
PASS=0; FAIL=0
trap 'rm -rf "$WORK"' EXIT INT TERM
ok() { if [ "$2" -eq 0 ]; then echo "  PASS  $1"; PASS=$((PASS+1)); else echo "  FAIL  $1"; [ -n "${3:-}" ] && echo "        $3"; FAIL=$((FAIL+1)); fi; }

T="$WORK/tree"
mkdir -p "$T/tools"
cp "$REPO/tools/_t578-js-comment-edge-census.py" "$T/tools/" || { echo "SETUP BROKEN: no _t578"; exit 1; }
cp "$REPO/tools/_t451-unwired-guard-census.py"  "$T/tools/" || { echo "SETUP BROKEN: no _t451"; exit 1; }

# Four subject tools. Nothing references them except the fixture callers below.
for n in _t918_py_prose.py _t918_py_call.py _t918_sh_prose.py _t918_sh_call.py; do
  printf '#!/usr/bin/env python3\nprint("subject")\n' > "$T/tools/$n"
done

# PY prose: the only mention is inside a module docstring.
cat > "$T/py_prose_caller.py" <<'EOF'
"""A module whose docstring mentions tools/_t918_py_prose.py and nothing else does."""
x = 1
EOF

# PY call: the mention is a real argument to a real call.
cat > "$T/py_call_caller.py" <<'EOF'
import subprocess
subprocess.run(["python3", "tools/_t918_py_call.py"], check=False)
EOF

# SH prose: the only mention is in a # comment.
cat > "$T/sh_prose_caller.sh" <<'EOF'
#!/usr/bin/env bash
# see tools/_t918_sh_prose.py for the rationale
echo hi
EOF

# SH call: the mention is an executed command.
cat > "$T/sh_call_caller.sh" <<'EOF'
#!/usr/bin/env bash
python3 tools/_t918_sh_call.py --check
EOF

run() { ( cd "$T" && python3 tools/_t578-js-comment-edge-census.py 2>&1 ); }

echo "=== T-918 prose-edge teeth ==="
echo

# ── CONTROLS FIRST ────────────────────────────────────────────────────────────────────────────
# A tool that crashes, or one whose stripper failed to load, produces output that can look like
# "everything is prose". Neither is a measurement.
echo "CONTROLS"
out="$(run)"
ok "the census runs in the scratch tree and produces its census block" \
   "$(printf '%s\n' "$out" | grep -q 'PROSE-ONLY' && echo 0 || echo 1)" "$(printf '%s\n' "$out" | tail -3)"
printf '%s\n' "$out" | grep -q 'PROSE STRIPPING UNAVAILABLE'
ok "the stripper LOADED — otherwise every result below is the pre-fix behaviour" "$([ $? -ne 0 ] && echo 0 || echo 1)"
printf '%s\n' "$out" | grep -q 'could not be stripped'
ok "no fixture file fell back to the unstripped path" "$([ $? -ne 0 ] && echo 0 || echo 1)"
echo

# ── THE CLAIM, AS A DIFFERENTIAL ──────────────────────────────────────────────────────────────
# The census reports COUNTS, not tool names — so the assertions are on counts. A differential is
# also the stronger form: it compares the same tree with the stripper live and disconnected, so
# nothing depends on how many other files happen to be in tools/.
#
# TWO TREES, because a single tree cannot separate "prose stopped counting" from "everything
# stopped counting":
#   A  only PROSE fixtures  -> stripping must move BOTH to prose-only
#   B  only CALL fixtures   -> stripping must move NEITHER
# A stripper that ate everything passes A and fails B. That is the whole point of B.
echo "THE CLAIM (differential: same tree, stripper live vs disconnected)"

counts() {  # <tree> -> "<code> <prose>"
  ( cd "$1" && python3 tools/_t578-js-comment-edge-census.py 2>&1 ) \
    | awk '/EXECUTABLE-CODE edge/{c=$NF}
           /PROSE-ONLY/{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/) {p=$i; break}}
           END{print c+0, p+0}'
}
disconnect() {  # <tree> — force STRIP_PROSE to None, asserting the edit applied
  python3 - "$1/tools/_t578-js-comment-edge-census.py" <<'PYX'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = "STRIP_PROSE = _load_strip_prose()"
if s.count(old) != 1:
    sys.stderr.write("MUTATION SETUP BROKEN: expected 1, found %d\n" % s.count(old)); sys.exit(1)
open(p, 'w', encoding='utf-8').write(s.replace(old, "STRIP_PROSE = None  # T-918 MUTANT"))
PYX
}
mktree() {  # <dir> <which: prose|call>
  local d="$1" which="$2"
  mkdir -p "$d/tools"
  cp "$REPO/tools/_t578-js-comment-edge-census.py" "$REPO/tools/_t451-unwired-guard-census.py" "$d/tools/"
  printf '#!/usr/bin/env python3\nprint(1)\n' > "$d/tools/_t918_subj_py.py"
  printf '#!/usr/bin/env python3\nprint(1)\n' > "$d/tools/_t918_subj_sh.py"
  if [ "$which" = prose ]; then
    printf '"""mentions tools/_t918_subj_py.py in a docstring"""\nx = 1\n' > "$d/caller.py"
    printf '#!/usr/bin/env bash\n# see tools/_t918_subj_sh.py\necho hi\n'     > "$d/caller.sh"
  else
    printf 'import subprocess\nsubprocess.run(["python3", "tools/_t918_subj_py.py"])\n' > "$d/caller.py"
    printf '#!/usr/bin/env bash\npython3 tools/_t918_subj_sh.py --check\n'              > "$d/caller.sh"
  fi
}

# Both trees contain the same two census copies, and _t578's own comment names _t451 in prose —
# so _t451 itself moves when stripping is on, in BOTH trees. That shared noise cancels exactly if
# the assertion is the DIFFERENCE OF DELTAS rather than either delta alone. Measured first, then
# asserted: prose tree moved 3, call tree moved 1, and 3 - 1 = the 2 fixtures.
declare -A D
for which in prose call; do
  live="$WORK/$which-live"; mut="$WORK/$which-mut"
  mktree "$live" "$which"; mktree "$mut" "$which"
  if ! disconnect "$mut"; then ok "[$which] mutation applied" 1 "MUTATION SETUP BROKEN — not scored"; continue; fi
  read -r lc lp <<<"$(counts "$live")"
  read -r mc mp <<<"$(counts "$mut")"
  D[$which-code]=$(( mc - lc ))    # how many code edges stripping removed
  D[$which-prose]=$(( lp - mp ))   # how many tools stripping moved into prose-only
  echo "    $which tree: code $mc -> $lc (delta ${D[$which-code]}), prose-only $mp -> $lp (delta ${D[$which-prose]})"
done

ok "PROSE fixtures lose their code edge; CALL fixtures keep theirs (delta difference = 2)" \
   "$([ $(( ${D[prose-code]:-0} - ${D[call-code]:-0} )) -eq 2 ] && echo 0 || echo 1)" \
   "prose-delta=${D[prose-code]:-?} call-delta=${D[call-code]:-?} — expected the prose tree to move exactly 2 more"
ok "and the same two land in prose-only (delta difference = 2)" \
   "$([ $(( ${D[prose-prose]:-0} - ${D[call-prose]:-0} )) -eq 2 ] && echo 0 || echo 1)" \
   "prose-delta=${D[prose-prose]:-?} call-delta=${D[call-prose]:-?}"
# The load-bearing half: a stripper that ate everything would move the CALL fixtures too.
ok "CALL tree moves ONLY the shared census noise, never a real call" \
   "$([ "${D[call-code]:-99}" -le 1 ] && echo 0 || echo 1)" \
   "call-tree code delta=${D[call-code]:-?} — a genuine call was demoted to prose"
echo

echo
echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
