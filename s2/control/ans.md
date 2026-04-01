## Задание 1. Оптимизация простого запроса

Используйте таблицу `exam_events`.

Исходный запрос:

```sql
SELECT id, user_id, amount, created_at
FROM exam_events
WHERE user_id = 4242
  AND created_at >= TIMESTAMP '2025-03-10 00:00:00'
  AND created_at < TIMESTAMP '2025-03-11 00:00:00';
```

Что нужно сделать:

```text
1. Постройте план выполнения запроса до изменений.
2. Укажите:
   - какой тип сканирования использован;
   - какие из уже созданных индексов не помогают этому запросу;
   - почему планировщик выбирает именно такой план.
3. Создайте индекс, который лучше подходит под этот запрос.
4. Повторно постройте план выполнения.
5. Кратко объясните, что изменилось в плане и почему.
6. Ответьте, нужно ли после создания индекса выполнять ANALYZE, и зачем.
```

1.
```sql
   EXPLAIN (ANALYSE, BUFFERS) SELECT id, user_id, amount, created_at
   FROM exam_events
   WHERE user_id = 4242
   AND created_at >= TIMESTAMP '2025-03-10 00:00:00'
   AND created_at < TIMESTAMP '2025-03-11 00:00:00';
```
```
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                                                               |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|Seq Scan on exam_events  (cost=0.00..1617.07 rows=1 width=26) (actual time=4.887..4.889 rows=3 loops=1)                                                                  |
|  Filter: ((created_at >= '2025-03-10 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-11 00:00:00'::timestamp without time zone) AND (user_id = 4242))|
|  Rows Removed by Filter: 60001                                                                                                                                          |
|  Buffers: shared hit=567                                                                                                                                                |
|Planning:                                                                                                                                                                |
|  Buffers: shared hit=52                                                                                                                                                 |
|Planning Time: 0.200 ms                                                                                                                                                  |
|Execution Time: 4.907 ms                                                                                                                                                 |
+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```
2. Seq Scan, индекс на status и hash индекс на amount не помогают очевидно потому что нет в запросе таких полей (idx_exam_events_status, idx_exam_events_amount_hash)
3. 
```sql
CREATE INDEX idx_exam_events ON exam_events using btree(created_at);
```
4. 
```
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                                                    |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+
|Bitmap Heap Scan on exam_events  (cost=15.16..623.62 rows=1 width=26) (actual time=0.963..0.965 rows=3 loops=1)                                               |
|  Recheck Cond: ((created_at >= '2025-03-10 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-11 00:00:00'::timestamp without time zone))    |
|  Filter: (user_id = 4242)                                                                                                                                    |
|  Rows Removed by Filter: 666                                                                                                                                 |
|  Heap Blocks: exact=567                                                                                                                                      |
|  Buffers: shared hit=567 read=4                                                                                                                              |
|  ->  Bitmap Index Scan on idx_exam_events  (cost=0.00..15.16 rows=687 width=0) (actual time=0.140..0.141 rows=669 loops=1)                                   |
|        Index Cond: ((created_at >= '2025-03-10 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-11 00:00:00'::timestamp without time zone))|
|        Buffers: shared read=4                                                                                                                                |
|Planning:                                                                                                                                                     |
|  Buffers: shared hit=17 read=1                                                                                                                               |
|Planning Time: 0.374 ms                                                                                                                                       |
|Execution Time: 0.993 ms                                                                                                                                      |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------+
```
5. Использовался Bitmap Heap Scan + Bitmap Index Scan, то есть мы проходим по индексу и помечаем page'ы, чтобы потом один раз пройти по ним и достать данные быстро
B-tree ускорил, так как мы накладываем условие в запросе на > <= на created at, поэтому получили ускорение 
6. Да, так как возможно планировщик не обновился после нового индекса, а Analyze исполняет сам запрос

## Задание 2. Анализ и улучшение JOIN-запроса

