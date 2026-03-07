/**
 * API Client for Development Dashboard
 */
const API_BASE_URL = window.location.origin + '/api';

class ApiClient {
    constructor() {
        this.baseURL = API_BASE_URL;
    }

    async request(endpoint, options = {}) {
        const url = `${this.baseURL}${endpoint}`;
        const config = {
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            },
            ...options
        };

        if (options.body && typeof options.body === 'object') {
            config.body = JSON.stringify(options.body);
        }

        try {
            const response = await fetch(url, config);
            
            if (!response.ok) {
                const error = await response.json().catch(() => ({ error: { message: response.statusText } }));
                throw new Error(error.error?.message || `HTTP ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('API request failed:', error);
            throw error;
        }
    }

    // Projects
    async getProjects() {
        return this.request('/projects');
    }

    async getProject(id) {
        return this.request(`/projects/${id}`);
    }

    async getProjectStatus(id) {
        return this.request(`/projects/${id}/status`);
    }

    async createProject(project) {
        return this.request('/projects', {
            method: 'POST',
            body: project
        });
    }

    async updateProject(id, project) {
        return this.request(`/projects/${id}`, {
            method: 'PUT',
            body: project
        });
    }

    async deleteProject(id) {
        return this.request(`/projects/${id}`, {
            method: 'DELETE'
        });
    }

    async syncCommits(projectId, days = 7) {
        return this.request(`/projects/${projectId}/sync-commits?days=${days}`, {
            method: 'POST'
        });
    }

    // Builds
    async getBuilds(projectId = null) {
        const endpoint = projectId ? `/builds/project/${projectId}` : '/builds';
        return this.request(endpoint);
    }

    async getLatestBuild(projectId) {
        return this.request(`/builds/project/${projectId}/latest`);
    }

    async getBuildStatus(projectId) {
        return this.request(`/builds/project/${projectId}/status`);
    }

    async syncBuilds(projectId) {
        return this.request(`/builds/project/${projectId}/sync`, {
            method: 'POST'
        });
    }

    async syncAllBuilds() {
        return this.request('/builds/sync-all', {
            method: 'POST'
        });
    }

    // Commits
    async getCommits(projectId = null, limit = 50) {
        const endpoint = projectId 
            ? `/commits/project/${projectId}?limit=${limit}`
            : `/commits?limit=${limit}`;
        return this.request(endpoint);
    }

    async getRecentCommits(projectId, days = 7) {
        return this.request(`/commits/project/${projectId}/recent?days=${days}`);
    }

    // Health
    async getHealth() {
        return this.request('/health');
    }

    // Workspace (ROADMAP 2.2.1, 2.2.2, 2.2.3, 3.2.3)
    async getWorkspaceReport() {
        return this.request('/workspace-report');
    }

    async getMcpStatus() {
        return this.request('/mcp-status');
    }

    async runQuickAction(action) {
        return this.request('/quick-action', { method: 'POST', body: { action } });
    }

    async getCodeAnalysis(filePath) {
        return this.request(`/code-analysis?path=${encodeURIComponent(filePath)}`);
    }

    async getProjectCoverage(projectId, limit = 30) {
        return this.request(`/projects/${projectId}/coverage?limit=${limit}`);
    }

    async getProjectDeployments(projectId) {
        return this.request(`/projects/${projectId}/deployments`);
    }

    async createDeployment(projectId, data) {
        return this.request(`/projects/${projectId}/deployments`, { method: 'POST', body: data });
    }
}

// Export singleton instance
const api = new ApiClient();
window.api = api; // Make available globally for debugging

