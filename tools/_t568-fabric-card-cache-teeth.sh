#!/usr/bin/env bash
# _t568-fabric-card-cache-teeth.sh — an edit to a component card must be visible.
#
# THE DEFECT. Watchtower's _load_components() cached the parsed cards under
# os.stat(COMP_DIR).st_mtime — the mtime of the DIRECTORY, not of the cards. POSIX bumps a
# directory's mtime on create / delete / rename of an entry and NOT on a write to a file
# already inside it, so `fw fabric register` invalidated the cache and `fw fabric enrich`
# — which our own audit's standing priority action tells operators to run — never did.
# The page then served the pre-enrichment card for the life of the process, HTTP 200,
# no signal. Reported by 001-CashWeb-Lightspeed-Ecwid-integration.
#
# WHY A MUTANT ARM AND NOT JUST "THE EDIT IS VISIBLE". "the new content came back" is also
# what a cache that never caches returns, on every request, forever. Mutant B deletes the
# caching and must redden the caching leg AND ONLY that leg; mutant A restores the
# directory-mtime key and must redden the in-place-edit leg AND ONLY that leg. If one
# mutant reddened everything the probe would be measuring its own fragility, not the fix.
# A control run on unmutated source therefore comes first: "every mutant died" is equally
# satisfied by a probe that fails on everything (T-560).
#
# Every mutant is a COPY in a tmpdir. Nothing here writes to the tree, and no leg touches
# the project's real .fabric/components — the module's COMP_DIR is repointed at a fixture.
#
# Usage: bash tools/_t568-fabric-card-cache-teeth.sh
# Exit 0 = control green AND each mutant kills exactly the leg it should.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

SRC="$ROOT/.agentic-framework/web/blueprints/fabric.py"

pass=0; fail=0
report() {
  if [ "$1" = PASS ]; then pass=$((pass+1)); else fail=$((fail+1)); fi
  printf '%s  %s — %s\n' "$1" "$2" "$3"
}

# ── the leg runner ────────────────────────────────────────────────────────────────
# Prints one `LEG <name> PASS|FAIL <detail>` line per leg, for whichever fabric.py it is
# handed. The bash layer reads those lines; that indirection is what lets the same four
# legs judge the control and every mutant.
cat > "$SCRATCH/legs.py" <<'PY'
import importlib.util, os, shutil, sys, tempfile, time

FW = sys.argv[1]        # path to .agentic-framework
MOD_SRC = sys.argv[2]   # path to the fabric.py under test

sys.path.insert(0, FW)

def load(name):
    spec = importlib.util.spec_from_file_location(name, MOD_SRC)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod

class CountingYaml:
    """Stands in for the module's `yaml` so parses can be counted.

    Only safe_load is used by _load_components; delegating keeps behaviour identical.
    """
    def __init__(self, real):
        self.real = real
        self.calls = 0
    def safe_load(self, *a, **kw):
        self.calls += 1
        return self.real.safe_load(*a, **kw)

def card(name, subsystem, purpose):
    return "id: %s\nname: %s\ntype: script\nsubsystem: %s\npurpose: %s\n" % (
        name, name, subsystem, purpose)

def emit(leg, ok, detail):
    print("LEG %s %s %s" % (leg, "PASS" if ok else "FAIL", detail))

def freeze_dir_mtime(d, fn):
    """Run fn with the directory's mtime restored afterwards.

    An in-place write does not move a directory's mtime on this filesystem (measured),
    but restoring it explicitly removes the question entirely: the leg then tests the
    CACHE KEY rather than the filesystem's timestamp semantics.
    """
    st = os.stat(d)
    fn()
    os.utime(d, ns=(st.st_atime_ns, st.st_mtime_ns))

fix = tempfile.mkdtemp(prefix="t568-cards-")
open(os.path.join(fix, "alpha.yaml"), "w").write(card("alpha", "designer-carrier", "the original purpose"))
open(os.path.join(fix, "beta.yaml"), "w").write(card("beta", "seam", "unchanged throughout"))

mod = load("t568_fabric_under_test")
mod.COMP_DIR = fix
cy = CountingYaml(mod.yaml)
mod.yaml = cy

def purposes():
    return {c.get("id"): c.get("purpose") for c in mod._load_components()}

# ── leg 1: an IN-PLACE edit is visible (the reported defect) ──────────────────────
before = purposes()
ok1 = before.get("alpha") == "the original purpose" and len(before) == 2
if not ok1:
    emit("edit", False, "fixture did not load: %r" % (before,))
else:
    time.sleep(0.01)
    freeze_dir_mtime(fix, lambda: open(os.path.join(fix, "alpha.yaml"), "w").write(
        card("alpha", "designer-carrier", "ENRICHED by fw fabric enrich")))
    after = purposes()
    ok1 = after.get("alpha") == "ENRICHED by fw fabric enrich"
    emit("edit", ok1, "in-place edit, directory mtime pinned -> %r" % (after.get("alpha"),))

# ── leg 2: a RENAME is visible (what the directory key did get right) ────────────
os.rename(os.path.join(fix, "beta.yaml"), os.path.join(fix, "beta-renamed.yaml"))
files = sorted(c.get("_card_file") for c in mod._load_components())
ok2 = "beta-renamed.yaml" in files
emit("rename", ok2, "card files now %r" % (files,))

