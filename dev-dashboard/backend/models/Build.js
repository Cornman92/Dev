const { getDatabase } = require('../config/database');

class Build {
    static async findAll(projectId = null) {
        const db = getDatabase();
        if (projectId) {
            return await db.query(
                'SELECT * FROM builds WHERE project_id = ? ORDER BY created_at DESC LIMIT 50',
                [projectId]
            );
        }
        return await db.query('SELECT * FROM builds ORDER BY created_at DESC LIMIT 100');
    }

    static async findById(id) {
        const db = getDatabase();
        return await db.get('SELECT * FROM builds WHERE id = ?', [id]);
    }

    static async findLatest(projectId) {
        const db = getDatabase();
        return await db.get(
            'SELECT * FROM builds WHERE project_id = ? ORDER BY created_at DESC LIMIT 1',
            [projectId]
        );
    }

    static async create(data) {
        const db = getDatabase();
        const {
            project_id,
            build_number,
            status,
            branch,
            commit_sha,
            workflow_name,
            started_at,
            completed_at,
            duration_ms,
            url
        } = data;

        const result = await db.run(
            `INSERT INTO builds (project_id, build_number, status, branch, commit_sha, workflow_name, 
             started_at, completed_at, duration_ms, url, created_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))`,
            [
                project_id,
                build_number || null,
                status,
                branch || null,
                commit_sha || null,
                workflow_name || null,
                started_at || null,
                completed_at || null,
                duration_ms || null,
                url || null
            ]
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

        values.push(id);
        await db.run(
            `UPDATE builds SET ${fields.join(', ')} WHERE id = ?`,
            values
        );

        return await this.findById(id);
    }

    static async getStatusCounts(projectId = null) {
        const db = getDatabase();
        let query = 'SELECT status, COUNT(*) as count FROM builds';
        const params = [];

        if (projectId) {
            query += ' WHERE project_id = ?';
            params.push(projectId);
        }

        query += ' GROUP BY status';
        return await db.query(query, params);
    }
}

module.exports = Build;


