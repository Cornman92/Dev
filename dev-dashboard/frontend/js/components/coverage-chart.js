/**
 * Test Coverage Chart Component
 * Displays test coverage trends using Chart.js
 */
class CoverageChart {
    constructor(containerId, projectId) {
        this.containerId = containerId;
        this.projectId = projectId;
        this.chart = null;
        this.container = document.getElementById(containerId);
    }

    async loadData() {
        try {
            if (typeof api !== 'undefined' && api) {
                // Fetch coverage metrics from API
                const metrics = await api.request(`/metrics/coverage/${this.projectId}`);
                return this.processData(metrics);
            }
        } catch (error) {
            console.warn('Could not load coverage data from API:', error);
        }
        return null;
    }

    processData(metrics) {
        if (!metrics || !metrics.history) {
            return null;
        }

        const labels = metrics.history.map(m => {
            const date = new Date(m.date);
            return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        });

        const coverage = metrics.history.map(m => m.coverage || 0);

        return {
            labels,
            datasets: [{
                label: 'Test Coverage %',
                data: coverage,
                borderColor: 'rgb(75, 192, 192)',
                backgroundColor: 'rgba(75, 192, 192, 0.2)',
                tension: 0.1,
                fill: true
            }]
        };
    }

    async render() {
        if (!this.container) {
            console.error(`Container ${this.containerId} not found`);
            return;
        }

        // Create canvas if it doesn't exist
        if (!this.container.querySelector('canvas')) {
            const canvas = document.createElement('canvas');
            this.container.appendChild(canvas);
        }

        const canvas = this.container.querySelector('canvas');
        const ctx = canvas.getContext('2d');

        const data = await this.loadData();

        // Destroy existing chart if it exists
        if (this.chart) {
            this.chart.destroy();
        }

        // Create new chart
        if (typeof Chart !== 'undefined') {
            this.chart = new Chart(ctx, {
                type: 'line',
                data: data || {
                    labels: [],
                    datasets: [{
                        label: 'Test Coverage %',
                        data: [],
                        borderColor: 'rgb(75, 192, 192)',
                        backgroundColor: 'rgba(75, 192, 192, 0.2)',
                        tension: 0.1,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: true,
                            position: 'top'
                        },
                        title: {
                            display: true,
                            text: 'Test Coverage Trend'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        }
                    }
                }
            });
        } else {
            console.warn('Chart.js not loaded');
            this.container.innerHTML = '<p>Chart.js not available</p>';
        }
    }

    update(data) {
        if (this.chart && data) {
            const processed = this.processData(data);
            if (processed) {
                this.chart.data = processed;
                this.chart.update();
            }
        }
    }

    destroy() {
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
    }
}

// Export for use in other modules
if (typeof window !== 'undefined') {
    window.CoverageChart = CoverageChart;
}
