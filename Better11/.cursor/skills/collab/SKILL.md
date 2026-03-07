---
name: collab
description: Use when coordinating between Claude and Cursor; leaving or reading handoff notes; or aligning on workspace context (git branch, status, project layout). Use when the user switches between agents, asks to "leave a note for Claude/Cursor," or needs shared workspace awareness.
---

# Claude–Cursor Collab

Use this skill when **coordinating between Claude and Cursor** or when **shared workspace context** is needed.

## When to use

- User is switching from one agent to the other and wants context handed off.
- User asks to "leave a note for Claude" or "leave instructions for Cursor."
- You are finishing a task and want to summarize next steps for the other agent.
- User or you need a quick workspace summary (branch, status, top-level folders).
- Aligning on project layout or workspace root with the other agent.

## MCP tools (collab server)

When the **collab** MCP server is enabled:

| Tool | Use for |
|------|--------|
| **collab_handoff_read** | Read what the other agent left (tasks, context, next steps). |
| **collab_handoff_write** | Write or append handoff notes. Use `content` (required) and `append` (optional, default true). |
| **collab_workspace_summary** | Get workspace root, git branch, and short status. |
| **collab_list_projects** | List top-level folders in the workspace. |

## Handoff file

Handoff notes are stored at **.cursor/claude-cursor-handoff.md**. You can read or update them via the tools. Prefer the tools so both agents use the same format and the file stays in one place.

## Prompt ideas for the other agent

When writing handoff notes, be specific:

- "Cursor: please run tests and fix any failures in Better11.ViewModels.Tests."
- "Claude: user asked for a summary of WS5; I updated PLAN.md; please suggest next steps."
- "Next: implement X in FileY; follow STYLE-GUIDE.md."
