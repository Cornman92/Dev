// Copyright (c) Better11. All rights reserved.
// MCP server for Better11: create (dev), use (optimize), post (after optimization)

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));
// From tools/mcp-server/dist: ../.. = tools/mcp-server, ../../.. = repo root (Better11 folder)
const BETTER11_ROOT = join(__dirname, "..", "..", "..");
const BETTER11_SLN = join(BETTER11_ROOT, "Better11", "Better11.sln");

function runCommand(
  command: string,
  args: string[],
  cwd: string = BETTER11_ROOT
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

const server = new Server(
  {
    name: "better11-mcp-server",
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
      name: "better11_create_build",
      description:
        "Build the Better11 solution. Use when developing or verifying the codebase.",
      inputSchema: {
        type: "object",
        properties: {
          configuration: {
            type: "string",
            enum: ["Debug", "Release"],
            default: "Debug",
          },
        },
      },
    },
    {
      name: "better11_create_test",
      description:
        "Run Better11 tests (xUnit). Use when developing or before commit.",
      inputSchema: {
        type: "object",
        properties: {
          filter: { type: "string", description: "Test filter (e.g. FullyQualifiedName~ViewModel)" },
        },
      },
    },
    {
      name: "better11_create_list_workstreams",
      description:
        "List Better11 work streams (WS1–WS7) and status. Use when planning or reporting.",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "better11_use_system_info",
      description:
        "Get current system info (OS, CPU, RAM) via PowerShell. Use when user is optimizing their system.",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "better11_use_list_presets",
      description:
        "List optimization presets (Gaming, Developer, Privacy, Balanced, Minimal). Use when guiding optimization.",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "better11_use_list_modules",
      description:
        "List Better11 modules/capabilities. Use when explaining what Better11 can do.",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "better11_post_export_report",
      description:
        "Suggest how to export a Better11 report after optimization. Use after user is done optimizing.",
      inputSchema: {
        type: "object",
        properties: {
          format: { type: "string", enum: ["html", "json", "md"], default: "json" },
        },
      },
    },
    {
      name: "better11_post_health_check",
      description:
        "Run a quick build/health check. Use after optimization or before imaging.",
      inputSchema: { type: "object", properties: {} },
    },
    {
      name: "better11_post_suggest_next_steps",
      description:
        "Get suggested next steps after optimization (imaging, backup, deployment). Use when user is done optimizing.",
      inputSchema: { type: "object", properties: {} },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const a = (args as Record<string, unknown>) ?? {};

  try {
    switch (name) {
      case "better11_create_build": {
        const config = (a.configuration as string) ?? "Debug";
        const r = await runCommand("dotnet", ["build", BETTER11_SLN, "-c", config]);
        return {
          content: [
            {
              type: "text",
              text: r.code === 0 ? r.stdout : `Exit ${r.code}\n${r.stderr}\n${r.stdout}`,
            },
          ],
          isError: r.code !== 0,
        };
      }
      case "better11_create_test": {
        const filter = a.filter as string | undefined;
        const filterArg = filter ? ["--filter", filter] : [];
        const r = await runCommand("dotnet", [
          "test",
          BETTER11_SLN,
          "--no-build",
          ...filterArg,
        ]);
        return {
          content: [{ type: "text", text: r.code === 0 ? r.stdout : `${r.stderr}\n${r.stdout}` }],
          isError: r.code !== 0,
        };
      }
      case "better11_create_list_workstreams": {
        const text = [
          "WS1 Reporting & Analytics — COMPLETE",
          "WS2 Testing & Validation — COMPLETE",
          "WS3 Certificate Manager + Credential Vault — COMPLETE",
          "WS4 Appearance Customizer + RAM Disk — COMPLETE",
          "WS5 Full UI Redesign — COMPLETE",
          "WS6 First Run Wizard + Integration QA — COMPLETE",
          "WS7 Final Zero-Error Pass — COMPLETE",
        ].join("\n");
        return { content: [{ type: "text", text }] };
      }
      case "better11_use_system_info": {
        const r = await runCommand("pwsh", [
          "-NoProfile",
          "-Command",
          "Get-ComputerInfo | Select-Object CsName, WindowsVersion, OsArchitecture, CsProcessors, CsTotalPhysicalMemory | ConvertTo-Json -Compress",
        ]);
        return {
          content: [{ type: "text", text: r.stdout || r.stderr || "PowerShell not available" }],
        };
      }
      case "better11_use_list_presets": {
        const text = [
          "Gaming — Max FPS, disable visual effects, optimize GPU/CPU, debloat",
          "Developer — Dev tools, package managers, Git, WSL, no bloatware",
          "Privacy — Maximum privacy, disable telemetry/tracking/ads",
          "Balanced — Sensible defaults (performance + privacy + usability)",
          "Minimal — Only essential tweaks, safe for any system",
        ].join("\n");
        return { content: [{ type: "text", text }] };
      }
      case "better11_use_list_modules": {
        const text = [
          "Optimization, Privacy, Security, Package Manager, Driver Manager,",
          "Network, Disk Cleanup, Startup Manager, Scheduled Tasks, System Info,",
          "Updates, Appearance, RAM Disk, Certificate Manager, Reporting, Testing.",
        ].join(" ");
        return { content: [{ type: "text", text }] };
      }
      case "better11_post_export_report": {
        const format = (a.format as string) ?? "json";
        return {
          content: [
            {
              type: "text",
              text: `Report export (${format}): Use Better11 GUI Reporting page or Better11.Reporting module. Suggested: save report.${format} for records after optimization.`,
            },
          ],
        };
      }
      case "better11_post_health_check": {
        const r = await runCommand("dotnet", ["build", BETTER11_SLN, "--no-restore"]);
        const ok = r.code === 0;
        return {
          content: [
            {
              type: "text",
              text: ok
                ? "Health check: solution builds OK."
                : `Build check failed (exit ${r.code}).\n${r.stderr}`,
            },
          ],
          isError: !ok,
        };
      }
      case "better11_post_suggest_next_steps": {
        const text = [
          "After optimizing with Better11, suggested next steps:",
          "1. Export a report (Reporting page or better11_post_export_report) for records.",
          "2. Create a system image or backup (e.g. DISM, Macrium, Windows Backup).",
          "3. If capturing for deployment: generalize (Sysprep) then capture with BetterBoot.",
          "4. Optional: create bootable USB or run post-boot scripts from BetterBoot.",
        ].join("\n");
        return { content: [{ type: "text", text }] };
      }
      default:
        return {
          content: [{ type: "text", text: `Unknown tool: ${name}` }],
          isError: true,
        };
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return {
      content: [{ type: "text", text: `Error: ${message}` }],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
