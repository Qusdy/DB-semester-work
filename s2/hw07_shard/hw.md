1. RANGE секционирование (по дате покупки)
```sql
-- RANGE партиционирование по дате
CREATE TABLE purchases_partitioned (
purchase_id SERIAL,
item_id INT NOT NULL,
buyer_id INT NOT NULL,
purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
status VARCHAR(50) DEFAULT 'completed'
) PARTITION BY RANGE (purchase_date);

-- Создаем партиции по месяцам
CREATE TABLE purchases_2024_01 PARTITION OF purchases_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE purchases_2024_02 PARTITION OF purchases_partitioned
FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE purchases_2024_03 PARTITION OF purchases_partitioned
FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE purchases_2024_04 PARTITION OF purchases_partitioned
FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE purchases_default PARTITION OF purchases_partitioned DEFAULT;
```
2. LIST секционирование (по статусу)
```sql
-- LIST партиционирование по статусу
CREATE TABLE orders_partitioned (
order_id SERIAL,
purchase_id INT NOT NULL,
pvz_id INT NOT NULL,
status VARCHAR(50) NOT NULL DEFAULT 'created',
order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY LIST (status);

CREATE TABLE orders_created PARTITION OF orders_partitioned FOR VALUES IN ('created');
CREATE TABLE orders_delivered PARTITION OF orders_partitioned FOR VALUES IN ('delivered');
CREATE TABLE orders_cancelled PARTITION OF orders_partitioned FOR VALUES IN ('cancelled');
```
3. HASH секционирование (по buyer_id)
```sql
-- HASH партиционирование для равномерного распределения
CREATE TABLE buyers_partitioned (
buyer_id SERIAL,
login VARCHAR(255) NOT NULL,
password_hash VARCHAR(255) NOT NULL,
salt VARCHAR(50) NOT NULL,
preferences JSONB
) PARTITION BY HASH (buyer_id);

-- 4 партиции
CREATE TABLE buyers_part0 PARTITION OF buyers_partitioned FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE buyers_part1 PARTITION OF buyers_partitioned FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE buyers_part2 PARTITION OF buyers_partitioned FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE buyers_part3 PARTITION OF buyers_partitioned FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

---

2.1 RANGE секционирование
```sql
-- Запрос: получить покупки за март 2024
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM purchases_partitioned
WHERE purchase_date >= '2024-03-01' AND purchase_date < '2024-04-01';
```
Ответы:

Partition pruning: ДА - PostgreSQL отсекает все партиции кроме purchases_2024_03

Сколько партиций в плане: 1 из 5 (только нужная партиция)

Использование индекса: нет

```sql
-- Проверка partition pruning
EXPLAIN (ANALYZE, VERBOSE)
SELECT * FROM purchases_partitioned
WHERE purchase_date = '2024-02-15 10:00:00';
-- Результат: только purchases_2024_02
```

```
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                                                                   |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|Seq Scan on public.purchases_2024_02 purchases_partitioned  (cost=0.00..16.12 rows=2 width=138) (actual time=0.006..0.006 rows=0 loops=1)                                    |
|  Output: purchases_partitioned.purchase_id, purchases_partitioned.item_id, purchases_partitioned.buyer_id, purchases_partitioned.purchase_date, purchases_partitioned.status|
|  Filter: (purchases_partitioned.purchase_date = '2024-02-15 10:00:00'::timestamp without time zone)                                                                         |
|Planning Time: 0.157 ms                                                                                                                                                      |
|Execution Time: 0.018 ms                                                                                                                                                     |
+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```

2.2 LIST секционирование
```sql
-- Запрос: все доставленные заказы
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders_partitioned WHERE status = 'delivered';
```
Ответы:
Partition pruning: ДА - выбирает только orders_delivered

Сколько партиций в плане: 1 из 3 (только delivered)

Использование индекса: нет

```sql
+------------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                    |
+------------------------------------------------------------------------------------------------------------------------------+
|Seq Scan on orders_delivered orders_partitioned  (cost=0.00..16.12 rows=2 width=138) (actual time=0.019..0.019 rows=0 loops=1)|
|  Filter: ((status)::text = 'delivered'::text)                                                                                |
|Planning:                                                                                                                     |
|  Buffers: shared hit=38                                                                                                      |
|Planning Time: 0.188 ms                                                                                                       |
|Execution Time: 0.030 ms                                                                                                      |
+------------------------------------------------------------------------------------------------------------------------------+
```

```sql
-- Запрос с несколькими статусами
EXPLAIN (ANALYZE)
SELECT * FROM orders_partitioned WHERE status IN ('created', 'delivered');
-- Результат: 2 партиции
```

```
+--------------------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                            |
+--------------------------------------------------------------------------------------------------------------------------------------+
|Append  (cost=0.00..32.30 rows=10 width=138) (actual time=0.057..0.058 rows=0 loops=1)                                                |
|  ->  Seq Scan on orders_created orders_partitioned_1  (cost=0.00..16.12 rows=5 width=138) (actual time=0.054..0.054 rows=0 loops=1)  |
|        Filter: ((status)::text = ANY ('{created,delivered}'::text[]))                                                                |
|  ->  Seq Scan on orders_delivered orders_partitioned_2  (cost=0.00..16.12 rows=5 width=138) (actual time=0.001..0.001 rows=0 loops=1)|
|        Filter: ((status)::text = ANY ('{created,delivered}'::text[]))                                                                |
|Planning Time: 0.293 ms                                                                                                               |
|Execution Time: 0.080 ms                                                                                                              |
+--------------------------------------------------------------------------------------------------------------------------------------+
```

2.3 HASH секционирование
```sql
-- Запрос по конкретному buyer_id (хеш определяется)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM buyers_partitioned WHERE buyer_id = 12345;
```

+---------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                 |
+---------------------------------------------------------------------------------------------------------------------------+
|Seq Scan on buyers_part0 buyers_partitioned  (cost=0.00..10.75 rows=1 width=1186) (actual time=0.007..0.008 rows=0 loops=1)|
|  Filter: (buyer_id = 12345)                                                                                               |
|Planning:                                                                                                                  |
|  Buffers: shared hit=32                                                                                                   |
|Planning Time: 0.204 ms                                                                                                    |
|Execution Time: 0.023 ms                                                                                                   |
+---------------------------------------------------------------------------------------------------------------------------+

Ответы:

Partition pruning: ДА - PostgreSQL вычисляет хеш и идет в одну партицию

Сколько партиций в плане: 1 из 4

Использование индекса: нет

```sql
-- Запрос без условия на ключ партиционирования
EXPLAIN (ANALYZE)
SELECT * FROM buyers_partitioned WHERE login = 'user@mail.com';
-- Результат: все 4 партиции (нет partition pruning)
```

+-----------------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                         |
+-----------------------------------------------------------------------------------------------------------------------------------+
|Append  (cost=0.00..43.02 rows=4 width=1186) (actual time=0.010..0.010 rows=0 loops=1)                                             |
|  ->  Seq Scan on buyers_part0 buyers_partitioned_1  (cost=0.00..10.75 rows=1 width=1186) (actual time=0.004..0.004 rows=0 loops=1)|
|        Filter: ((login)::text = 'user@mail.com'::text)                                                                            |
|  ->  Seq Scan on buyers_part1 buyers_partitioned_2  (cost=0.00..10.75 rows=1 width=1186) (actual time=0.003..0.003 rows=0 loops=1)|
|        Filter: ((login)::text = 'user@mail.com'::text)                                                                            |
|  ->  Seq Scan on buyers_part2 buyers_partitioned_3  (cost=0.00..10.75 rows=1 width=1186) (actual time=0.001..0.001 rows=0 loops=1)|
|        Filter: ((login)::text = 'user@mail.com'::text)                                                                            |
|  ->  Seq Scan on buyers_part3 buyers_partitioned_4  (cost=0.00..10.75 rows=1 width=1186) (actual time=0.001..0.001 rows=0 loops=1)|
|        Filter: ((login)::text = 'user@mail.com'::text)                                                                            |
|Planning Time: 0.227 ms                                                                                                            |
|Execution Time: 0.028 ms                                                                                                           |
+-----------------------------------------------------------------------------------------------------------------------------------+

