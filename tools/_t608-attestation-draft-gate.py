#!/usr/bin/env python3
"""T-608 — does the unsent AEF attestation draft ask for what the clause register requires?

WHAT THIS GUARDS. The draft's whole value is that the operator can rule on concrete text
instead of an abstract "authorise contact?". That value is destroyed in two ways, both
silent:

  1. the draft drifts from the clause register (asks for something the gate will not
     accept as satisfying the clause), or
  2. the register is edited later and the draft quietly stops matching it.

So the required phrasing is DERIVED FROM `arc-0-exit-clauses.yaml` at run time rather than
restated here. A gate that carried its own copy of the ask would agree with itself forever
and would have passed on a draft that asked for the wrong thing.

It also enforces the two limits the draft must disclose TO THE COUNTERPARTY, not merely to
us: that a reply is not ratification, and that both attestations still leave Arc 0 open.
A limit disclosed only internally is a limit the other party cannot act on.

The text legs are pure functions of a string, so the poison arms mutate an in-memory copy.
Nothing on disk is touched — a verifier that edits the artifact it is verifying can leave
the tree dirty when it dies, and this one runs on a document awaiting operator review.
"""
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DRAFT = REPO / "docs" / "research" / "executable-workflow" / "aef-attestation-request-draft.md"
REGISTER = REPO / "docs" / "research" / "executable-workflow" / "arc-0-exit-clauses.yaml"

STOP = {
    "that", "with", "from", "this", "they", "them", "have", "been", "were", "will",
    "every", "each", "which", "when", "what", "your", "ours", "into", "onto", "them",
    "then", "than", "also", "such", "some", "more", "most", "very", "just", "only",
    "does", "doing", "done", "here", "there", "their", "these", "those", "would",
    "could", "should", "about", "after", "before", "where", "while", "being",
}
THRESHOLD = 0.80


def normalise(text):
    """Strip markdown emphasis and blockquote markers so a phrase inside **bold** or a
    `> quoted` block still matches. The draft's message body is entirely blockquoted."""
    text = text.replace("—", " ").replace("’", "'")
    text = re.sub(r"^\s*>\s?", "", text, flags=re.M)
    # NOT `_` — stripping it as markdown emphasis mangles the snake_case identifiers the
    # legs match on (definition_ratified, from_project). Measured: two legs failed on a
    # draft that said exactly the right thing.
    text = re.sub(r"[*`#]", "", text)
    return re.sub(r"\s+", " ", text).lower()


def content_words(phrase):
    toks = re.findall(r"[a-z0-9]+", phrase.lower())
    return sorted({t for t in toks if len(t) > 3 and t not in STOP})


def load_register():
    import yaml
    return yaml.safe_load(REGISTER.read_text(encoding="utf-8"))


# --------------------------------------------------------------------- text-only legs

def leg_unsent(norm, raw):
    head = "\n".join(raw.splitlines()[:5]).upper()
    return ("DRAFT" in head and "UNSENT" in head,
            "marked DRAFT / UNSENT within the first five lines")


def leg_clause_coverage(norm, reg):
    """One leg per counterparty-owned clause, derived from its own what_would_satisfy."""
    rows = []
    for c in reg["clauses"]:
        if c.get("owner") != "aef":
            continue
        words = content_words(c["evaluation"]["what_would_satisfy"])
        hit = [w for w in words if w in norm]
        ratio = len(hit) / len(words) if words else 0.0
        missing = [w for w in words if w not in norm]
        rows.append((ratio >= THRESHOLD,
                     f"{c['id']} ask matches register ({len(hit)}/{len(words)} "
                     f"= {ratio:.0%}, need {THRESHOLD:.0%})"
                     + (f"; missing {missing[:6]}" if missing else "")))
    return rows


def leg_reply_not_ratification(norm, *_):
    ok = ("attestation" in norm
          and "definition_ratified" in norm
          and re.search(r"does not flip .{0,4}definition_ratified", norm) is not None)
    return (ok, "tells the counterparty a reply is recorded, not ratifying")


def leg_arc0_still_open(norm, *_):
    ok = ("clause 3" in norm and "t-596" in norm
          and re.search(r"does not close\s+arc 0", norm) is not None)
    return (ok, "discloses that both attestations still leave Arc 0 open (clause 3, T-596)")


def leg_transport(norm, *_):
    ok = "termlink" in norm and "from_project: 832-workflow-designer" in norm
    return (ok, "names the transport and the producer attribution")


