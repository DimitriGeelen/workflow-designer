#!/usr/bin/env python3
"""tracked-secret-artifacts.py — refuse key material that git is TRACKING (T-410).

THE DEFECT THIS EXISTS FOR. `.context/working/.fw-secret-key` — the value that signs
Watchtower's `fw_session_<port>` cookie and the CSRF token inside it — was tracked from
2b9c8ffa (2026-06-04) until T-410. Two months, pushed to origin and mirrored to GitHub
(D-701). Every audit in that window reported `[PASS] Secret scan: tracked tree clean`.

WHY THE EXISTING SCANNER COULD NOT SEE IT, AND WHY THIS IS NOT ITS FAULT.
`agents/git/lib/secret-scan.sh` matches CONTENT against a catalogue of vendor-prefixed
credentials — AKIA…, ghp_…, sk-ant-…, xox…, `-----BEGIN … PRIVATE KEY-----`. Its own
header states the design deliberately:

    "prefer specific (e.g. AKIA prefix) over generic (e.g. base64 entropy).
     Generic entropy checks belong in gitleaks; this catalogue is the always-on baseline."

That is a defensible choice, and it is precisely why the framework's own key is invisible
to it: `secrets.token_hex(32)` is 64 bare lowercase hex characters. No prefix, no vendor
marker, no `key =` assignment — nothing to anchor a specific pattern on. The scanner
catches credentials a developer PASTES IN from elsewhere. It structurally cannot catch
the credential the framework GENERATES ITSELF, because self-generated keys are exactly
the ones with no third-party fingerprint.

So this tool does not compete with it and does not duplicate it. It adds the orthogonal
axis nobody was reading: THE NAME. `.fw-secret-key` announced itself in its filename for
two months. Reading filenames requires no entropy analysis, no gitleaks, and no catalogue
of vendors — and it would have caught this on day one.

POPULATION = `git ls-files`, NOT the working tree. An untracked key on disk is a key
doing its job; a TRACKED one is a published key. The distinction is the whole point, and
scanning the wrong one would flood the report with every legitimate local secret.

TWO RULE CLASSES, deliberately unequal in confidence:

  DEFINITIVE   the name is key material by construction — `*.pem`, `*.p12`, `id_rsa`,
               `.netrc`, `.env` … Extension and exact-name rules. No judgement involved.
  ANNOUNCED    the name pairs a secrecy word (secret/credential/password) with a
               credential noun (key/token/cred/passwd). `.fw-secret-key` is this class.

ANNOUNCED is a heuristic and is labelled as one. It is the floor, not the ceiling: a key
named `blob.dat` defeats it completely, exactly as `closure_condition` defeated the
audit's "does the name contain 'trigger'" check in G-027. Substring rules catch names
that ANNOUNCE themselves; they never catch names that don't. The DEFINITIVE class is the
part that does not depend on anyone choosing an honest filename.

WHY `token` IS NOT A SECRECY WORD HERE. Measured on this tree: 5562 tracked files, of
which `token` matches 17 — "token budget" reports, "design tokens", "CSRF token" RCAs,
`context_tokens.py`. Every one a false positive. In a codebase that talks about token
budgets constantly, `token` as a standalone signal is noise. It survives only as the
CREDENTIAL NOUN half of an ANNOUNCED pair, where a secrecy word must also be present.

ALLOWLIST. `.tracked-secret-allowlist` — one `<glob><TAB><reason>` per line. A reason is
REQUIRED: an entry without one is itself an error. An allowlist of bare paths rots into
unverifiable prose within a year, which is the failure mode `concerns-schema.py` exists
to prevent; the reason is what makes an excuse checkable by the next reader.

Usage:
  tracked-secret-artifacts.py             check (exit 1 if tracked key material found)
  tracked-secret-artifacts.py --census    show population, rules and allowlist; exit 0

Exit 0 = clean over a non-empty population. 1 = tracked key material. 2 = vacuity or
harness error (no git, empty population, malformed allowlist).
"""
import argparse
import fnmatch
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ALLOWLIST = os.path.join(ROOT, ".tracked-secret-allowlist")

