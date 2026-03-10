-- GIN индекс 1: Полнотекстовый поиск по профессиям
CREATE INDEX idx_profession_description_gin ON profession USING GIN(description_search);
-- GIN индекс 2: Полнотекстовый поиск по отзывам
CREATE INDEX idx_reviews_text_gin ON reviews USING GIN(review_text);
-- GIN индекс 3: JSONB поиск по навыкам работников
CREATE INDEX idx_workers_skills_gin ON workers USING GIN(skills);
-- GIN индекс 4: JSONB поиск по предпочтениям покупателей
CREATE INDEX idx_buyers_preferences_gin ON buyers USING GIN(preferences);
-- GIN индекс 5: JSONB поиск по атрибутам категорий
CREATE INDEX idx_category_attributes_gin ON category_of_item USING GIN(attributes);

-- GIN запрос 1: Поиск профессий с ключевым словом в описании
EXPLAIN (ANALYZE, BUFFERS)
SELECT profession_id, name, salary
FROM profession
WHERE description_search @@ to_tsquery('russian', 'description & 15');

-- GIN запрос 2: Поиск работников с опытом 5 лет
EXPLAIN (ANALYZE, BUFFERS)
SELECT worker_id, login, skills->>'exp' as experience
FROM workers
WHERE skills @> '{"exp": 5}';

-- GIN запрос 3: Поиск покупателей с возрастом 25 лет
EXPLAIN (ANALYZE, BUFFERS)
SELECT buyer_id, login, preferences->>'age' as age
FROM buyers
WHERE preferences @> '{"age": 25}';

-- GIN запрос 4: Поиск популярных категорий товаров
EXPLAIN (ANALYZE, BUFFERS)
SELECT category_id, name, attributes
FROM category_of_item
WHERE attributes @> '{"popular": true}';

-- GIN запрос 5: Полнотекстовый поиск по отзывам
EXPLAIN (ANALYZE, BUFFERS)
SELECT review_id, purchase_id, rating
FROM reviews
WHERE review_text @@ to_tsquery('russian', 'review');

-- Удаление GIN индексов
DROP INDEX idx_profession_description_gin;
DROP INDEX idx_reviews_text_gin;
DROP INDEX idx_workers_skills_gin;
DROP INDEX idx_buyers_preferences_gin;
DROP INDEX idx_category_attributes_gin;

-- GiST индекс 1: Пространственный поиск по координатам ПВЗ
CREATE INDEX idx_pvz_coordinates_gist ON pvz USING GIST(coordinates);
-- GiST индекс 2: Поиск по времени работы магазинов
CREATE INDEX idx_shops_hours_gist ON shops USING GIST(working_hours);
-- GiST индекс 3: Поиск по периодам работы сотрудников
CREATE INDEX idx_worker_period_gist ON worker_assignments USING GIST(work_period);
-- GiST индекс 4: Поиск по периодам покупок
CREATE INDEX idx_purchases_period_gist ON purchases USING GIST(purchase_period);
-- GiST индекс 5: Поиск по периодам доставки заказов
CREATE INDEX idx_orders_delivery_gist ON orders USING GIST(delivery_range);

-- Добавление дополнительных данных для репрезентативности
INSERT INTO pvz (address, coordinates)
SELECT 'address_' || i, point(random()*1000, random()*1000)
FROM generate_series(51, 500) i;

INSERT INTO shops (owner_id, name, working_hours)
SELECT floor(random() * 250000 + 1), 'shop_' || i,
       CASE WHEN random() < 0.7 THEN
                tsrange(
                        ('2024-01-01 ' || (8 + floor(random()*4))::int || ':00:00')::timestamp,
                        ('2024-01-01 ' || (18 + floor(random()*4))::int || ':00:00')::timestamp
                )
            ELSE NULL END
FROM generate_series(101, 1000) i;

-- GiST запрос 1: Поиск ПВЗ в радиусе 50 от точки (500,500)
EXPLAIN (ANALYZE, BUFFERS)
SELECT pvz_id, address, coordinates
FROM pvz
WHERE coordinates <-> point(500, 500) < 50;

-- GiST запрос 2: Поиск магазинов, работающих в 20:00
EXPLAIN (ANALYZE, BUFFERS)
SELECT shop_id, name, working_hours
FROM shops
WHERE working_hours @> '2024-01-01 20:00:00'::timestamp;

-- GiST запрос 3: Поиск сотрудников, работавших летом 2024
EXPLAIN (ANALYZE, BUFFERS)
SELECT worker_id, place_type, work_period
FROM worker_assignments
WHERE work_period && daterange('2024-06-01', '2024-08-01');

-- GiST запрос 4: Поиск покупок за 15 января 2024
EXPLAIN (ANALYZE, BUFFERS)
SELECT purchase_id, item_id, buyer_id, purchase_period
FROM purchases
WHERE purchase_period @> '2024-01-15 00:00:00'::timestamp
  AND purchase_period @> '2024-01-15 23:59:59'::timestamp;

-- GiST запрос 5: Поиск заказов с доставкой в выходные дни
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, purchase_id, pvz_id, delivery_range
FROM orders
WHERE EXTRACT(DOW FROM lower(delivery_range)) IN (0, 6)
  AND delivery_range IS NOT NULL;

-- Удаление GiST индексов
DROP INDEX idx_pvz_coordinates_gist;
DROP INDEX idx_shops_hours_gist;
DROP INDEX idx_worker_period_gist;
DROP INDEX idx_purchases_period_gist;
DROP INDEX idx_orders_delivery_gist;