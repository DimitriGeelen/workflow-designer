#!/bin/bash
# _t1192-teeth.sh — T-1192: tools/_t1192-upgrade-templates.sh on scratch git repos.
#   1. control: nothing changed -> exit 0, "nothing to settle"
#   2. all four cases -> SYNCED / DIFFERS / SUPERSEDED / KEEP each named, exit 1
#   3. --commit commits only the SYNCED one, removes only the SUPERSEDED file, leaves DIFFERS and KEEP alone
#   4. --commit without --task is refused (exit 2) and changes nothing
# Exit 0 = all legs pass, 1 = a leg failed.
TOOL="$(cd "$(dirname "$0")/.." && pwd)/tools/_t1192-upgrade-templates.sh"
T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT
fail=0
ok()  { echo "ok    $1"; }
bad() { echo "FAIL  $1"; fail=1; }
mkrepo() {
    local r="$1"
    mkdir -p "$r/.tasks/templates" "$r/.agentic-framework/.tasks/templates"
    git -C "$r" init -q && git -C "$r" config user.email t@t && git -C "$r" config user.name t
    for n in a b c; do printf 'line 1\nline 2\n' > "$r/.tasks/templates/$n.md"; done
    printf 'line 1\nline 2\nupstream addition\n' > "$r/.agentic-framework/.tasks/templates/a.md"
    printf 'vendored b\n' > "$r/.agentic-framework/.tasks/templates/b.md"
    git -C "$r" add -A && git -C "$r" commit -q -m init
}

mkrepo "$T/r1"
out=$(bash "$TOOL" --root "$T/r1"); rc=$?
[ "$rc" = 0 ] && grep -q 'nothing to settle' <<<"$out" && ok "1. control: exit 0, nothing to settle" || bad "1. control: rc=$rc: $out"

mkrepo "$T/r2"
cp "$T/r2/.agentic-framework/.tasks/templates/a.md" "$T/r2/.tasks/templates/a.md"        # SYNCED
printf 'local edit\n' >> "$T/r2/.tasks/templates/b.md"                                    # DIFFERS
printf 'line 2\n' > "$T/r2/.tasks/templates/c.md.upstream"                                # SUPERSEDED
printf 'line 1\nonly upstream\n' > "$T/r2/.tasks/templates/b.md.upstream"                 # KEEP (1 line)
out=$(bash "$TOOL" --root "$T/r2"); rc=$?
if [ "$rc" = 1 ] && grep -q '^SYNCED .*a\.md' <<<"$out" && grep -q '^DIFFERS .*b\.md' <<<"$out" \
   && grep -q '^SUPERSEDED .*c\.md\.upstream' <<<"$out" && grep -q '^KEEP .*b\.md\.upstream (1 line' <<<"$out"; then
    ok "2. four cases named, exit 1"
else bad "2. rc=$rc: $out"; fi

mkrepo "$T/r3"
cp "$T/r3/.agentic-framework/.tasks/templates/a.md" "$T/r3/.tasks/templates/a.md"
printf 'local edit\n' >> "$T/r3/.tasks/templates/b.md"
printf 'line 2\n' > "$T/r3/.tasks/templates/c.md.upstream"
printf 'line 1\nonly upstream\n' > "$T/r3/.tasks/templates/b.md.upstream"
before=$(git -C "$T/r3" rev-list --count HEAD)
bash "$TOOL" --root "$T/r3" --commit --task T-1192 >/dev/null 2>&1
last=$(git -C "$T/r3" show --name-only --format= HEAD)
if [ "$(git -C "$T/r3" rev-list --count HEAD)" = $((before + 1)) ] && [ "$last" = ".tasks/templates/a.md" ] \
   && [ ! -f "$T/r3/.tasks/templates/c.md.upstream" ] && [ -f "$T/r3/.tasks/templates/b.md.upstream" ] \
   && ! git -C "$T/r3" diff --quiet -- .tasks/templates/b.md; then
    ok "3. --commit: only a.md committed, only c.md.upstream removed, b.md and b.md.upstream left"
else bad "3. --commit: commits=$(git -C "$T/r3" rev-list --count HEAD) last=[$last]"; fi

mkrepo "$T/r4"
cp "$T/r4/.agentic-framework/.tasks/templates/a.md" "$T/r4/.tasks/templates/a.md"
printf 'line 2\n' > "$T/r4/.tasks/templates/c.md.upstream"
bash "$TOOL" --root "$T/r4" --commit >/dev/null 2>&1; rc=$?
if [ "$rc" = 2 ] && [ "$(git -C "$T/r4" rev-list --count HEAD)" = 1 ] && [ -f "$T/r4/.tasks/templates/c.md.upstream" ]; then
    ok "4. --commit without --task refused (exit 2), nothing changed"
else bad "4. rc=$rc"; fi
[ "$fail" = 0 ] && echo "PASS: 4/4" || echo "FAIL"
exit "$fail"
