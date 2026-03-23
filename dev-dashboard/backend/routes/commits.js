const express = require('express');
const router = express.Router();
const Commit = require('../models/Commit');

// Get all commits
router.get('/', async (req, res, next) => {
    try {
        const projectId = req.query.projectId ? parseInt(req.query.projectId) : null;
        const limit = parseInt(req.query.limit) || 50;
        const commits = await Commit.findAll(projectId, limit);
        res.json(commits);
    } catch (error) {
        next(error);
    }
});

// Get commits for a project
router.get('/project/:projectId', async (req, res, next) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const commits = await Commit.findAll(parseInt(req.params.projectId), limit);
        res.json(commits);
    } catch (error) {
        next(error);
    }
});

// Get recent commits for a project
router.get('/project/:projectId/recent', async (req, res, next) => {
    try {
        const days = parseInt(req.query.days) || 7;
        const commits = await Commit.getRecentCommits(parseInt(req.params.projectId), days);
        res.json(commits);
    } catch (error) {
        next(error);
    }
});

// Create commit
router.post('/', async (req, res, next) => {
    try {
        const commit = await Commit.create(req.body);
        res.status(201).json(commit);
    } catch (error) {
        next(error);
    }
});

module.exports = router;


