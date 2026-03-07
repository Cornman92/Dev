/**
 * Dev Dashboard - Project Health Monitor
 * Real-time development dashboard for the Dev workspace
 */

// ============================================
// Project Data - Based on Active Projects
// ============================================
const projectsData = [
    {
        name: "Better11",
        description: "Windows 11 enhancement suite with WPF UI for system optimization and customization.",
        status: "active",
        type: "dotnet",
        tags: ["dotnet", "wpf"],
        path: "D:\\Dev\\Better11",
        lastUpdated: "2025-12-10"
    },
    {
        name: "PowerShell-Profile",
        description: "Enhanced PowerShell profile with advanced features, aliases, and productivity tools.",
        status: "healthy",
        type: "powershell",
        tags: ["powershell"],
        path: "D:\\Dev\\PowerShell",
        lastUpdated: "2025-12-08"
    },
    {
        name: "App-Installer-Pro",
        description: "Automated application installer supporting 300+ applications with batch install capabilities.",
        status: "healthy",
        type: "powershell",
        tags: ["powershell"],
        path: "D:\\Dev\\BetterShell",
        lastUpdated: "2025-12-05"
    },
    {
        name: "Windows-Deployment-Toolkit",
        description: "Comprehensive deployment automation tools for Windows imaging and configuration.",
        status: "active",
        type: "powershell",
        tags: ["powershell"],
        path: "D:\\Dev\\deployment-toolkit",
        lastUpdated: "2025-12-09"
    },
    {
        name: "ClaudeAgents",
        description: "AI agent workflows and automation for Claude AI integration.",
        status: "active",
        type: "ai",
        tags: ["ai", "powershell"],
        path: "D:\\Dev\\claude-agents",
        lastUpdated: "2025-12-10"
    },
    {
        name: "GaymerPC",
        description: "Gaming PC optimization suite with performance tuning and monitoring.",
        status: "healthy",
        type: "powershell",
        tags: ["powershell"],
        path: "D:\\Dev\\Better11",
        lastUpdated: "2025-12-06"
    },
    {
        name: "GaymerPC.AI",
        description: "AI-powered features for the GaymerPC suite including smart automation.",
        status: "planning",
        type: "ai",
        tags: ["ai", "powershell"],
        path: "D:\\Dev\\Skills",
        lastUpdated: "2025-12-01"
    },
    {
        name: "GaymerPC.Monitoring",
        description: "System monitoring and health tracking for gaming PC performance.",
        status: "active",
        type: "powershell",
        tags: ["powershell"],
        path: "D:\\Dev\\dev-dashboard",
        lastUpdated: "2025-12-07"
    },
    {
        name: "DeployForge",
        description: "Deployment automation platform for streamlined software delivery.",
        status: "planning",
        type: "powershell",
        tags: ["powershell"],
        path: "D:\\Dev\\BetterPE",
        lastUpdated: "2025-11-28"
    },
    {
        name: "ControlCenter",
        description: "Centralized system control UI for managing Windows configurations.",
        status: "planning",
        type: "electron",
        tags: ["electron"],
        path: "D:\\Dev\\Better11",
        lastUpdated: "2025-11-20"
    },
    {
        name: "UnifiedFileManager",
        description: "Advanced file management system with unified operations and smart features.",
        status: "active",
        type: "powershell",
        tags: ["powershell"],
        path: "D:\\Dev\\modules",
        lastUpdated: "2025-12-08"
    },
    {
        name: "Aurora",
        description: "Collection of various utilities and helper tools for development.",
        status: "warning",
        type: "powershell",
        tags: ["powershell"],
        path: "D:\\Dev\\scripts",
        lastUpdated: "2025-10-15"
    }
];

// ============================================
// Workflow Data
// ============================================
const workflowsData = [
    {
        name: "Feature Sprint",
        description: "Plan, develop, and deploy features",
        icon: "🚀",
        path: ".agent/workflows/feature-sprint.md"
    },
    {
        name: "Create Feature",
        description: "Quick feature scaffolding",
        icon: "✨",
        path: ".agent/workflows/create-feature.md"
    },
    {
        name: "PowerShell Module",
        description: "Develop PS modules with testing",
        icon: "📦",
        path: ".agent/workflows/powershell-module.md"
    },
    {
        name: ".NET Development",
        description: "Build .NET apps (Better11 pattern)",
        icon: "💎",
        path: ".agent/workflows/dotnet-development.md"
    },
    {
        name: "Windows Automation",
        description: "Create automation scripts",
        icon: "🤖",
        path: ".agent/workflows/windows-automation.md"
    },
    {
        name: "Release & Deployment",
        description: "Version, publish, and deploy",
        icon: "📤",
        path: ".agent/workflows/release-deployment.md"
    },
    {
        name: "Manage Backlog",
        description: "Prioritize features",
        icon: "📋",
        path: ".agent/workflows/manage-backlog.md"
    }
];

