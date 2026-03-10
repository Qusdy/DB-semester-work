### Сами запросы которые выполнялись можно посмотреть в explain_index.sql (там после запроса индекс удаляется сразу)
# 1 запрос
## Цена > 20000
```sql
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM items WHERE price > 20000;
```

<img width="1164" height="303" alt="image" src="https://github.com/user-attachments/assets/9ef0b289-4651-4b5f-89be-3ce6aca147a6" />


```sql
CREATE INDEX idx_items_price_btree ON items USING btree(price);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM items WHERE price > 20000;
```

<img width="1169" height="301" alt="image" src="https://github.com/user-attachments/assets/0ecc00a5-1cc0-4214-b9cb-31206721f7e1" />


```sql
CREATE INDEX idx_items_price_hash ON items USING hash(price);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM items WHERE price > 20000;
```

<img width="1237" height="305" alt="image" src="https://github.com/user-attachments/assets/47ac6c91-b37e-4934-8fdf-b7a2c3262a1b" />

# 2 Запрос
## Провека завершен ли заказ (поле с низкой селективностью)

```sql
-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';
```

<img width="1175" height="306" alt="image" src="https://github.com/user-attachments/assets/1f5e68b8-8198-4e92-9f2a-56a14ddc6bbc" />

```sql
-- Создание B-tree индекса
CREATE INDEX idx_purchases_status_btree ON purchases USING btree(status);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';
```

<img width="1115" height="309" alt="image" src="https://github.com/user-attachments/assets/57b659c4-9640-4640-8f43-3931bedf29a6" />

```sql
-- Создание Hash индекса
CREATE INDEX idx_purchases_status_hash ON purchases USING hash(status);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases 
WHERE status = 'completed';
```

<img width="1127" height="305" alt="image" src="https://github.com/user-attachments/assets/72220cbd-c102-4d7a-bc7e-00e63c27bed7" />


# 3 Запрос
## Запрос  с IN
```sql
-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);
```

<img width="1123" height="301" alt="image" src="https://github.com/user-attachments/assets/e8d3a68c-598d-4f9a-836a-cfbbd72baedf" />

```sql
-- Создание B-tree индекса
CREATE INDEX idx_worker_assignments_work_id_btree ON worker_assignments USING btree(work_id);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);
```

<img width="1126" height="310" alt="image" src="https://github.com/user-attachments/assets/69c7f0ef-159d-468e-8f25-3002f8a9a94f" />

```sql
-- Создание Hash индекса
CREATE INDEX idx_worker_assignments_work_id_hash ON worker_assignments USING hash(work_id);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM worker_assignments 
WHERE work_id IN (5, 10, 15, 20);
```

<img width="1593" height="403" alt="image" src="https://github.com/user-attachments/assets/1ca3b8f4-a7b2-4fab-8865-f647959e7750" />

# 4 Запрос
## %... запрос
```sql
-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';
```

<img width="1134" height="302" alt="image" src="https://github.com/user-attachments/assets/ce0b5141-33d2-417b-a3e6-c67537792904" />

```sql
-- Создание B-tree индекса
CREATE INDEX idx_workers_login_btree ON workers USING btree(login);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';
```

<img width="1138" height="302" alt="image" src="https://github.com/user-attachments/assets/d3637a5f-2e5d-4ba3-aedf-781edcb15160" />

```sql
-- Создание Hash индекса
CREATE INDEX idx_workers_login_hash ON workers USING hash(login);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM workers 
WHERE login LIKE '%1@mail.com';
```

<img width="1129" height="301" alt="image" src="https://github.com/user-attachments/assets/53bd6384-4f9d-421e-8d3c-056a00463723" />

# 5 Запрос
## ...% Запрос
```sql
-- Без индекса
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';
```

<img width="1130" height="304" alt="image" src="https://github.com/user-attachments/assets/345f0e4c-9bad-484e-92fe-274af6b20399" />

```sql
-- Создание B-tree индекса
CREATE INDEX idx_buyers_login_btree ON buyers USING btree(login);

-- С B-tree индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';
```

<img width="1118" height="305" alt="image" src="https://github.com/user-attachments/assets/1f8a1b80-76b4-46ba-a331-1b2bd786abf0" />

```sql
-- Создание Hash индекса
CREATE INDEX idx_buyers_login_hash ON buyers USING hash(login);

-- С Hash индексом
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers 
WHERE login LIKE 'buyer10%';
```

<img width="1124" height="307" alt="image" src="https://github.com/user-attachments/assets/6663e434-0b51-4721-a9c1-8df6b7f7ed1c" />