Используйте таблицы `exam_users` и `exam_orders`.

Исходный запрос:

```sql
SELECT u.id, u.country, o.amount, o.created_at
FROM exam_users u
JOIN exam_orders o ON o.user_id = u.id
WHERE u.country = 'JP'
  AND o.created_at >= TIMESTAMP '2025-03-01 00:00:00'
  AND o.created_at < TIMESTAMP '2025-03-08 00:00:00';
```

Что нужно сделать:

```text
1. Постройте план выполнения запроса до изменений.
2. Определите, какой тип JOIN использован.
3. Объясните, почему планировщик выбрал именно этот тип JOIN.
4. Укажите, какие существующие индексы полезны слабо или не полезны для этого запроса.
5. Предложите и создайте одно улучшение, которое может ускорить запрос.
   Допустимые варианты: новый индекс, другой более подходящий индекс, ANALYZE.
6. Повторно постройте план выполнения.
7. Кратко поясните, улучшился ли план и за счет чего.
8. Отдельно укажите, что означает преобладание shared hit или read в BUFFERS.
```

1. 
```sql
EXPLAIN (ANALYSE, BUFFERS) SELECT u.id, u.country, o.amount, o.created_at
FROM exam_users u
JOIN exam_orders o ON o.user_id = u.id
WHERE u.country = 'JP'
AND o.created_at >= TIMESTAMP '2025-03-01 00:00:00'
AND o.created_at < TIMESTAMP '2025-03-08 00:00:00';
```
```
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                                                          |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|Hash Join  (cost=552.88..1690.19 rows=341 width=25) (actual time=7.262..11.443 rows=1000 loops=1)                                                                   |
|  Hash Cond: (o.user_id = u.id)                                                                                                                                     |
|  Buffers: shared hit=1165 read=21                                                                                                                                  |
|  ->  Bitmap Heap Scan on exam_orders o  (cost=142.38..1261.77 rows=6826 width=22) (actual time=4.292..7.038 rows=7000 loops=1)                                     |
|        Recheck Cond: ((created_at >= '2025-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-08 00:00:00'::timestamp without time zone))    |
|        Heap Blocks: exact=1017                                                                                                                                     |
|        Buffers: shared hit=1017 read=21                                                                                                                            |
|        ->  Bitmap Index Scan on idx_exam_orders_created_at  (cost=0.00..140.68 rows=6826 width=0) (actual time=4.139..4.140 rows=7000 loops=1)                     |
|              Index Cond: ((created_at >= '2025-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-08 00:00:00'::timestamp without time zone))|
|              Buffers: shared read=21                                                                                                                               |
|  ->  Hash  (cost=398.00..398.00 rows=1000 width=11) (actual time=2.943..2.946 rows=1000 loops=1)                                                                   |
|        Buckets: 1024  Batches: 1  Memory Usage: 50kB                                                                                                               |
|        Buffers: shared hit=148                                                                                                                                     |
|        ->  Seq Scan on exam_users u  (cost=0.00..398.00 rows=1000 width=11) (actual time=0.019..2.674 rows=1000 loops=1)                                           |
|              Filter: (country = 'JP'::text)                                                                                                                        |
|              Rows Removed by Filter: 19000                                                                                                                         |
|              Buffers: shared hit=148                                                                                                                               |
|Planning:                                                                                                                                                           |
|  Buffers: shared hit=80                                                                                                                                            |
|Planning Time: 0.601 ms                                                                                                                                             |
|Execution Time: 11.549 ms                                                                                                                                           |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```
2. Использовался Hash Join
3. наверное мало строк и там и там и проще сделать hash по id, может потому что id - PK
4. idx_exam_orders_created_at(created_at) - помогает по условию в where для одной таблицы, idx_exam_users_name(name) - вообще не помогает, не особо нужен, так как поле не испольуется в запросе
5. 
```sql
CREATE index idx_exam_users_country ON exam_users using hash(country);
```
6. 
```
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|QUERY PLAN                                                                                                                                                          |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|Hash Join  (cost=359.13..1496.44 rows=341 width=25) (actual time=2.508..8.983 rows=1000 loops=1)                                                                    |
|  Hash Cond: (o.user_id = u.id)                                                                                                                                     |
|  Buffers: shared hit=1197                                                                                                                                          |
|  ->  Bitmap Heap Scan on exam_orders o  (cost=142.38..1261.77 rows=6826 width=22) (actual time=1.213..5.585 rows=7000 loops=1)                                     |
|        Recheck Cond: ((created_at >= '2025-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-08 00:00:00'::timestamp without time zone))    |
|        Heap Blocks: exact=1017                                                                                                                                     |
|        Buffers: shared hit=1038                                                                                                                                    |
|        ->  Bitmap Index Scan on idx_exam_orders_created_at  (cost=0.00..140.68 rows=6826 width=0) (actual time=0.870..0.870 rows=7000 loops=1)                     |
|              Index Cond: ((created_at >= '2025-03-01 00:00:00'::timestamp without time zone) AND (created_at < '2025-03-08 00:00:00'::timestamp without time zone))|
|              Buffers: shared hit=21                                                                                                                                |
|  ->  Hash  (cost=204.25..204.25 rows=1000 width=11) (actual time=1.279..1.281 rows=1000 loops=1)                                                                   |
|        Buckets: 1024  Batches: 1  Memory Usage: 50kB                                                                                                               |
|        Buffers: shared hit=159                                                                                                                                     |
|        ->  Bitmap Heap Scan on exam_users u  (cost=43.75..204.25 rows=1000 width=11) (actual time=0.139..0.993 rows=1000 loops=1)                                  |
|              Recheck Cond: (country = 'JP'::text)                                                                                                                  |
|              Heap Blocks: exact=148                                                                                                                                |
|              Buffers: shared hit=159                                                                                                                               |
|              ->  Bitmap Index Scan on idx_exam_users_country  (cost=0.00..43.50 rows=1000 width=0) (actual time=0.100..0.100 rows=1000 loops=1)                    |
|                    Index Cond: (country = 'JP'::text)                                                                                                              |
|                    Buffers: shared hit=11                                                                                                                          |
|Planning:                                                                                                                                                           |
|  Buffers: shared hit=22                                                                                                                                            |
|Planning Time: 0.495 ms                                                                                                                                             |
|Execution Time: 9.144 ms                                                                                                                                            |
+--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```
7. ускорило поиск по country
8. shared hit - из оперативки читаем, read - из постоянной памяти 