# ---------------------------------------------------------------------------
# DEFINITIVE — the name is key material by construction.
# ---------------------------------------------------------------------------
DEFINITIVE_SUFFIX = {
    ".pem":      "PEM-encoded key or certificate bundle",
    ".key":      "private key (nginx/openssl convention)",
    ".p12":      "PKCS#12 keystore",
    ".pfx":      "PKCS#12 keystore (Windows spelling)",
    ".jks":      "Java keystore",
    ".keystore": "Java keystore",
    ".ovpn":     "OpenVPN profile — embeds inline keys",
    ".kdbx":     "KeePass database",
}

DEFINITIVE_NAME = {
    ".fw-secret-key": "Watchtower session signing key (web/app.py:_resolve_secret_key)",
    "id_rsa":         "OpenSSH private key",
    "id_dsa":         "OpenSSH private key",
    "id_ecdsa":       "OpenSSH private key",
    "id_ed25519":     "OpenSSH private key",
    ".netrc":         "plaintext machine credentials",
    "_netrc":         "plaintext machine credentials (Windows spelling)",
    ".npmrc":         "may carry an npm auth token",
    ".pypirc":        "may carry a PyPI password",
    ".htpasswd":      "hashed HTTP basic-auth credentials",
    ".pgpass":        "plaintext PostgreSQL passwords",
}

# `.env` and friends, minus the ones that exist precisely to be committed.
RE_DOTENV = re.compile(r"^\.env(\..+)?$")
DOTENV_OK = ("example", "sample", "template", "dist", "defaults", "schema")

# ---------------------------------------------------------------------------
# ANNOUNCED — a secrecy word AND a credential noun at NON-OVERLAPPING spans.
# Both halves required: "secret-scan.sh" is secrecy+scan (tooling, not a secret);
# "context_tokens.py" is noun-only. ".fw-secret-key" is secret+key.
#
# T-412 — WHY "DIFFERENT LISTS" IS NOT ENOUGH, AND WHY THE FIX IS SPANS.
# `password` and `passwd` are in BOTH tuples below, so one occurrence of either satisfied
# both halves and the pair silently collapsed into a single-word match. `reset-password.md`,
# `password-policy.md` and `password_reset_test.py` all flagged: documentation and a test,
# none of them key material, and exactly the false-positive class the pair EXISTS to exclude.
#
# The obvious fix — remove the overlap from the lists — repairs this instance and leaves the
# rule that permitted it in place, so the next author to add a sensible-looking word to both
# tuples reintroduces it. So the pair is now required to match at DISJOINT SPANS of the name:
# two different stretches of text, not two different list memberships. The overlap is left in
# the tuples deliberately (both words genuinely belong in both roles) and made harmless.
#
# Credit: AEF hit the identical shape in their own name-axis scanner (rail 501) —
# "a pair one word can complete is a single-word match wearing a pair's clothes."
# ---------------------------------------------------------------------------
# SELF-SUFFICIENT: these already name key material on their own and carry their own noun.
# `private-key` spans the noun `key`, so under the disjoint-span rule it could never pair with
# anything and `private-key-store.dat` would go unflagged. They are not qualifiers awaiting a
# noun; they are the whole announcement.
SELF_SUFFICIENT = ("privkey", "private-key", "priv-key")

# QUALIFIERS: need a credential noun at a DISJOINT span. `password` is here rather than in
# SELF_SUFFICIENT deliberately — `reset-password.md` and `password-policy.md` are prose about
# passwords, and the noun is what separates those from `password-key.txt`.
SECRECY_WORDS = ("secret", "credential", "password", "passwd")
CREDENTIAL_NOUNS = ("key", "token", "cred", "passwd", "password", "pass", "pw")


def _norm(name):
    """Lowercase, with separators flattened so `fw_secret_key` == `fw-secret-key`."""
    return re.sub(r"[^a-z0-9]+", "-", name.lower())


