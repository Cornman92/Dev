# MCP Skills and Sub-Agents

This directory contains comprehensive skill definitions and sub-agent configurations for the MCP (Model Context Protocol) ecosystem.

## Structure

### Skills Directory (`/skills/`)
Contains detailed skill documentation for each MCP server capability:

- **`filesystem-operations.md`** - File and directory management
- **`git-operations.md`** - Version control and repository management
- **`web-automation.md`** - Browser automation and web scraping
- **`database-operations.md`** - SQL and NoSQL database management
- **`cloud-integration.md`** - Cloud service integrations (Drive, GitHub, etc.)
- **`ai-integration.md`** - AI services and intelligent automation

### Sub-Agents Directory (`/sub-agents/`)
Specialized agent configurations for different domains:

- **`developer-assistant.json`** - Software development and coding
- **`data-analyst.json`** - Data analysis and database operations
- **`automation-specialist.json`** - Workflow automation and web scraping
- **`research-assistant.json`** - Research and knowledge management
- **`devops-engineer.json`** - DevOps, CI/CD, and infrastructure
- **`project-manager.json`** - Project management and coordination

## Usage

### Loading a Sub-Agent
Each sub-agent can be loaded with its specific configuration:
```json
{
  "agent": "developer-assistant",
  "task": "code-review",
  "context": "feature-branch"
}
```

### Skill Activation
Skills can be activated individually or as part of agent workflows:
```json
{
  "skills": ["filesystem-operations", "git-operations"],
  "operation": "deploy-feature"
}
```

## Configuration

### MCP Servers
The system uses the following MCP servers:
- **filesystem** - File system operations
- **git** - Version control
- **github-mcp-server** - GitHub integration
- **mcp-playwright** - Browser automation
- **postgresql/sqlite** - Database operations
- **redis** - Caching and data structures
- **deepwiki** - Repository analysis
- **perplexity-ask** - AI question answering
- **memory** - Persistent memory storage
- **notion-mcp-server** - Notion integration

### Environment Setup
Ensure all required environment variables are configured:
- API keys for external services
- Database connection strings
- Authentication tokens
- File paths and permissions

## Workflows

### Standard Workflows
Each sub-agent includes predefined workflows:
1. **Analysis** - Understand the task and requirements
2. **Planning** - Create execution plan
3. **Execution** - Perform the actual work
4. **Validation** - Verify results
5. **Documentation** - Document outcomes

### Custom Workflows
Create custom workflows by combining skills and tools:
```json
{
  "name": "custom-workflow",
  "steps": [
    {"skill": "filesystem-operations", "action": "read-config"},
    {"skill": "git-operations", "action": "create-branch"},
    {"skill": "ai-integration", "action": "analyze-code"}
  ]
}
```

## Best Practices

### Agent Selection
- Use **Developer Assistant** for coding tasks
- Use **Data Analyst** for database and analysis work
- Use **Automation Specialist** for repetitive tasks
- Use **Research Assistant** for information gathering
- Use **DevOps Engineer** for infrastructure and deployment
- Use **Project Manager** for coordination and planning

### Skill Combination
- Combine complementary skills for complex tasks
- Use memory skill to maintain context across sessions
- Leverage AI integration for intelligent decision making
- Use filesystem operations for data persistence

### Security Considerations
- Validate all inputs and configurations
- Use appropriate authentication for external services
- Implement proper error handling and logging
- Follow principle of least privilege

## Troubleshooting

### Common Issues
1. **MCP Server Connection** - Check server configuration and network connectivity
2. **Authentication Failures** - Verify API keys and tokens
3. **Permission Errors** - Check file system and database permissions
4. **Memory Issues** - Clear memory cache if needed

### Debug Mode
Enable debug logging for detailed troubleshooting:
```json
{
  "debug": true,
  "log_level": "verbose"
}
```

## Extensions

### Adding New Skills
1. Create skill documentation in `/skills/`
2. Define capabilities and usage examples
3. Update agent configurations to include new skill
4. Test integration with existing workflows

### Adding New Sub-Agents
1. Create agent configuration in `/sub-agents/`
2. Define capabilities, tools, and workflows
3. Set appropriate constraints and preferences
4. Test with sample tasks

## Support

For issues and questions:
1. Check this documentation
2. Review skill-specific documentation
3. Examine agent configurations
4. Check MCP server logs
5. Consult the MCP protocol specification