## Задание 3. MVCC и очистка

Используйте таблицу `exam_mvcc_items`.

Последовательно выполните:

```sql
SELECT xmin, xmax, ctid, id, title, qty
FROM exam_mvcc_items
ORDER BY id;

UPDATE exam_mvcc_items
SET qty = qty + 5
WHERE id = 1;

SELECT xmin, xmax, ctid, id, title, qty
FROM exam_mvcc_items
ORDER BY id;

DELETE FROM exam_mvcc_items
WHERE id = 2;

SELECT xmin, xmax, ctid, id, title, qty
FROM exam_mvcc_items
ORDER BY id;
```

Что нужно сделать:

```text
1. Опишите, что изменилось после UPDATE с точки зрения xmin, xmax и ctid.
2. Объясните, почему в модели MVCC UPDATE не является простым "перезаписыванием" строки.
3. Объясните, что произошло после DELETE и почему строка исчезла из обычного SELECT.
4. Кратко сравните:
   - VACUUM;
   - autovacuum;
   - VACUUM FULL.
5. Отдельно укажите, какой из этих механизмов может полностью блокировать таблицу.
```

1. После update xmin изменилось с 750 а 810, ctid поменялось с (0,1) на (0, 4)
2. delete + insert вместе вроде как
3. autovacuum вроде как работает и поэтому убралось
4. vacuum ручная очистка, ничего не блокируте на запись вроде, autovacuum - обновление автоматическое, vacuum full - блокировка всех таблиц
5. Vacuum full олностью блокирует таблицу

