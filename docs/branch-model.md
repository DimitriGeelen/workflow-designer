# Branch model — release train

**Adopted 2026-09-22 (T-805), on the operator's instruction, after consulting AEF.**
AEF's answer is `agent-chat-arc @1656`; our question is `@sidecar:999-Agentic-Engineering-Framework @13`.

## The two branches

| branch | role | who writes it |
|---|---|---|
| `master` | **consumer install surface.** What `origin/HEAD` points at, what peers pin, what a release tags. | **nothing, directly.** Only advanced by fast-forward from `bleeding-edge`, at a release. |
| `bleeding-edge` | **development.** All work lands here. | everyone |

`bleeding-edge` is `master`'s **only** writer. That is the whole invariant, and everything below follows from it.

## Why fast-forward, and not merge-squash

The operator's original instruction was merge-and-squash. AEF was asked directly whether that
was safe and answered that it is not — quoted verbatim from `@1656`:

> "fast-forward is deliberate, not incidental, and squash breaks two things on our side."

Because `bleeding-edge` is master's only writer, `master` can never lead it, so a clean
fast-forward **exists by construction**. A squash creates a commit on `master` that is not on
`bleeding-edge`; `master` is then ahead-and-behind — **diverged** — and two things break
permanently:

1. `fw release tag-and-release` **refuses** when master has diverged (AEF T-3190): *"a release
   that cannot advance the install surface is not a release."* Every subsequent release blocked.
2. `fw doctor`'s diverged-fork and wrong-branch rails (AEF T-3187) fire forever.

What does **not** depend on commit reachability from `master` — we asked specifically, because
we expected the opposite:

- `fw upgrade` / `fw vendor` — they take master's *content*, not its history
- `fw fabric blast-radius` — works on the branch it runs on
- the git mining that fills a task's `## Updates` at completion — reads `T-XXX` in messages on
  the dev branch

So the cost of squashing is precisely: AEF's release command and two doctor rails, or
maintaining our own equivalents. AEF's position on that trade: *"we would not."*

## "Stable" is a tag, not a branch

The operator's word for the vetted surface is *stable*. AEF's ruling:

> "If your operator wants the word 'stable', make it a second name for master (a branch alias or
> a tag series), **never a third branch**."

So: **no `stable` branch exists and none should be created.** `master` IS stable. The release
tag series (`designer-vX.Y.Z`) is what names a specific stable point.

## Rules

1. Work on `bleeding-edge`. Commit there, push there.
2. Never commit directly to `master`.
3. `master` advances **only** by fast-forward from `bleeding-edge`, **only** at a release, and
   **only** on the operator's instruction — integration and merging are not delegated to the agent.
4. Never create a `stable` branch.
5. `origin/HEAD` stays pointed at `master`. Peers read it as the vetted surface.

## The seam

AEF pins against `examples/aef-processes/rendered/`. Under this model they pin **master**, which
advances at a release rather than continuously. Their words:

> "Continuous pinning against a branch at 89/day is what put your rendered/ files one `--help`
> invocation away from a rewrite; the topology, not attention, should protect the seam."

Two outstanding asks from AEF, not yet done:

- keep `examples/aef-processes/rendered/` out of every tool's default sweep
- tag the seam artefacts in release notes so AEF pins a tag, not a moving head

## Note on the vendored framework

Our vendored `.agentic-framework/` is v1.6.354 and **predates the release train entirely**. Its
libs still name `master` as the *integration target*, which is the opposite role:

- `lib/branch-hygiene.sh:9` — "Judged against TARGET = origin/master when present"
- `lib/worktree.sh:18` — "Resolve the 'master' ref this repo integrates onto"
- `lib/worktree.sh:196` — `"on_master": branch in ("master", "main")`
- `agents/handover/handover.sh:303` — "land the strand with `fw integrate run master --push`"

We reported this; AEF filed it as **OBS-467** and confirmed the nudge text is a real defect on
their side. Until it ships, **ignore any framework prompt that tells you to integrate onto
`master`** — under this model a strand cut from `bleeding-edge` lands on `bleeding-edge`.
