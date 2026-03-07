# GaymerPC API Reference

## Overview

This document provides comprehensive API reference for all GaymerPC
components, including PowerShell cmdlets, Python
classes, and REST endpoints

## Table of Contents

1. PowerShell API

2. Python API

3. REST API

4. Integration APIs

5. Error Handling

## PowerShell API

### File Management Cmdlets

#### Copy-FMFile

Copies files with advanced options and progress tracking

```powershell

Copy-FMFile -Source <string[]> -Destination <string> [-Options <hashtable>]

```text**Parameters: **- `Source`: Array of source file paths

-`Destination`: Destination directory path

-`Options` : Additional options hashtable**Options:**```powershell

$Options = @{
    Overwrite = $true
    ShowProgress = $true
    UseMLClassification = $false
    CloudStorage = "AWS"
    PreserveAttributes = $true
}

```text**Example:**```powershell

Copy-FMFile -Source @("file1.txt", "file2.txt") -Destination "backup\"
-Options @{ShowProgress=$true}

```text

#### Invoke-FMOrganization

Organizes files using ML-powered classification

```powershell

Invoke-FMOrganization -Path <string> [-Options <hashtable>]

```text**Parameters:**- `Path`: Source directory to organize

-`Options` : Organization options**Options:**```powershell

$Options = @{
    UseMLClassification = $true
    CreateCategories = $true
    MoveFiles = $true
    GenerateReport = $true
}

```text**Example:**```powershell

Invoke-FMOrganization -Path "Downloads\" -Options
@{UseMLClassification=$true; CreateCategories=$true}

```text

#### Find-FMFile

Advanced file search with multiple criteria

```powershell

Find-FMFile -Path <string> [-Criteria <hashtable>]

```text**Parameters:**- `Path`: Search directory

-`Criteria` : Search criteria hashtable**Criteria:**```powershell

$Criteria = @{
    Extension = "*.py"
    MinSize = 1KB
    MaxSize = 10MB
    ModifiedAfter = (Get-Date).AddDays(-30)
    ContentPattern = "class"
    MLClassification = "Code"
}

```text**Example:**```powershell

Find-FMFile -Path "C:\Projects\" -Criteria @{Extension="*.py"; MinSize=1KB}

```text

### Analytics Cmdlets

#### Invoke-FunctionAnalytics

Analyzes PowerShell functions for quality metrics

```powershell

Invoke-FunctionAnalytics -Path <string> [-OutputFormat <string>]
[-IncludeRecommendations]

```text**Parameters: **- `Path`: Directory containing PowerShell files

-`OutputFormat`: Output format (JSON, XML, CSV)

-`IncludeRecommendations` : Include improvement
recommendations**Example:**```powershell

Invoke-FunctionAnalytics -Path "Scripts\" -OutputFormat JSON -IncludeRecommendations

```text

#### Get-ProjectHealthReport

Generates comprehensive project health report

```powershell

Get-ProjectHealthReport -ProjectPath <string> [-Detailed] [-IncludeRecommendations]

```text**Parameters:**- `ProjectPath`: Path to project directory

-`Detailed`: Include detailed analysis

-`IncludeRecommendations` : Include improvement suggestions**Example:**```powershell

Get-ProjectHealthReport -ProjectPath "MyProject\" -Detailed -IncludeRecommendations

```text

### Security Cmdlets

#### Set-FileOwnership

Manages file ownership and permissions

```powershell

Set-FileOwnership -Path <string> -User <string> [-Recurse] [-Force]

```text**Parameters:**- `Path`: File or directory path

-`User`: User or group name

-`Recurse`: Apply recursively to subdirectories

-`Force` : Override existing permissions**Example:**```powershell

Set-FileOwnership -Path "C:\Sensitive\" -User "Administrators" -Recurse

```text

#### Get-PermissionAudit

Audits file permissions and access rights

```powershell

Get-PermissionAudit -Path <string> [-IncludeInherited] [-OutputFormat <string>]

```text**Parameters:**- `Path`: Directory to audit

-`IncludeInherited`: Include inherited permissions

-`OutputFormat` : Output format (JSON, CSV, XML)
**Example:**```powershell

Get-PermissionAudit -Path "C:\Data\" -IncludeInherited -OutputFormat JSON

```text

## Python API

### File Management Classes

#### FileManager

Main file management class with advanced capabilities

```python

from core.file_management import FileManager

fm = FileManager(config=None)

```text**Methods:**##### copy_files(source_paths, destination_path, options=None)

```python

result = fm.copy_files(
    source_paths=['file1.txt', 'file2.txt'],
    destination_path='backup/',
    options={
        'overwrite': True,
        'progress_callback': lambda p: print(f"Progress: {p['percentage']}%"),
        'use_cloud': False
    }
)

```text**Returns:**`OperationResult`object with:

-`success`: Boolean indicating success

-`files_processed`: Number of files processed

-`total_bytes`: Total bytes copied

-`errors`: List of error messages

-`duration`: Operation duration in seconds

##### organize_files(source_path, options=None)

```python

result = fm.organize_files(
    source_path='Downloads/',
    options={
        'use_ml': True,
        'create_categories': True,
        'move_files': True
    }
)

```text**Returns:**`OperationResult`object with organization details.

##### search_files(search_path, criteria)

```python

from core.file_management import SearchCriteria

criteria = SearchCriteria(
    file_extension='py',
    min_size=1024,
    content_pattern='class',
    classification='Code'
)

result = fm.search_files('Projects/', criteria)

```text**Returns:**Dictionary with search results.

##### classify_file(file_path)

```python

classification = fm.classify_file('document.pdf')
print(f"Category: {classification.category}")
print(f"Confidence: {classification.confidence}")
print(f"Recommendations: {classification.recommendations}")

```text**Returns:**`FileClassification`object.

### Analytics Classes

#### FunctionAnalyzer

Analyzes PowerShell functions for quality metrics

```python

from core.analytics import FunctionAnalyzer

analyzer = FunctionAnalyzer()

```text**Methods:**##### analyze_project(project_path)

```python

metrics = analyzer.analyze_project('Scripts/')

```text**Returns:**Dictionary with function metrics.

##### generate_report(metrics, format='json')

```python

report = analyzer.generate_report(metrics, format='markdown')

```text**Returns:**Report string in specified format.

### Security Classes

#### OwnershipManager

Manages file ownership and permissions

```python

from core.security.ownership import OwnershipManager

om = OwnershipManager()

```text**Methods:**##### set_ownership(path, user, recursive=False)

```python

result = om.set_ownership('sensitive_file.txt', 'Administrators')

```text

##### audit_permissions(path, include_inherited=True)

```python

audit_result = om.audit_permissions('data_directory/')

```text

### AI/ML Classes

#### MLFileClassifier

ML-powered file classification

```python

from features.ai_ml import MLFileClassifier

classifier = MLFileClassifier()

```text**Methods:**##### classify_file(file_path, model_name='default')

```python

result = classifier.classify_file('document.pdf')

```text**Returns:**`FileClassification`object.

##### batch_classify(file_paths, model_name='default')

```python

results = classifier.batch_classify(['file1.txt', 'file2.pdf'])

```text**Returns:**List of `FileClassification`objects.

#### PredictiveAnalytics

Predictive analytics for file usage and system performance

```python

from features.ai_ml import PredictiveAnalytics

analytics = PredictiveAnalytics()

```text**Methods:**##### predict_file_usage(file_path, days_ahead=7)

```python

prediction = analytics.predict_file_usage('important_file.txt')
print(f"Predicted usage: {prediction.predicted_value}")
print(f"Confidence: {prediction.confidence}")
print(f"Recommendations: {prediction.recommendations}")

```text

##### predict_system_performance(hours_ahead=24)

```python

perf_predictions = analytics.predict_system_performance()
for metric, pred in perf_predictions.items():
    print(f"{metric}: {pred.predicted_value}")

```text

## REST API

### Base URL

```text

<<http://localhost:8080/api/v1>>

```text

### Authentication

```http

Authorization: Bearer <token>

```text

### Endpoints

#### File Management

##### POST /files/copy

Copy files with advanced options

```json

{
  "source_paths": ["file1.txt", "file2.txt"],
  "destination_path": "backup/",
  "options": {
    "overwrite": true,
    "show_progress": true
  }
}

```text**Response:**```json

{
  "success": true,
  "operation_id": "uuid",
  "files_processed": 2,
  "total_bytes": 1024,
  "duration": 1.5
}

```text

##### POST /files/organize

Organize files using ML classification

```json

{
  "source_path": "Downloads/",
  "options": {
    "use_ml": true,
    "create_categories": true
  }
}

```text

##### GET /files/search

Search files with criteria

```text

GET /files/search?path=Projects/&extension=py&min_size=1024

```text

#### Analytics

##### GET /analytics/functions/{project_id}

Get function analytics for a project**Response:**```json

{
  "project_id": "project123",
  "total_functions": 45,
  "average_complexity": 2.3,
  "quality_score": 8.5,
  "recommendations": ["Add error handling", "Improve documentation"]
}

```text

##### GET /analytics/projects/health

Get project health reports**Response:**```json

{
  "projects": [
    {
      "name": "MyProject",
      "health_score": 8.2,
      "issues": ["Missing README", "No tests"],
      "recommendations": ["Add documentation", "Create test suite"]
    }
  ]
}

```text