## Задание 4. Блокировки строк

Используйте таблицу `exam_lock_items`.

Откройте две сессии к базе данных: `A` и `B`.

В сессии `A` выполните:

```sql
BEGIN;
SELECT * FROM exam_lock_items WHERE id = 1 FOR SHARE;
```

В сессии `B` выполните:

```sql
UPDATE exam_lock_items
SET qty = qty + 1
WHERE id = 1;
```

После наблюдения результата завершите сессию `A`:

```sql
ROLLBACK;
```

Затем повторите эксперимент.

В сессии `A` выполните:

```sql
BEGIN;
SELECT * FROM exam_lock_items WHERE id = 1 FOR UPDATE;
```

В сессии `B` выполните тот же запрос:

```sql
UPDATE exam_lock_items
SET qty = qty + 1
WHERE id = 1;
```

После наблюдения результата завершите сессию `A`:

```sql
ROLLBACK;
```

Что нужно сделать:

```text
1. Опишите, что происходит с UPDATE в сессии B в первом и во втором эксперименте.
2. Объясните, чем FOR SHARE отличается от FOR UPDATE по смыслу и по силе блокировки.
3. Укажите, почему обычный SELECT без FOR UPDATE/FOR SHARE ведет себя иначе.
4. Кратко поясните, где в прикладных сценариях имеет смысл использовать FOR UPDATE.
```

1. В первом эксперименте UPDATE зависает и когда Rollback делаем, запрос выполняется. Во втором эксперименте то же самое
2. For Update блокирует практически все, For Share крайне мало, вроде только for update ждет
3. select не устанавливает блокировок на строки, он работает со снимком данных
4. Если нужно чтобы транзакция точно выполнилась перед другими

## Задание 5. Секционирование и partition pruning

Используйте таблицу-источник `exam_measurements_src`.

Сначала самостоятельно создайте секционированную таблицу `exam_measurements`:

```text
1. Таблица должна быть секционирована по RANGE по полю log_date.
2. Создайте секции:
   - январь 2025;
   - февраль 2025;
   - март 2025;
   - DEFAULT.
3. Перенесите данные из exam_measurements_src в exam_measurements.
```

Постройте планы для двух запросов:

```sql
SELECT city_id, log_date, unitsales
FROM exam_measurements
WHERE log_date >= DATE '2025-02-01'
  AND log_date < DATE '2025-03-01';
```

```sql
SELECT city_id, log_date, unitsales
FROM exam_measurements
WHERE city_id = 10;
```

Что нужно сделать:

```text
1. Для каждого запроса укажите, есть ли partition pruning.
2. Для каждого запроса укажите, сколько секций участвует в плане.
3. Объясните, почему в одном случае планировщик может отсечь секции, а в другом — нет.
4. Ответьте, связан ли pruning напрямую с наличием обычного индекса.
5. Кратко объясните, зачем в этом задании нужна секция DEFAULT.
```

0. 
```sql
CREATE TABLE exam_measurements (
                                   city_id INTEGER NOT NULL,
                                   log_date DATE NOT NULL,
                                   peaktemp INTEGER,
                                   unitsales INTEGER
) PARTITION BY RANGE (log_date);

CREATE TABLE exam_measurements_2025_01 PARTITION OF exam_measurements
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE exam_measurements_2025_02 PARTITION OF exam_measurements
    FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE exam_measurements_2025_03 PARTITION OF exam_measurements
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE exam_measurements_default PARTITION OF exam_measurements
    DEFAULT;

INSERT INTO exam_measurements
SELECT * FROM exam_measurements_src;
```
