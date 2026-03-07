const Project = require('../models/Project');
const Commit = require('../models/Commit');
const { getDatabase } = require('../config/database');
const githubService = require('./github.service');

class ProjectService {
    async syncCommitsForProject(projectId, days = 7) {
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

            // Get branches
            const branches = await githubService.getBranches(repoInfo.owner, repoInfo.repo);
            const mainBranch = branches.find(b => b.name === 'main' || b.name === 'master')?.name || branches[0]?.name;

            if (!mainBranch) {
                return { synced: 0, error: 'No branches found' };
            }

            // Calculate since date
            const since = new Date();
            since.setDate(since.getDate() - days);
            const sinceISO = since.toISOString();

            // Get commits
            const commits = await githubService.getCommits(repoInfo.owner, repoInfo.repo, mainBranch, sinceISO);

            // Transform and save commits
            const commitsToSave = commits.map(commit => ({
                project_id: projectId,
                ...commit
            }));

            const saved = await Commit.bulkCreate(commitsToSave);

            return { synced: saved.length, total: commits.length };
        } catch (error) {
            console.error(`Error syncing commits for project ${projectId}:`, error.message);
            return { synced: 0, error: error.message };
        }
    }

    async getProjectHealth(projectId) {
        return await Project.getHealthStatus(projectId);
    }

    async getAllProjectsWithHealth() {
        const projects = await Project.findAll();
        const projectsWithHealth = await Promise.all(
            projects.map(async (project) => {
                const health = await this.getProjectHealth(project.id);
                return {
                    ...project,
                    health: health?.latestBuild || 'unknown',
                    testCoverage: health?.testCoverage || null,
                    recentCommits: health?.recentCommits || 0
                };
            })
        );
        return projectsWithHealth;
    }
}

module.exports = new ProjectService();


