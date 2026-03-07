# Development Dashboard - Setup Guide

## Quick Setup Instructions

### 1. Install Dependencies

```bash
cd D:\Dev\dev-dashboard
npm install
```

### 2. Configure Environment

Create a `.env` file in the root directory:

```bash
# Copy example file
cp config/env.example .env
```

Edit `.env` with your settings:

```env
PORT=3000
NODE_ENV=development
GITHUB_TOKEN=your_token_here
GITHUB_ORG=your_org_name
DATABASE_PATH=./database/dashboard.db
```

### 3. Initialize Database

The database will be automatically created on first server start, but you can also run:

```bash
npm run setup-db
```

### 4. Start Server

```bash
# Production mode
npm start

# Development mode (with auto-reload)
npm run dev
```

### 5. Access Dashboard

Open your browser to: `http://localhost:3000`

## GitHub Token Setup

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token"
3. Select scopes:
   - `repo` - Full control of private repositories
   - `read:org` - Read org and team membership
4. Copy the token and add it to your `.env` file

## Adding Your First Project

### Via API

```bash
curl -X POST http://localhost:3000/api/projects \
  -H "Content-Type: application/json" \
  -d '{
    "name": "MyProject",
    "description": "My awesome project",
    "path": "D:\\Dev\\MyProject",
    "type": "powershell",
    "status": "healthy",
    "github_repo": "owner/repo"
  }'
```

### Sync from GitHub

After adding a project with a `github_repo`, you can sync its data:

```bash
# Sync commits
curl -X POST http://localhost:3000/api/projects/1/sync-commits?days=30

# Sync builds
curl -X POST http://localhost:3000/api/builds/project/1/sync
```

## Verification

1. Check server health: `http://localhost:3000/health`
2. List projects: `http://localhost:3000/api/projects`
3. Open dashboard: `http://localhost:3000`

## Next Steps

- Configure more projects via the API (or use workspace report integration when available)
- Set up automated syncing (cron jobs or scheduled tasks); see [AUTOMATION-RUNBOOK.md](../docs/AUTOMATION-RUNBOOK.md)
- Customize the dashboard frontend
- Add authentication if needed
- See [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) for the full roadmap

