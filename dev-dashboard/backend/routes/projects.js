const express = require('express');
const router = express.Router();
const Project = require('../models/Project');
const projectService = require('../services/project.service');

// Get all projects
router.get('/', async (req, res, next) => {
    try {
        const projects = await projectService.getAllProjectsWithHealth();
        res.json(projects);
    } catch (error) {
        next(error);
    }
});

// Get project by ID
router.get('/:id', async (req, res, next) => {
    try {
        const project = await Project.findById(req.params.id);
        if (!project) {
            return res.status(404).json({ error: 'Project not found' });
        }
        res.json(project);
    } catch (error) {
        next(error);
    }
});

// Get project health status
router.get('/:id/status', async (req, res, next) => {
    try {
        const health = await projectService.getProjectHealth(req.params.id);
        if (!health) {
            return res.status(404).json({ error: 'Project not found' });
        }
        res.json(health);
    } catch (error) {
        next(error);
    }
});

// Create new project
router.post('/', async (req, res, next) => {
    try {
        const { name, description, path, type, status, github_repo } = req.body;
        if (!name) {
            return res.status(400).json({ error: 'Project name is required' });
        }
        const project = await Project.create({ name, description, path, type, status, github_repo });
        res.status(201).json(project);
    } catch (error) {
        if (error.message.includes('UNIQUE constraint')) {
            return res.status(409).json({ error: 'Project with this name already exists' });
        }
        next(error);
    }
});

// Update project
router.put('/:id', async (req, res, next) => {
    try {
        const project = await Project.update(req.params.id, req.body);
        if (!project) {
            return res.status(404).json({ error: 'Project not found' });
        }
        res.json(project);
    } catch (error) {
        next(error);
    }
});

// Delete project
router.delete('/:id', async (req, res, next) => {
    try {
        await Project.delete(req.params.id);
        res.status(204).send();
    } catch (error) {
        next(error);
    }
});

// Sync commits for project
router.post('/:id/sync-commits', async (req, res, next) => {
    try {
        const days = parseInt(req.query.days) || 7;
        const result = await projectService.syncCommitsForProject(req.params.id, days);
        res.json(result);
    } catch (error) {
        next(error);
    }
});

// Get test coverage for project (2.1.1 — trend and latest)
const { getDatabase } = require('../config/database');
router.get('/:id/coverage', async (req, res, next) => {
    try {
        const db = getDatabase();
        const limit = Math.min(parseInt(req.query.limit) || 30, 365);
        const rows = await db.query(
            'SELECT id, coverage_percent, total_tests, passed_tests, failed_tests, recorded_at FROM test_coverage WHERE project_id = ? ORDER BY recorded_at DESC LIMIT ?',
            [req.params.id, limit]
        );
        const latest = rows.length ? rows[0] : null;
        res.json({ projectId: req.params.id, latest, trend: rows });
    } catch (error) {
        next(error);
    }
});

// Get deployments for project (2.1.2)
router.get('/:id/deployments', async (req, res, next) => {
    try {
        const db = getDatabase();
        const rows = await db.query(
            'SELECT * FROM deployments WHERE project_id = ? ORDER BY created_at DESC LIMIT 50',
            [req.params.id]
        );
        res.json(rows);
    } catch (error) {
        next(error);
    }
});

// Create deployment record (2.1.2 — manual or webhook)
router.post('/:id/deployments', async (req, res, next) => {
    try {
        const db = getDatabase();
        const { environment, status, version, deployed_at, deployed_by, url } = req.body || {};
        if (!environment || !status) {
            return res.status(400).json({ error: 'environment and status required' });
        }
        await db.run(
            `INSERT INTO deployments (project_id, environment, status, version, deployed_at, deployed_by, url) VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [req.params.id, environment, status || 'pending', version || null, deployed_at || null, deployed_by || null, url || null]
        );
        const row = await db.get('SELECT * FROM deployments WHERE id = last_insert_rowid()');
        res.status(201).json(row);
    } catch (error) {
        next(error);
    }
});

module.exports = router;


