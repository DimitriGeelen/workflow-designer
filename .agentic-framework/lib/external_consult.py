#!/usr/bin/env python3
"""fw external — consult differently-trained models for the strongest objection.

WHY THIS EXISTS, and why it is not `fw peer`.

`fw peer` and `fw sidecar` already consult peers: they long-poll the TermLink
mesh and spawn responders. Every responder on that mesh is a Claude, and the
mesh shares one cohort identity. So a peer consult is fast, free, and
CORRELATED — it cannot catch a failure mode that the whole lineage shares.

This verb is the uncorrelated counterpart. It asks models trained by other
organisations, on other data, with other biases. That is the entire value
proposition, and it is why the default panel deliberately contains no Claude:
a second Claude would agree with the first for reasons that are not evidence.

TWO DESIGN RULES THAT ARE LOAD-BEARING, not decoration:

1. THE PROMPT ASKS FOR THE STRONGEST OBJECTION. A consult that asks "is this
   reasonable?" gets "yes" and launders the decision it was supposed to test —
   converting uncertainty into confidence with an audit trail attached. So the
   instruction is adversarial by construction: argue against the proposal, name
   what would have to be true for it to be wrong, say what the author has
   probably not considered.

2. A CONSULT IS A NAMED, RESCANNABLE ARTIFACT. Models change. Asking the same
   question in six months and diffing the answers is evidence available no other
   way, and it is only available if the original question, the exact prompt, the
   model ids and the date were all recorded. A chat transcript is not that.

AND ONE HONESTY CLAUSE. The artifact carries `changed_decision: null` until a
human fills it in. A consult that has never once changed a decision is
decoration — the same reasoning the arc-goal practice applies to purpose
questions, one level out. The field exists so that fact is visible rather than
comfortable.

CREDENTIAL RESOLUTION is an ordered search that NAMES WHAT IT CHECKED when it
fails, and refuses rather than degrading. An empty panel and a missing key must
never render identically: "nobody answered" is a finding, "we never asked" is a
bug, and a silent fall-through would make them the same output.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

API_URL = "https://openrouter.ai/api/v1/chat/completions"

# No Claude here, deliberately — see the module docstring. Five lineages.
DEFAULT_PANEL = [
    "openai/gpt-4o",
    "google/gemini-2.5-pro",
    # 404 on the first real run as "x-ai/grok-2-1212" — provider model ids move,
    # which is itself an argument for `rescan`: a panel is a claim about what
    # exists today, not a constant.
    "x-ai/grok-3",
    "deepseek/deepseek-chat",
    "qwen/qwen-2.5-72b-instruct",
]

OBJECTION_INSTRUCTION = """\
You are being consulted as an outside reviewer. The author has already decided they
like this proposal, which is exactly why your agreement is worth very little to them.

Do NOT validate it. Give your STRONGEST OBJECTION.

Specifically:
1. What is the best argument AGAINST this proposal?
2. What would have to be true for it to be the wrong choice?
3. What has the author probably not considered?
4. If you think the proposal is right, say so in one line — then still give the
   strongest objection you can construct, and say what evidence would settle it.

