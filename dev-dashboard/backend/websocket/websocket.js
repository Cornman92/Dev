const WebSocket = require('ws');
const config = require('../config/config');

class WebSocketServer {
    constructor() {
        this.wss = null;
        this.clients = new Set();
    }

    initialize(server) {
        this.wss = new WebSocket.Server({ 
            server,
            path: '/ws'
        });

        this.wss.on('connection', (ws, req) => {
            console.log('WebSocket client connected');
            this.clients.add(ws);

            // Send welcome message
            ws.send(JSON.stringify({
                type: 'connection',
                message: 'Connected to Development Dashboard WebSocket',
                timestamp: new Date().toISOString()
            }));

            // Handle incoming messages
            ws.on('message', (message) => {
                try {
                    const data = JSON.parse(message.toString());
                    this.handleMessage(ws, data);
                } catch (error) {
                    console.error('Error parsing WebSocket message:', error);
                }
            });

            // Handle client disconnect
            ws.on('close', () => {
                console.log('WebSocket client disconnected');
                this.clients.delete(ws);
            });

            // Handle errors
            ws.on('error', (error) => {
                console.error('WebSocket error:', error);
                this.clients.delete(ws);
            });

            // Send heartbeat
            const heartbeatInterval = setInterval(() => {
                if (ws.isAlive === false) {
                    clearInterval(heartbeatInterval);
                    ws.terminate();
                    this.clients.delete(ws);
                    return;
                }
                ws.isAlive = false;
                ws.ping();
            }, config.websocket.heartbeatInterval);

            ws.on('pong', () => {
                ws.isAlive = true;
            });

            ws.on('close', () => {
                clearInterval(heartbeatInterval);
            });
        });

        console.log('WebSocket server initialized');
    }

    handleMessage(ws, data) {
        switch (data.type) {
            case 'subscribe':
                ws.subscriptions = data.topics || [];
                ws.send(JSON.stringify({
                    type: 'subscribed',
                    topics: ws.subscriptions,
                    timestamp: new Date().toISOString()
                }));
                break;
            case 'unsubscribe':
                ws.subscriptions = [];
                ws.send(JSON.stringify({
                    type: 'unsubscribed',
                    timestamp: new Date().toISOString()
                }));
                break;
            case 'ping':
                ws.send(JSON.stringify({
                    type: 'pong',
                    timestamp: new Date().toISOString()
                }));
                break;
            default:
                console.log('Unknown message type:', data.type);
        }
    }

    broadcast(event, data, topic = null) {
        const message = JSON.stringify({
            type: 'event',
            event,
            data,
            timestamp: new Date().toISOString()
        });

        this.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                // If topic is specified, check subscriptions
                if (topic && client.subscriptions) {
                    if (client.subscriptions.includes(topic) || client.subscriptions.includes('*')) {
                        client.send(message);
                    }
                } else {
                    // Send to all clients if no topic specified
                    client.send(message);
                }
            }
        });
    }

    // Convenience methods for specific events
    broadcastProjectUpdate(projectId, data) {
        this.broadcast('project:update', { projectId, ...data }, `project:${projectId}`);
    }

    broadcastBuildComplete(projectId, build) {
        this.broadcast('build:complete', { projectId, build }, `project:${projectId}`);
    }

    broadcastNewCommit(projectId, commit) {
        this.broadcast('commit:new', { projectId, commit }, `project:${projectId}`);
    }

    broadcastMetricUpdate(projectId, metric) {
        this.broadcast('metric:update', { projectId, metric }, `project:${projectId}`);
    }

    getClientCount() {
        return this.clients.size;
    }
}

module.exports = new WebSocketServer();


