/** @type {import('jest').Config} */
module.exports = {
    testEnvironment: 'node',
    testMatch: ['**/__tests__/**/*.test.js', '**/*.test.js'],
    roots: ['<rootDir>'],
    testPathIgnorePatterns: ['/node_modules/'],
    collectCoverageFrom: [
        'backend/**/*.js',
        '!backend/**/*.test.js',
        '!**/node_modules/**',
    ],
    coverageDirectory: 'coverage',
    verbose: true,
};
