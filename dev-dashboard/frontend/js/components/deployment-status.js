/**
 * Deployment Status Component
 * Displays deployment status for projects
 */
class DeploymentStatus {
    constructor(containerId) {
        this.containerId = containerId;
        this.container = document.getElementById(containerId);
        this.deployments = [];
    }

    async loadData() {
        try {
            if (typeof api !== 'undefined' && api) {
                // Fetch deployments from API
                const deployments = await api.request('/deployments');
                return deployments || [];
            }
        } catch (error) {
            console.warn('Could not load deployment data from API:', error);
        }
        return [];
    }

    formatDate(dateStr) {
        const date = new Date(dateStr);
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return `${diffMins}m ago`;
        if (diffHours < 24) return `${diffHours}h ago`;
        if (diffDays < 7) return `${diffDays}d ago`;
        return date.toLocaleDateString();
    }

    getStatusClass(status) {
        const statusMap = {
            'success': 'status-success',
            'failed': 'status-failed',
            'in-progress': 'status-in-progress',
            'pending': 'status-pending'
        };
        return statusMap[status] || 'status-unknown';
    }

    getStatusIcon(status) {
        const iconMap = {
            'success': '✅',
            'failed': '❌',
            'in-progress': '🔄',
            'pending': '⏳'
        };
        return iconMap[status] || '❓';
    }

    createDeploymentCard(deployment) {
        const card = document.createElement('div');
        card.className = 'deployment-card';
        card.innerHTML = `
            <div class="deployment-header">
                <div class="deployment-info">
                    <h4 class="deployment-project">${deployment.project_name || 'Unknown'}</h4>
                    <span class="deployment-environment">${deployment.environment || 'production'}</span>
                </div>
                <div class="deployment-status ${this.getStatusClass(deployment.status)}">
                    <span class="status-icon">${this.getStatusIcon(deployment.status)}</span>
                    <span class="status-text">${deployment.status || 'unknown'}</span>
                </div>
            </div>
            <div class="deployment-details">
                <div class="deployment-meta">
                    <span class="meta-item">🕐 ${this.formatDate(deployment.deployed_at || deployment.created_at)}</span>
                    ${deployment.version ? `<span class="meta-item">📦 v${deployment.version}</span>` : ''}
                    ${deployment.commit ? `<span class="meta-item">🔀 ${deployment.commit.substring(0, 7)}</span>` : ''}
                </div>
                ${deployment.message ? `<p class="deployment-message">${deployment.message}</p>` : ''}
            </div>
        `;
        return card;
    }

    async render() {
        if (!this.container) {
            console.error(`Container ${this.containerId} not found`);
            return;
        }

        this.deployments = await this.loadData();

        if (this.deployments.length === 0) {
            this.container.innerHTML = `
                <div class="empty-state">
                    <p>📦 No deployments found</p>
                    <p class="empty-state-hint">Deployments will appear here when available</p>
                </div>
            `;
            return;
        }

        // Sort by date (newest first)
        this.deployments.sort((a, b) => {
            const dateA = new Date(a.deployed_at || a.created_at || 0);
            const dateB = new Date(b.deployed_at || b.created_at || 0);
            return dateB - dateA;
        });

        // Clear container
        this.container.innerHTML = '';

        // Render deployment cards
        this.deployments.slice(0, 10).forEach(deployment => {
            const card = this.createDeploymentCard(deployment);
            this.container.appendChild(card);
        });
    }

    update(deployment) {
        // Add or update deployment in the list
        const index = this.deployments.findIndex(d => d.id === deployment.id);
        if (index >= 0) {
            this.deployments[index] = deployment;
        } else {
            this.deployments.unshift(deployment);
        }
        this.render();
    }
}

// Export for use in other modules
if (typeof window !== 'undefined') {
    window.DeploymentStatus = DeploymentStatus;
}
