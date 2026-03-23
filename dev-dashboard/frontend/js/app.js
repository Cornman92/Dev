/**
 * Development Dashboard - Main Application
 * Integrates API, WebSocket, and all components
 */

// Import components (loaded via script tags in HTML)
// CoverageChart, DeploymentStatus, ProjectCard

class DashboardApp {
    constructor() {
        this.projects = [];
        this.projectCards = new Map();
        this.coverageCharts = new Map();
        this.deploymentStatus = null;
        this.useAPI = false;
        this.apiAvailable = false;
        this.wsConnected = false;
    }

    // ============================================
    // Initialization
    // ============================================
    async init() {
        console.log('🚀 Initializing Development Dashboard...');

        // Load saved theme
        this.loadTheme();

        // Setup event listeners
        this.setupEventListeners();

        // Try to connect to API
        await this.initializeAPI();

        // Load projects
        await this.loadProjects();

        // Setup WebSocket connection
        this.setupWebSocket();

        // Initialize deployment status
        this.initializeDeploymentStatus();

        // Initialize workspace panel (report, MCP status, quick actions)
        const wsContainer = document.getElementById('workspacePanelContainer');
        if (wsContainer && typeof WorkspacePanel !== 'undefined') {
            this.workspacePanel = new WorkspacePanel('workspacePanelContainer');
            this.workspacePanel.render();
        }

        console.log('✅ Dashboard initialized');
    }

