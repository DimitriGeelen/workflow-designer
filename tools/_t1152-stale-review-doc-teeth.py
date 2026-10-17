#!/usr/bin/env python3
"""Teeth for tools/_t1152-stale-review-doc.py (T-1152, OBS-291), on a scratch git repo with backdated commits.

GATE: a [REVIEW] criterion naming a docs/ document whose task CONTENT moved on after the document fires STALE.
CONTROLS (must stay silent): the document edited after the task; a frontmatter-only bump; a checkbox tick; an edit
confined to a bookkeeping section; a corpus sweep; a checked criterion; a non-REVIEW criterion; an example inside a
template comment; an untracked path; a non-docs path (unless --all-paths). And the states: NOT EVALUATED with
nothing to examine (exit 3), NO-STALE (exit 0), STALE-REVIEW-DOCS (exit 1).
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SUBJECT = os.environ.get("SUBJECT", os.path.join(ROOT, "tools", "_t1152-stale-review-doc.py"))
PASS = FAIL = 0


def ok(name):
    global PASS
    PASS += 1
    print(f"  PASS  {name}")


def bad(name, why):
    global FAIL
    FAIL += 1
    print(f"  FAIL  {name}\n       {why}")


def git(repo, *args, day=None):
    env = dict(os.environ, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t", GIT_COMMITTER_NAME="t",
               GIT_COMMITTER_EMAIL="t@t")
    if day is not None:
        stamp = f"2026-01-{day:02d}T12:00:00Z"
        env.update(GIT_AUTHOR_DATE=stamp, GIT_COMMITTER_DATE=stamp)
    return subprocess.run(["git", "-C", repo, *args], env=env, capture_output=True, text=True, check=True).stdout


def write(repo, rel, text):
    p = os.path.join(repo, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write(text)


def commit(repo, day, msg, *paths):
    git(repo, "add", *paths)
    git(repo, "commit", "-q", "-m", msg, day=day)


def task(tid, review_lines, extra_body="", fm_extra=""):
    return (f"---\nid: {tid}\nname: fixture\nstatus: started-work\n{fm_extra}---\n\n# {tid}\n\n## Context\n\n"
            f"Proposal under review.{extra_body}\n\n## Acceptance Criteria\n\n### Agent\n- [x] built\n\n### Human\n"
            f"{review_lines}\n\n## Verification\n\ntrue\n\n## Updates\n\n- created\n")


def crit(path, box=" ", tag="REVIEW"):
    return (f"- [{box}] [{tag}] Approve the proposal\n  **Steps:**\n  1. Read {path}\n  **Expected:** agreed\n"
            f"  **If not:** say why\n")


def run(repo, *extra):
    r = subprocess.run([sys.executable, SUBJECT, "--root", repo, *extra], capture_output=True, text=True)
    return r.returncode, r.stdout


def main():
    with tempfile.TemporaryDirectory(prefix="t1152.") as repo:
        git(repo, "init", "-q")
        A = ".tasks/active"
        # NOT EVALUATED first: a repo with nothing to examine.
        write(repo, f"{A}/T-0001-x.md", task("T-0001", "- [ ] plain human check"))
        commit(repo, 1, "seed", A)
        rc, out = run(repo)
        ok("state_not_evaluated_when_nothing_to_examine") if rc == 3 and out.startswith("NOT EVALUATED") \
            else bad("state_not_evaluated_when_nothing_to_examine", f"rc={rc} out={out!r}")

        # Documents, all written on day 2.
        for n in range(1, 11):
            write(repo, f"docs/reports/d{n}.md", f"# doc {n}\n")
        write(repo, "tools/evidence.py", "x = 1\n")
        commit(repo, 2, "docs", "docs", "tools")

        # Tasks created day 3 (inside the 7-day threshold of the documents).
        tasks = {
            "T-0101": task("T-0101", crit("docs/reports/d1.md")),                          # gate: content moves day 20
            "T-0102": task("T-0102", crit("docs/reports/d2.md")),                          # doc edited after the task
            "T-0103": task("T-0103", crit("docs/reports/d3.md")),                          # frontmatter-only bump
            "T-0104": task("T-0104", crit("docs/reports/d4.md") + "- [ ] another\n"),      # tick only
            "T-0105": task("T-0105", crit("docs/reports/d5.md")),                          # Updates-only edit
            "T-0106": task("T-0106", crit("docs/reports/d6.md", box="x")),                 # checked criterion
            "T-0107": task("T-0107", crit("docs/reports/d7.md").replace("[REVIEW] ", "")),  # not a REVIEW criterion
            "T-0108": task("T-0108", "<!--\n" + crit("docs/reports/d8.md") + "-->\n"),       # template comment
            "T-0109": task("T-0109", crit("docs/reports/untracked.md")),                   # untracked path
            "T-0110": task("T-0110", crit("tools/evidence.py")),                          # evidence, not a document
            "T-0111": task("T-0111", crit("docs/reports/d9.md", tag="REVIEWER")),          # REVIEWER counts too
        }
        for tid, text in tasks.items():
            write(repo, f"{A}/{tid}-x.md", text)
        commit(repo, 3, "tasks", A)
        write(repo, "docs/reports/untracked.md", "# never added\n")

        def edit(tid, old, new, day, msg):
            p = os.path.join(repo, A, f"{tid}-x.md")
            t = open(p).read()
            assert old in t, (tid, old)
            open(p, "w").write(t.replace(old, new, 1))
            commit(repo, day, msg, os.path.join(A, f"{tid}-x.md"))

        content = ("Proposal under review.", "Proposal under review.\nNew finding recorded in the task only.")
        edit("T-0101", *content, 20, "content")
        edit("T-0111", *content, 20, "content")
        edit("T-0110", *content, 20, "content")
        edit("T-0102", *content, 20, "content")
        write(repo, "docs/reports/d2.md", "# doc 2, revised to match\n")
        commit(repo, 21, "doc follows", "docs/reports/d2.md")
        edit("T-0103", "status: started-work\n", "status: started-work\nbvp_scores_proposed: [{D1: 3}]\n", 20, "sweep fm")
        edit("T-0104", "- [ ] another", "- [x] another", 20, "tick")
        edit("T-0105", "- created\n", "- created\n- reviewer verdict appended\n", 20, "updates")

        rc, out = run(repo)
        stale = {l.split()[1] for l in out.splitlines() if l.startswith("STALE ")}
        ok("gate_task_content_newer_than_doc_fires") if "T-0101" in stale \
            else bad("gate_task_content_newer_than_doc_fires", out)
        ok("gate_reviewer_criterion_counts_too") if "T-0111" in stale \
            else bad("gate_reviewer_criterion_counts_too", out)
        for tid, name in (("T-0102", "doc_edited_after_task_silent"), ("T-0103", "frontmatter_only_bump_silent"),
                          ("T-0104", "tick_only_silent"), ("T-0105", "bookkeeping_section_edit_silent"),
                          ("T-0106", "checked_criterion_silent"), ("T-0107", "non_review_criterion_silent"),
                          ("T-0108", "template_comment_silent"), ("T-0109", "untracked_path_silent"),
                          ("T-0110", "evidence_path_silent_by_default")):
            ok(f"control_{name}") if tid not in stale else bad(f"control_{name}", out)
        ok("state_stale_exits_1") if rc == 1 and "STALE-REVIEW-DOCS 2 " in out \
            else bad("state_stale_exits_1", f"rc={rc} out={out!r}")
        _, out2 = run(repo, "--all-paths")
        ok("all_paths_includes_evidence") if any(l.startswith("STALE T-0110 ") for l in out2.splitlines()) \
            else bad("all_paths_includes_evidence", out2)

        # A corpus sweep must not date a task: edit both gate tasks' bodies in ONE commit with --sweep-files 2.
        # The sweep edits CONTENT (## Context), 9 days after T-0102's revised doc: only the limit stops it dating.
        for t in ("T-0102", "T-0105"):
            p = os.path.join(repo, A, f"{t}-x.md")
            text = open(p).read()          # read BEFORE opening for write: "w" truncates first
            open(p, "w").write(text.replace("Proposal under review.",
                                            "Proposal under review (placeholder wording fixed corpus-wide).", 1))
        git(repo, "add", A)
        git(repo, "commit", "-q", "-m", "sweep", day=30)
        _, out4 = run(repo, "--sweep-files", "2")
        stale4 = {l.split()[1] for l in out4.splitlines() if l.startswith("STALE ")}
        ok("control_corpus_sweep_does_not_date") if not ({"T-0102", "T-0105"} & stale4) \
            else bad("control_corpus_sweep_does_not_date", out4)
        _, out5 = run(repo)  # default limit 20: the same two-file commit is NOT a sweep, so it dates both
        stale5 = {l.split()[1] for l in out5.splitlines() if l.startswith("STALE ")}
        ok("sweep_limit_is_the_discriminator") if {"T-0102", "T-0105"} <= stale5 \
            else bad("sweep_limit_is_the_discriminator", out5)

        # NO-STALE: bring every flagged document up to date.
        for n in range(1, 11):
            write(repo, f"docs/reports/d{n}.md", f"# doc {n}, current\n")
        commit(repo, 29, "docs current", "docs")
        rc6, out6 = run(repo)
        ok("state_no_stale_exits_0") if rc6 == 0 and out6.startswith("NO-STALE") \
            else bad("state_no_stale_exits_0", f"rc={rc6} out={out6!r}")

    print(f"\nPASS {PASS} / FAIL {FAIL}")
    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    print("=== T-1152 teeth: stale [REVIEW] documents ===")
    sys.exit(main())
