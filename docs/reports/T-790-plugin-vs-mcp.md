# T-790 — Claude Code plugin vs MCP server: which route for 832?

**Question as the operator put it:** *"research for me the difference between the plugin and
the mcp dev? I think I actually want to go the route of mcp because that makes it more vendor
agnostic and it will also work for other harnesses besides Anthropic or Claude Code."*

Sources are the two trees installed on 2026-09-22, read rather than recalled:
`~/.claude/plugins/cache/claude-plugins-official/{plugin-dev,mcp-server-dev}/c447c3207a42/`.

---

## 1. The headline: they are not alternatives

The premise "plugin **or** MCP" does not survive reading the sources. They sit at **different
layers**, and one contains the other.

| | **MCP server** | **Claude Code plugin** |
|---|---|---|
| What it is | A protocol server | A packaging format for one harness |
| Speaks to | Any MCP client | Claude Code only |
| Ships | tools, resources, prompts | commands, skills, agents, **hooks**, *and MCP servers* |
| Transport | stdio, streamable HTTP | n/a — it is a directory layout |

`plugin-dev` ships an entire skill, `skills/mcp-integration/SKILL.md`, whose subject is
**putting an MCP server inside a plugin** — via `.mcp.json` at plugin root ("Method 1,
Recommended") or an `mcpServers` field in `plugin.json` ("Method 2"). And
`skills/plugin-structure/SKILL.md` lists `.mcp.json` as a first-class member of the plugin
directory layout.

**So the relationship is containment, not competition.** The real question is not which to
pick. It is **where the logic lives** — and on that, the operator's instinct is right.

## 2. What only MCP can do

From `mcp-server-dev/skills/build-mcp-server/SKILL.md` and
`references/server-capabilities.md`:

- **Cross-host reach.** The skill's own words for remote HTTP: *"Works across Claude desktop,
  Claude Code, Claude.ai, and third-party MCP hosts."* This is the operator's point, and it
  is correct.
- **One deployment serves all users**, upgrades under the author's control, *"zero install
  friction — users add a URL, done."*
- **`instructions`** — injects straight into the system prompt. The reference calls it *"the
  highest-leverage one-liner in the spec."*
- **Sampling** — a tool can delegate LLM inference back to the host instead of shipping its
  own model client.
- **Elicitation** — structured mid-call user input with zero UI code, spec-native. (Host
  support is new: Claude Code ≥ 2.1.76, Desktop unconfirmed — the skill insists on a
  capability check plus fallback.)

## 3. What only a plugin can do — and this is the part the hypothesis misses

**Hooks.** `plugin-dev/skills/hook-development/SKILL.md` enumerates nine lifecycle events:

    PreToolUse · PostToolUse · UserPromptSubmit · Stop · SubagentStop
    SessionStart · SessionEnd · PreCompact · Notification

**MCP has no equivalent, and this is structural rather than a gap waiting to be filled.** MCP
is a client–server protocol for *offering capability*: the host asks, the server answers. It
has no way to *intercept the host's own lifecycle*. An MCP server cannot block a `Write`,
cannot refuse a `Bash` call, cannot see a prompt before the model does, and cannot act when a
session starts or a context compacts.

For this project that is not an abstract limitation. **The entire AEF enforcement model is
PreToolUse hooks.** Measured in this session alone, four separate gates fired and changed what
happened:

- P-002 blocked a Bash call with *"No active task. Framework rule: nothing gets done without
  a task."*
- G-020 refused a test task carrying placeholder ACs.
- G-067 refused to let inception work touch a file before its Open Questions were declared.
- T-638 refused a commit whose message carried a `$(...)` substitution on the same line.

**None of that is expressible over MCP.** "Nothing gets done without a task" is not a tool —
it is a veto on other tools. Port 832's capability to MCP and it travels; port its governance
and it does not, because nothing in the standard carries it. That is worth knowing *before*
committing, not after.

## 4. The collision with this project's own constraint

This is the finding that does not appear in either skill, because neither knows about the
operator's ruling.

`build-mcp-server` Phase 2 is emphatic about its default:

> **⭐ Remote streamable-HTTP MCP server (default recommendation)** … *"Choose this unless the
> server must touch the user's local machine."*

The operator's standing constraint, verbatim: *"Key dependency for plugins is that they are
independent and can run stand alone and don't have any dependency on a service commercial or
non-commercial."* Refined later to **load-bearing vs optional** — a dependency disqualifies
when the thing *cannot function without it*.

**A remote HTTP MCP server is a load-bearing service dependency by construction.** If the
host is unreachable, every tool it offers is gone — it does not degrade, it stops. So the
skill's ⭐ default is exactly the shape this project has ruled out.

The MCP shapes that **do** satisfy the constraint are the two the skill ranks lower:

- **Local stdio** — a child process, no third party, no account, no network. Passes cleanly,
  and is the same shape as the plugins already ruled as passing (`pyright-lsp`,
  `rust-analyzer-lsp`, `semgrep`).
- **MCPB** (`skills/build-mcpb/SKILL.md`) — *"Packages a local stdio server with its runtime
  so users can install it without Node/Python."* This is the strongest fit: standalone by
  design, installable without a toolchain, and still speaking a vendor-neutral protocol.

## 5. Recommendation

**Both, with the logic in MCP and the harness integration thin.**

1. **Capability goes in an MCP server, local stdio, packaged as MCPB for distribution.**
   Portable across hosts (D4), standalone (the operator's constraint), no service dependency.
2. **A Claude Code plugin wraps it** — `.mcp.json` pointing at the server, plus the slash
   commands and skills that make it pleasant *here*. The plugin becomes **distribution and
   ergonomics, not the home of the logic**. If the plugin is deleted, the server still works
   in Claude Desktop, claude.ai, or any third-party MCP host.
3. **Do not try to make governance portable.** Hooks stay Claude Code-specific because there
   is nowhere standard to put them. Treat that as a known, named boundary rather than a
   problem to engineer around — the alternative is inventing a private protocol, which is the
   lock-in D4 exists to prevent.

**What this gives up, stated plainly:** anyone running the MCP server outside Claude Code gets
832's *capability* with **none of its enforcement**. No task gate, no budget gate, no
sovereignty boundary. For a workflow *editor* that is likely fine. For anything that writes
into a governed tree it is not, and that line should be drawn deliberately when the first such
tool is designed.

## 6. Citation check (run 2026-09-22)

Every structural claim above was re-read from the installed trees rather than recalled. The
load-bearing one — *MCP has no lifecycle-hook surface* — is an **absence**, so it carries a
positive control on the same string:

```
ok mcpServers in mcp-integration
ok .mcp.json in plugin-structure layout
ok cross-host quote
ok remote-HTTP is the default
ok MCPB quote
ok instructions quote
ok control: PreToolUse IS in plugin hook docs
ok absence: PreToolUse appears nowhere in mcp-server-dev
```

These are **not** in this task's `## Verification` block, deliberately. The plugin cache lives
at `~/.claude/plugins/cache/.../c447c3207a42/` — outside the repository, under a content hash
that changes on reinstall. T-787 was this session's lesson about exactly that: a probe citing
an ephemeral path outside the repo stopped reproducing and took a published "16/16" claim with
it. Verification legs assert repo facts; external citations are dated here instead.

## 7. What this does not decide

Whether 832 ships an MCP server **at all** is downstream of T-788 (does 832 build any part of
the executor). If the answer there is "AEF owns the bridge", 832's MCP surface is small —
read-only access to the corpus and validation. This task settles *the shape*, not *the scope*.

**The decision is the operator's.** This is the advisory.