Be concrete and technical. Brevity over hedging. If you need information you have
not been given, name exactly what is missing rather than assuming it.
"""


def _utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def resolve_key() -> tuple[str | None, list[str]]:
    """(key, locations_checked). Never logs or returns the value elsewhere."""
    checked = []

    checked.append("environment $OPENROUTER_API_KEY")
    env = os.environ.get("OPENROUTER_API_KEY")
    if env:
        return env.strip(), checked

    env_file = Path.home() / ".litellm-openrouter.env"
    checked.append(str(env_file))
    if env_file.is_file():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\s*(?:export\s+)?OPENROUTER_API_KEY\s*=\s*(.+)", line)
            if m:
                return m.group(1).strip().strip("'\""), checked

    return None, checked


def consult_dir(root: Path) -> Path:
    return root / ".context" / "consults"


def ask_one(key: str, model: str, prompt: str, timeout: int) -> dict:
    """One model, one answer. A transport failure is RECORDED, never swallowed:
    an error stored beside the answers is a fact about the run; an error dropped
    would leave a four-model panel looking like a deliberate four-model panel."""
    body = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
    }).encode("utf-8")
    req = urllib.request.Request(
        API_URL, data=body, method="POST",
        headers={
            "Authorization": "Bearer %s" % key,
            "Content-Type": "application/json",
            # Deliberately generic. The first run sent "AEF external-consult",
            # which leaked a name the brief had been written to keep out — an
            # inconsistency between what the author redacted and what the
            # transport announced. A header is part of the disclosure surface.
            "X-Title": "external-consult",
        },
    )
    started = _utc()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
        answer = payload["choices"][0]["message"]["content"] or ""
        # AN EMPTY BODY IS NOT AN ANSWER. Measured on the first real run
        # (832 T-887): one model returned HTTP 200 with content "" and the tool
        # reported "4/5 answered" — a silent-consent panel with a phantom member.
        # A reasoning model that spends its whole budget in a hidden channel and
        # emits nothing does this, and so does a provider truncation. Counting it
        # as an answer is the same false-green class this verb exists to break.
        if not answer.strip():
            return {"model": model, "asked_at": started, "ok": False,
                    "error": "EMPTY_ANSWER",
                    "detail": "HTTP 200 with empty content — the model was "
                              "reached and said nothing. Not an answer, and not "
                              "counted as one.",
                    "reported_model": payload.get("model"),
                    "usage": payload.get("usage")}
        return {"model": model, "asked_at": started, "ok": True,
                "answer": answer,
                "reported_model": payload.get("model"),
                "usage": payload.get("usage")}
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")[:600]
        return {"model": model, "asked_at": started, "ok": False,
                "error": "HTTP %s" % exc.code, "detail": detail}
    except Exception as exc:                                  # noqa: BLE001
        return {"model": model, "asked_at": started, "ok": False,
                "error": type(exc).__name__, "detail": str(exc)[:600]}


def build_prompt(brief: str) -> str:
    return "%s\n\n--- THE PROPOSAL UNDER REVIEW ---\n\n%s\n" % (
        OBJECTION_INSTRUCTION, brief.strip())


def cmd_scan(args, root: Path) -> int:
    brief_path = Path(args.brief)
    if not brief_path.is_file():
        print("REFUSED: brief not found: %s" % brief_path, file=sys.stderr)
        return 2
    brief = brief_path.read_text(encoding="utf-8")
    prompt = build_prompt(brief)
    panel = args.model or DEFAULT_PANEL

    if args.dry_run:
        print("DRY RUN — nothing sent.\n")
        print("panel (%d):" % len(panel))
        for m in panel:
            print("  %s" % m)
        print("\nprompt (%d chars):\n" % len(prompt))
        print(prompt)
        return 0

    key, checked = resolve_key()
    if not key:
        # Refuse loudly and name the search. A silent empty panel would make
        # "nobody answered" and "we never asked" the same output.
        print("REFUSED: no OpenRouter key found. Checked, in order:", file=sys.stderr)
        for c in checked:
            print("  - %s" % c, file=sys.stderr)
        print("\nNothing was sent. Set OPENROUTER_API_KEY or create the file above.",
              file=sys.stderr)
        return 2

    out_dir = consult_dir(root)
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / ("%s.json" % args.name)

    print("Consulting %d model(s) — asking for the strongest objection, not approval.\n"
          % len(panel))
    responses = []
    for m in panel:
        print("  → %s … " % m, end="", flush=True)
        r = ask_one(key, m, prompt, args.timeout)
        responses.append(r)
        print("ok (%d chars)" % len(r.get("answer") or "") if r["ok"]
              else "FAILED (%s)" % r.get("error"))

    record = {
        "name": args.name,
        "created": _utc(),
        "brief_path": str(brief_path),
        "brief_sha256": __import__("hashlib").sha256(
            brief.encode("utf-8")).hexdigest(),
        "prompt_sent": prompt,
        "panel": panel,
        "responses": responses,
        # Filled in by a human, deliberately not by the tool. A consult that
        # never changed a decision is decoration, and this field is how that
        # becomes visible instead of comfortable.
        "changed_decision": None,
    }
    if out.exists():
        prior = json.loads(out.read_text(encoding="utf-8"))
        record["supersedes"] = prior.get("created")
        record["prior_panel"] = prior.get("panel")
    out.write_text(json.dumps(record, indent=2), encoding="utf-8")

    ok = sum(1 for r in responses if r["ok"])
    print("\n%d/%d answered. Written: %s" % (ok, len(panel), out))
    if ok == 0:
        print("NO MODEL ANSWERED — this is a failed run, not an empty verdict.",
              file=sys.stderr)
        return 1
    print("\nNOTE: `changed_decision` is null. Fill it in when you know — a consult "
          "that never changes a decision is decoration.")
    return 0


def cmd_show(args, root: Path) -> int:
    out = consult_dir(root) / ("%s.json" % args.name)
    if not out.is_file():
        print("no such consult: %s" % out, file=sys.stderr)
        return 2
    rec = json.loads(out.read_text(encoding="utf-8"))
    print("consult: %s   created: %s" % (rec["name"], rec["created"]))
    print("changed_decision: %s" % rec.get("changed_decision"))
    for r in rec["responses"]:
        print("\n" + "=" * 72)
        print("%s  %s" % (r["model"], "OK" if r["ok"] else "FAILED: %s" % r.get("error")))
        print("=" * 72)
        print((r.get("answer") or r.get("detail") or "").strip())
    return 0


def cmd_list(_args, root: Path) -> int:
    d = consult_dir(root)
    if not d.is_dir():
        print("no consults yet (%s does not exist)" % d)
        return 0
    rows = sorted(d.glob("*.json"))
    if not rows:
        print("no consults yet")
        return 0
    for p in rows:
        rec = json.loads(p.read_text(encoding="utf-8"))
        ok = sum(1 for r in rec["responses"] if r["ok"])
        print("%-28s %s  %d/%d answered  changed_decision=%s"
              % (rec["name"], rec["created"], ok, len(rec["panel"]),
                 rec.get("changed_decision")))
    return 0


def main(argv=None) -> int:
    root = Path(os.environ.get("PROJECT_ROOT") or Path.cwd())
    p = argparse.ArgumentParser(
        prog="fw external",
        description="Consult differently-trained models for the strongest objection. "
                    "The uncorrelated counterpart to `fw peer`.")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("scan", help="send a brief to the panel and record the answers")
    s.add_argument("name", help="consult name (the artifact is keyed by this)")
    s.add_argument("--brief", required=True, help="path to the proposal under review")
    s.add_argument("--model", action="append",
                   help="override the panel (repeatable)")
    s.add_argument("--timeout", type=int, default=180)
    s.add_argument("--dry-run", action="store_true",
                   help="print panel + prompt, send nothing")
    s.set_defaults(fn=cmd_scan)

    r = sub.add_parser("rescan", help="re-ask the same brief against the current panel")
    r.add_argument("name")
    r.add_argument("--brief", required=True)
    r.add_argument("--model", action="append")
    r.add_argument("--timeout", type=int, default=180)
    r.add_argument("--dry-run", action="store_true")
    r.set_defaults(fn=cmd_scan)   # same path; prior record becomes `supersedes`

    sh = sub.add_parser("show", help="print a recorded consult")
    sh.add_argument("name")
    sh.set_defaults(fn=cmd_show)

    ls = sub.add_parser("list", help="list recorded consults")
    ls.set_defaults(fn=cmd_list)

    args = p.parse_args(argv)
    return args.fn(args, root)


if __name__ == "__main__":
    sys.exit(main())
