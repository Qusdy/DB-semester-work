-- Без индекса
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM items WHERE price > 20000;

-- Создание B-tree индекса
CREATE INDEX idx_items_price_btree ON items USING btree(price);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM items 
WHERE price > 20000;

-- Удаление B-tree индекса
DROP INDEX idx_items_price_btree;

-- Создание Hash индекса
CREATE INDEX idx_items_price_hash ON items USING hash(price);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM items 
WHERE price > 20000;

-- Удаление Hash индекса
DROP INDEX idx_items_price_hash;


-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';

-- Создание B-tree индекса
CREATE INDEX idx_purchases_status_btree ON purchases USING btree(status);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';

-- Удаление B-tree индекса
DROP INDEX idx_purchases_status_btree;

-- Создание Hash индекса
CREATE INDEX idx_purchases_status_hash ON purchases USING hash(status);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';

-- Удаление Hash индекса
DROP INDEX idx_purchases_status_hash;



-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);

-- Создание B-tree индекса
CREATE INDEX idx_worker_assignments_work_id_btree ON worker_assignments USING btree(work_id);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);

-- Удаление B-tree индекса
DROP INDEX idx_worker_assignments_work_id_btree;

-- Создание Hash индекса
CREATE INDEX idx_worker_assignments_work_id_hash ON worker_assignments USING hash(work_id);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);

-- Удаление Hash индекса
DROP INDEX idx_worker_assignments_work_id_hash;



-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';

-- Создание B-tree индекса
CREATE INDEX idx_workers_login_btree ON workers USING btree(login);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';

-- Удаление B-tree индекса
DROP INDEX idx_workers_login_btree;

-- Создание Hash индекса
CREATE INDEX idx_workers_login_hash ON workers USING hash(login);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';

-- Удаление Hash индекса
DROP INDEX idx_workers_login_hash;



-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';

-- Создание B-tree индекса
CREATE INDEX idx_buyers_login_btree ON buyers USING btree(login);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';

-- Удаление B-tree индекса
DROP INDEX idx_buyers_login_btree;

-- Создание Hash индекса
CREATE INDEX idx_buyers_login_hash ON buyers USING hash(login);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';

-- Удаление Hash индекса
DROP INDEX idx_buyers_login_hash;