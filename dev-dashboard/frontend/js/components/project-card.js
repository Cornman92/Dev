/**
 * Enhanced Project Card Component
 * Displays project information with real-time updates
 */
class ProjectCard {
    constructor(project) {
        this.project = project;
        this.element = null;
    }

    getStatusClass(status) {
        const statusMap = {
            'healthy': 'status-healthy',
            'warning': 'status-warning',
            'active': 'status-active',
            'planning': 'status-planning',
            'failed': 'status-failed'
        };
        return statusMap[status] || 'status-unknown';
    }

    getStatusLabel(status) {
        const labels = {
            'healthy': 'Healthy',
            'warning': 'Needs Attention',
            'active': 'In Progress',
            'planning': 'Planning',
            'failed': 'Failed'
        };
        return labels[status] || status;
    }

    formatDate(dateStr) {
        if (!dateStr) return 'Unknown';
        const date = new Date(dateStr);
        const now = new Date();
        const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));

        if (diffDays === 0) return 'Today';
        if (diffDays === 1) return 'Yesterday';
        if (diffDays < 7) return `${diffDays}d ago`;
        if (diffDays < 30) return `${Math.floor(diffDays / 7)}w ago`;
        return `${Math.floor(diffDays / 30)}mo ago`;
    }

    createElement() {
        const card = document.createElement('div');
        card.className = 'project-card fade-in';
        card.dataset.projectId = this.project.id || this.project.name;
        card.dataset.type = this.project.type || 'unknown';

        const status = this.project.status || this.project.health || 'unknown';
        const tags = this.project.tags || (this.project.type ? [this.project.type] : []);
        const tagsHtml = tags.map(tag => `<span class="tag ${tag}">${tag}</span>`).join('');

        // Build status indicator
        const buildStatus = this.project.build_status || this.project.latest_build?.status;
        const buildStatusHtml = buildStatus 
            ? `<span class="meta-item build-status build-${buildStatus}">🔨 ${buildStatus}</span>` 
            : '';

        // Test coverage
        const coverage = this.project.test_coverage !== null && this.project.test_coverage !== undefined
            ? `<div class="coverage-indicator">
                <span class="coverage-label">📊 Coverage:</span>
                <span class="coverage-value ${this.getCoverageClass(this.project.test_coverage)}">${this.project.test_coverage.toFixed(1)}%</span>
               </div>`
            : '';

        // Real-time indicator
        const realtimeIndicator = this.project.realtime_update 
            ? '<span class="realtime-indicator" title="Real-time updates active">⚡</span>'
            : '';

        card.innerHTML = `
            <div class="project-header">
                <h3 class="project-name">${this.project.name}${realtimeIndicator}</h3>
                <span class="project-status ${this.getStatusClass(status)}">${this.getStatusLabel(status)}</span>
            </div>
            <p class="project-description">${this.project.description || ''}</p>
            <div class="project-meta">
                ${this.project.path ? `<span class="meta-item">📁 ${this.project.path}</span>` : ''}
                ${this.project.github_repo ? `<span class="meta-item">🔗 ${this.project.github_repo}</span>` : ''}
                ${this.project.last_updated || this.project.lastUpdated ? `<span class="meta-item">🕐 ${this.formatDate(this.project.last_updated || this.project.lastUpdated)}</span>` : ''}
                ${buildStatusHtml}
            </div>
            ${coverage}
            <div class="project-tags">${tagsHtml}</div>
        `;

        // Add click handler
        if (this.project.path) {
            card.addEventListener('click', () => {
                // Could open project details modal or navigate
                console.log('Project clicked:', this.project.name);
            });
        }

        this.element = card;
        return card;
    }

    getCoverageClass(coverage) {
        if (coverage >= 80) return 'coverage-high';
        if (coverage >= 60) return 'coverage-medium';
        return 'coverage-low';
    }

    update(projectData) {
        this.project = { ...this.project, ...projectData };
        if (this.element) {
            const newElement = this.createElement();
            this.element.replaceWith(newElement);
            this.element = newElement;
        }
    }

    getElement() {
        if (!this.element) {
            this.createElement();
        }
        return this.element;
    }
}

// Export for use in other modules
if (typeof window !== 'undefined') {
    window.ProjectCard = ProjectCard;
}
