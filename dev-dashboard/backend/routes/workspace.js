/**
 * Workspace and MCP status API (FEATURES-AND-AUTOMATIONS-PLAN: workspace report integration, MCP status panel).
 * Serves workspace_report.json and optional MCP health from the Dev workspace root.
 */
const express = require('express');
const router = express.Router();
const fs = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

const config = require('../config/config');
const workspaceRoot = config.paths.workspaceRoot;
const reportPath = path.join(workspaceRoot, 'workspace_report.json');
const mcpHealthScript = path.join(workspaceRoot, 'Invoke-McpHealthCheck.ps1');

/**
 * GET /api/workspace-report
 * Returns workspace_report.json from workspace root (regenerate with Generate-WorkspaceReport.ps1 or npm run report:workspace).
 */
router.get('/workspace-report', async (req, res, next) => {
    try {
        const data = await fs.readFile(reportPath, 'utf8');
        const report = JSON.parse(data);
        res.json({
            source: reportPath,
            generatedAt: (await fs.stat(reportPath).catch(() => null))?.mtime?.toISOString() || null,
            entries: report
        });
    } catch (err) {
        if (err.code === 'ENOENT') {
            return res.status(404).json({
                error: 'Workspace report not found',
                hint: 'Run from workspace root: .\\Generate-WorkspaceReport.ps1 or npm run report:workspace'
            });
        }
        if (err instanceof SyntaxError) {
            return res.status(502).json({ error: 'Invalid workspace_report.json' });
        }
        next(err);
    }
});

/**
 * GET /api/mcp-status
 * Runs Invoke-McpHealthCheck.ps1 -AsJson and returns status for each MCP server.
 */
router.get('/mcp-status', async (req, res, next) => {
    try {
        const scriptExists = await fs.access(mcpHealthScript).then(() => true).catch(() => false);
        if (!scriptExists) {
            return res.status(404).json({
                error: 'MCP health check script not found',
                path: mcpHealthScript
            });
        }
        const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${mcpHealthScript}" -WorkspaceRoot "${workspaceRoot}" -AsJson`;
        const raw = execSync(cmd, { encoding: 'utf8', timeout: 15000, maxBuffer: 64 * 1024 });
        const data = JSON.parse(raw.trim());
        res.json({
            source: 'Invoke-McpHealthCheck.ps1',
            servers: Array.isArray(data) ? data : [data]
        });
    } catch (err) {
        if (err.killed && err.signal === 'SIGTERM') {
            return res.status(504).json({ error: 'MCP health check timed out' });
        }
        if (err.stdout) {
            try {
                const data = JSON.parse(String(err.stdout).trim());
                return res.json({ source: 'Invoke-McpHealthCheck.ps1', servers: Array.isArray(data) ? data : [data] });
            } catch (_) { /* ignore */ }
        }
        next(err);
    }
});

/**
 * POST /api/quick-action (2.2.3, 3.2.2)
 * Run a named workspace script (mcp-tests, lint, report) with timeout. Returns output and exit code.
 */
const ALLOWED_ACTIONS = {
    'mcp-tests': { cmd: 'npm run test:mcp-all', cwd: workspaceRoot, timeout: 300000 },
    'lint': { cmd: `powershell -NoProfile -ExecutionPolicy Bypass -File "${path.join(workspaceRoot, '_lint-migrate.ps1').replace(/"/g, '\\"')}"`, cwd: workspaceRoot, timeout: 60000 },
    'report': { cmd: `powershell -NoProfile -ExecutionPolicy Bypass -File "${path.join(workspaceRoot, 'Generate-WorkspaceReport.ps1').replace(/"/g, '\\"')}"`, cwd: workspaceRoot, timeout: 60000 }
};

router.post('/quick-action', async (req, res, next) => {
    try {
        const name = (req.body?.action || req.query?.action || '').toLowerCase();
        const def = ALLOWED_ACTIONS[name];
        if (!def) {
            return res.status(400).json({ error: 'Unknown action', allowed: Object.keys(ALLOWED_ACTIONS) });
        }
        let stdout = ''; let stderr = ''; let exitCode = 0;
        try {
            stdout = execSync(def.cmd, {
                encoding: 'utf8', timeout: def.timeout || 60000, maxBuffer: 2 * 1024 * 1024,
                cwd: def.cwd || workspaceRoot, shell: true
            });
        } catch (e) {
            stdout = (e.stdout || '').toString(); stderr = (e.stderr || '').toString(); exitCode = e.status ?? 1;
        }
        res.json({ action: name, exitCode, stdout: (stdout || '').slice(-8000), stderr: (stderr || '').slice(-2000) });
    } catch (err) {
        next(err);
    }
});

/**
 * GET /api/code-analysis (3.2.3)
 * Run PSScriptAnalyzer on a path (query: path=relative or absolute). Returns diagnostics.
 */
router.get('/code-analysis', async (req, res, next) => {
    try {
        const targetPath = req.query?.path || req.query?.file;
        if (!targetPath) {
            return res.status(400).json({ error: 'Query parameter path or file required' });
        }
        const fullPath = path.isAbsolute(targetPath) ? targetPath : path.join(workspaceRoot, targetPath);
        const script = path.join(workspaceRoot, '_lint-migrate.ps1');
        const scriptExists = await fs.access(script).then(() => true).catch(() => false);
        if (!scriptExists) {
            return res.status(404).json({ error: 'Lint script not found', path: script });
        }
        const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-ScriptAnalyzer -Path '${fullPath.replace(/'/g, "''")}' -Severity Error, Warning | ConvertTo-Json -Depth 5 -Compress"`;
        let raw = '';
        try {
            raw = execSync(cmd, { encoding: 'utf8', timeout: 30000, maxBuffer: 256 * 1024 });
        } catch (e) {
            raw = e.stdout || '[]';
        }
        let diagnostics = [];
        try {
            const parsed = JSON.parse(raw.trim() || '[]');
            diagnostics = Array.isArray(parsed) ? parsed : [parsed];
        } catch (_) {
            diagnostics = [];
        }
        res.json({ path: fullPath, diagnostics });
    } catch (err) {
        next(err);
    }
});

module.exports = router;
