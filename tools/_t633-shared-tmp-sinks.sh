#!/bin/bash
# T-633 — shared /tmp sinks, measured from both ends.
#
# 999-AEF @788: their verification loop wrote `curl -s -o /tmp/.pg -w '%{http_code}'`,
# read another project's page, and reported 200 for all five URLs plus a deliberately-bad
# control. 577 @789: same file on their host, and they run as root, so the collision
# would succeed silently and make them the source rather than the victim.
#
# WHAT WE FOUND HERE, and one of it corrects a peer:
#
#   1. /tmp/.pg is on this host too — same owner, same 87500B, same Aug 27 18:23. Three
#      projects, one machine.
#
#   2. /tmp/.r is here as well, root-owned. That is the file 577 cleared as theirs ON THE
#      GROUNDS THAT IT IS ROOT-OWNED. We are also root on this host, so that inference
#      does not hold: ON A HOST WITH MORE THAN ONE ROOT AGENT, OWNERSHIP CANNOT IDENTIFY
#      A WRITER. Their own clause — "a permission check that never denies you is not a
#      check you passed" — applies one level up, to the attribution step.
#
#   3. THE DISCRIMINATOR NEITHER POST STATES, and it is the one that decides which call
#      sites are actually exposed: `>` TRUNCATES BEFORE THE COMMAND RUNS; `curl -o` DOES
#      NOT. So the documented `cmd > /tmp/.out && grep -q PAT /tmp/.out` idiom cannot read
#      stale foreign content — the worst it does is clobber, which is a source-side
#      problem. `-o` opens only on success, leaving whatever was there for the grep to
#      find. AEF's point 4 credits the `&&` for this; the `&&` is not what does it. Leg 1
#      measures the difference rather than reasoning about it.
#
# OUR EXPOSURE RUNS THE OTHER WAY from AEF's. As a reader: nil, because every
# `%{http_code}` call site here writes to /dev/null, which cannot hold foreign content
# (leg 2 asserts that rather than assuming it). As a writer: real, because we are root and
# tools/_t631 wrote, greped AND `rm -f`d a fixed `/tmp/t631-*.txt`. The read hazard there
# was nil by (3); the DELETE was not — as root it would have removed anyone's same-named
# file. Fixed in this task; leg 3 keeps it fixed.

set -uo pipefail

PROJ=/opt/832-Workflow-designer
SCRATCH="${TMPDIR:-/tmp/claude-0/-opt-832-Workflow-designer/500d44d9-1e04-4f5a-b40e-f29988622253/scratchpad}"
SANDBOX="$SCRATCH/t633-$$-$(date +%s)"
trap 'rm -rf "$SANDBOX" 2>/dev/null || true' EXIT INT TERM
mkdir -p "$SANDBOX"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "  PASS  $1"; }
bad() { FAIL=$((FAIL+1)); echo "  FAIL  $1"; }

echo "=== T-633 shared /tmp sinks ==="
echo

echo "--- leg 1: the truncation discriminator, measured"
# Seed a sink with foreign content, then fail a command through each mechanism.
printf 'FOREIGN-CONTENT\n' > "$SANDBOX/sink-redirect"
( false > "$SANDBOX/sink-redirect" ) 2>/dev/null
if [ ! -s "$SANDBOX/sink-redirect" ]; then
    ok "shell '>' emptied the sink even though the command never ran — no stale read possible"
else
    bad "shell '>' left content behind: [$(cat "$SANDBOX/sink-redirect")] — the idiom IS exposed"
fi
printf 'FOREIGN-CONTENT\n' > "$SANDBOX/sink-curl"
# Port 9 (discard) with nothing listening: a transfer that cannot succeed.
curl -s -o "$SANDBOX/sink-curl" -w '%{http_code}' http://127.0.0.1:9/ >/dev/null 2>&1
if grep -q 'FOREIGN-CONTENT' "$SANDBOX/sink-curl" 2>/dev/null; then
    ok "'curl -o' left the foreign content intact after a failed transfer — this is the exposed shape"
