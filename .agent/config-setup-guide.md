# MCP Configuration Setup Guide

This guide helps complete the remaining MCP server configurations that require API keys and credentials.

## Required Configurations

### 1. Google Drive Integration
**File**: `c:\Users\saymo\.codeium\windsurf\mcp_config.json`
**Section**: `gdrive`

**Steps**:
1. Create Google Cloud Project
2. Enable Google Drive API
3. Create OAuth 2.0 credentials
4. Download credentials JSON file
5. Update configuration:

```json
"gdrive": {
  "args": [
    "run",
    "-i",
    "--rm",
    "-v",
    "mcp-gdrive:/gdrive-server",
    "-e",
    "GDRIVE_CREDENTIALS_PATH=/gdrive-server/credentials.json",
    "mcp/gdrive"
  ],
  "command": "docker",
  "env": {
    "GOOGLE_CLIENT_ID": "your-client-id-here",
    "GOOGLE_CLIENT_SECRET": "your-client-secret-here"
  }
}
```

### 2. GitHub MCP Server
**Section**: `github-mcp-server`

**Steps**:
1. Generate GitHub Personal Access Token
2. Grant necessary permissions (repo, workflow, etc.)
3. Update configuration:

```json
"github-mcp-server": {
  "args": [
    "run",
    "-i",
    "--rm",
    "-e",
    "GITHUB_PERSONAL_ACCESS_TOKEN",
    "ghcr.io/github/github-mcp-server"
  ],
  "command": "docker",
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your-token-here"
  }
}
```

### 3. Perplexity AI
**Section**: `perplexity-ask`

**Steps**:
1. Sign up for Perplexity API
2. Generate API key
3. Update configuration:

```json
"perplexity-ask": {
  "args": [
    "-y",
    "server-perplexity-ask"
  ],
  "command": "npx",
  "env": {
    "PERPLEXITY_API_KEY": "pplx-your-api-key-here"
  }
}
```

### 4. Redis Server
**Section**: `redis`

**Steps**:
1. Set up Redis instance (local or cloud)
2. Get connection URL
3. Update configuration:

```json
"redis": {
  "args": [
    "-y",
    "@modelcontextprotocol/server-redis"
  ],
  "command": "npx",
  "env": {
    "REDIS_URL": "redis://localhost:6379"
  }
}
```

### 5. Notion Integration
**Section**: `notion-mcp-server`

**Steps**:
1. Create Notion integration
2. Generate API key
3. Grant access to relevant pages/databases
4. Update configuration:

```json
"notion-mcp-server": {
  "args": [
    "-y",
    "@modelcontextprotocol/server-notion"
  ],
  "command": "npx",
  "env": {
    "NOTION_API_KEY": "secret_your-notion-key-here"
  }
}
```

## Optional Configurations

### GitLab Integration
**Section**: `gitlab`

```json
"gitlab": {
  "args": [
    "run",
    "--rm",
    "-i",
    "-e",
    "GITLAB_PERSONAL_ACCESS_TOKEN",
    "-e",
    "GITLAB_API_URL",
    "mcp/gitlab"
  ],
  "command": "docker",
  "env": {
    "GITLAB_PERSONAL_ACCESS_TOKEN": "glpat-your-token-here",
    "GITLAB_API_URL": "https://gitlab.com/api/v4"
  }
}
```

### PostgreSQL Database
**Section**: `postgresql`

```json
"postgresql": {
  "args": [
    "run",
    "-i",
    "--rm",
    "mcp/postgres",
    "postgresql://username:password@localhost:5432/database"
  ],
  "command": "docker",
  "env": {
    "POSTGRES_CONNECTION_STRING": "postgresql://username:password@localhost:5432/database"
  }
}
```

## Environment Setup Script

Create a PowerShell script to set up environment variables:

```powershell
# setup-mcp-env.ps1
$env:GOOGLE_CLIENT_ID = "your-client-id"
$env:GOOGLE_CLIENT_SECRET = "your-client-secret"
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_your-token"
$env:PERPLEXITY_API_KEY = "pplx_your-key"
$env:REDIS_URL = "redis://localhost:6379"
$env:NOTION_API_KEY = "secret_your-key"

Write-Host "MCP environment variables set"
```

## Security Best Practices

### API Key Management
1. **Never commit API keys to version control**
2. Use environment variables or secure storage
3. Rotate keys regularly
4. Use least privilege permissions

### Docker Security
1. Use official images
2. Keep images updated
3. Run containers with minimal permissions
4. Use Docker secrets for sensitive data

### Network Security
1. Use HTTPS for all API calls
2. Implement rate limiting
3. Monitor API usage
4. Use VPN for sensitive operations

## Testing Configurations

### Verification Script
```bash
# Test each MCP server
echo "Testing MCP servers..."

# Test filesystem
echo "Testing filesystem..."
npx -y @modelcontextprotocol/server-filesystem c:\Users\saymo\OneDrive\Dev

# Test git
echo "Testing git..."
uvx mcp-server-git

# Test memory
echo "Testing memory..."
npx -y @modelcontextprotocol/server-memory

echo "MCP server tests completed"
```

### Connection Validation
1. Restart Windsurf/Codeium after configuration changes
2. Check MCP server status in IDE
3. Test basic operations for each configured server
4. Monitor logs for connection issues

## Troubleshooting

### Common Issues
1. **Docker not running** - Start Docker Desktop
2. **API key invalid** - Verify key format and permissions
3. **Network connectivity** - Check firewall and proxy settings
4. **Permission denied** - Verify file/directory permissions

### Debug Mode
Enable debug logging in MCP configuration:
```json
{
  "debug": true,
  "logLevel": "verbose"
}
```

## Maintenance

### Regular Tasks
1. Update API keys periodically
2. Monitor API usage and quotas
3. Update Docker images
4. Review security permissions
5. Backup configurations

### Monitoring
- Monitor API usage metrics
- Check error logs regularly
- Validate server connections
- Review security audit logs

## Support Resources

- [MCP Protocol Documentation](https://modelcontextprotocol.io/)
- [Windsurf Documentation](https://docs.codeium.com/windsurf)
- [Docker Documentation](https://docs.docker.com/)
- Individual service documentation for each MCP server
