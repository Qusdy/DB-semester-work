CREATE USER replicator WITH REPLICATION PASSWORD 'pass';

-- Создание схемы marketplace
CREATE SCHEMA IF NOT EXISTS marketplace;

-- Предоставление прав
GRANT USAGE ON SCHEMA marketplace TO replicator;
GRANT CREATE ON SCHEMA marketplace TO replicator;