// ============================================
// DOM Elements
// ============================================
const elements = {
    projectsGrid: document.getElementById('projectsGrid'),
    workflowsGrid: document.getElementById('workflowsGrid'),
    searchInput: document.getElementById('searchInput'),
    totalProjects: document.getElementById('totalProjects'),
    activeProjects: document.getElementById('activeProjects'),
    healthyCount: document.getElementById('healthyCount'),
    warningCount: document.getElementById('warningCount'),
    inProgressCount: document.getElementById('inProgressCount'),
    workflowCount: document.getElementById('workflowCount'),
    lastUpdate: document.getElementById('lastUpdate'),
    themeToggle: document.getElementById('themeToggle'),
    refreshBtn: document.getElementById('refreshBtn'),
    filterChips: document.querySelectorAll('.chip')
};

// ============================================
// State
// ============================================
let currentFilter = 'all';
let searchQuery = '';

// ============================================
// Render Functions
// ============================================
function renderProjects(projects) {
    elements.projectsGrid.innerHTML = '';

    const filteredProjects = projects.filter(project => {
        const matchesSearch = project.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
            project.description.toLowerCase().includes(searchQuery.toLowerCase());
        const matchesFilter = currentFilter === 'all' || project.type === currentFilter;
        return matchesSearch && matchesFilter;
    });

    if (filteredProjects.length === 0) {
        elements.projectsGrid.innerHTML = `
            <div class="no-results" style="grid-column: 1/-1; text-align: center; padding: 3rem; color: var(--text-muted);">
                <p style="font-size: 2rem; margin-bottom: 1rem;">🔍</p>
                <p>No projects match your search</p>
            </div>
        `;
        return;
    }

    filteredProjects.forEach((project, index) => {
        const card = createProjectCard(project);
        card.style.animationDelay = `${index * 0.05}s`;
        elements.projectsGrid.appendChild(card);
    });
}

function createProjectCard(project) {
    const card = document.createElement('div');
    card.className = 'project-card fade-in';
    card.dataset.type = project.type || 'unknown';
    if (project.id) card.dataset.projectId = project.id;

    const status = project.status || project.health || 'unknown';
    const statusLabel = getStatusLabel(status);
    const tags = project.tags || (project.type ? [project.type] : []);
    const tagsHtml = tags.map(tag => `<span class="tag ${tag}">${tag}</span>`).join('');

    // Build status indicator if available
    const buildStatusHtml = project.health && project.health !== 'unknown' 
        ? `<span class="meta-item" style="color: var(--accent-primary);">🔨 ${project.health}</span>` 
        : '';

    // Test coverage if available
    const coverageHtml = project.testCoverage !== null && project.testCoverage !== undefined
        ? `<div style="margin-top: 0.5rem; font-size: 0.85rem; color: var(--text-secondary);">📊 Coverage: ${project.testCoverage.toFixed(1)}%</div>`
        : '';

    card.innerHTML = `
        <div class="project-header">
            <h3 class="project-name">${project.name}</h3>
            <span class="project-status ${status}">${statusLabel}</span>
        </div>
        <p class="project-description">${project.description || ''}</p>
        <div class="project-meta">
            ${project.path ? `<span class="meta-item">📁 ${project.path}</span>` : ''}
            ${project.github_repo ? `<span class="meta-item">🔗 ${project.github_repo}</span>` : ''}
            ${project.lastUpdated ? `<span class="meta-item">🕐 ${formatDate(project.lastUpdated)}</span>` : ''}
            ${buildStatusHtml}
        </div>
        ${coverageHtml}
        <div class="project-tags">${tagsHtml}</div>
    `;

    card.addEventListener('click', () => {
        if (project.path) {
            // Open project folder
            window.open(`file:///e:/OneDrive/Dev/${project.path}`, '_blank');
        }
    });

    return card;
}

function renderWorkflows() {
    elements.workflowsGrid.innerHTML = '';

    workflowsData.forEach(workflow => {
        const card = document.createElement('div');
        card.className = 'workflow-card fade-in';

        card.innerHTML = `
            <div class="workflow-icon">${workflow.icon}</div>
            <div class="workflow-info">
                <div class="workflow-name">${workflow.name}</div>
                <div class="workflow-desc">${workflow.description}</div>
            </div>
            <span class="workflow-arrow">→</span>
        `;

        card.addEventListener('click', () => {
            window.open(`file:///e:/OneDrive/Dev/${workflow.path}`, '_blank');
        });

        elements.workflowsGrid.appendChild(card);
    });
}

function updateStats() {
    const healthy = projectsData.filter(p => p.status === 'healthy').length;
    const warning = projectsData.filter(p => p.status === 'warning').length;
    const inProgress = projectsData.filter(p => p.status === 'active').length;
    const planning = projectsData.filter(p => p.status === 'planning').length;

    elements.totalProjects.textContent = projectsData.length;
    elements.activeProjects.textContent = inProgress + planning;
    elements.healthyCount.textContent = healthy;
    elements.warningCount.textContent = warning;
    elements.inProgressCount.textContent = inProgress;
    elements.workflowCount.textContent = workflowsData.length;
    elements.lastUpdate.textContent = new Date().toLocaleString();
}

