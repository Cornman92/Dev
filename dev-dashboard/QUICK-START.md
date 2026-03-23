# Development Dashboard - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Install Dependencies

```bash
cd D:\Dev\dev-dashboard
npm install
```

### Step 2: Configure Environment

Create a `.env` file:

```bash
# Windows PowerShell
Copy-Item config/env.example .env

# Or manually create .env with:
PORT=3000
NODE_ENV=development
DATABASE_PATH=./database/dashboard.db
```

**Optional (for GitHub integration):**
```env
GITHUB_TOKEN=your_github_token_here
GITHUB_ORG=your_organization_name
```

### Step 3: Start the Server

```bash
npm start
```

The database will be automatically created on first run.

### Step 4: Open the Dashboard

Open your browser to: **http://localhost:3000**

## 📊 What You'll See

- **Static Data Mode**: The dashboard will show static project data from `script.js`
- **API Mode**: If projects are added via API, it will show live data
- **Real-time Updates**: WebSocket connection provides live updates (when API is used)

## 🔧 Adding Projects

### Method 1: Via API (Recommended)

```bash
# Add a project
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

### Method 2: Use Static Data

The dashboard automatically falls back to static project data defined in `script.js` if no API projects are found.

## 🔄 Syncing GitHub Data

If you have projects with `github_repo` configured:

```bash
# Sync commits (last 7 days)
curl -X POST http://localhost:3000/api/projects/1/sync-commits?days=7

# Sync builds (from GitHub Actions)
curl -X POST http://localhost:3000/api/builds/project/1/sync
```

## 🎯 Key Features

✅ **Backward Compatible**: Works with existing static data  
✅ **API Integration**: Seamlessly uses API when available  
✅ **Real-time Updates**: WebSocket for live updates  
✅ **GitHub Integration**: Track commits, builds, and PRs  
✅ **Responsive UI**: Modern dark/light theme  

## 🐛 Troubleshooting

### Port Already in Use
Change the port in `.env`: `PORT=3001`

### Database Errors
Delete `database/dashboard.db` and restart - it will be recreated.

### API Not Working
Check browser console - the dashboard automatically falls back to static data if API is unavailable.

### GitHub Integration Not Working
- Verify `GITHUB_TOKEN` is set in `.env`
- Check token has required scopes: `repo`, `read:org`
- Ensure `github_repo` is correctly formatted (e.g., "owner/repo")

## 📚 Next Steps

- See [README.md](./README.md) for full documentation
- See [SETUP.md](./SETUP.md) for detailed setup instructions
- See [IMPLEMENTATION-SUMMARY.md](./IMPLEMENTATION-SUMMARY.md) for architecture details
- See [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) (workspace root) for planned features and automations

## 💡 Tips

- The dashboard works immediately with static data - no configuration required
- Add GitHub token to enable live data syncing
- Use the refresh button to manually reload data
- Check browser console for connection status

