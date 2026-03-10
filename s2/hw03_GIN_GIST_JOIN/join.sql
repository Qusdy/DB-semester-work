-- Индексы для JOIN запросов
CREATE INDEX idx_purchases_buyer_id ON purchases(buyer_id);
CREATE INDEX idx_purchases_item_id ON purchases(item_id);
CREATE INDEX idx_items_shop_id ON items(shop_id);
CREATE INDEX idx_orders_purchase_id ON orders(purchase_id);
CREATE INDEX idx_reviews_purchase_id ON reviews(purchase_id);

-- JOIN запрос 1: Покупки с информацией о покупателе и товаре
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    p.purchase_id,
    p.purchase_date,
    b.login AS buyer,
    i.name AS item,
    i.price
FROM purchases p
         JOIN buyers b ON p.buyer_id = b.buyer_id
         JOIN items i ON p.item_id = i.item_id
    LIMIT 20;

-- JOIN запрос 2: Заказы с адресом ПВЗ
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    o.order_id,
    o.order_date,
    o.status,
    pvz.address
FROM orders o
         JOIN pvz ON o.pvz_id = pvz.pvz_id
    LIMIT 20;

-- JOIN запрос 3: Отзывы с рейтингом и названием товара
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    r.review_id,
    r.rating,
    r.description,
    i.name AS item_name
FROM reviews r
         JOIN purchases p ON r.purchase_id = p.purchase_id
         JOIN items i ON p.item_id = i.item_id
    LIMIT 20;

-- JOIN запрос 4: Работники и их профессии
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    w.login,
    pr.name AS profession,
    pr.salary
FROM worker_assignments wa
         JOIN workers w ON wa.worker_id = w.worker_id
         JOIN profession pr ON wa.work_id = pr.profession_id
    LIMIT 20;

-- JOIN запрос 5: Товары и их категории
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    i.name AS item,
    i.price,
    c.name AS category
FROM items i
         JOIN category_of_item c ON i.category_id = c.category_id
    LIMIT 20;

-- Удаление индексов
DROP INDEX idx_purchases_buyer_id;
DROP INDEX idx_purchases_item_id;
DROP INDEX idx_items_shop_id;
DROP INDEX idx_orders_purchase_id;
DROP INDEX idx_reviews_purchase_id;