// ============================================
// Helper Functions
// ============================================
function getStatusLabel(status) {
    const labels = {
        healthy: 'Healthy',
        warning: 'Needs Attention',
        active: 'In Progress',
        planning: 'Planning'
    };
    return labels[status] || status;
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    const now = new Date();
    const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays}d ago`;
    if (diffDays < 30) return `${Math.floor(diffDays / 7)}w ago`;
    return `${Math.floor(diffDays / 30)}mo ago`;
}

// ============================================
// Event Handlers
// ============================================
function setupEventListeners() {
    // Search
    elements.searchInput.addEventListener('input', (e) => {
        searchQuery = e.target.value;
        renderProjects(projectsData);
    });

    // Filter chips
    elements.filterChips.forEach(chip => {
        chip.addEventListener('click', () => {
            elements.filterChips.forEach(c => c.classList.remove('active'));
            chip.classList.add('active');
            currentFilter = chip.dataset.filter;
            renderProjects(projectsData);
        });
    });

    // Theme toggle
    elements.themeToggle.addEventListener('click', () => {
        const currentTheme = document.body.dataset.theme;
        document.body.dataset.theme = currentTheme === 'light' ? 'dark' : 'light';
        elements.themeToggle.textContent = currentTheme === 'light' ? '🌙' : '☀️';
        localStorage.setItem('theme', document.body.dataset.theme);
    });

    // Refresh button
    elements.refreshBtn.addEventListener('click', async () => {
        elements.refreshBtn.style.animation = 'spin 0.5s ease';
        setTimeout(() => {
            elements.refreshBtn.style.animation = '';
        }, 500);
        
        if (useAPI && apiAvailable) {
            // Reload from API
            const projects = await loadProjectsFromAPI();
            if (projects) {
                renderProjects(projects);
                updateStatsFromProjects(projects);
            } else {
                // Fallback to static
                updateStats();
                renderProjects(projectsData);
            }
        } else {
            // Use static data
            updateStats();
            renderProjects(projectsData);
        }
    });
}

// ============================================
// API Integration (Optional - falls back to static data)
// ============================================
let useAPI = false;
let apiAvailable = false;

async function loadProjectsFromAPI() {
    try {
        if (typeof api !== 'undefined' && api) {
            apiAvailable = true;
            const projects = await api.getProjects();
            if (projects && projects.length > 0) {
                useAPI = true;
                return projects;
            }
        }
    } catch (error) {
        console.warn('API not available, using static data:', error.message);
        apiAvailable = false;
    }
    return null;
}

async function setupWebSocketConnection() {
    if (typeof wsClient !== 'undefined' && wsClient) {
        try {
            wsClient.connect();
            
            wsClient.on('connected', () => {
                console.log('WebSocket connected');
                wsClient.subscribe(['*']); // Subscribe to all events
            });

            wsClient.on('project:update', (data) => {
                console.log('Project update:', data);
                if (useAPI) {
                    loadProjectsFromAPI().then(projects => {
                        if (projects) {
                            renderProjects(projects);
                            updateStatsFromProjects(projects);
                        }
                    });
                }
            });

            wsClient.on('build:complete', (data) => {
                console.log('Build complete:', data);
                if (useAPI) {
                    loadProjectsFromAPI().then(projects => {
                        if (projects) {
                            renderProjects(projects);
                        }
                    });
                }
            });
        } catch (error) {
            console.warn('WebSocket setup failed:', error.message);
        }
    }
}

// ============================================
// Initialization
// ============================================
async function init() {
    // Load saved theme
    const savedTheme = localStorage.getItem('theme') || 'dark';
    document.body.dataset.theme = savedTheme;
    elements.themeToggle.textContent = savedTheme === 'light' ? '🌙' : '☀️';

    // Try to load from API first
    const apiProjects = await loadProjectsFromAPI();
    
    if (apiProjects) {
        // Use API data
        renderProjects(apiProjects);
        updateStatsFromProjects(apiProjects);
        useAPI = true;
        console.log('✅ Loaded projects from API');
    } else {
        // Fallback to static data
        renderProjects(projectsData);
        updateStats();
        console.log('✅ Using static project data');
    }

    renderWorkflows();
    setupEventListeners();
    
    // Setup WebSocket if available
    setupWebSocketConnection();

    console.log('✅ Dev Dashboard initialized');
}

// Helper function to update stats from API projects
function updateStatsFromProjects(projects) {
    const healthy = projects.filter(p => (p.status || p.health) === 'healthy').length;
    const warning = projects.filter(p => (p.status || p.health) === 'warning').length;
    const inProgress = projects.filter(p => (p.status || p.health) === 'active').length;
    const planning = projects.filter(p => (p.status || p.health) === 'planning').length;

    elements.totalProjects.textContent = projects.length;
    elements.activeProjects.textContent = inProgress + planning;
    elements.healthyCount.textContent = healthy;
    elements.warningCount.textContent = warning;
    elements.inProgressCount.textContent = inProgress;
    elements.workflowCount.textContent = workflowsData.length;
    elements.lastUpdate.textContent = new Date().toLocaleString();
}

// Start the app
document.addEventListener('DOMContentLoaded', init);