def classify(path):
    """-> (rule_class, why) or (None, None). Judges the NAME only, never content."""
    name = os.path.basename(path)
    lower = name.lower()

    for suf, why in DEFINITIVE_SUFFIX.items():
        if lower.endswith(suf):
            # `.pub` companions are public by definition and end in .pub, not .key.
            return "DEFINITIVE", why
    if lower in DEFINITIVE_NAME:
        return "DEFINITIVE", DEFINITIVE_NAME[lower]
    if RE_DOTENV.match(lower):
        if any(ok in lower for ok in DOTENV_OK):
            return None, None
        return "DEFINITIVE", "dotenv file — the canonical home for service credentials"

    if lower.endswith(".pub"):
        return None, None
    if announced_pair(name):
        return "ANNOUNCED", "filename pairs a secrecy word with a credential noun"
    return None, None


def _spans(flat, words, whole_part_only):
    """Char ranges in `flat` where any of `words` matches.

    whole_part_only=True restricts matches to complete `-`-separated parts, which is what
    the credential-noun half wants: `pass` must not match inside `passenger`.
    """
    out = []
    if whole_part_only:
        pos = 0
        for part in flat.split("-"):
            if part and part in words:
                out.append((pos, pos + len(part)))
            pos += len(part) + 1
        return out
    for w in words:
        start = flat.find(w)
        while start != -1:
            out.append((start, start + len(w)))
            start = flat.find(w, start + 1)
    return out


def announced_pair(name):
    """-> (secrecy_span, noun_span), or None. The noun must survive MASKING every qualifier.

    T-412 required the two halves to match at DISJOINT SPANS, which fixed the case where one
    occurrence of `password` satisfied both. T-416: disjointness is necessary and NOT
    SUFFICIENT. `password` and `passwd` are in both tuples, so a name carrying two members of
    that family completes the pair from two qualifiers at two different spans, with no
    credential noun anywhere in it:

        secret-password-rotation.md   secret(0,6) + password(7,15), disjoint -> ANNOUNCED
        credential-password-guide.md  -> ANNOUNCED
        passwd-password-migration.md  -> ANNOUNCED

    Ordinary documentation, classed as key material. So the noun is now required to be in
    what REMAINS once every occurrence of every secrecy word is masked out. A word already
    spent as the qualifier cannot be re-spent as the noun, at any span.

    MASKING SUBSTITUTES A SEPARATOR, IT DOES NOT DELETE. Deleting closes the gap and lets a
    noun be assembled across the seam from two harmless neighbours; substituting `-` also
    creates the part boundary the whole-part noun match wants, so `mypasswordkey` still
    yields `key`. Length is preserved, which keeps the returned spans meaningful against the
    original string.

    Credit: AEF, rail 506 §4 — their own first fix split on the qualifier's FIRST occurrence,
    passed all seven fixture legs, and was still wrong; their generative leg caught it. Third
    fix in this lineage (their T-2897 curated the lists, our T-412 added spans), and the first
    two each repaired their own instance while leaving a rule one plausible word from failing.
    This one is keyed on what remains after the qualifiers are gone, which has no next word.
    """
    flat = _norm(name)
    for w in SELF_SUFFICIENT:
        if w in flat:
            i = flat.find(w)
            return (i, i + len(w)), (i, i + len(w))

    sec = _spans(flat, SECRECY_WORDS, whole_part_only=False)
    if not sec:
        return None

    residue = list(flat)
    for s0, s1 in sec:
        for i in range(s0, s1):
            residue[i] = "-"
    noun = _spans("".join(residue), CREDENTIAL_NOUNS, whole_part_only=True)
    if not noun:
        return None
    return sec[0], noun[0]


