# Web Automation Skill

## Overview
Advanced web browser automation and interaction capabilities using Playwright and Puppeteer MCP servers.

## Capabilities

### Browser Automation
- **Page navigation**: Open and navigate web pages
- **Element interaction**: Click, type, select, and manipulate DOM elements
- **Screenshot capture**: Capture full page or element screenshots
- **PDF generation**: Convert web pages to PDF documents

### Data Extraction
- **Content scraping**: Extract text, links, and structured data
- **Form automation**: Fill and submit web forms
- **Table extraction**: Extract data from HTML tables
- **API monitoring**: Capture and analyze network requests

### Testing and Validation
- **Functional testing**: Automated user interaction testing
- **Performance monitoring**: Page load times and resource analysis
- **Accessibility testing**: Check for accessibility compliance
- **Cross-browser testing**: Test across different browsers

## Usage Examples

### Basic Automation
```javascript
// Navigate and interact
await page.goto('https://example.com');
await page.click('#login-button');
await page.type('#username', 'user');
await page.type('#password', 'pass');
await page.click('#submit');

// Take screenshot
await page.screenshot({ path: 'screenshot.png' });
```

### Data Extraction
```javascript
// Extract text content
const title = await page.textContent('h1');
const links = await page.$$eval('a', links => links.map(l => l.href));

// Extract table data
const tableData = await page.$$eval('table tr', rows => 
  rows.map(row => Array.from(row.cells, cell => cell.textContent))
);
```

### Advanced Operations
```javascript
// Wait for conditions
await page.waitForSelector('#content');
await page.waitForFunction(() => window.loaded === true);

// Handle file downloads
const download = await page.waitForEvent('download');
await download.saveAs('/path/to/file.pdf');
```

## Best Practices
- Use explicit waits instead of fixed delays
- Implement proper error handling and retries
- Respect robots.txt and website terms of service
- Use headless mode for automated tasks
- Clean up resources properly

## Configuration
- **Browser engines**: Chromium, Firefox, Safari (via Playwright)
- **Execution mode**: Headless or headed
- **Timeouts**: Configurable wait and navigation timeouts
- **Viewport**: Customizable browser window size

## Integration
Works with other MCP servers for:
- **Filesystem**: Save screenshots and extracted data
- **Git**: Version control for test scripts
- **Memory**: Store automation patterns and workflows

## Security Considerations
- Handle sensitive data securely
- Use environment variables for credentials
- Implement proper authentication flows
- Log activities for audit trails
- Respect user privacy and data protection

## Use Cases
- **Web scraping**: Extract structured data from websites
- **Automated testing**: Functional and regression testing
- **Form filling**: Automated data entry workflows
- **Monitoring**: Website uptime and performance monitoring
- **Report generation**: Automated report creation from web data
