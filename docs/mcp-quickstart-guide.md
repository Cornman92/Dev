# MCP Unified Platform - Quick Start Guide

## 🚀 Getting Started in 30 Minutes

This guide will help you set up a basic MCP server connecting Claude Code and other AI coding tools.

---

## Prerequisites

### Required Tools
- Python 3.11+ or Node.js 18+
- Docker & Docker Compose
- Git
- PostgreSQL 15+
- Redis 7+

### Required Accounts
- Anthropic API key (for Claude)
- OpenAI API key (for Codex)
- GitHub account (for version control)

---

## Step 1: Project Setup (5 minutes)

### Python/FastMCP Approach (Recommended)

```bash
# Create project directory
mkdir unified-mcp-server
cd unified-mcp-server

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install fastmcp anthropic openai psycopg2-binary redis aioredis

# Create project structure
mkdir -p src/{server,tools,adapters,resources,models,db,utils}
touch src/__init__.py
touch src/server/{__init__.py,main.py,config.py}
touch src/tools/{__init__.py,context_manager.py,routing.py}
touch src/adapters/{__init__.py,claude_code.py,codex.py}
```

### TypeScript/Node.js Approach (Alternative)

```bash
# Create project directory
mkdir unified-mcp-server
cd unified-mcp-server

# Initialize npm project
npm init -y

# Install dependencies
npm install @modelcontextprotocol/sdk anthropic openai pg redis

# Create project structure
mkdir -p src/{server,tools,adapters,resources,models,db,utils}
```

---

## Step 2: Basic MCP Server (10 minutes)

Create `src/server/main.py`:

```python
from mcp import FastMCP
from typing import Any
import os

# Initialize MCP server
mcp = FastMCP(
    name="Unified Coding Platform",
    version="0.1.0"
)

# Basic health check tool
@mcp.tool()
async def health_check() -> dict[str, Any]:
    """Check server health and connected tools."""
    return {
        "status": "healthy",
        "tools": ["claude_code", "codex"],
        "version": "0.1.0"
    }

# Context sharing tool (minimal)
@mcp.tool()
async def share_context(
    content: str,
    target_tool: str
) -> dict[str, Any]:
    """Share context with another AI tool."""
    # Simplified implementation
    return {
        "status": "shared",
        "target": target_tool,
        "context_id": "ctx_001"
    }

# Project state resource
@mcp.resource("unified://project/state")
async def project_state() -> str:
    """Get current project state."""
    return """{
  "workspace": "/path/to/project",
  "files_changed": 3,
  "last_edit": "2024-12-13T10:30:00Z"
}"""

if __name__ == "__main__":
    mcp.run()
```

---

## Step 3: Claude Code Adapter (5 minutes)

Create `src/adapters/claude_code.py`:

```python
import anthropic
import asyncio
from typing import Any

class ClaudeCodeAdapter:
    """Simple adapter for Claude Code."""
    
    def __init__(self, api_key: str):
        self.client = anthropic.Anthropic(api_key=api_key)
        
    async def execute(self, command: str, context: dict) -> dict[str, Any]:
        """Execute command via Claude."""
        
        # Create message with context
        message = self.client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=4000,
            messages=[{
                "role": "user",
                "content": f"Context: {context}\n\nCommand: {command}"
            }]
        )
        
        return {
            "result": message.content[0].text,
            "usage": {
                "input_tokens": message.usage.input_tokens,
                "output_tokens": message.usage.output_tokens
            }
        }
    
    async def get_context(self) -> dict[str, Any]:
        """Get current context from Claude Code."""
        # In real implementation, this would query Claude Code's MCP resources
        return {
            "workspace": "/current/workspace",
            "current_file": "main.py",
            "selection": None
        }
```

---

## Step 4: Configuration (3 minutes)

Create `.env` file:

```bash
# API Keys
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/unified_mcp
REDIS_URL=redis://localhost:6379

# Server Config
MCP_SERVER_PORT=3000
LOG_LEVEL=INFO
ENVIRONMENT=development
```

Create `src/server/config.py`:

```python
import os
from dataclasses import dataclass

@dataclass
class Config:
    """Server configuration."""
    
    # API Keys
    anthropic_api_key: str = os.getenv("ANTHROPIC_API_KEY", "")
    openai_api_key: str = os.getenv("OPENAI_API_KEY", "")
    
    # Database
    database_url: str = os.getenv("DATABASE_URL", "")
    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379")
    
    # Server
    port: int = int(os.getenv("MCP_SERVER_PORT", "3000"))
    log_level: str = os.getenv("LOG_LEVEL", "INFO")
    environment: str = os.getenv("ENVIRONMENT", "development")
    
    @classmethod
    def load(cls) -> "Config":
        """Load configuration from environment."""
        return cls()
```

---

## Step 5: Docker Setup (5 minutes)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  mcp-server:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/unified_mcp
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    volumes:
      - ./src:/app/src
    
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: unified_mcp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/

# Expose MCP server port
EXPOSE 3000

# Run server
CMD ["python", "-m", "src.server.main"]
```

Create `requirements.txt`:

```
fastmcp>=0.1.0
anthropic>=0.8.0
openai>=1.0.0
psycopg2-binary>=2.9.0
redis>=5.0.0
aioredis>=2.0.0
python-dotenv>=1.0.0
pydantic>=2.0.0
```

---

## Step 6: Run the Server (2 minutes)

### Local Development

```bash
# Start database services
docker-compose up -d db redis

# Run MCP server
python src/server/main.py
```

### Docker Deployment

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f mcp-server

# Stop services
docker-compose down
```

---

## Step 7: Test the Integration

### Connect Claude Code

Create `claude_desktop_config.json` (location varies by OS):

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "unified-platform": {
      "command": "python",
      "args": ["/path/to/unified-mcp-server/src/server/main.py"],
      "env": {
        "ANTHROPIC_API_KEY": "your_key_here",
        "OPENAI_API_KEY": "your_key_here"
      }
    }
  }
}
```

### Test with Python Client

```python
import asyncio
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

async def test_mcp_server():
    """Test MCP server connection."""
    
    server_params = StdioServerParameters(
        command="python",
        args=["src/server/main.py"]
    )
    
    async with stdio_client(server_params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # List available tools
            tools = await session.list_tools()
            print("Available tools:", tools)
            
            # Call health check
            result = await session.call_tool("health_check", {})
            print("Health check:", result)
            
            # Share context
            result = await session.call_tool("share_context", {
                "content": "def hello(): print('world')",
                "target_tool": "claude_code"
            })
            print("Context shared:", result)

# Run test
asyncio.run(test_mcp_server())
```

---

## Common Issues & Solutions

### Issue: "Module 'mcp' not found"
```bash
pip install --upgrade fastmcp
```

### Issue: "Database connection failed"
```bash
# Check if PostgreSQL is running
docker-compose ps

# Restart database
docker-compose restart db
```

### Issue: "Redis connection timeout"
```bash
# Check Redis status
docker-compose logs redis

# Restart Redis
docker-compose restart redis
```

### Issue: "Claude Code not connecting"
- Verify `claude_desktop_config.json` path
- Check file permissions
- Restart Claude desktop app
- Check logs in Claude app settings

---

## Next Steps

1. **Add More Tools:**
   - Implement Codex adapter
   - Add Cursor integration
   - Add Windsurf support

2. **Enhance Routing:**
   - Implement intelligent routing engine
   - Add ML-based task classification
   - Create capability scoring system

3. **Add Persistence:**
   - Set up PostgreSQL schema
   - Implement context storage
   - Add activity logging

4. **Security:**
   - Add authentication
   - Implement rate limiting
   - Add audit logging

5. **Monitoring:**
   - Set up Prometheus metrics
   - Add Grafana dashboards
   - Configure alerting

---

## Useful Commands

```bash
# Development
python src/server/main.py              # Run server
pytest tests/                          # Run tests
black src/                             # Format code
mypy src/                              # Type checking

# Docker
docker-compose up -d                   # Start services
docker-compose down                    # Stop services
docker-compose logs -f mcp-server      # View logs
docker-compose exec mcp-server bash    # SSH into container

# Database
docker-compose exec db psql -U postgres -d unified_mcp  # Connect to DB
```

---

## Resources

- **MCP Documentation:** https://modelcontextprotocol.io
- **FastMCP GitHub:** https://github.com/jlowin/fastmcp
- **Anthropic Docs:** https://docs.anthropic.com
- **OpenAI Docs:** https://platform.openai.com/docs

---

## Support

For issues or questions:
1. Check the main plan document
2. Review MCP specification
3. Contact project team leads
4. File issue in project repository
