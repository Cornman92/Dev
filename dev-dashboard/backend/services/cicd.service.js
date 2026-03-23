const Build = require('../models/Build');
const Project = require('../models/Project');
const { getDatabase } = require('../config/database');
const githubService = require('./github.service');

class CICDService {
    async syncBuildsForProject(projectId) {
        try {
            const project = await Project.findById(projectId);
            if (!project || !project.github_repo) {
                return { synced: 0, error: 'Project not found or no GitHub repo configured' };
            }

            const repoInfo = githubService.parseRepoUrl(project.github_repo);
            if (!repoInfo) {
                return { synced: 0, error: 'Invalid GitHub repository URL' };
            }

            if (!githubService.isConfigured()) {
                return { synced: 0, error: 'GitHub API not configured' };
            }

            // Get workflow runs
            const runs = await githubService.getWorkflowRuns(repoInfo.owner, repoInfo.repo);
            
            let synced = 0;
            for (const run of runs) {
                try {
                    // Check if build already exists
                    const db = getDatabase();
                    const existing = await db.get(
                        'SELECT id FROM builds WHERE project_id = ? AND build_number = ?',
                        [projectId, run.id.toString()]
                    );

                    if (existing) {
                        continue; // Already synced
                    }

                    // Determine build status
                    let status = 'pending';
                    if (run.status === 'completed') {
                        status = run.conclusion === 'success' ? 'success' : 'failure';
                        if (run.conclusion === 'cancelled') {
                            status = 'cancelled';
                        }
                    } else if (run.status === 'in_progress') {
                        status = 'running';
                    }

                    // Calculate duration
                    let durationMs = null;
                    if (run.started_at && run.completed_at) {
                        durationMs = new Date(run.completed_at) - new Date(run.started_at);
                    }

                    await Build.create({
                        project_id: projectId,
                        build_number: run.id.toString(),
                        status: status,
                        branch: run.branch,
                        commit_sha: run.commit_sha,
                        workflow_name: run.workflow_name,
                        started_at: run.started_at,
                        completed_at: run.completed_at,
                        duration_ms: durationMs,
                        url: run.url
                    });

                    synced++;
                } catch (error) {
                    console.error(`Error syncing build ${run.id}:`, error.message);
                }
            }

            return { synced, total: runs.length };
        } catch (error) {
            console.error(`Error syncing builds for project ${projectId}:`, error.message);
            return { synced: 0, error: error.message };
        }
    }

    async syncAllBuilds() {
        const projects = await Project.findAll();
        const results = [];

        for (const project of projects) {
            if (project.github_repo) {
                const result = await this.syncBuildsForProject(project.id);
                results.push({
                    project: project.name,
                    ...result
                });
            }
        }

        return results;
    }

    async getBuildStatus(projectId) {
        const latestBuild = await Build.findLatest(projectId);
        const statusCounts = await Build.getStatusCounts(projectId);

        return {
            latest: latestBuild,
            counts: statusCounts.reduce((acc, item) => {
                acc[item.status] = item.count;
                return acc;
            }, {})
        };
    }
}

module.exports = new CICDService();

