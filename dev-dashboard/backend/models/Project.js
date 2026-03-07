const { getDatabase } = require('../config/database');

class Project {
    static async findAll() {
        const db = getDatabase();
        return await db.query('SELECT * FROM projects ORDER BY name');
    }

    static async findById(id) {
        const db = getDatabase();
        return await db.get('SELECT * FROM projects WHERE id = ?', [id]);
    }

    static async findByName(name) {
        const db = getDatabase();
        return await db.get('SELECT * FROM projects WHERE name = ?', [name]);
    }

    static async create(data) {
        const db = getDatabase();
        const { name, description, path, type, status, github_repo } = data;
        const result = await db.run(
            `INSERT INTO projects (name, description, path, type, status, github_repo, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))`,
            [name, description || null, path || null, type || null, status || 'healthy', github_repo || null]
        );
        return await this.findById(result.id);
    }

    static async update(id, data) {
        const db = getDatabase();
        const fields = [];
        const values = [];

        Object.keys(data).forEach(key => {
            if (key !== 'id' && data[key] !== undefined) {
                fields.push(`${key} = ?`);
                values.push(data[key]);
            }
        });

        if (fields.length === 0) {
            return await this.findById(id);
        }

        fields.push(`updated_at = datetime('now')`);
        values.push(id);

        await db.run(
            `UPDATE projects SET ${fields.join(', ')} WHERE id = ?`,
            values
        );

        return await this.findById(id);
    }

    static async delete(id) {
        const db = getDatabase();
        await db.run('DELETE FROM projects WHERE id = ?', [id]);
        return true;
    }

    static async getHealthStatus(id) {
        const db = getDatabase();
        const project = await this.findById(id);
        if (!project) return null;

        // Get latest build status
        const latestBuild = await db.get(
            'SELECT status FROM builds WHERE project_id = ? ORDER BY created_at DESC LIMIT 1',
            [id]
        );

        // Get test coverage
        const latestCoverage = await db.get(
            'SELECT * FROM test_coverage WHERE project_id = ? ORDER BY recorded_at DESC LIMIT 1',
            [id]
        );

        // Get recent commits count
        const recentCommits = await db.get(
            `SELECT COUNT(*) as count FROM commits 
             WHERE project_id = ? AND created_at > datetime('now', '-7 days')`,
            [id]
        );

        return {
            project,
            latestBuild: latestBuild?.status || 'unknown',
            testCoverage: latestCoverage?.coverage_percent || null,
            recentCommits: recentCommits?.count || 0,
            health: project.status
        };
    }
}

module.exports = Project;