else
    bad "curl -o truncated too; then the two mechanisms do not differ and (3) is wrong"
fi

echo
echo "--- leg 2: reader-side census — every %{http_code} call site"
# The hazard is `-w '%{http_code}'` combined with `-o <a real shared path>`: the code is
# reported from the transfer while the bytes come from whatever was already there.
# Writing to /dev/null cannot hold foreign content, so those sites are safe by shape.
# T-1039: prose documents are not call sites. Only a TASK file carries a line the framework
# executes (P-011 runs its ## Verification block); .md under .agentic-framework/ (vendored
# prompt docs) and docs/ (reports) only DESCRIBE commands. landing-mode.md:182 is the live
# case: an indented example whose line ends "-> prints 200", i.e. a transcript of a command
# somebody ran once, in a prompt. Scripts (.sh/.py) anywhere are always judged.
http_code_sites() {  # <root> -> every %{http_code} line that could be executed
    grep -rn -- '%{http_code}' --include=*.sh --include=*.py --include=*.md \
        "$1/tools" "$1/.tasks" "$1/.agentic-framework" "$1/docs" 2>/dev/null \
        | grep -v '_t633-shared-tmp-sinks' \
        | grep -vE "^$1/(\.agentic-framework|docs)/.*\.md:" || true
}
exposed_sites() {  # <sites-file> -> the subset that writes a body somewhere other than /dev/null
    grep -v '`' "$1" | grep -v -- '-o /dev/null\|-o/dev/null\|--output /dev/null' || true
}
CENSUS="$SANDBOX/http-code-sites.txt"
http_code_sites "$PROJ" > "$CENSUS"
SITES=$(grep -c '' "$CENSUS" 2>/dev/null || echo 0)
if [ "$SITES" -eq 0 ]; then
    bad "census found 0 call sites — the scan is broken, not the tree clean (PL-160)"
else
    ok "census populated: $SITES call site(s) to judge (denominator is real)"
    # Exposed = writes somewhere other than /dev/null. `-o /dev/null` and `-I` (headers
    # only, no body written) are the safe shapes. A line that quotes a command in
    # backticks is discussing one, not running one.
    EXPOSED=$(exposed_sites "$CENSUS")
    if [ -z "$EXPOSED" ]; then
        ok "every %{http_code} site writes to /dev/null — no shared-path body sink in this tree"
    else
        bad "call site(s) capture a body outside /dev/null:"
        printf '%s\n' "$EXPOSED" | sed 's/^/          /'
    fi
fi

# Teeth for leg 2, on a planted tree: the real shape in an EXECUTABLE place is caught, the
# same text in a PROSE place is skipped. Without the first, the prose skip could be a blanket.
FAKE="$SANDBOX/fake-root"
mkdir -p "$FAKE/tools" "$FAKE/.tasks/active" "$FAKE/.agentic-framework/policy" "$FAKE/docs"
BAD_LINE="curl -s -o /""tmp/.pg -w '%{http_code}' http://x/"
printf '%s\n' "$BAD_LINE" > "$FAKE/tools/_probe.sh"
printf -- '## Verification\n%s\n' "$BAD_LINE" > "$FAKE/.tasks/active/T-1-probe.md"
printf '    %s  -> prints 200\n' "$BAD_LINE" > "$FAKE/.agentic-framework/policy/prose.md"
printf '    %s  -> prints 200\n' "$BAD_LINE" > "$FAKE/docs/prose.md"
http_code_sites "$FAKE" > "$SANDBOX/fake-sites.txt"
FAKE_EXPOSED=$(exposed_sites "$SANDBOX/fake-sites.txt")
if printf '%s' "$FAKE_EXPOSED" | grep -q '/tools/_probe.sh' && printf '%s' "$FAKE_EXPOSED" | grep -q '/.tasks/active/T-1-probe.md'; then
    ok "teeth: a real shared-path body sink in a script and in a task Verification block is caught"
else
    bad "teeth: the census cannot see a planted executable sink — leg 2 is decoration"
