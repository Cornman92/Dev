# Development Dashboard

A real-time project health monitoring dashboard for the Dev workspace with GitHub integration, CI/CD tracking, and comprehensive metrics.

## Features

### ✅ Implemented

- **Backend API Server** (Node.js/Express)
  - RESTful API endpoints for projects, builds, commits, and metrics
  - SQLite database for data persistence
  - GitHub API integration service
  - CI/CD status tracking service
  - WebSocket server for real-time updates
  - Error handling and logging middleware

- **Frontend Dashboard** (Enhanced)
  - Modern, responsive UI with dark/light theme
  - Project health overview cards
  - Real-time updates via WebSocket
  - Search and filter functionality
  - Build status indicators
  - Commit tracking

### 🚧 In Progress / Planned

See [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) for the full roadmap. Planned:

- Test coverage charts and trends
- Deployment status tracking
- Customizable dashboard layouts/widgets
- Authentication/authorization system
- Advanced metrics visualization
- **Workspace report integration** — ingest `workspace_report.json`; show project types, file stats
- **MCP server status panel** — up/down and last test result per MCP server
- **Quick actions** — run workspace scripts (e.g. all MCP tests, lint) from the UI
- **Alerts and export/reports**

## Quick Start

### Prerequisites

- Node.js 18+
- npm or yarn
- GitHub Personal Access Token (optional, for GitHub integration)

### Installation

1. **Install Dependencies**

   ```bash
   cd D:\Dev\dev-dashboard
   npm install
   ```

2. **Configure Environment**

   Copy the example environment file:

   ```bash
   cp config/env.example .env
   ```

   Edit `.env` and configure:
   - `GITHUB_TOKEN` - Your GitHub personal access token (optional)
   - `GITHUB_ORG` - Your GitHub organization name
   - `PORT` - Server port (default: 3000)
   - Other settings as needed

3. **Initialize Database**

   ```bash
   npm run setup-db
   ```

4. **Start Server**

   ```bash
   npm start
   ```

   Or for development with auto-reload:

   ```bash
   npm run dev
   ```

5. **Access Dashboard**

   Open your browser to: `http://localhost:3000`

## Project Structure

```text
dev-dashboard/
├── backend/
│   ├── server.js              # Main Express server
│   ├── config/                # Configuration files
│   ├── routes/                # API route handlers
│   ├── services/              # Business logic services
│   ├── models/                # Database models
│   ├── middleware/            # Express middleware
│   └── websocket/             # WebSocket server
├── frontend/
│   ├── index.html             # Main dashboard page
│   ├── css/                   # Stylesheets
│   └── js/                    # Frontend JavaScript
│       ├── api.js             # API client
│       ├── websocket.js       # WebSocket client
│       └── app.js             # Main app logic
├── database/
│   └── schema.sql             # Database schema
└── config/
    └── env.example            # Environment variables template
```

## API Endpoints

### Projects

- `GET /api/projects` - List all projects
- `GET /api/projects/:id` - Get project details
- `GET /api/projects/:id/status` - Get project health status
- `POST /api/projects` - Create new project
- `PUT /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project
- `POST /api/projects/:id/sync-commits` - Sync commits from GitHub
- `GET /api/projects/:id/coverage` - Test coverage trend and latest (query: `?limit=30`)
- `GET /api/projects/:id/deployments` - List deployments
- `POST /api/projects/:id/deployments` - Create deployment (body: `environment`, `status`, optional `version`, `deployed_at`, `deployed_by`, `url`)

### Builds

- `GET /api/builds` - List all builds
- `GET /api/builds/project/:projectId` - Get builds for project
- `GET /api/builds/project/:projectId/latest` - Get latest build
- `GET /api/builds/project/:projectId/status` - Get build status
- `POST /api/builds/project/:projectId/sync` - Sync builds from GitHub Actions

### Commits

- `GET /api/commits` - List recent commits
- `GET /api/commits/project/:projectId` - Get commits for project
- `GET /api/commits/project/:projectId/recent` - Get recent commits (last 7 days)

### Workspace (workspace report, MCP status, quick actions, code analysis)

- `GET /api/workspace-report` - Workspace report from `workspace_report.json` (run `Generate-WorkspaceReport.ps1` or `npm run report:workspace` to regenerate)
- `GET /api/mcp-status` - MCP server health (runs `Invoke-McpHealthCheck.ps1 -AsJson`)
- `POST /api/quick-action` - Run workspace script (body: `{ "action": "mcp-tests" | "lint" | "report" }`); returns `exitCode`, `stdout`, `stderr`
- `GET /api/code-analysis?path=...` - Run PSScriptAnalyzer on a path; returns `diagnostics` array

### Health

- `GET /health` - Server health check

## WebSocket Events

The WebSocket server broadcasts the following events:

- `project:update` - Project status changed
- `build:complete` - Build completed
- `commit:new` - New commit detected
- `metric:update` - Metric updated

Connect to: `ws://localhost:3000/ws`

## Adding Projects

Projects can be added via the API:

```javascript
POST /api/projects
{
  "name": "MyProject",
  "description": "Project description",
  "path": "D:\\Dev\\MyProject",
  "type": "powershell",
  "status": "healthy",
  "github_repo": "owner/repo" // or full GitHub URL
}
```

Or they can be added directly to the database, or synced from your existing project structure.

## GitHub Integration

To enable GitHub integration:

1. Create a GitHub Personal Access Token with the following scopes:
   - `repo` (full control of private repositories)
   - `read:org` (read org and team membership)

2. Add the token to your `.env` file:

   ```env
   GITHUB_TOKEN=your_token_here
   GITHUB_ORG=your_organization_name
   ```

3. Configure projects with GitHub repository URLs or names (e.g., "owner/repo")

4. Use the sync endpoints to fetch commits and build status from GitHub

## Development

### Running in Development Mode

```bash
npm run dev
```

This uses nodemon for automatic server restarts on file changes.

### Database Management

The database is automatically initialized on first server start. The schema is defined in `database/schema.sql`.

### Testing

```bash
npm test
```

## Configuration

See `config/env.example` for all available configuration options. Projects can be added manually via the API or (when implemented) auto-imported from the workspace report (`workspace_report.json`). See [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) for optional feature flags (auth, webhooks, alerts).

Key settings:

- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment (development/production)
- `DATABASE_PATH` - SQLite database file path
- `GITHUB_TOKEN` - GitHub API token
- `GITHUB_ORG` - GitHub organization name
- Rate limiting and interval settings

## Troubleshooting

### Database Errors

- Ensure the database directory exists and is writable
- Check file permissions on the database file

### GitHub API Errors

- Verify your GitHub token is valid and has required scopes
- Check rate limiting (GitHub allows 5000 requests/hour)
- Ensure repository URLs are correctly formatted

### WebSocket Connection Issues

- Check firewall settings
- Verify the WebSocket path is `/ws`
- Check browser console for connection errors

## Contributing

- [Implementation Plan](./IMPLEMENTATION-PLAN.md) — architecture and phases
- [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) (workspace root) — planned features, automations, and implementation order

## License

MIT
