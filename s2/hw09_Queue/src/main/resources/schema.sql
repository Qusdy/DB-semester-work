DROP TABLE IF EXISTS tasks^^
DROP TABLE IF EXISTS orders^^

CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    item_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW()
)^^

CREATE TABLE tasks (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    task_type VARCHAR(50) NOT NULL,
    priority INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'READY',
    attempts INT DEFAULT 0,
    max_attempts INT DEFAULT 3,
    created_at TIMESTAMP DEFAULT NOW(),
    scheduled_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT,
    version BIGINT DEFAULT 0
) WITH (
      autovacuum_vacuum_scale_factor = 0.01,
      autovacuum_vacuum_threshold = 50
  )^^

CREATE INDEX idx_tasks_queue ON tasks (priority DESC, scheduled_at ASC) WHERE status = 'READY'^^

CREATE OR REPLACE FUNCTION notify_new_task() RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('new_task_channel', NEW.id::text);
RETURN NEW;
END;
$$ LANGUAGE plpgsql^^

CREATE TRIGGER trg_notify_new_task
    AFTER INSERT ON tasks
    FOR EACH ROW EXECUTE FUNCTION notify_new_task()^^