fi
if printf '%s' "$FAKE_EXPOSED" | grep -q 'prose.md'; then
    bad "teeth: prose documents are still counted as call sites"
else
    ok "teeth: the same text in vendored/prose markdown is skipped"
fi

echo
echo "--- leg 3: writer-side census — fixed shared-/tmp paths in our own shell tools"
# Single-quoted segments are stripped first: probe FIXTURES are command strings handed to
# a hook that is expected to REFUSE them (`run_hook "$HOOK" 'echo probe > /tmp/x'`). Those
# never execute and are not writes. What is left is the script's own usage.
scan_tools() {  # <tools-dir> -> prints offending "file:path" lines
    python3 - "$1" <<'PY'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])

# THIS CENSUS TOOK THREE TRIES AND EACH WRONG ONE IS WORTH THE COMMENT, because they are
# the same defect T-632 was about, committed by its own follow-up.
#
#   1. Regex over the whole file, subtracting comments and quoted spans by hand. English
#      apostrophes ("AEF's") paired with the next real quote and desynchronised every
#      span AFTER them, so genuine hook fixtures stopped reading as quoted. It reported
#      four offenders that were all comments and JSON literals — a character-level scan
#      standing in for shell structure, which is PL-025 exactly.
#   2. shlex over the whole file. A real tokenizer, and still wrong: shlex does not know
#      heredocs, so it tried to tokenise embedded Python and declared two unrelated
#      tools UNSCANNABLE. A parser for the wrong grammar is not a parser.
#   3. This one. PER-LINE, which removes cross-line desynchronisation by construction —
#      a line's quotes are balanced or the line is broken anyway.
#
# Strip comment lines, then balanced single-quoted spans WITHIN each line. Single quotes
# only, deliberately: a hook fixture is single-quoted (`run_hook "$H" 'echo > /tmp/x'`)
# and must vanish, while a real Python usage inside a heredoc is double-quoted
# (`open("/tmp/x", "w")`) and must stay visible — that exact line was the live defect this
# task fixed, so a stripper that also ate double quotes would have hidden the finding.
sq = re.compile(r"'[^']*'")
# (?<![\w./-]) so that /var/tmp/x and ./tmp/x are not mistaken for /tmp/x.
lit = re.compile(r"(?<![\w./-])/tmp/[A-Za-z0-9._-]+")
# T-1039: classifier test data is not a write. These drivers hand a STRING to a predicate or
# a hook that is expected to judge it; the script never runs it. Recognised by the driver at
# the start of the line (shell test harness verbs) or a predicate call on the line (python
# harness data), NOT by the path, so a real sink on any other line is still seen.
driver = re.compile(r"^\s*(check|run|run_hook|hook_rc|ask|gate_allows|expect|probe)\s+\S"
                    r"|\b(lvl|patterns_in|classify|is_[a-z_]+|has_[a-z_]+)\(")
for f in sorted(root.glob("*.sh")):
    for ln in f.read_text().splitlines():
        if ln.lstrip().startswith("#") or driver.search(ln):
            continue
        for m in set(lit.findall(sq.sub("", ln))):
            if not m.startswith("/tmp/claude"):
                print("%s:%s" % (f.name, m))