#### Security

##### POST /security/ownership

Set file ownership

```json

{
  "path": "sensitive_file.txt",
  "user": "Administrators"
}

```text

##### GET /security/audit/{path}

Audit file permissions**Response:**```json

{
  "path": "/data/",
  "permissions": [
    {
      "user": "Administrators",
      "rights": "FullControl",
      "type": "Allow"
    }
  ],
  "issues": ["Overly permissive access"],
  "recommendations": ["Restrict access to specific users"]
}

```text

## Integration APIs

### Integration Bridge

#### PowerShell Integration

```powershell

## Import integration bridge

Import-Module .\core\file-management\integration_bridge.psm1

## Use integrated functionality

$result = Invoke-IntegratedFileOperation -Operation Copy -Source
"file1.txt" -Destination "backup\"

```text

### Python Integration

```python

from core.file_management.integration_bridge import get_integration_bridge

bridge = get_integration_bridge()
result = bridge.copy_files(['file1.txt'], 'backup/')

```text

### Cross-Language Compatibility

#### PowerShell to Python Bridge

```powershell

## Execute Python function from PowerShell

$result = Invoke-PythonFunction -Module "core.file_management" -Function
"copy_files" -Arguments @{
    source_paths = @("file1.txt")
    destination_path = "backup/"
}

```text

### Python to PowerShell Bridge

```python

## Execute PowerShell cmdlet from Python

from core.integration.bridges import PowerShellBridge

ps_bridge = PowerShellBridge()
result = ps_bridge.invoke_cmdlet('Copy-FMFile', {
    'Source': ['file1.txt'],
    'Destination': 'backup/'
})

```text

## Error Handling

### PowerShell Error Handling

```powershell

try {
    Copy-FMFile -Source "file1.txt" -Destination "backup\"
} catch {
    Write-Error "Operation failed: $($_.Exception.Message)"

    # Check error type
    if ($_.Exception -is [System.IO.FileNotFoundException]) {
        Write-Warning "Source file not found"
    } elseif ($_.Exception -is [System.UnauthorizedAccessException]) {
        Write-Warning "Insufficient permissions"
    }
}

```text

### Python Error Handling

```python

try:
    result = fm.copy_files(['file1.txt'], 'backup/')
    if not result.success:
        print(f"Operation failed: {result.errors}")
except FileNotFoundError as e:
    print(f"File not found: {e}")
except PermissionError as e:
    print(f"Permission denied: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")

```text

### REST API Error Responses

```json

{
  "error": {
    "code": "FILE_NOT_FOUND",
    "message": "Source file not found: file1.txt",
    "details": {
      "file_path": "file1.txt",
      "operation": "copy"
    }
  }
}

```text

### Error Codes

| Code | Description |
|------|-------------|
| `FILE_NOT_FOUND`| Source file or directory not found |
|`PERMISSION_DENIED`| Insufficient permissions |
|`INVALID_PATH`| Invalid file or directory path |
|`OPERATION_FAILED`| General operation failure |
|`VALIDATION_ERROR`| Input validation failed |
|`SYSTEM_ERROR`| System-level error |

## Rate Limiting

### REST API Limits

-**File Operations**: 100 requests/minute

-**Analytics**: 50 requests/minute

-**Security**: 200 requests/minute

### Response Headers

```http

X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200

```text

## Examples

### Complete Workflow Example**PowerShell:**```powershell

## 1. Discover projects

$projects = Get-ProjectDiscovery -Path "C:\Projects\"

## 2. Analyze each project

foreach ($project in $projects) {
    $health = Get-ProjectHealthReport -ProjectPath $project.Path -Detailed

    # 3. Organize files if needed
    if ($health.Score -lt 7) {
Invoke-FMOrganization -Path $project.Path -Options
  @{UseMLClassification=$true}
    }

    # 4. Generate documentation
    New-ProjectDocumentation -ProjectPath $project.Path -Format Markdown
}

```text**Python:**```python

from core.project_management import ProjectManager
from core.file_management import FileManager
from core.analytics import FunctionAnalyzer

## 1. Initialize managers

pm = ProjectManager("Projects/")
fm = FileManager()
analyzer = FunctionAnalyzer()

## 2. Discover and analyze projects

projects = pm.discover_projects()
for project in projects:
    health = pm.get_project_health_report(project['path'])

    # 3. Organize files if needed
    if health['score'] < 7:
        fm.organize_files(project['path'], {'use_ml': True})

    # 4. Analyze functions
    metrics = analyzer.analyze_project(project['path'])
    report = analyzer.generate_report(metrics)

    print(f"Project: {project['name']}, Health: {health['score']}")

```text

---

* This API reference covers the core functionality. For advanced features
and customization, refer to the Developer

Guide.*
