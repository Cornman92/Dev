const axios = require('axios');
const config = require('../config/config');

class GitHubService {
    constructor() {
        this.api = axios.create({
            baseURL: config.github.apiBase,
            headers: {
                'Authorization': config.github.token ? `token ${config.github.token}` : undefined,
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'Development-Dashboard/1.0'
            },
            timeout: 10000
        });

        // Response interceptor for rate limiting
        this.api.interceptors.response.use(
            response => response,
            async error => {
                if (error.response?.status === 403 && error.response?.headers['x-ratelimit-remaining'] === '0') {
                    const resetTime = error.response.headers['x-ratelimit-reset'];
                    console.warn(`GitHub API rate limit exceeded. Resets at: ${new Date(resetTime * 1000)}`);
                    throw new Error('GitHub API rate limit exceeded');
                }
                throw error;
            }
        );
    }

    async getRepositories(org) {
        try {
            const response = await this.api.get(`/orgs/${org}/repos`, {
                params: {
                    per_page: 100,
                    sort: 'updated',
                    direction: 'desc'
                }
            });
            return response.data;
        } catch (error) {
            console.error('Error fetching repositories:', error.message);
            throw error;
        }
    }

    async getCommits(owner, repo, branch = 'main', since = null, perPage = 30) {
        try {
            const params = {
                sha: branch,
                per_page: perPage
            };
            if (since) {
                params.since = since;
            }

            const response = await this.api.get(`/repos/${owner}/${repo}/commits`, { params });
            return response.data.map(commit => ({
                sha: commit.sha,
                message: commit.commit.message.split('\n')[0], // First line only
                author: commit.commit.author.name,
                author_email: commit.commit.author.email,
                created_at: commit.commit.author.date,
                url: commit.html_url,
                branch: branch
            }));
        } catch (error) {
            console.error(`Error fetching commits for ${owner}/${repo}:`, error.message);
            throw error;
        }
    }

    async getBranches(owner, repo) {
        try {
            const response = await this.api.get(`/repos/${owner}/${repo}/branches`, {
                params: {
                    per_page: 100
                }
            });
            return response.data.map(branch => ({
                name: branch.name,
                commit_sha: branch.commit.sha,
                commit_url: branch.commit.url
            }));
        } catch (error) {
            console.error(`Error fetching branches for ${owner}/${repo}:`, error.message);
            throw error;
        }
    }

    async getWorkflowRuns(owner, repo, branch = null) {
        try {
            const params = {
                per_page: 10
            };
            if (branch) {
                params.branch = branch;
            }

            const response = await this.api.get(`/repos/${owner}/${repo}/actions/runs`, { params });
            return response.data.workflow_runs.map(run => ({
                id: run.id,
                name: run.name,
                status: run.status,
                conclusion: run.conclusion,
                branch: run.head_branch,
                commit_sha: run.head_sha,
                workflow_name: run.name,
                started_at: run.created_at,
                completed_at: run.updated_at,
                url: run.html_url,
                workflow_id: run.workflow_id
            }));
        } catch (error) {
            console.error(`Error fetching workflow runs for ${owner}/${repo}:`, error.message);
            throw error;
        }
    }

    async getPullRequests(owner, repo, state = 'open') {
        try {
            const response = await this.api.get(`/repos/${owner}/${repo}/pulls`, {
                params: {
                    state: state,
                    per_page: 30,
                    sort: 'updated',
                    direction: 'desc'
                }
            });
            return response.data.map(pr => ({
                number: pr.number,
                title: pr.title,
                state: pr.state,
                author: pr.user.login,
                branch: pr.head.ref,
                base_branch: pr.base.ref,
                created_at: pr.created_at,
                updated_at: pr.updated_at,
                url: pr.html_url,
                mergeable: pr.mergeable
            }));
        } catch (error) {
            console.error(`Error fetching pull requests for ${owner}/${repo}:`, error.message);
            throw error;
        }
    }

    parseRepoUrl(repoUrl) {
        // Parse GitHub URL or repo name like "owner/repo"
        if (repoUrl.includes('github.com')) {
            const match = repoUrl.match(/github\.com\/([^\/]+)\/([^\/]+)/);
            if (match) {
                return { owner: match[1], repo: match[2].replace(/\.git$/, '') };
            }
        } else if (repoUrl.includes('/')) {
            const parts = repoUrl.split('/');
            return { owner: parts[0], repo: parts[1].replace(/\.git$/, '') };
        }
        return null;
    }

    isConfigured() {
        return !!config.github.token;
    }
}

module.exports = new GitHubService();


