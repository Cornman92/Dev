// MCP server for Claude–Cursor collaboration: handoff notes and workspace awareness

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { readFile, writeFile, mkdir } from "fs/promises";
import { existsSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";
import { spawn } from "child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
// When Cursor runs this server, cwd is usually the workspace root (e.g. Better11 or Dev)
const WORKSPACE_ROOT = process.env.WORKSPACE_ROOT || process.cwd();
const HANDOFF_PATH = join(WORKSPACE_ROOT, ".cursor", "claude-cursor-handoff.md");
const HANDOFF_URI = "workspace://handoff";

function runCommand(
  command: string,
  args: string[],
  cwd: string = WORKSPACE_ROOT
): Promise<{ stdout: string; stderr: string; code: number }> {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, {
      cwd,
      shell: true,
      windowsHide: true,
    });
    let stdout = "";
    let stderr = "";
    proc.stdout?.on("data", (d) => (stdout += d.toString()));
    proc.stderr?.on("data", (d) => (stderr += d.toString()));
    proc.on("error", (err) => reject(err));
    proc.on("close", (code) =>
      resolve({ stdout, stderr, code: code ?? -1 })
    );
  });
}

async function readHandoff(): Promise<string> {
  try {
    if (existsSync(HANDOFF_PATH)) {
      return await readFile(HANDOFF_PATH, "utf-8");
    }
  } catch {
    // ignore
  }
  return "";
}

async function writeHandoff(content: string, append: boolean): Promise<void> {
  await mkdir(dirname(HANDOFF_PATH), { recursive: true });
  if (append) {
    const existing = await readHandoff();
    content = existing ? `${existing}\n\n---\n\n${content}` : content;
  }
  await writeFile(HANDOFF_PATH, content, "utf-8");
}

const server = new Server(
  {
    name: "collab-mcp-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "collab_handoff_read",
      description:
        "Read the shared handoff notes between Claude and Cursor. Use to see what the other agent left for you (tasks, context, next steps).",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "collab_handoff_write",
      description:
        "Write or append to the shared handoff notes for the other agent. Use when finishing work so Claude or Cursor can continue with context.",
      inputSchema: {
        type: "object",
        properties: {
          content: {
            type: "string",
            description: "Markdown or plain text to leave for the other agent.",
          },
          append: {
            type: "boolean",
            description: "If true, append to existing notes; if false, replace.",
            default: true,
          },
        },
        required: ["content"],
      },
    },
    {
      name: "collab_workspace_summary",
      description:
        "Get a short workspace summary: git branch, status, root path, and key folders. Use so both agents share the same workspace context.",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "collab_list_projects",
      description:
        "List top-level projects/folders in the workspace (e.g. Better11, Libraries). Use to align on project layout.",
      inputSchema: { type: "object", properties: {} },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const a = (args as Record<string, unknown>) ?? {};

  try {
    switch (name) {
      case "collab_handoff_read": {
        const text = await readHandoff();
        return {
          content: [
            {
              type: "text" as const,
              text: text || "(No handoff notes yet. Use collab_handoff_write to leave context for the other agent.)",
            },
          ],
        };
      }
      case "collab_handoff_write": {
        const content = (a.content as string) ?? "";
        const append = (a.append as boolean) ?? true;
        await writeHandoff(content, append);
        return {
          content: [
            {
              type: "text" as const,
              text: append
                ? "Appended to handoff notes."
                : "Handoff notes replaced.",
            },
          ],
        };
      }
      case "collab_workspace_summary": {
        const parts: string[] = [`Workspace root: ${WORKSPACE_ROOT}`];
        try {
          const gitStatus = await runCommand("git", ["status", "--short", "-b"]);
          if (gitStatus.code === 0 && gitStatus.stdout.trim()) {
            parts.push("\nGit:\n" + gitStatus.stdout.trim());
          }
        } catch {
          parts.push("\nGit: not available or not a repo.");
        }
        return {
          content: [{ type: "text" as const, text: parts.join("\n") }],
        };
      }
      case "collab_list_projects": {
        const { readdirSync } = await import("fs");
        let entries: string[] = [];
        try {
          entries = readdirSync(WORKSPACE_ROOT, { withFileTypes: true })
            .filter((e) => e.isDirectory() && !e.name.startsWith("."))
            .map((e) => e.name);
        } catch {
          entries = ["(cannot read workspace directory)"];
        }
        const text = "Top-level folders:\n" + entries.join("\n");
        return {
          content: [{ type: "text" as const, text }],
        };
      }
      default:
        return {
          content: [{ type: "text" as const, text: `Unknown tool: ${name}` }],
          isError: true,
        };
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return {
      content: [{ type: "text" as const, text: `Error: ${message}` }],
      isError: true,
    };
  }
});

async function main() {
  // Expose handoff as a resource if this SDK version supports it
  try {
    const types = await import("@modelcontextprotocol/sdk/types.js");
    if (types.ListResourcesRequestSchema && types.ReadResourceRequestSchema) {
      server.setRequestHandler(types.ListResourcesRequestSchema, async () => ({
        resources: [
          {
            uri: HANDOFF_URI,
            name: "Claude–Cursor handoff notes",
            description: "Shared handoff notes between Claude and Cursor",
            mimeType: "text/markdown",
          },
        ],
      }));
      server.setRequestHandler(types.ReadResourceRequestSchema, async (request) => {
        if (request.params.uri === HANDOFF_URI) {
          const text = await readHandoff();
          return {
            contents: [
              {
                uri: HANDOFF_URI,
                mimeType: "text/markdown",
                text: text || "(No handoff notes yet.)",
              },
            ],
          }
        }
        throw new Error(`Unknown resource: ${request.params.uri}`);
      });
    }
  } catch {
    // SDK may not export resource schemas; tools are enough
  }

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