# ── leg 3: create and delete are visible ─────────────────────────────────────────
open(os.path.join(fix, "gamma.yaml"), "w").write(card("gamma", "new", "created after first load"))
ids_after_create = sorted(purposes())
os.remove(os.path.join(fix, "gamma.yaml"))
ids_after_delete = sorted(purposes())
ok3 = "gamma" in ids_after_create and "gamma" not in ids_after_delete
emit("createdelete", ok3, "create -> %r, delete -> %r" % (ids_after_create, ids_after_delete))

# ── leg 4: the cache is still a cache ────────────────────────────────────────────
# The repair must not be "stop caching". Parsing this project's 65 real cards was
# measured at 98.58 ms against 1.36 ms to digest them; a cache that reloads every request
# gives the correct answer and throws that away.
purposes()                      # settle
n0 = cy.calls
for _ in range(5):
    purposes()
ok4 = cy.calls == n0
emit("cached", ok4, "%d parse(s) across 5 unchanged loads (want 0)" % (cy.calls - n0))

shutil.rmtree(fix, ignore_errors=True)
PY

run_legs() { # run_legs <fabric.py> -> LEG lines on stdout
  python3 "$SCRATCH/legs.py" "$1/.agentic-framework" "$2" 2>&1
}

leg_verdict() { # leg_verdict <output> <leg name> -> PASS|FAIL|MISSING
  echo "$1" | awk -v l="$2" '$1=="LEG" && $2==l {print $3; found=1} END{if(!found) print "MISSING"}'
}

# ── control ───────────────────────────────────────────────────────────────────────
CONTROL="$(run_legs "$ROOT" "$SRC")"
control_bad=""
for leg in edit rename createdelete cached; do
  v="$(leg_verdict "$CONTROL" "$leg")"
  [ "$v" = PASS ] || control_bad="$control_bad $leg=$v"
done
if [ -n "$control_bad" ]; then
  report FAIL "control: unmutated source passes all four legs" "failing:$control_bad"
  echo "$CONTROL" | sed 's/^/      | /'
  echo; echo "$pass passed, $fail failed"; exit 1
fi
report PASS "control: unmutated source passes all four legs" "edit, rename, create/delete, cached"

# ── mutants ───────────────────────────────────────────────────────────────────────
# Each is a repair someone would plausibly ship, and each names the ONE leg it must
# redden. The uniqueness matters: a mutant that reddens several legs is indistinguishable
# from the others and proves nothing about which property the leg guards.
mutate() { # mutate <name> <python patch>
  local name="$1" patch="$2"
  mkdir -p "$SCRATCH/$name"
  cp "$SRC" "$SCRATCH/$name/fabric.py"
  python3 - "$SCRATCH/$name/fabric.py" <<PY
import sys
p = sys.argv[1]; s = open(p, encoding='utf-8').read()
$patch
open(p, 'w', encoding='utf-8').write(s)
PY
}

check_mutant() { # check_mutant <name> <leg that must go red> <label>
  local name="$1" want="$2" label="$3"
  local out; out="$(run_legs "$ROOT" "$SCRATCH/$name/fabric.py")"
  local red="" wrong=""
  for leg in edit rename createdelete cached; do
    local v; v="$(leg_verdict "$out" "$leg")"
    if [ "$v" != PASS ]; then
      red="$red $leg"
      [ "$leg" = "$want" ] || wrong="$wrong $leg=$v"
    fi
  done
  if ! echo "$red" | grep -qw "$want"; then
    report FAIL "mutant $name killed ($label)" "leg '$want' stayed GREEN under the mutation — that leg asserts nothing"
    echo "$out" | sed 's/^/      | /'
  elif [ -n "$wrong" ]; then
    report FAIL "mutant $name killed ($label)" "reddened more than its own leg:$wrong — not discriminating"
  else
    report PASS "mutant $name killed ($label)" "reddened '$want' and only '$want'"
  fi
}

# A — the shipping code: key on the DIRECTORY's mtime.
mutate A "
old = 'digest = hashlib.sha256()'
assert s.count(old) == 1
s = s.replace('''    digest = hashlib.sha256()''', '''    digest = hashlib.sha256()
    digest.update(str(os.stat(COMP_DIR).st_mtime).encode())
    _blobs_only = True''')
old2 = '        digest.update(os.path.basename(path).encode(\"utf-8\", \"surrogateescape\"))'
assert s.count(old2) == 1, 'mutant A anchor2: %d' % s.count(old2)
s = s.replace(old2 + '''
        digest.update(b\"\\\\0\")
        digest.update(raw)
        digest.update(b\"\\\\0\")''', '''        pass''')
"
check_mutant A edit "directory mtime as the key, as shipped"

# B — drop the caching entirely. The correct answer, every time, at 72x the cost.
mutate B "
old = '    if key == _comp_cache[\"key\"]:'
assert s.count(old) == 1, 'mutant B anchor: %d' % s.count(old)
s = s.replace(old, '    if False:')
"
check_mutant B cached "cache removed — right answer, wrong cost"

# C — hash the bytes but not the NAME. Reads as a simplification; loses rename.
mutate C "
old = '        digest.update(os.path.basename(path).encode(\"utf-8\", \"surrogateescape\"))'
assert s.count(old) == 1, 'mutant C anchor: %d' % s.count(old)
s = s.replace(old, '        pass')
"
check_mutant C rename "filename dropped from the digest"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
echo "$pass/$pass teeth legs passed"
