#!/usr/bin/env python3
"""T-198 / G-007: release immutability guard tests for scripts/release-designer.sh.

A release is a promise: version X means these exact bytes, forever. AEF vendors
``dist/aef-workflow-designer-<VERSION>.html`` and verifies it by sha256, so an
in-place rewrite of an already-released version breaks a consumer's pin with no
local signal. Before T-198 the script did an unconditional ``cp`` and every
downstream check still reported green — they verify internal self-consistency
(artifact == src, manifest == artifact), never immutability against what was
already published.

These tests drive the REAL script against a THROWAWAY repo in a temp dir
(scripts/ + src/ + VERSION + dist/), so the actual ``dist/`` is never touched.
The temp repo deliberately has no ``tests/`` directory, so the script's render
gate self-skips with a warning — no playwright/chromium needed here (the render
gate is covered by tests/test_designer_render.py).

Paths covered:
  1. new-version          — VERSION not yet in dist/ → releases, no guard fires
  2. unchanged-idempotent — re-cut with identical bytes → still green (the
                            script's determinism contract)
  3. blocked-mutation     — src changed at a released VERSION → exit 1
  4. dist-untouched       — a blocked run leaves artifact AND manifest byte-identical
  5. bypass-overwrites    — RELEASE_ALLOW_OVERWRITE=1 overwrites, loudly, naming both shas

Runnable standalone: `python3 tests/test_release_immutability.py`
(exit 0 = pass), matching the repo's other test scripts.
"""

import hashlib
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REAL_SCRIPT = os.path.join(ROOT, "scripts", "release-designer.sh")
# T-1042: since T-808 (87a73faa) the release script refuses to cut unless this parity guard is
# present AND src's APP_VERSION literal equals ./VERSION. The fixture repo carries both, so the
# test exercises the immutability guard rather than stopping at the parity precondition.
REAL_PARITY = os.path.join(ROOT, "tools", "_t808-version-parity.sh")

# AEF's pinned artifact — must be byte-stable across this whole test run.
PINNED_ARTIFACT = os.path.join(ROOT, "dist", "aef-workflow-designer-0.2.0.html")
PINNED_SHA = "e301986b993baf58d5ed29ed25436d94b08ed2be910c6781b0f4b906c25c153a"


def sha256(path):
    # T-1042: a missing artifact is a FAILED case, reported by the caller, never a crash.
    if not os.path.exists(path):
        return None
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()


def make_repo(tmp, version, src_body):
    """Build a throwaway repo the script can resolve REPO_ROOT from."""
    os.makedirs(os.path.join(tmp, "scripts"))
    os.makedirs(os.path.join(tmp, "src"))
    os.makedirs(os.path.join(tmp, "dist"))
    os.makedirs(os.path.join(tmp, "tools"))
    shutil.copy2(REAL_SCRIPT, os.path.join(tmp, "scripts", "release-designer.sh"))
    shutil.copy2(REAL_PARITY, os.path.join(tmp, "tools", "_t808-version-parity.sh"))
    # T-1042: STAND-INS for the two authoring-kit steps the release grew in T-974/T-1008 (the kit
    # calibration gate, the kit builder). This test's subject is the ARTIFACT immutability guard;
    # the kit's own immutability and calibration are tested by tests/test_t974_authoring_kit.py
    # and tests/test_t983_review_loop_kit.py. The stand-ins are deterministic and say what they are.
    with open(os.path.join(tmp, "tools", "kit-calibration-gate.py"), "w") as fh:
        fh.write("# fixture stand-in (test_release_immutability.py): the real gate is tested elsewhere\n"
                 "import sys; sys.exit(0)\n")
    with open(os.path.join(tmp, "tools", "build-authoring-kit.py"), "w") as fh:
        fh.write("# fixture stand-in (test_release_immutability.py): --check passes; a build writes a\n"
                 "# fixed SHA256SUMS, the only file release-designer.sh reads from the kit afterwards\n"
                 "import os, sys\n"
                 "a = sys.argv; out = a[a.index('--out') + 1]\n"
                 "if '--check' in a: sys.exit(0)\n"
                 "os.makedirs(out, exist_ok=True)\n"
                 "open(os.path.join(out, 'SHA256SUMS'), 'w').write('0' * 64 + '  fixture\\n')\n")
    with open(os.path.join(tmp, "VERSION"), "w") as fh:
        fh.write(version + "\n")
    write_src(tmp, src_body)


def write_src(tmp, body):
    # The APP_VERSION line tracks ./VERSION (T-808 parity); `body` stays the bytes under test.
    with open(os.path.join(tmp, "VERSION")) as fh:
        version = fh.read().strip()
    with open(os.path.join(tmp, "src", "aef-workflow-designer.html"), "w") as fh:
        fh.write("const APP_VERSION = '%s';\n" % version + body)


def set_version(tmp, version):
    with open(os.path.join(tmp, "VERSION"), "w") as fh:
        fh.write(version + "\n")


def run(tmp, env=None):
    e = dict(os.environ)
    e.pop("RELEASE_ALLOW_OVERWRITE", None)
    # T-1042: a fixture release must never announce to the fleet's rail, even if a later
    # fixture copies scripts/announce-release.sh; and it has no browser render gate to run.
    e["RELEASE_SKIP_ANNOUNCE"] = "1"
    e["RELEASE_SKIP_RENDER_CHECK"] = "1"
    if env:
        e.update(env)
    return subprocess.run(
        ["bash", os.path.join(tmp, "scripts", "release-designer.sh")],
        capture_output=True, text=True, env=e,
    )


