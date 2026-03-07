const { execSync } = require('child_process');
const scripts = [
  'test:mcp-time-utils',
  'test:mcp-code-analysis',
  'test:mcp-powershell',
  'test:mcp-system-info',
  'test:mcp-winget',
  'test:mcp-dotnet-cli',
  'test:mcp-nuget',
  'test:mcp-project-scaffolder'
];
const failed = [];
for (const s of scripts) {
  try {
    execSync('npm run ' + s, { stdio: 'inherit' });
  } catch (e) {
    failed.push(s);
  }
}
if (failed.length) {
  console.error('Failed:', failed.join(', '));
  process.exit(1);
}
process.exit(0);
