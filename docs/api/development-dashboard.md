# Development Dashboard API Reference

> REST API documentation for the Development Dashboard  
> Last Updated: 2025-01-20

## Base URL

```
http://localhost:3000/api
```

## Authentication

Currently, the API does not require authentication. Future versions will support API keys or OAuth.

## Endpoints

### Projects

#### List All Projects

Get a list of all projects.

**Endpoint**: `GET /projects`

**Response**:
```json
[
  {
    "id": 1,
    "name": "Better11",
    "description": "Windows 11 enhancement suite",
    "path": "active-projects/Better11",
    "type": "dotnet",
    "status": "active",
    "github_repo": "owner/repo",
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-20T00:00:00Z"
  }
]
```

#### Get Project by ID

Get details for a specific project.

**Endpoint**: `GET /projects/:id`

**Parameters**:
- `id` (path, required): Project ID

**Response**:
```json
{
  "id": 1,
  "name": "Better11",
  "description": "Windows 11 enhancement suite",
  "path": "active-projects/Better11",
  "type": "dotnet",
  "status": "active",
  "github_repo": "owner/repo",
  "health": {
    "status": "healthy",
    "last_build": "success",
    "test_coverage": 85.5
  }
}
```

#### Get Project Status

Get health status for a project.

**Endpoint**: `GET /projects/:id/status`

**Response**:
```json
{
  "status": "healthy",
  "last_build": "success",
  "test_coverage": 85.5,
  "last_commit": "2025-01-20T10:00:00Z",
  "builds_count": 42
}
```

#### Create Project

Create a new project.

**Endpoint**: `POST /projects`

**Request Body**:
```json
{
  "name": "MyProject",
  "description": "Project description",
  "path": "active-projects/MyProject",
  "type": "powershell",
  "github_repo": "owner/repo"
}
```

**Response**: Created project object (same as GET /projects/:id)

#### Update Project

Update an existing project.

**Endpoint**: `PUT /projects/:id`

**Request Body**: Same as POST /projects (all fields optional)

**Response**: Updated project object

#### Delete Project

Delete a project.

**Endpoint**: `DELETE /projects/:id`

**Response**: `204 No Content`

#### Sync Commits

Sync commits from GitHub for a project.

**Endpoint**: `POST /projects/:id/sync-commits`

**Query Parameters**:
- `days` (optional): Number of days to sync (default: 7)

**Response**:
```json
{
  "synced": 15,
  "message": "Successfully synced 15 commits"
}
```

### Builds

#### List All Builds

Get all builds, optionally filtered by project.

**Endpoint**: `GET /builds` or `GET /builds/project/:projectId`

**Response**:
```json
[
  {
    "id": 1,
    "project_id": 1,
    "status": "success",
    "workflow_run_id": 12345,
    "started_at": "2025-01-20T10:00:00Z",
    "completed_at": "2025-01-20T10:05:00Z",
    "duration": 300
  }
]
```

#### Get Latest Build

Get the latest build for a project.

**Endpoint**: `GET /builds/project/:projectId/latest`

**Response**: Build object (same as list response)

#### Get Build Status

Get build status summary for a project.

**Endpoint**: `GET /builds/project/:projectId/status`

**Response**:
```json
{
  "latest_status": "success",
  "latest_build_id": 1,
  "total_builds": 42,
  "success_count": 40,
  "failure_count": 2
}
```

#### Sync Builds

Sync builds from GitHub Actions for a project.

**Endpoint**: `POST /builds/project/:projectId/sync`

**Response**:
```json
{
  "synced": 5,
  "message": "Successfully synced 5 builds"
}
```

#### Sync All Builds

Sync builds for all projects.

**Endpoint**: `POST /builds/sync-all`

**Response**:
```json
{
  "projects_synced": 8,
  "total_builds": 42
}
```

### Commits

#### List Recent Commits

Get recent commits, optionally filtered by project.

**Endpoint**: `GET /commits` or `GET /commits/project/:projectId`

**Query Parameters**:
- `limit` (optional): Maximum number of commits (default: 50)

**Response**:
```json
[
  {
    "id": 1,
    "project_id": 1,
    "sha": "abc123def456",
    "message": "Fix bug in feature",
    "author": "Developer",
    "committed_at": "2025-01-20T10:00:00Z",
    "url": "https://github.com/owner/repo/commit/abc123"
  }
]
```

#### Get Recent Commits

Get recent commits for a project (last 7 days by default).

**Endpoint**: `GET /commits/project/:projectId/recent`

**Query Parameters**:
- `days` (optional): Number of days (default: 7)

**Response**: Array of commit objects

### Health

#### Health Check

Check API health status.

**Endpoint**: `GET /health`

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-01-20T10:00:00Z",
  "database": "connected",
  "version": "1.0.0"
}
```

## WebSocket Events

Connect to `ws://localhost:3000/ws` for real-time updates.

### Event Types

#### project:update
Project status or information changed.

```json
{
  "type": "event",
  "event": "project:update",
  "data": {
    "project_id": 1,
    "status": "healthy",
    "updated_at": "2025-01-20T10:00:00Z"
  }
}
```

#### build:complete
Build completed.

```json
{
  "type": "event",
  "event": "build:complete",
  "data": {
    "project_id": 1,
    "build_id": 1,
    "status": "success"
  }
}
```

#### commit:new
New commit detected.

```json
{
  "type": "event",
  "event": "commit:new",
  "data": {
    "project_id": 1,
    "commit": {
      "sha": "abc123",
      "message": "New commit"
    }
  }
}
```

#### metric:update
Metric updated (e.g., test coverage).

```json
{
  "type": "event",
  "event": "metric:update",
  "data": {
    "project_id": 1,
    "type": "coverage",
    "value": 85.5
  }
}
```

### WebSocket Client Example

```javascript
const ws = new WebSocket('ws://localhost:3000/ws');

ws.onopen = () => {
  // Subscribe to all events
  ws.send(JSON.stringify({
    type: 'subscribe',
    topics: ['*']
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Event:', message.event, message.data);
};
```

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "message": "Error description",
    "code": "ERROR_CODE"
  }
}
```

### Common Error Codes

- `400 Bad Request`: Invalid request parameters
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## Rate Limiting

API requests are rate-limited to prevent abuse. Limits:
- 100 requests per minute per IP
- 1000 requests per hour per IP

Rate limit headers:
- `X-RateLimit-Limit`: Request limit
- `X-RateLimit-Remaining`: Remaining requests
- `X-RateLimit-Reset`: Reset time (Unix timestamp)

## Examples

### PowerShell Example

```powershell
# Get all projects
$projects = Invoke-RestMethod -Uri "http://localhost:3000/api/projects" -Method Get

# Create a project
$body = @{
    name = "MyProject"
    description = "My project description"
    path = "active-projects/MyProject"
    type = "powershell"
} | ConvertTo-Json

$project = Invoke-RestMethod -Uri "http://localhost:3000/api/projects" -Method Post -Body $body -ContentType "application/json"
```

### JavaScript Example

```javascript
// Using fetch API
const response = await fetch('http://localhost:3000/api/projects');
const projects = await response.json();

// Create project
const newProject = await fetch('http://localhost:3000/api/projects', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    name: 'MyProject',
    description: 'My project description',
    path: 'active-projects/MyProject',
    type: 'powershell'
  })
});
```

## Changelog

### v1.0.0 (2025-01-20)
- Initial API release
- Projects, Builds, Commits endpoints
- WebSocket support for real-time updates

---

*For questions or issues, see the [Development Dashboard README](../active-projects/development-dashboard/README.md)*
