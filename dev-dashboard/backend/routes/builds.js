const express = require('express');
const router = express.Router();
const Build = require('../models/Build');
const cicdService = require('../services/cicd.service');

// Get all builds
router.get('/', async (req, res, next) => {
    try {
        const projectId = req.query.projectId ? parseInt(req.query.projectId) : null;
        const builds = await Build.findAll(projectId);
        res.json(builds);
    } catch (error) {
        next(error);
    }
});

// Get builds for a project
router.get('/project/:projectId', async (req, res, next) => {
    try {
        const builds = await Build.findAll(parseInt(req.params.projectId));
        res.json(builds);
    } catch (error) {
        next(error);
    }
});

// Get latest build for a project
router.get('/project/:projectId/latest', async (req, res, next) => {
    try {
        const build = await Build.findLatest(parseInt(req.params.projectId));
        if (!build) {
            return res.status(404).json({ error: 'No builds found' });
        }
        res.json(build);
    } catch (error) {
        next(error);
    }
});

// Get build status for a project
router.get('/project/:projectId/status', async (req, res, next) => {
    try {
        const status = await cicdService.getBuildStatus(parseInt(req.params.projectId));
        res.json(status);
    } catch (error) {
        next(error);
    }
});

// Create build
router.post('/', async (req, res, next) => {
    try {
        const build = await Build.create(req.body);
        res.status(201).json(build);
    } catch (error) {
        next(error);
    }
});

// Sync builds for a project
router.post('/project/:projectId/sync', async (req, res, next) => {
    try {
        const result = await cicdService.syncBuildsForProject(parseInt(req.params.projectId));
        res.json(result);
    } catch (error) {
        next(error);
    }
});

// Sync all builds
router.post('/sync-all', async (req, res, next) => {
    try {
        const results = await cicdService.syncAllBuilds();
        res.json(results);
    } catch (error) {
        next(error);
    }
});

module.exports = router;


