const { getDatabase } = require('../config/database');

class Commit {
    static async findAll(projectId = null, limit = 50) {
        const db = getDatabase();
        if (projectId) {
            return await db.query(
                `SELECT * FROM commits 
                 WHERE project_id = ? 
                 ORDER BY created_at DESC 
                 LIMIT ?`,
                [projectId, limit]
            );
        }
        return await db.query(
            `SELECT * FROM commits 
             ORDER BY created_at DESC 
             LIMIT ?`,
            [limit]
        );
    }

    static async findById(id) {
        const db = getDatabase();
        return await db.get('SELECT * FROM commits WHERE id = ?', [id]);
    }

    static async findBySha(projectId, sha) {
        const db = getDatabase();
        return await db.get('SELECT * FROM commits WHERE project_id = ? AND sha = ?', [projectId, sha]);
    }

    static async create(data) {
        const db = getDatabase();
        const {
            project_id,
            sha,
            message,
            author,
            author_email,
            branch,
            created_at,
            url
        } = data;

        try {
            const result = await db.run(
                `INSERT INTO commits (project_id, sha, message, author, author_email, branch, created_at, url, synced_at)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))`,
                [
                    project_id,
                    sha,
                    message || null,
                    author || null,
                    author_email || null,
                    branch || null,
                    created_at || new Date().toISOString(),
                    url || null
                ]
            );
            return await this.findById(result.id);
        } catch (error) {
            // Ignore unique constraint errors (commit already exists)
            if (error.message.includes('UNIQUE constraint')) {
                return await this.findBySha(project_id, sha);
            }
            throw error;
        }
    }

    static async bulkCreate(commits) {
        const results = [];
        for (const commit of commits) {
            try {
                const created = await this.create(commit);
                results.push(created);
            } catch (error) {
                // Continue on error
                console.error('Error creating commit:', error.message);
            }
        }
        return results;
    }

    static async getRecentCommits(projectId, days = 7) {
        const db = getDatabase();
        return await db.query(
            `SELECT * FROM commits 
             WHERE project_id = ? AND created_at > datetime('now', '-${days} days')
             ORDER BY created_at DESC`,
            [projectId]
        );
    }
}

module.exports = Commit;


