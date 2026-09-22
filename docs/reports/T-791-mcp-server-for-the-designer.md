# T-791 — Should 832 ship a local MCP server for the workflow designer?

**Question:** *"Should we build MCP servers local for the workflow designer which can be
installed and called by AEF users?"*

**Recommendation: YES — narrow, read-only, in-repo, and NOT packaged for distribution yet.**

Shape follows T-790: local stdio (satisfies the standalone constraint; the ⭐ remote-HTTP
default does not).

---

## 1. The callable surface already exists and is dependency-light

Measured, not assumed. The public tools in `tools/` that are candidates:

| tool | imports | verdict |
|---|---|---|
| `validate-workflow.py` | `argparse, json, sys, xml.etree` — **stdlib only** | ⭐ the crown jewel |
| `yaml-to-bpmn.py` | stdlib + `yaml` | strong second |
| `bpmn-cli.py` | stdlib | one narrow verb (`claim`) |
| `bake-clean-layout.py`, `check-lane-bands.py` | — | layout, lower value |

`validate-workflow.py` has **zero third-party dependencies**. It passes the operator's
standalone constraint by construction rather than by argument — there is no service to be
unreachable, no account, no network.

This matters more than it looks: the hard part of an MCP server is usually the dependency and
auth story. Here there isn't one.

## 2. The demand is real, repeated, and HISTORICAL — say so plainly

**32 completed tasks mention `dogfood`.** AEF ran a formal series of pair rounds where they
sent us their bytes to validate against our validator — T-297 is *"dogfood #2"*, T-299 is
*"dogfood #3 of 4"*, opened on rail 314 against their T-2665/T-2666.

So agents on the other side of the seam **have** wanted to call this thing, 32 times.

**And then it stopped.** The dates are unambiguous:

- T-297, T-299: **2026-07-29**
- every saved workflow in the corpus: **2026-07-29**
- most recent `dogfood` mention anywhere: **2026-08-20**
- today: **2026-09-22**

Roughly two months of silence on exactly the collaboration an MCP server would serve. A
recommendation that hid that number would be worthless.

### Two readings, and the honest resolution

**Reading A — the loop died of friction.** Every round needed a human to coordinate, a live
URL, and bytes hand-copied into a scratchpad. An MCP call collapses that to one call. Silence
means cost, not disinterest.

**Reading B — the exercise simply finished.** *"dogfood #3 of 4"* is explicit: a planned,
finite series with a defined end. Building infrastructure for a completed exercise is
speculative.

**Reading B is better supported.** The series named its own length. I am not going to argue
the silence means what I would like it to mean.

**But the transport was independently proven lossy today.** T-299's archived Verification line
cites
`/tmp/.../scratchpad/draft-task-creation-v2.bpmn` — bytes fetched from AEF's running service
into a scratchpad that was later reaped. That took a published "16/16" claim down with it
(T-787, this session). So Reading B explains the silence, and the transport was *also* bad.
Both are true.

## 3. The argument that does not depend on AEF resuming anything

The operator's confirmed yardstick, verbatim:

> "the workflow designer and its integration with AEF and our ability to facilitate **the
> agent and human collaboration** to iterate from the workflow to actual working applications"

**Today the designer is human-only.** It is 997 KB of browser application (T-789: it works,
console clean, palette encodes the authority model) with **no programmatic entry point at
all**. An agent cannot validate a workflow, cannot list the corpus, cannot convert YAML to
BPMN, without cloning this repository and shelling out.

The "agent" half of "agent and human collaboration" **has no surface**. That is the gap, and
it is true whether or not AEF ever opens dogfood #5.

**The demand test is also unfair here:** you cannot measure demand for an interface that has
never existed. What can be measured is that when agents *could* reach this capability — over
a bad manual transport — they did it 32 times.

## 4. Scope fence: read-only and pure functions ONLY

T-790 established that governance does not travel over MCP: no `PreToolUse`, no task gate, no
sovereignty boundary. An MCP server hands out capability with **none** of the enforcement.

That sounds like a blocker. It is not — it is a **scope fence**, and a clean one:

> **Every tool is a pure function or a read. Nothing writes into a governed tree.**

A pure function needs no governance. `validate(bytes) → verdict` cannot violate sovereignty;
there is nothing for P-002 to protect. The moment a tool writes a task, saves to the corpus,
or touches `.tasks/`, the enforcement gap becomes real — so those tools are **out of scope**,
by rule rather than by omission.

**Recommended surface (4 tools):**

| tool | shape | governance risk |
|---|---|---|
| `validate_workflow` | pure fn | none |
| `yaml_to_bpmn` | pure fn | none |
| `list_corpus` | read | none |
| `get_workflow` | read | none |

## 5. What NOT to build, and why

- **Not MCPB, not yet.** MCPB packages a runtime for people who do not have the repo. **Nobody
  has asked to install it.** Packaging is cheap to add later; G-007 makes shipped bytes a
  sovereignty promise. Build the server, package it when someone asks for it.
- **Not remote HTTP.** The ⭐ default in `build-mcp-server`, and a load-bearing service
  dependency — exactly what the operator's constraint excludes (T-790 §4).
- **No write tools.** See §4.
- **Not a translator.** T-788 is open and the frozen standard says *"No translator is built
  here."* Nothing in the recommended surface is one: validate, convert and read are all
  consumer-side, and Phase 5 F-10 measured that slice already intact.

## 6. Risks, named

1. **T-788 could move the boundary.** If AEF's Child-2 lands, some surface could become
   theirs. Low collision risk for these four — they expose what 832 already owns.
2. **It may get no users.** Reading B says the dogfood series is over. Mitigated by keeping it
   to four thin wrappers over tools that already exist and are already maintained — if nobody
   calls it, little was spent.
3. **A future contributor adds a write tool** and silently crosses the governance gap. The
   scope fence in §4 exists to be cited when that is proposed.

## 7. Recommendation

**GO, narrowly:** one local stdio MCP server in this repo, four read-only/pure tools, no
packaging, no writes.

**The decision is the operator's.** This is the advisory, and §2 is the part that could
reasonably change their mind — the demand is historical, and I am not going to dress that up.