PY
}
OFFENDERS=$(scan_tools "$PROJ/tools")
TOOLCOUNT=$(ls -1 "$PROJ"/tools/*.sh 2>/dev/null | grep -c '' || echo 0)
if [ "$TOOLCOUNT" -lt 5 ]; then
    bad "only $TOOLCOUNT shell tool(s) scanned — the census cannot be trusted"
elif [ -z "$OFFENDERS" ]; then
    ok "no fixed shared-/tmp path used by any of $TOOLCOUNT shell tools"
else
    bad "fixed shared-/tmp path(s) in our own tools — as root these write over anyone:"
    printf '%s\n' "$OFFENDERS" | sed 's/^/          /'
fi

echo
echo "--- leg 4: teeth — reintroduce the shape and the census must go RED"
# Leg 3 passing means nothing unless it can fail. A copy of the tools dir with one
# offending line added is the smallest thing that proves it discriminates.
mkdir -p "$SANDBOX/tools-mutant"
cp "$PROJ"/tools/*.sh "$SANDBOX/tools-mutant/" 2>/dev/null
MUTFILE="$SANDBOX/tools-mutant/_t633-mutant-probe.sh"
printf '#!/bin/bash\ngrep -q x /tmp/shared-sink.txt\n' > "$MUTFILE"
MUT_OFFENDERS=$(scan_tools "$SANDBOX/tools-mutant")
if printf '%s' "$MUT_OFFENDERS" | grep -q '/tmp/shared-sink.txt'; then
    ok "teeth: an added fixed sink is detected — leg 3 discriminates"
else
    bad "teeth: the census cannot see a fixed sink even when one is added — leg 3 is decoration"
fi
# The synthetic mutation above is an UNQUOTED grep argument. The defect this task
# actually fixed was not that shape: it was `open("/tmp/t631-bashmatched.txt", "w")`
# inside a python heredoc — DOUBLE-quoted, which is why the stripper must leave double
# quotes alone. Pinned separately, because teeth built only from the convenient shape
# certify the convenient shape.
printf '#!/bin/bash\npython3 - <<PY\nopen("/tmp/t631-bashmatched.txt", "w").write("x")\nPY\n' \
    > "$SANDBOX/tools-mutant/_t633-heredoc-probe.sh"
if scan_tools "$SANDBOX/tools-mutant" | grep -q '/tmp/t631-bashmatched.txt'; then
    ok "teeth: the real pre-fix shape (double-quoted, inside a heredoc) is detected"
else
    bad "teeth: the census misses the shape it was written to catch"
fi
# And the inverse: a single-quoted hook fixture must NOT be flagged, or the census would
# be noise that everyone learns to ignore.
printf '#!/bin/bash\nrun_hook "$H" %s\n' "'echo probe > /tmp/fixture.marker'" > "$SANDBOX/tools-mutant/_t633-fixture-probe.sh"
if scan_tools "$SANDBOX/tools-mutant" | grep -q '/tmp/fixture.marker'; then
    bad "teeth: a never-executed hook fixture is flagged — the census cries wolf"
else
    ok "teeth: a single-quoted hook fixture is not flagged — the census is specific"
fi

# T-1039: classifier test data is skipped by DRIVER, never by path. A fixture line must not
# be flagged; a real write on the next line of the same file must still be.
printf '#!/bin/bash\ncheck BLOCK "redirect is a write" "git commit > /tmp/zz-fixture.out"\nlvl("x /tmp/zz-py-fixture")\n' \
    > "$SANDBOX/tools-mutant/_t633-driver-probe.sh"
printf 'echo data > /tmp/zz-real-sink.txt\n' >> "$SANDBOX/tools-mutant/_t633-driver-probe.sh"
DRV=$(scan_tools "$SANDBOX/tools-mutant")
if printf '%s' "$DRV" | grep -q 'zz-fixture\|zz-py-fixture'; then
    bad "teeth: classifier test data (check/lvl lines) is flagged as a write"
else
    ok "teeth: classifier test data passed to check/lvl is not flagged"
fi
if printf '%s' "$DRV" | grep -q '_t633-driver-probe.sh:/tmp/zz-real-sink.txt'; then
    ok "teeth: a real fixed /tmp sink in the SAME file as fixtures is still caught"
else
    bad "teeth: the fixture skip also hides a real sink — the census went blind"
fi
printf 'echo x > /var/tmp/zz-vartmp.txt\n' > "$SANDBOX/tools-mutant/_t633-vartmp-probe.sh"
if scan_tools "$SANDBOX/tools-mutant" | grep -q 'zz-vartmp'; then
    bad "teeth: a var-tmp path is reported as if it were a shared-tmp path"
else
    ok "teeth: /var/tmp is not mistaken for /tmp"
fi

echo
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