def message_body(raw):
    """The blockquoted message — exactly the bytes that would be transmitted. The prose
    around it (transport notes, scope boundary) stays on this machine and is not scanned.

    Measured: scanning the whole document failed on its own disclaimer, because the
    transport section says "no `payload_b64` block". A token scan cannot tell a USE from a
    MENTION, so it has to be pointed at the region where only uses can occur."""
    return "\n".join(re.sub(r"^\s*>\s?", "", l)
                     for l in raw.splitlines() if l.lstrip().startswith(">"))


def leg_refs_only(norm, raw):
    """Refs only while OBS-108 is open. Also a plain secret sweep — the message body is
    drafted to leave the machine, so it is the last place a credential should survive."""
    bad = []
    raw = message_body(raw)
    if not raw.strip():
        # An empty body would pass every pattern below for the wrong reason.
        return (False, "refs only — MESSAGE BODY EMPTY, scan would be vacuous")
    if "payload_b64" in raw:
        bad.append("payload_b64")
    for pat, label in ((r"ghp_[A-Za-z0-9]{20,}", "github token"),
                       (r"github_pat_[A-Za-z0-9_]{20,}", "github pat"),
                       (r"-----BEGIN [A-Z ]*PRIVATE KEY-----", "private key"),
                       (r"[A-Za-z0-9+/]{120,}={0,2}", "base64 blob")):
        if re.search(pat, raw):
            bad.append(label)
    return (not bad, "refs only, no seam bytes or credentials"
            + (f" — FOUND {bad}" if bad else ""))


TEXT_LEGS = [leg_unsent, leg_reply_not_ratification, leg_arc0_still_open,
             leg_transport, leg_refs_only]


def evaluate(raw, reg):
    norm = normalise(raw)
    rows = [f(norm, raw) for f in TEXT_LEGS]
    rows.extend(leg_clause_coverage(norm, reg))
    return rows


# ------------------------------------------------------------------- filesystem legs

def leg_nothing_sent():
    """Option (a) is the operator's to choose. If a send-authorisation task has appeared
    while this draft still sits unapproved, the agent has answered its own question."""
    hits = []
    for d in ("active", "completed"):
        for p in (REPO / ".tasks" / d).glob("*.md"):
            n = p.name.lower()
            if ("send-auth" in n or "authorise-send" in n or "send-envelope" in n):
                hits.append(p.name)
    return (not hits, "no send-authorisation task created"
            + (f" — FOUND {hits}" if hits else ""))


def main():
    print("T-608 — unsent AEF attestation draft vs. the clause register\n" + "=" * 74)
    if not DRAFT.exists():
        print(f"  [FAIL] draft missing: {DRAFT}")
        return 1
    raw = DRAFT.read_text(encoding="utf-8")
    reg = load_register()

    rows = evaluate(raw, reg) + [leg_nothing_sent()]
    ok = True
    for good, label in rows:
        if not good:
            ok = False
        print(f"  [{'PASS' if good else 'FAIL'}] {label}")

    # ------------------------------------------------------------------ poison arms
    print("\npoison arms (in-memory only — the draft on disk is never modified)")
    arms = [
        ("drop the refusal-matrix ask",
         lambda s: re.sub(r"The consolidated refusal/threat matrix.*?testable scenario\.",
                          "We would also like the other thing.", s, flags=re.S)),
        # The needle must survive the blockquote wrapping the message body: the sentence
        # breaks as "does not close\n> Arc 0", so a literal replace finds nothing and the
        # arm reports SKIP rather than a false PROVEN.
        ("drop the Arc-0-still-open disclosure",
         lambda s: re.sub(r"does not close[\s>]+Arc 0", "closes Arc 0", s)),
    ]
    arm_ok = True
    for label, mutate in arms:
        poisoned = mutate(raw)
        if poisoned == raw:
            print(f"  [SKIP] {label}: needle absent — arm would probe UNPOISONED text")
            arm_ok = False
            continue
        before = {l for g, l in evaluate(raw, reg) if not g}
        after = {l for g, l in evaluate(poisoned, reg) if not g}
        newly_red = after - before
        if newly_red:
            print(f"  [PROVEN] {label}: reddened -> {sorted(newly_red)[0]}")
        else:
            print(f"  [NOT PROVEN] {label}: nothing reddened")
            arm_ok = False

    print("=" * 74)
    verdict = "PASS" if ok and arm_ok else "FAIL"
    print(f"{verdict} — {sum(1 for g, _ in rows if g)}/{len(rows)} legs; "
          f"arms {'proven failable' if arm_ok else 'NOT proven'}")
    return 0 if verdict == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