def load_allowlist(path):
    """-> (list of (glob, reason), error_or_None). A reason is mandatory."""
    entries = []
    if not os.path.exists(path):
        return entries, None
    for n, raw in enumerate(open(path, encoding="utf-8"), 1):
        line = raw.rstrip("\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if "\t" not in line:
            return None, ("%s:%d has no reason. Format is `<glob><TAB><why this is not "
                          "key material>`. A bare path is an excuse nobody can check "
                          "later." % (os.path.relpath(path, ROOT), n))
        glob, reason = line.split("\t", 1)
        if not reason.strip():
            return None, ("%s:%d has an empty reason." % (os.path.relpath(path, ROOT), n))
        entries.append((glob.strip(), reason.strip()))
    return entries, None


def tracked_files():
    try:
        out = subprocess.run(["git", "-C", ROOT, "ls-files"],
                             capture_output=True, text=True, check=True).stdout
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        return None, "git ls-files failed: %s" % e
    return [l for l in out.splitlines() if l.strip()], None


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--census", action="store_true")
    ap.add_argument("--allowlist", default=ALLOWLIST)
    args = ap.parse_args()

    files, err = tracked_files()
    if err:
        print("ERROR: %s" % err, file=sys.stderr)
        return 2

    # ANTI-VACUITY (PL-084): "no tracked key material" over zero tracked files reads
    # exactly like a clean repository. It is a statement about nothing.
    if not files:
        print("VACUOUS: git tracks no files here, so 'no tracked key material' would be "
              "a statement about an empty population.", file=sys.stderr)
        return 2

    allow, alerr = load_allowlist(args.allowlist)
    if alerr:
        print("ERROR: %s" % alerr, file=sys.stderr)
        return 2

    hits, excused = [], []
    for p in files:
        klass, why = classify(p)
        if not klass:
            continue
        reason = next((r for g, r in allow if fnmatch.fnmatch(p, g)), None)
        if reason:
            excused.append((p, klass, reason))
        else:
            hits.append((p, klass, why))

    if args.census:
        print("population : %d tracked file(s)" % len(files))
        print("rules      : %d definitive suffix, %d definitive name, dotenv, "
              "announced(secrecy x noun)"
              % (len(DEFINITIVE_SUFFIX), len(DEFINITIVE_NAME)))
        print("allowlist  : %d entry/entries\n" % len(allow))
        if excused:
            print("EXCUSED (matched a rule, allowlisted with a reason)")
            for p, k, r in excused:
                print("  [%s] %s\n        %s" % (k, p, r))
        if hits:
            print("\nFLAGGED")
            for p, k, w in hits:
                print("  [%s] %s\n        %s" % (k, p, w))
        if not excused and not hits:
            print("no tracked file matches any name rule.")
        return 0

    if hits:
        print("TRACKED KEY MATERIAL — %d file(s) git is publishing:" % len(hits),
              file=sys.stderr)
        for p, k, w in hits:
            print("  [%s] %s\n        %s" % (k, p, w), file=sys.stderr)
        print("\nA tracked secret is a PUBLISHED secret — it reaches every clone, every "
              "mirror, and every reader of this repository's history, not just this "
              "working copy.", file=sys.stderr)
        print("\nRemedy, in this order:", file=sys.stderr)
        print("  1. ROTATE first. Untracking does not un-publish; the value in history "
              "stays readable. Generating a new one is what makes the old one harmless.",
              file=sys.stderr)
        print("  2. git rm --cached <path>   — drops it from the index, not from history.",
              file=sys.stderr)
        print("  3. Add it to .gitignore. Use a pattern with NO leading slash if the same "
              "artifact can exist at more than one depth (T-410: this tree held two "
              "copies, and a path-anchored rule covered only one).", file=sys.stderr)
        print("  4. History rewrite (git filter-repo) + force-push is TIER 0 and is the "
              "operator's call, not the agent's. It is defence-in-depth AFTER rotation, "
              "never a substitute for it.", file=sys.stderr)
        print("\nIf a flagged file is genuinely not key material, add it to "
              "%s as `<glob><TAB><why>`. The reason is required."
              % os.path.relpath(args.allowlist, ROOT), file=sys.stderr)
        return 1

    print("tracked-secret scan ok: %d tracked file(s), no key material tracked "
          "(%d allowlisted with reasons)." % (len(files), len(excused)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
