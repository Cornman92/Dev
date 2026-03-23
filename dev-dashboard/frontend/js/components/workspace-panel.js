/**
 * Workspace Panel — workspace report, MCP status, quick actions (ROADMAP 30–32).
 */
class WorkspacePanel {
    constructor(containerId) {
        this.containerId = containerId;
        this.report = null;
        this.mcpStatus = null;
    }

    getContainer() {
        return document.getElementById(this.containerId);
    }

    async render() {
        const container = this.getContainer();
        if (!container) return;

        container.innerHTML = `
            <section class="workspace-panel card" data-theme-section>
                <h2>Workspace & MCP</h2>
                <div class="workspace-tabs">
                    <button type="button" class="tab active" data-tab="report">Report</button>
                    <button type="button" class="tab" data-tab="mcp">MCP Status</button>
                    <button type="button" class="tab" data-tab="actions">Quick Actions</button>
                </div>
                <div class="workspace-content">
                    <div class="tab-pane active" data-pane="report">
                        <p class="muted">Load workspace report (project list &amp; stats).</p>
                        <button type="button" class="btn btn-secondary" data-load-report>Load Report</button>
                        <pre class="workspace-report-output" style="max-height:200px;overflow:auto;margin-top:0.5rem;font-size:0.85rem;"></pre>
                    </div>
                    <div class="tab-pane" data-pane="mcp">
                        <p class="muted">MCP server status (Ready / Missing).</p>
                        <button type="button" class="btn btn-secondary" data-load-mcp>Load MCP Status</button>
                        <div class="mcp-status-list" style="margin-top:0.5rem;"></div>
                    </div>
                    <div class="tab-pane" data-pane="actions">
                        <p class="muted">Run workspace scripts (may take a minute).</p>
                        <div class="quick-actions">
                            <button type="button" class="btn btn-primary" data-action="report">Regenerate Report</button>
                            <button type="button" class="btn btn-primary" data-action="lint">Lint Scripts</button>
                            <button type="button" class="btn btn-primary" data-action="mcp-tests">Run MCP Tests</button>
                        </div>
                        <pre class="quick-action-output" style="max-height:180px;overflow:auto;margin-top:0.5rem;font-size:0.8rem;white-space:pre-wrap;"></pre>
                    </div>
                </div>
            </section>
        `;

        this.bindTabs(container);
        this.bindReport(container);
        this.bindMcp(container);
        this.bindQuickActions(container);
    }

    bindTabs(container) {
        container.querySelectorAll('.tab').forEach(tab => {
            tab.addEventListener('click', () => {
                const t = tab.dataset.tab;
                container.querySelectorAll('.tab').forEach(x => x.classList.remove('active'));
                container.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
                tab.classList.add('active');
                const pane = container.querySelector(`[data-pane="${t}"]`);
                if (pane) pane.classList.add('active');
            });
        });
    }

    bindReport(container) {
        const btn = container.querySelector('[data-load-report]');
        const out = container.querySelector('.workspace-report-output');
        if (!btn || !out) return;
        btn.addEventListener('click', async () => {
            out.textContent = 'Loading...';
            try {
                if (typeof api === 'undefined') { out.textContent = 'API not available'; return; }
                const data = await api.getWorkspaceReport();
                this.report = data;
                out.textContent = `Entries: ${(data.entries || []).length}\nGenerated: ${data.generatedAt || 'n/a'}\n\n${JSON.stringify((data.entries || []).slice(0, 5), null, 2)}...`;
            } catch (e) {
                out.textContent = 'Error: ' + (e.message || String(e));
            }
        });
    }

    bindMcp(container) {
        const btn = container.querySelector('[data-load-mcp]');
        const list = container.querySelector('.mcp-status-list');
        if (!btn || !list) return;
        btn.addEventListener('click', async () => {
            list.innerHTML = 'Loading...';
            try {
                if (typeof api === 'undefined') { list.textContent = 'API not available'; return; }
                const data = await api.getMcpStatus();
                const servers = data.servers || [];
                list.innerHTML = servers.map(s => `
                    <div class="mcp-row" style="display:flex;align-items:center;gap:0.5rem;margin:0.25rem 0;">
                        <span class="status-dot ${(s.Status || '').toLowerCase()}" style="width:8px;height:8px;border-radius:50%;background:${s.Status === 'Ready' ? 'var(--success)' : '#888';}"></span>
                        <strong>${s.Name || s.name}</strong>
                        <span class="muted">${s.Status || s.status}</span>
                    </div>
                `).join('');
            } catch (e) {
                list.innerHTML = '<span class="error">Error: ' + (e.message || String(e)) + '</span>';
            }
        });
    }

    bindQuickActions(container) {
        const output = container.querySelector('.quick-action-output');
        container.querySelectorAll('[data-action]').forEach(btn => {
            btn.addEventListener('click', async () => {
                const action = btn.dataset.action;
                if (!output) return;
                output.textContent = `Running ${action}...`;
                try {
                    if (typeof api === 'undefined') { output.textContent = 'API not available'; return; }
                    const data = await api.runQuickAction(action);
                    output.textContent = `Exit code: ${data.exitCode}\n\n${(data.stdout || '').slice(-4000)}${data.stderr ? '\n\nStderr:\n' + data.stderr.slice(-1000) : ''}`;
                } catch (e) {
                    output.textContent = 'Error: ' + (e.message || String(e));
                }
            });
        });
    }
}

if (typeof window !== 'undefined') {
    window.WorkspacePanel = WorkspacePanel;
}
