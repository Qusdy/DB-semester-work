### Сами запросы которые выполнялись можно посмотреть в explain_index.sql (там после запроса индекс удаляется сразу)
# 1 запрос
## Цена > 20000
```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM items WHERE price > 20000;
```

```sql
CREATE INDEX idx_items_price_btree ON items USING btree(price);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM items WHERE price > 20000;
```

```sql
CREATE INDEX idx_items_price_hash ON items USING hash(price);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM items WHERE price > 20000;
```


# 2 Запрос
## Провека завершен ли заказ (поле с низкой селективностью)

```sql
-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';
```

```sql
-- Создание B-tree индекса
CREATE INDEX idx_purchases_status_btree ON purchases USING btree(status);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';
```

```sql
-- Создание Hash индекса
CREATE INDEX idx_purchases_status_hash ON purchases USING hash(status);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';
```

# 3 Запрос

```sql
-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);
```

```sql
-- Создание B-tree индекса
CREATE INDEX idx_worker_assignments_work_id_btree ON worker_assignments USING btree(work_id);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);
```

```sql
-- Создание Hash индекса
CREATE INDEX idx_worker_assignments_work_id_hash ON worker_assignments USING hash(work_id);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);
```

# 4 Запрос

```sql
-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';
```

```sql
-- Создание B-tree индекса
CREATE INDEX idx_workers_login_btree ON workers USING btree(login);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';
```

```sql
-- Создание Hash индекса
CREATE INDEX idx_workers_login_hash ON workers USING hash(login);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';
```

# 5 Запрос

```sql
-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';
```

```sql
-- Создание B-tree индекса
CREATE INDEX idx_buyers_login_btree ON buyers USING btree(login);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';
```

```sql
-- Создание Hash индекса
CREATE INDEX idx_buyers_login_hash ON buyers USING hash(login);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';
```