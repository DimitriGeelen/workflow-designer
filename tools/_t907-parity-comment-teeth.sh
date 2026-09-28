#!/bin/bash
# T-907 (arc-001) — teeth for the editor/bridge parity checker's comment handling.
#
# WHAT IT DEFENDS. tests/test_editor_bridge_meta_parity.py extracts the editor's
# metaKeys by scanning the array literal for quoted strings. Until T-907 it did so
# over the RAW literal, so two English apostrophes in an inline comment paired up
# and the sentence between them was reported as a key the bridge drops — a false
# RED whose printed remedy would have written prose into the bridge. T-904 moved
# its comment out of the literal (mitigation); this is the prevention.
#
# GATE case: a planted apostrophe-bearing comment inside a copy of the LIVE literal
# yields exactly the comment-free key list. Under --mutation the strip is replaced
# by identity and that case must go RED. CONTROLS run first: the live literal
# agrees with node's evaluation of it (the parser that runs the code), the checker
# exits 0 on the live editor+bridge with a non-zero key count, and a // inside a
# real string is still a string.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "REFUSING: cannot cd to $ROOT"; exit 2; }
SUBJECT="${SUBJECT:-$ROOT/tests/test_editor_bridge_meta_parity.py}"
EDITOR_HTML="$ROOT/src/aef-workflow-designer.html"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/t907.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n       %s\n' "$1" "$2"; }

grep -q 'T-907-STRIP' "$SUBJECT" || {
    echo "TEETH BROKEN — T-907-STRIP anchor not found in $SUBJECT."
    echo "This probe can no longer test what it claims to test. Not reporting a pass."
    exit 4; }
command -v node >/dev/null || { echo "TEETH BROKEN — node not available; the engine control cannot run. Not reporting a pass."; exit 4; }

# helper: run a python snippet with the subject imported as `par`
py() { python3 - "$SUBJECT" "$EDITOR_HTML" "$@" <<'PY'
import sys, importlib.util, re, subprocess, json
spec = importlib.util.spec_from_file_location("par", sys.argv[1]); par = importlib.util.module_from_spec(spec); spec.loader.exec_module(par)
html = open(sys.argv[2], encoding="utf-8").read()
case = sys.argv[3]
raw = re.search(r"const\s+metaKeys\s*=\s*\[[^\]]*\]", html).group(0)
clean = par.editor_meta_keys(raw)
if case == "engine":
    node = subprocess.run(["node", "-e", raw + "; console.log(JSON.stringify(metaKeys))"], capture_output=True, text=True)
    js = json.loads(node.stdout)
    print("OK" if (clean == js and len(js) > 0) else "MISMATCH python=%r node=%r" % (clean, js))
elif case == "planted":
    planted = raw.replace("'authority']", "// T-889's addition, after T-904's fix\n    'authority']")
    got = par.editor_meta_keys(planted)
    print("OK" if got == clean else "EXTRA %r" % [k for k in got if k not in clean])
elif case == "quoted_in_comment":
    got = par.editor_meta_keys("const metaKeys = ['tier', // 'emits' would go here\n 'agentType'];")
    print("OK" if got == ["tier", "agentType"] else "GOT %r" % got)
elif case == "slashes_in_string":
    got = par.editor_meta_keys("const metaKeys = ['a//b', 'c'];")
    print("OK" if got == ["a//b", "c"] else "GOT %r" % got)
elif case == "count":
    print(len(clean))
PY
}

c_live_literal_matches_engine() {
    local out; out=$(py engine); [ "$out" = "OK" ] && ok live_literal_matches_engine || bad live_literal_matches_engine "$out"
}
c_checker_green_with_keys() {
    local out rc n; out=$(python3 "$SUBJECT" 2>&1); rc=$?; n=$(py count)
    [ $rc -eq 0 ] && [ "${n:-0}" -gt 0 ] && ok checker_green_with_keys || bad checker_green_with_keys "rc=$rc keys=$n"
}
c_slashes_in_string_kept() {
    local out; out=$(py slashes_in_string); [ "$out" = "OK" ] && ok slashes_in_string_kept || bad slashes_in_string_kept "$out"
}
# checker_green_with_keys was filed as a control and the mutation run refused it: the
# checker's OWN self-test now asserts comments are not keys, so the whole checker goes
# red under the mutant. That is coverage, not a broken harness — the in-file self-test
# is the first line of defence and this suite is the second. Same correction T-866's
# suite records four times: a surviving/dying case is as likely misfiled as it is a defect.
CONTROL_CASES="c_live_literal_matches_engine c_slashes_in_string_kept"

g_planted_apostrophe_comment_is_not_a_key() {
    local out; out=$(py planted); [ "$out" = "OK" ] && ok planted_apostrophe_comment_is_not_a_key || bad planted_apostrophe_comment_is_not_a_key "$out"
}
g_quoted_word_in_comment_is_not_a_key() {
    local out; out=$(py quoted_in_comment); [ "$out" = "OK" ] && ok quoted_word_in_comment_is_not_a_key || bad quoted_word_in_comment_is_not_a_key "$out"
}
GATE_CASES="g_planted_apostrophe_comment_is_not_a_key g_quoted_word_in_comment_is_not_a_key c_checker_green_with_keys"

if [ "${1:-}" = "--mutation" ]; then
    MUT="$WORK/parity.mutant.py"
    python3 - "$SUBJECT" "$MUT" <<'PY'
import sys
src=open(sys.argv[1]).read()
needle='m = RE_EDITOR_METAKEYS.search(_strip_js_comments(text))'
if needle not in src: sys.exit("strip call not found — anchor moved")
open(sys.argv[2],'w').write(src.replace(needle,'m = RE_EDITOR_METAKEYS.search(text)  # MUTANT: strip disabled',1))
PY
    [ -s "$MUT" ] || { echo "MUTATION SETUP FAILED: no mutant"; exit 1; }
    python3 -m py_compile "$MUT" || { echo "MUTATION SETUP FAILED: mutant does not parse"; exit 1; }
    cmp -s "$SUBJECT" "$MUT" && { echo "MUTATION SETUP FAILED: mutant identical to subject"; exit 1; }
    grep -q 'MUTANT: strip disabled' "$MUT" || { echo "MUTATION SETUP FAILED: mutation not applied"; exit 1; }
    echo "=== T-907 MUTATION RUN (comment strip disabled — the pre-fix extractor) ==="
    out=$(SUBJECT="$MUT" bash "$0" 2>&1); echo "$out" | sed 's/^/  | /'
    broken=""; for c in $CONTROL_CASES; do n=${c#c_}; echo "$out" | grep -q "^  PASS  $n\$" || broken="$broken $n"; done
    [ -n "$broken" ] && { echo "MUTATION SETUP BROKEN — controls failed under the mutant:$broken"; exit 1; }
    survivors=""; for c in $GATE_CASES; do n=${c#g_}; n=${n#c_}; echo "$out" | grep -q "^  FAIL  $n\$" || survivors="$survivors $n"; done
    [ -n "$survivors" ] && { echo "MUTATION FAILED — these pass against an extractor that reads comments:$survivors"; exit 1; }
    echo "MUTATION OK — controls green, every comment case went red."
    exit 0
fi

echo "=== T-907 teeth: parity checker comment handling (subject: ${SUBJECT#$ROOT/}) ==="
for c in $CONTROL_CASES; do $c; done
for c in $GATE_CASES; do $c; done
echo; echo "PASS $PASS / FAIL $FAIL"
[ "$FAIL" -eq 0 ]
