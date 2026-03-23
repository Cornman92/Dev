const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');

const config = require('./config/config');
const { getDatabase } = require('./config/database');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');
const requestLogger = require('./middleware/logger');
const websocketServer = require('./websocket/websocket');

// Routes
const projectsRouter = require('./routes/projects');
const buildsRouter = require('./routes/builds');
const commitsRouter = require('./routes/commits');
const workspaceRouter = require('./routes/workspace');

const app = express();
const server = http.createServer(app);

// Initialize WebSocket
websocketServer.initialize(server);

// Middleware
app.use(helmet({
    contentSecurityPolicy: false // Allow inline scripts for simplicity
}));
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

// Rate limiting
const limiter = rateLimit({
    windowMs: config.security.rateLimit.windowMs,
    max: config.security.rateLimit.maxRequests,
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        websocket: {
            connected: websocketServer.getClientCount()
        }
    });
});

// API Routes
app.use('/api/projects', projectsRouter);
app.use('/api/builds', buildsRouter);
app.use('/api/commits', commitsRouter);
app.use('/api', workspaceRouter);

// Serve static files from root (for CSS, JS, images, etc.)
const rootPath = path.join(__dirname, '..');
app.use(express.static(rootPath));

// Serve frontend JS files with correct path
app.use('/frontend', express.static(path.join(rootPath, 'frontend')));

// Serve index.html for all non-API routes
app.get('*', (req, res) => {
    if (req.path.startsWith('/api')) {
        return notFoundHandler(req, res);
    }
    // Serve index.html from root
    res.sendFile(path.join(rootPath, 'index.html'));
});

// Error handling
app.use(notFoundHandler);
app.use(errorHandler);

// Initialize database and start server
async function start() {
    try {
        // Initialize database
        const db = getDatabase();
        await db.initialize();

        // Start server
        server.listen(config.port, () => {
            console.log(`
╔═══════════════════════════════════════════════════════╗
║   Development Dashboard Server                        ║
╠═══════════════════════════════════════════════════════╣
║   Server:     http://localhost:${config.port}${' '.repeat(21 - config.port.toString().length)}║
║   WebSocket:  ws://localhost:${config.port}/ws${' '.repeat(18 - config.port.toString().length)}║
║   Environment: ${config.nodeEnv}${' '.repeat(32 - config.nodeEnv.length)}║
╚═══════════════════════════════════════════════════════╝
            `);
        });

        // Graceful shutdown
        process.on('SIGTERM', async () => {
            console.log('SIGTERM received, shutting down gracefully...');
            await db.close();
            server.close(() => {
                console.log('Server closed');
                process.exit(0);
            });
        });

        process.on('SIGINT', async () => {
            console.log('\nSIGINT received, shutting down gracefully...');
            await db.close();
            server.close(() => {
                console.log('Server closed');
                process.exit(0);
            });
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Only start server when run directly (not when required by tests)
if (require.main === module) {
    start();
}

module.exports = { app, server };


