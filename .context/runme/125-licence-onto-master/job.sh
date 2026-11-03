# Operator job for tools/runme-launcher.sh (T-1055). DEFINITIONS ONLY.
# T-1383, the operator's option 1 (2026-11-03): GitHub's mirror shows `master`, which has not moved since 2026-09-30
# (69a0ac734); the work is on bleeding-edge. So the Apache-2.0 LICENSE and NOTICE go onto master as ONE commit that adds
# only those two files, taken from bleeding-edge's licence commit. Nothing else on master changes, nothing is checked
# out, and the push is a plain fast-forward (no force). Every step reads origin's state (fetched in step 1), which a
# clone of HEAD does not have, so all are `step_outward`.
JOB_TITLE="Put the Apache-2.0 LICENSE and NOTICE onto master (one commit, those two files only) and push it, so GitHub shows the licence"
JOB_TASK="T-1383"
JOB_WHY="You chose option 1: GitHub shows the master branch, last updated 2026-09-30, and the licence is on bleeding-edge
(commit 329437154). This job:
  1 fetches origin and checks master is still where we saw it (69a0ac734) and has no LICENSE or NOTICE yet;
  2 builds one commit on top of master that adds exactly LICENSE and NOTICE (the same bytes as on bleeding-edge),
    without checking anything out, and shows you its file list (it must be those two files only);
  3 pushes that commit to origin master as a fast-forward (no force). The GitHub mirror then follows.
Nothing else on master changes. If master moved in the meantime, step 1 stops and nothing is pushed. Answer y at each
step. Afterwards the agent sends the commit id to Pen and AEF."

SRC=329437154
EXPECT_MASTER=69a0ac734
OUT=.context/runme/125-licence-onto-master

preflight() {
    check "on bleeding-edge" '[ "$(git rev-parse --abbrev-ref HEAD)" = bleeding-edge ]'
    check "the licence commit $SRC is in bleeding-edge" 'git merge-base --is-ancestor "$SRC" HEAD'
    check "LICENSE at $SRC is the canonical Apache-2.0 text" '[ "$(git show "$SRC:LICENSE" | sha256sum | cut -d" " -f1)" = cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30 ]'
    check "NOTICE at $SRC names Geelen & Company" 'git show "$SRC:NOTICE" | grep -q "^Copyright 2026 Geelen & Company"'
    check "the index holds nothing staged" '[ -z "$(git diff --cached --name-only)" ]'
}

steps() {
    step_outward "Fetch origin; master must still be $EXPECT_MASTER and carry no LICENSE or NOTICE" 'do_check_master'
    step_outward "Build one commit on master adding only LICENSE and NOTICE from $SRC (no checkout); show its files" 'do_build'
    step_outward "Push that commit to origin master (fast-forward, no force)" 'do_push'
}

do_check_master() {
    git fetch -q origin master || { echo "fetch failed"; return 1; }
    local m; m=$(git rev-parse origin/master) || return 1
    case "$m" in "$EXPECT_MASTER"*) ;; *) echo "origin master moved to ${m:0:12} (expected $EXPECT_MASTER): stopping, nothing pushed — the agent brings it to you"; return 1 ;; esac
    if git ls-tree --name-only origin/master | grep -qxE 'LICENSE|NOTICE'; then echo "master already has a LICENSE or NOTICE: stopping"; return 1; fi
    echo "ok  origin master is ${m:0:12}, without LICENSE or NOTICE"
}

do_build() {
    local base idx tree c files b f
    base=$(git rev-parse origin/master) || return 1
    idx=$(mktemp /tmp/t1383-index.XXXXXX) || return 1
    GIT_INDEX_FILE="$idx" git read-tree "$base" || { rm -f "$idx"; return 1; }
    for f in LICENSE NOTICE; do
        b=$(git rev-parse "$SRC:$f") || { rm -f "$idx"; return 1; }
        GIT_INDEX_FILE="$idx" git update-index --add --cacheinfo 100644,"$b","$f" || { rm -f "$idx"; return 1; }
    done
    tree=$(GIT_INDEX_FILE="$idx" git write-tree); rm -f "$idx"
    [ -n "$tree" ] || { echo "write-tree failed"; return 1; }
    c=$(git commit-tree "$tree" -p "$base" -m "T-1383: Apache-2.0 LICENSE and NOTICE (Geelen & Company)

The same two files as bleeding-edge $SRC, added to master on its own so the GitHub mirror shows the licence
(operator decision 2026-11-03). Nothing else on master changes.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>") || return 1
    files=$(git diff --name-status "$base" "$c")
    echo "$files"
    [ "$(printf '%s\n' "$files" | sort)" = "$(printf 'A\tLICENSE\nA\tNOTICE')" ] || { echo "the commit changes more than LICENSE and NOTICE: stopping"; return 1; }
    printf '%s\n' "$c" > "$OUT/master-commit"
    echo "ok  commit ${c:0:12} on top of ${base:0:12}: adds LICENSE and NOTICE only"
}

do_push() {
    local c; c=$(cat "$OUT/master-commit" 2>/dev/null) || { echo "no commit from step 2"; return 1; }
    git push origin "$c:refs/heads/master" || { echo "push failed (not a fast-forward?) — the agent brings it to you"; return 1; }
    echo "DONE: master is now ${c:0:12} on origin; the GitHub mirror follows."
}
