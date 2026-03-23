# Database Operations Skill

## Overview
Comprehensive database management capabilities using PostgreSQL, SQLite, and Redis MCP servers for data persistence and caching.

## Capabilities

### SQL Database Operations (PostgreSQL/SQLite)
- **Query execution**: Run SQL queries and retrieve results
- **Schema management**: Create, modify, and drop tables
- **Data manipulation**: Insert, update, and delete operations
- **Transaction management**: Handle database transactions
- **Connection management**: Multiple database connections

### NoSQL Operations (Redis)
- **Key-value operations**: Set, get, delete operations
- **Data structures**: Lists, sets, hashes, sorted sets
- **Caching strategies**: Implement efficient caching patterns
- **Pub/Sub messaging**: Real-time messaging capabilities
- **Performance monitoring**: Track Redis performance metrics

### Data Analysis
- **Aggregation queries**: Complex data analysis
- **Reporting**: Generate reports from database data
- **Data export**: Export data in various formats
- **Import operations**: Bulk data import capabilities

## Usage Examples

### PostgreSQL Operations
```sql
-- Create table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Insert data
INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');

-- Query data
SELECT * FROM users WHERE created_at > '2024-01-01';

-- Update data
UPDATE users SET email = 'newemail@example.com' WHERE id = 1;
```

### SQLite Operations
```sql
-- Create table
CREATE TABLE logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    level TEXT,
    message TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert log entry
INSERT INTO logs (level, message) VALUES ('INFO', 'Application started');

-- Query logs
SELECT * FROM logs ORDER BY timestamp DESC LIMIT 10;
```

### Redis Operations
```bash
# Basic key-value
SET user:1001 "John Doe"
GET user:1001

# List operations
LPUSH tasks "task1"
LPUSH tasks "task2"
LRANGE tasks 0 -1

# Hash operations
HSET user:1001 name "John Doe"
HSET user:1001 email "john@example.com"
HGETALL user:1001

# Set operations
SADD tags "python"
SADD tags "database"
SMEMBERS tags
```

## Best Practices
- Use parameterized queries to prevent SQL injection
- Implement proper connection pooling
- Use transactions for multi-step operations
- Index frequently queried columns
- Monitor database performance
- Regular backups and maintenance

## Configuration
- **PostgreSQL**: Docker container with persistent storage
- **SQLite**: File-based database in workspace
- **Redis**: Configurable connection URL
- **Security**: Environment-based credential management

## Integration
Works with other MCP servers for:
- **Filesystem**: Database backups and exports
- **Git**: Version control for database schemas
- **Memory**: Cache query results and connection patterns

## Data Patterns
- **Caching**: Use Redis for frequently accessed data
- **Persistence**: Use PostgreSQL for critical data
- **Logging**: Use SQLite for application logs
- **Sessions**: Store session data in Redis
- **Analytics**: Aggregate data in PostgreSQL

## Performance Optimization
- Use appropriate indexes
- Implement query caching
- Optimize database connections
- Monitor slow queries
- Use connection pooling
- Implement read replicas for high load

## Security Considerations
- Encrypt sensitive data
- Use least privilege access
- Implement audit logging
- Regular security updates
- Backup encryption
- Network security (firewalls, VPNs)
