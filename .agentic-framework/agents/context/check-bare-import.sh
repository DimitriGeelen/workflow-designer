#!/usr/bin/env bash
# check-bare-import.sh — PreToolUse(Bash): refuse a command whose first word is `import`.
#
# WHY. `import` is ImageMagick's screen-capture binary. When a `python3 - <<'PY'` heredoc body leaks to
# the shell, or a multi-line `python3 -c "` block loses its quoting, the first body line is typically an
# import statement — and the shell runs import(1), which CAPTURES THE SCREEN and writes PostScript named
# after the next token. Exit 0. No error. The command's expected output often still appears, so nobody
# looks.
#
# FOUR TIMES IN SEVEN DAYS in this project (OBS-448):
#     0                 0 bytes          2026-09-22   capture interrupted
#     importlib.util    7,962,637 bytes  2026-09-25   1431x915
#     yaml,glob,sys     28,916,814 bytes 2026-09-28   3440x1383  (a whole desktop)
#     re,io             7,962,628 bytes  2026-09-29   1431x915   created by the agent, mid-session
# 37MB of the operator's screen at the repository root. The only thing that kept it out of the git index
# was T-571 — never `git add -A` — which is a convention, not a hook. Hence this.
#
# COVERAGE LIMIT, STATED HERE BECAUSE CLAIMING FULL COVERAGE WOULD BE WORSE THAN THE GAP.
# This hook sees the command string the harness hands it. It therefore catches:
#     - a Bash tool call whose command begins with `import`
#     - the same after leading whitespace, `&&`, `;`, `|`, `(` or a newline -- outside heredoc
#       bodies and quoted text, so `python3 - <<'PY'` bodies and `python3 -c "import x"` pass
# It does NOT catch:
#     - a heredoc body that leaks INSIDE an already-running `bash -c` or script — the inner shell is
#       not re-scanned, and that is exactly how all four real cases arose
#     - `env import ...`, `command import ...`, or an absolute path such as /usr/bin/import
# So this is a partial gate over the SECOND-most-likely path, not a fix for the first. The detector
# (tools/_t936-stray-capture-scan.py, wired into `fw audit`) is what covers the rest, and removing
# import(1) from PATH is the only complete prevention — the operator's call, not the agent's.
#
# NOT ENABLED BY THE AGENT. Enabling means writing .claude/settings.json, which B-005 blocks
# structurally, with no settings.local.json side door. The operator enables it:
#   cd <project root> && bin/fw hook-enable   (vendored: .agentic-framework/bin/fw) --event PreToolUse --matcher Bash --name check-bare-import
set -uo pipefail

# The harness passes the tool call as JSON on stdin.
_payload="$(cat 2>/dev/null || true)"

_cmd="$(printf '%s' "$_payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)          # unparseable input is not a violation; stay out of the way
ti = d.get("tool_input") or {}
print(ti.get("command") or "")
' 2>/dev/null || true)"

[ -n "$_cmd" ] || exit 0

# EVERY CLAUSE'S FIRST TOKEN, OUTSIDE HEREDOC BODIES AND QUOTES (T-1009, 832, 2026-10-04).
#
# The first version matched `import ` after any separator, including a newline. grep works line by
# line, so it fired on the BODY of a perfectly good heredoc:
#     python3 - <<'PY'
#     import re,io          <- matched, and the whole command was refused
#     PY
# The second version narrowed to the command's first token only, which fixed that and silently
# dropped every catch the header promises (`cd x && import re` went through) — found by the teeth
# below, not by review. This version removes the two things that made the first one wrong BEFORE it
# splits: heredoc bodies (from a `<<WORD` line to the line that is exactly WORD) and quoted text
# (`python3 -c "import x"`). What is left is shell, split into clauses on newline ; & | ( ), and a
# clause whose first word is `import` is refused. Both directions are held by
# tools/_t936-bare-import-gate-teeth.sh (8 catches, 9 controls incl. both heredoc forms).
# The coverage note in the header still holds: a leak INSIDE an already-running shell is not seen.
_hit="$(CMD="$_cmd" python3 -c '
import os, re
s = os.environ["CMD"]
out, term = [], None
for ln in s.split("\n"):
    if term is not None:
        if ln.strip() == term:
            term = None
        continue
    out.append(ln)
    m = re.search(r"<<-?\s*[\x27\x22]?([A-Za-z_][A-Za-z0-9_]*)[\x27\x22]?", ln)
    if m:
        term = m.group(1)
s = "\n".join(out)
buf, q, i = [], None, 0
while i < len(s):
    ch = s[i]
    if q:
        if ch == q:
            q = None
        elif ch == "\\" and q == "\x22":
            i += 1
        i += 1
        continue
    if ch in ("\x27", "\x22"):
        q = ch
        buf.append(" ")
    elif ch == "\\":
        i += 1
    else:
        buf.append(ch)
    i += 1
for clause in re.split(r"[\n;&|()]", "".join(buf)):
    w = clause.split()
    if w and w[0] == "import":
        print("import")
        break
' 2>/dev/null || true)"
if [ "$_hit" = "import" ]; then
    cat >&2 <<'BLOCK'
BLOCKED: this command starts with `import`, which is ImageMagick's SCREEN CAPTURE tool.

`import` is not Python here. Run as a shell command it photographs the screen and writes
multi-megabyte PostScript named after the next token, exits 0, and prints nothing. It has happened
four times in seven days in this project (OBS-448) — `importlib.util`, `yaml,glob,sys`, `re,io` and
one interrupted capture, 37MB total, at the repository root for six days before anyone noticed.

WHAT PROBABLY WENT WRONG: a `python3 - <<'PY'` heredoc body, or a multi-line `python3 -c "` block,
leaked to the shell. The first line of Python became a shell command.

WHAT TO DO INSTEAD — write the script to a file and run it, rather than piping it through the shell:
    cat > "$SCRATCH/x.py" <<'PY'
    import re, io
    ...
    PY
    python3 "$SCRATCH/x.py"

If you genuinely mean ImageMagick's import(1), call it by its absolute path so the intent is explicit:
    /usr/bin/import -window root /path/to/out.png
BLOCK
    exit 2
fi

exit 0
