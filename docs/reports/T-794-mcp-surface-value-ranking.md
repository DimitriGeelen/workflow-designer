# T-794 — Where the value is in an MCP surface for the workflow designer

Ranked against the operator's confirmed yardstick: *"the workflow designer and its integration
with AEF and our ability to facilitate **the agent and human collaboration** to iterate from
the workflow to actual working applications."*

`validate_workflow` shipped in T-792. This ranks what comes next, and why.

---

## 1. The finding that decides the ranking

**The value is not in exposing tools. It is in closing the loop that has no agent path today.**

Measured, not reasoned. I wrote a workflow YAML **from scratch, with no template**, the way an
LLM naturally would, and ran it through the two-tool chain:

| step | result |
|---|---|
| author `.workflow.yaml` by hand | 4 nodes, 2 lanes, 3 edges |
| `yaml-to-bpmn.py` | **converted cleanly — 2062 bytes, no complaint** |
| `validate-workflow.py` | **exit 1 — `W-XML-UNREACHABLE` on all three non-start nodes** |
| diagnosis | I had guessed the key `flows:`. The schema says `edges:` |
| one-word fix, re-run | **exit 0, zero findings** |

Read that middle row again. **The converter accepted a diagram whose every node was
disconnected and said nothing.** The error was the most predictable mistake an LLM can make —
guessing a plausible key name — and only the validator caught it.

**So the pair is the unit, not two separate tools.** Convert without validate silently emits
broken diagrams. Validate without convert can only judge what somebody else authored. Together
they are an agent's authoring path, and that path did not exist before this session.

## 2. The ranking

### ⭐ 1. `yaml_to_bpmn` — highest value, build next

It is the **authoring direction**, and authoring is the half the yardstick names that we do not
have. An LLM writes structured YAML far better than it drives a browser canvas. With
`validate_workflow` already shipped, the loop becomes:

> agent drafts YAML → converts → validates → **human opens it in the designer and refines**

That is the agent-and-human collaboration in the yardstick, in one sentence, and every step of
it is inside T-791's read-only/pure-function fence.

Cost: near zero. `yaml-to-bpmn.py` is stdlib + pyyaml, already written, already correct.
The MCP wrapper is the same shape as the one built in T-792.

### 2. `describe_workflow` — high value, does not exist yet

Today an agent handed a `.bpmn` must parse XML to learn anything. A tool returning the
structure — lanes with their authorities, nodes with owners and tiers, edges — lets an agent
**reason about** a workflow rather than transcribe it: review it, diff two versions, explain
one to a human, spot a task with no derivable owner.

This is the one genuinely new thing on the list. It is a pure function over bytes.
Highest value per line of new code, but it is *new* code, unlike #1.

### 3. `list_corpus` / `get_workflow` — real but modest

Reads over our saved workflows. The honest caveat: **our corpus is 5/6 fixtures with nothing
saved since 2026-07-29** (T-789). These are useful to somebody who wants *our* examples, and
the evidence that anybody does is thin. Cheap to add, so worth folding in once #1 and #2 land
— not worth prioritising over them.

### ✗ Not eligible: auto-layout

An agent authoring YAML must invent x/y coordinates — I did, and they were arbitrary. Cleaning
that up would genuinely help a human opening agent-authored output, so `bake-clean-layout.py`
looks like an obvious fourth tool.

**It is disqualified.** It is a corpus-wide *mutator*, not a pure function, so the T-791 scope
fence excludes it. That fence is what keeps the absent governance harmless, and this is exactly
the case it exists to refuse.

Worse, and found the hard way this session: **it does not parse `--help` and runs its real
sweep instead**, rewriting 24 files under the pinned `examples/aef-processes/rendered/` seam.
Reverted, byte-identical to HEAD, nothing committed — but filed as **OBS-373**, because
`--help` is the first thing any agent reaches for.

If auto-layout is wanted for agents later, the answer is a *pure* layout function that returns
repositioned bytes, not a wrapper around a tool that writes to the tree.

### ✗ Not eligible: anything that writes

Saving to the corpus, creating tasks, touching `.tasks/`. The human already has the browser for
the first; the other two cross the fence.

## 4. What is NOT worth building, and why that matters

**Do not re-expose the designer UI over MCP.** The browser is the human's surface and it works
(T-789: console clean, palette encodes the authority model). MCP is the agent's surface.
Duplicating one in the other buys nothing and doubles the maintenance.

**Do not build toward execution.** No MCP tool closes the workflow→application gap; that is
upstream, and T-788 has the ownership question with AEF at `agent-chat-arc` @1630.

## 5. Recommendation

**Build `yaml_to_bpmn` next, and treat it as completing `validate_workflow` rather than as a
second feature.** Then `describe_workflow`. Then the corpus reads, if anyone asks.

The measurement in §1 is the argument: the two tools together are an agent's authoring path,
and apart they are a silent failure generator and a judge with nothing to judge.