def artifact(tmp, version):
    return os.path.join(tmp, "dist", "aef-workflow-designer-%s.html" % version)


def manifest_text(tmp):
    p = os.path.join(tmp, "dist", "MANIFEST.yaml")
    if not os.path.exists(p):
        return None
    with open(p) as fh:
        return fh.read()


def failures():
    fails = []

    # ---- 1. new-version: nothing released yet → guard must not fire ----------
    with tempfile.TemporaryDirectory() as tmp:
        make_repo(tmp, "0.1.0", "<html>v1 bytes</html>")
        r = run(tmp)
        if r.returncode != 0:
            fails.append("(1) new-version release failed (exit %d): %s"
                         % (r.returncode, r.stderr.strip()[:200]))
        if not os.path.exists(artifact(tmp, "0.1.0")):
            fails.append("(1) new-version: artifact not written")
        if 'latest: "0.1.0"' not in (manifest_text(tmp) or ""):
            fails.append("(1) new-version: manifest does not point at 0.1.0")

    # ---- 2. unchanged-idempotent: same bytes, same version → still green -----
    with tempfile.TemporaryDirectory() as tmp:
        make_repo(tmp, "0.1.0", "<html>v1 bytes</html>")
        run(tmp)
        before = sha256(artifact(tmp, "0.1.0"))
        if before is None:
            fails.append("(2) the first release wrote no artifact, so idempotence cannot be checked")
        r = run(tmp)  # identical re-cut
        if r.returncode != 0:
            fails.append("(2) idempotent re-cut of UNCHANGED bytes was blocked "
                         "(exit %d) — determinism contract broken: %s"
                         % (r.returncode, r.stderr.strip()[:200]))
        if sha256(artifact(tmp, "0.1.0")) != before:
            fails.append("(2) idempotent re-cut changed the artifact bytes")

    # ---- 3+4. blocked-mutation, and dist left untouched ----------------------
    with tempfile.TemporaryDirectory() as tmp:
        make_repo(tmp, "0.1.0", "<html>v1 bytes</html>")
        run(tmp)
        released_sha = sha256(artifact(tmp, "0.1.0"))
        manifest_before = manifest_text(tmp)

        write_src(tmp, "<html>v1 bytes MUTATED</html>")  # the hazard
        r = run(tmp)

        if r.returncode == 0:
            fails.append("(3) MUTATION OF A RELEASED VERSION WAS ALLOWED — guard did not fire")
        if "refusing to overwrite" not in r.stderr:
            fails.append("(3) block message missing 'refusing to overwrite': %s"
                         % r.stderr.strip()[:200])
        # actionable: names the version, and both real options as commands
        for want in ("0.1.0", "VERSION", "RELEASE_ALLOW_OVERWRITE=1"):
            if want not in r.stderr:
                fails.append("(3) block message not actionable — missing %r" % want)
        if released_sha is None:
            fails.append("(3) the first release wrote no artifact, so there is nothing to protect")
        elif released_sha not in r.stderr:
            fails.append("(3) block message does not name the released sha")

        # (4) a refused release must leave dist/ exactly as it was
        if sha256(artifact(tmp, "0.1.0")) != released_sha:
            fails.append("(4) BLOCKED RUN STILL MUTATED THE ARTIFACT")
        if manifest_text(tmp) != manifest_before:
            fails.append("(4) blocked run rewrote MANIFEST.yaml")

    # ---- 5. bypass-overwrites, loudly ---------------------------------------
    with tempfile.TemporaryDirectory() as tmp:
        make_repo(tmp, "0.1.0", "<html>v1 bytes</html>")
        run(tmp)
        old_sha = sha256(artifact(tmp, "0.1.0"))
        write_src(tmp, "<html>v1 bytes DELIBERATELY RECUT</html>")
        new_src_sha = sha256(os.path.join(tmp, "src", "aef-workflow-designer.html"))

        r = run(tmp, env={"RELEASE_ALLOW_OVERWRITE": "1"})
        if r.returncode != 0:
            fails.append("(5) explicit bypass did not release (exit %d): %s"
                         % (r.returncode, r.stderr.strip()[:200]))
        if sha256(artifact(tmp, "0.1.0")) != new_src_sha:
            fails.append("(5) bypass did not actually overwrite the artifact")
        if "WARNING" not in r.stderr:
            fails.append("(5) bypass overwrote SILENTLY — no WARNING on stderr")
        if old_sha is None:
            fails.append("(5) the first release wrote no artifact, so there is nothing to overwrite")
        elif old_sha not in r.stderr or new_src_sha not in r.stderr:
            fails.append("(5) bypass warning does not name BOTH the old and new sha")

    # ---- guard on the guard: the real pinned artifact is untouched -----------
    if os.path.exists(PINNED_ARTIFACT):
        if sha256(PINNED_ARTIFACT) != PINNED_SHA:
            fails.append("(!) REAL dist/aef-workflow-designer-0.2.0.html CHANGED — "
                         "AEF's pin broken by this test run")
    else:
        fails.append("(!) real pinned artifact missing: %s" % PINNED_ARTIFACT)

    return fails


def main():
    if not os.path.exists(REAL_SCRIPT):
        sys.stderr.write("FAIL: script not found: %s\n" % REAL_SCRIPT)
        return 1
    fails = failures()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        return 1
    print("OK: release immutability guard (G-007) — 5 paths pass "
          "(new-version, unchanged-idempotent, blocked-mutation, "
          "dist-untouched-on-block, bypass-overwrites); AEF pin 0.2.0 intact")
    return 0


if __name__ == "__main__":
    sys.exit(main())
