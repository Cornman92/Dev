require('dotenv').config();
const path = require('path');

const config = {
    // Server
    port: process.env.PORT || 3000,
    nodeEnv: process.env.NODE_ENV || 'development',
    websocketPort: process.env.WEBSOCKET_PORT || 3001,

    // GitHub
    github: {
        token: process.env.GITHUB_TOKEN || '',
        org: process.env.GITHUB_ORG || '',
        apiBase: process.env.GITHUB_API_BASE || 'https://api.github.com',
        rateLimit: {
            requests: 5000,
            window: 3600000 // 1 hour
        }
    },

    // Database
    database: {
        path: process.env.DATABASE_PATH || path.join(__dirname, '../../database/dashboard.db')
    },

    // Security
    security: {
        jwtSecret: process.env.JWT_SECRET || 'development-secret-change-in-production',
        sessionSecret: process.env.SESSION_SECRET || 'development-session-secret',
        rateLimit: {
            windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000, // 15 minutes
            maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
        }
    },

    // Intervals (in milliseconds)
    intervals: {
        commitSync: parseInt(process.env.COMMIT_SYNC_INTERVAL) || 300000, // 5 minutes
        buildSync: parseInt(process.env.BUILD_SYNC_INTERVAL) || 60000, // 1 minute
        metricsUpdate: parseInt(process.env.METRICS_UPDATE_INTERVAL) || 60000 // 1 minute
    },

    // WebSocket
    websocket: {
        heartbeatInterval: parseInt(process.env.WS_HEARTBEAT_INTERVAL) || 30000, // 30 seconds
        reconnectDelay: parseInt(process.env.WS_RECONNECT_DELAY) || 5000 // 5 seconds
    },

    // Paths
    paths: {
        root: path.join(__dirname, '../..'),
        database: path.join(__dirname, '../../database'),
        frontend: path.join(__dirname, '../../frontend'),
        // Workspace root (parent of dashboard); override with WORKSPACE_ROOT env
        workspaceRoot: process.env.WORKSPACE_ROOT || path.join(__dirname, '../..', '..')
    }
};

// Validate required configuration
if (config.nodeEnv === 'production') {
    if (!config.github.token) {
        console.warn('WARNING: GITHUB_TOKEN not set. GitHub integration will be disabled.');
    }
    if (config.security.jwtSecret === 'development-secret-change-in-production') {
        console.warn('WARNING: JWT_SECRET using default value. Change in production!');
    }
}

module.exports = config;


