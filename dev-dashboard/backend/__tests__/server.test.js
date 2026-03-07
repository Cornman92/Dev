const request = require('supertest');
const { app } = require('../server');

describe('Development Dashboard API', () => {
    describe('GET /health', () => {
        it('returns 200 with status ok and timestamp', async () => {
            const res = await request(app)
                .get('/health')
                .expect(200)
                .expect('Content-Type', /json/);

            expect(res.body).toHaveProperty('status', 'ok');
            expect(res.body).toHaveProperty('timestamp');
            expect(res.body).toHaveProperty('websocket');
            expect(res.body.websocket).toHaveProperty('connected');
        });

        it('timestamp is valid ISO string', async () => {
            const res = await request(app).get('/health').expect(200);
            expect(() => new Date(res.body.timestamp)).not.toThrow();
            expect(res.body.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
        });
    });

    describe('API routes exist', () => {
        it('GET /api/projects returns 200 or 500 when DB not initialized', async () => {
            const res = await request(app).get('/api/projects');
            expect([200, 500]).toContain(res.status);
        });
    });
});
