import { defineConfig } from 'vitest/config';

export default defineConfig({
    resolve: {
        extensions: ['.ts', '.js', '.json'],
    },
    test: {
        globals: true,
        testTimeout: 15000,
        alias: {
            '../src/': new URL('./src/', import.meta.url).pathname,
        },
        coverage: {
            provider: 'v8',
            include: ['src/**/*.ts'],
            exclude: ['src/index.ts', 'src/**/*.test.ts', 'src/**/*.spec.ts'],
            thresholds: {
                statements: 90,
                branches: 80,
                functions: 90,
                lines: 90,
            },
        },
    },
});