    loadTheme() {
        const savedTheme = localStorage.getItem('theme') || 'dark';
        document.body.dataset.theme = savedTheme;
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.textContent = savedTheme === 'light' ? '🌙' : '☀️';
        }
    }

    setupEventListeners() {
        // Search
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.handleSearch(e.target.value);
            });
        }

        // Filter chips
        const filterChips = document.querySelectorAll('.chip');
        filterChips.forEach(chip => {
            chip.addEventListener('click', () => {
                filterChips.forEach(c => c.classList.remove('active'));
                chip.classList.add('active');
                const filter = chip.dataset.filter || 'all';
                this.handleFilter(filter);
            });
        });

        // Theme toggle
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.addEventListener('click', () => {
                this.toggleTheme();
            });
        }

        // Refresh button
        const refreshBtn = document.getElementById('refreshBtn');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => {
                this.refresh();
            });
        }
    }

    // ============================================
    // API Integration
    // ============================================
    async initializeAPI() {
        try {
            if (typeof api !== 'undefined' && api) {
                // Test API connection
                const health = await api.getHealth();
                if (health) {
                    this.apiAvailable = true;
                    this.useAPI = true;
                    console.log('✅ API connected');
                    return true;
                }
            }
        } catch (error) {
            console.warn('⚠️ API not available, using static data:', error.message);
            this.apiAvailable = false;
        }
        return false;
    }

    async loadProjects() {
        try {
            if (this.useAPI && typeof api !== 'undefined') {
                const projects = await api.getProjects();
                if (projects && projects.length > 0) {
                    this.projects = projects;
                    this.renderProjects();
                    this.updateStats();
                    return;
                }
            }
        } catch (error) {
            console.warn('Failed to load projects from API:', error);
        }

        // Fallback to static data (from script.js if available)
        if (typeof projectsData !== 'undefined' && projectsData.length > 0) {
            this.projects = projectsData;
            this.renderProjects();
            this.updateStats();
        }
    }

    // ============================================
    // WebSocket Integration
    // ============================================
    setupWebSocket() {
        if (typeof wsClient === 'undefined' || !wsClient) {
            console.warn('WebSocket client not available');
            return;
        }

        try {
            wsClient.connect();

            wsClient.on('connected', () => {
                console.log('✅ WebSocket connected');
                this.wsConnected = true;
                wsClient.subscribe(['*']); // Subscribe to all events
                this.showNotification('WebSocket connected', 'success');
            });

            wsClient.on('disconnected', () => {
                console.log('⚠️ WebSocket disconnected');
                this.wsConnected = false;
                this.showNotification('WebSocket disconnected', 'warning');
            });

            wsClient.on('project:update', (data) => {
                console.log('📦 Project update:', data);
                this.handleProjectUpdate(data);
            });

            wsClient.on('build:complete', (data) => {
                console.log('🔨 Build complete:', data);
                this.handleBuildUpdate(data);
            });

            wsClient.on('commit:new', (data) => {
                console.log('📝 New commit:', data);
                this.handleCommitUpdate(data);
            });

            wsClient.on('metric:update', (data) => {
                console.log('📊 Metric update:', data);
                this.handleMetricUpdate(data);
            });

        } catch (error) {
            console.error('WebSocket setup failed:', error);
        }
    }

    // ============================================
    // Event Handlers
    // ============================================
    handleProjectUpdate(data) {
        const projectIndex = this.projects.findIndex(p => p.id === data.project_id || p.name === data.name);
        if (projectIndex >= 0) {
            this.projects[projectIndex] = { ...this.projects[projectIndex], ...data };
            this.updateProjectCard(this.projects[projectIndex]);
        } else if (data.id || data.name) {
            // New project
            this.projects.push(data);
            this.renderProjects();
        }
        this.updateStats();
    }

    handleBuildUpdate(data) {
        const projectIndex = this.projects.findIndex(p => p.id === data.project_id);
        if (projectIndex >= 0) {
            this.projects[projectIndex].build_status = data.status;
            this.projects[projectIndex].latest_build = data;
            this.updateProjectCard(this.projects[projectIndex]);
            this.showNotification(`Build ${data.status} for ${this.projects[projectIndex].name}`, data.status === 'success' ? 'success' : 'warning');
        }
    }

    handleCommitUpdate(data) {
        // Update project with latest commit info
        const projectIndex = this.projects.findIndex(p => p.id === data.project_id);
        if (projectIndex >= 0) {
            this.projects[projectIndex].last_commit = data;
            this.projects[projectIndex].last_updated = data.committed_at || new Date().toISOString();
            this.updateProjectCard(this.projects[projectIndex]);
        }
    }

    handleMetricUpdate(data) {
        if (data.type === 'coverage' && data.project_id) {
            // Update coverage chart if it exists
            const chart = this.coverageCharts.get(data.project_id);
            if (chart) {
                chart.update(data);
            }
        }
    }

    // ============================================
    // Rendering
    // ============================================
    renderProjects(filteredProjects = null) {
        const projectsGrid = document.getElementById('projectsGrid');
        if (!projectsGrid) return;

        const projectsToRender = filteredProjects || this.projects;
        projectsGrid.innerHTML = '';

        if (projectsToRender.length === 0) {
            projectsGrid.innerHTML = `
                <div class="no-results" style="grid-column: 1/-1; text-align: center; padding: 3rem;">
                    <p style="font-size: 2rem; margin-bottom: 1rem;">🔍</p>
                    <p>No projects found</p>
                </div>
            `;
            return;
        }

        projectsToRender.forEach(project => {
            if (typeof ProjectCard !== 'undefined') {
                const cardComponent = new ProjectCard(project);
                const cardElement = cardComponent.getElement();
                projectsGrid.appendChild(cardElement);
                this.projectCards.set(project.id || project.name, cardComponent);
            } else {
                // Fallback to simple rendering
                const card = this.createSimpleProjectCard(project);
                projectsGrid.appendChild(card);
            }
        });
    }

    createSimpleProjectCard(project) {
        const card = document.createElement('div');
        card.className = 'project-card';
        card.innerHTML = `
            <div class="project-header">
                <h3>${project.name}</h3>
                <span class="project-status">${project.status || 'unknown'}</span>
            </div>
            <p>${project.description || ''}</p>
        `;
        return card;
    }

    updateProjectCard(project) {
        const cardComponent = this.projectCards.get(project.id || project.name);
        if (cardComponent) {
            cardComponent.update(project);
        }
    }

    handleSearch(query) {
        const filtered = this.projects.filter(project => {
            const searchLower = query.toLowerCase();
            return project.name.toLowerCase().includes(searchLower) ||
                   (project.description && project.description.toLowerCase().includes(searchLower));
        });
        this.renderProjects(filtered);
    }

    handleFilter(filter) {
        const filtered = filter === 'all' 
            ? this.projects 
            : this.projects.filter(p => p.type === filter);
        this.renderProjects(filtered);
    }

    updateStats() {
        const healthy = this.projects.filter(p => (p.status || p.health) === 'healthy').length;
        const warning = this.projects.filter(p => (p.status || p.health) === 'warning').length;
        const active = this.projects.filter(p => (p.status || p.health) === 'active').length;
        const planning = this.projects.filter(p => (p.status || p.health) === 'planning').length;

        const totalProjectsEl = document.getElementById('totalProjects');
        const activeProjectsEl = document.getElementById('activeProjects');
        const healthyCountEl = document.getElementById('healthyCount');
        const warningCountEl = document.getElementById('warningCount');
        const inProgressCountEl = document.getElementById('inProgressCount');
        const lastUpdateEl = document.getElementById('lastUpdate');

        if (totalProjectsEl) totalProjectsEl.textContent = this.projects.length;
        if (activeProjectsEl) activeProjectsEl.textContent = active + planning;
        if (healthyCountEl) healthyCountEl.textContent = healthy;
        if (warningCountEl) warningCountEl.textContent = warning;
        if (inProgressCountEl) inProgressCountEl.textContent = active;
        if (lastUpdateEl) lastUpdateEl.textContent = new Date().toLocaleString();
    }

    // ============================================
    // Deployment Status
    // ============================================
    initializeDeploymentStatus() {
        const deploymentContainer = document.getElementById('deploymentStatus');
        if (deploymentContainer && typeof DeploymentStatus !== 'undefined') {
            this.deploymentStatus = new DeploymentStatus('deploymentStatus');
            this.deploymentStatus.render();
        }
    }

    // ============================================
    // UI Actions
    // ============================================
    toggleTheme() {
        const currentTheme = document.body.dataset.theme;
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        document.body.dataset.theme = newTheme;
        localStorage.setItem('theme', newTheme);
        
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.textContent = newTheme === 'light' ? '🌙' : '☀️';
        }
    }

    async refresh() {
        const refreshBtn = document.getElementById('refreshBtn');
        if (refreshBtn) {
            refreshBtn.style.animation = 'spin 0.5s ease';
            setTimeout(() => {
                refreshBtn.style.animation = '';
            }, 500);
        }

        await this.loadProjects();
        if (this.deploymentStatus) {
            await this.deploymentStatus.render();
        }
        this.showNotification('Dashboard refreshed', 'success');
    }

    showNotification(message, type = 'info') {
        // Simple notification system
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 1rem 1.5rem;
            background: var(--bg-secondary);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 1000;
            animation: slideIn 0.3s ease;
        `;
        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }
}

// Initialize app when DOM is ready
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new DashboardApp();
    app.init();
});

// Export for debugging
if (typeof window !== 'undefined') {
    window.DashboardApp = DashboardApp;
    window.app = app;
}
