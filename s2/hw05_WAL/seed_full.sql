TRUNCATE TABLE
    reviews,
    orders,
    purchases,
    items,
    worker_assignments,
    workers,
    buyers,
    shops,
    category_of_item,
    profession,
    pvz,
    career_path,
    delivery_zones
CASCADE;

INSERT INTO profession (profession_id, name, salary) VALUES
                                                         (1, 'Продавец-консультант', 45000),
                                                         (2, 'Кассир', 38000),
                                                         (3, 'Администратор магазина', 55000),
                                                         (4, 'Кладовщик', 42000),
                                                         (5, 'Водитель-курьер', 48000),
                                                         (6, 'Менеджер по закупкам', 60000)
    ON CONFLICT (profession_id) DO NOTHING;
SELECT setval('profession_profession_id_seq', (SELECT MAX(profession_id) FROM profession));

INSERT INTO category_of_item (category_id, name, description, attributes) VALUES
                                                                              (1, 'Электроника', 'Бытовая техника и электроника', '{"popular": true}'),
                                                                              (2, 'Одежда', 'Мужская и женская одежда', '{"popular": true}'),
                                                                              (3, 'Книги', 'Художественная и учебная литература', '{"popular": false}'),
                                                                              (4, 'Продукты', 'Продукты питания', '{"perishable": true}')
    ON CONFLICT (category_id) DO NOTHING;
SELECT setval('category_of_item_category_id_seq', (SELECT MAX(category_id) FROM category_of_item));

INSERT INTO pvz (pvz_id, address, coordinates) VALUES
                                                   (1, 'г. Москва, ул. Тверская, д. 1', point(55.7558, 37.6176)),
                                                   (2, 'г. Санкт-Петербург, Невский пр., д. 10', point(59.9343, 30.3351)),
                                                   (3, 'г. Казань, ул. Баумана, д. 5', point(55.7963, 49.1088))
    ON CONFLICT (pvz_id) DO NOTHING;
SELECT setval('pvz_pvz_id_seq', (SELECT MAX(pvz_id) FROM pvz));

INSERT INTO workers (worker_id, login, password_hash, salt, skills) VALUES
                                                                        (1, 'owner@shops.com', md5('owner123'), 'salt_owner', '{"exp": 5}'),
                                                                        (2, 'manager@shop1.com', md5('manager123'), 'salt_mgr1', '{"exp": 3}'),
                                                                        (3, 'seller@shop1.com', md5('seller123'), 'salt_slr1', '{"exp": 2}')
    ON CONFLICT (worker_id) DO NOTHING;
SELECT setval('workers_worker_id_seq', (SELECT MAX(worker_id) FROM workers));

INSERT INTO shops (shop_id, owner_id, name, working_hours) VALUES
                                                               (1, 1, 'Магазин Электроника на Тверской',
                                                                tsrange('2024-01-01 09:00:00', '2024-01-01 21:00:00')),
                                                               (2, 1, 'Бутик Одежды на Невском',
                                                                tsrange('2024-01-01 10:00:00', '2024-01-01 22:00:00'))
    ON CONFLICT (shop_id) DO NOTHING;
SELECT setval('shops_shop_id_seq', (SELECT MAX(shop_id) FROM shops));

INSERT INTO buyers (buyer_id, login, password_hash, salt, preferences) VALUES
                                                                           (1, 'ivan@mail.com', md5('ivan123'), 'salt_ivan', '{"age": 28}'),
                                                                           (2, 'maria@mail.com', md5('maria123'), 'salt_maria', '{"age": 32}'),
                                                                           (3, 'petr@mail.com', md5('petr123'), 'salt_petr', '{"age": 45}')
    ON CONFLICT (buyer_id) DO NOTHING;
SELECT setval('buyers_buyer_id_seq', (SELECT MAX(buyer_id) FROM buyers));

INSERT INTO items (item_id, shop_id, name, category_id, price, tags) VALUES
                                                                         (1, 1, 'Смартфон XYZ', 1, 29999.99, ARRAY['новинка']),
                                                                         (2, 1, 'Ноутбук ABC', 1, 54999.99, ARRAY['распродажа']),
                                                                         (3, 2, 'Футболка хлопковая', 2, 999.99, ARRAY['лето']),
                                                                         (4, 2, 'Джинсы классические', 2, 2999.99, ARRAY['базовый'])
    ON CONFLICT (item_id) DO NOTHING;
SELECT setval('items_item_id_seq', (SELECT MAX(item_id) FROM items));

INSERT INTO worker_assignments (worker_id, place_type, place_id, work_id) VALUES
                                                                              (1, 'shop', 1, 3),
                                                                              (2, 'shop', 1, 1),
                                                                              (3, 'shop', 1, 2)
    ON CONFLICT DO NOTHING;

INSERT INTO purchases (purchase_id, item_id, buyer_id, status) VALUES
                                                                   (1, 1, 1, 'completed'),
                                                                   (2, 2, 1, 'pending'),
                                                                   (3, 3, 2, 'completed'),
                                                                   (4, 4, 3, 'cancelled')
    ON CONFLICT (purchase_id) DO NOTHING;
SELECT setval('purchases_purchase_id_seq', (SELECT MAX(purchase_id) FROM purchases));

INSERT INTO orders (order_id, purchase_id, pvz_id, status) VALUES
                                                               (1, 1, 1, 'delivered'),
                                                               (2, 2, 1, 'created'),
                                                               (3, 3, 2, 'delivered'),
                                                               (4, 4, 3, 'cancelled')
    ON CONFLICT (order_id) DO NOTHING;
SELECT setval('orders_order_id_seq', (SELECT MAX(order_id) FROM orders));

INSERT INTO reviews (review_id, purchase_id, rating, description) VALUES
                                                                      (1, 1, 5, 'Отличный смартфон! Очень доволен покупкой'),
                                                                      (2, 3, 4, 'Хорошая футболка, но маломерит')
    ON CONFLICT (review_id) DO NOTHING;
SELECT setval('reviews_review_id_seq', (SELECT MAX(review_id) FROM reviews));

INSERT INTO career_path (current_profession_id, next_profession_id) VALUES
                                                                        (2, 1),  -- Кассир -> Продавец-консультант
                                                                        (1, 3),  -- Продавец-консультант -> Администратор
                                                                        (4, 5)   -- Кладовщик -> Водитель-курьер
    ON CONFLICT DO NOTHING;

INSERT INTO delivery_zones (pvz_id, coverage_area) VALUES
                                                       (1, polygon '((55.75,37.61),(55.76,37.62),(55.75,37.63))'),
                                                       (2, polygon '((59.93,30.33),(59.94,30.34),(59.93,30.35))')
    ON CONFLICT DO NOTHING;

SELECT '=== SEED COMPLETED ===' as status;
SELECT
    table_name, rows
FROM (
    SELECT 'profession' as table_name, COUNT(*) as rows FROM profession
    UNION ALL SELECT 'category_of_item', COUNT(*) FROM category_of_item
    UNION ALL SELECT 'pvz', COUNT(*) FROM pvz
    UNION ALL SELECT 'workers', COUNT(*) FROM workers
    UNION ALL SELECT 'buyers', COUNT(*) FROM buyers
    UNION ALL SELECT 'shops', COUNT(*) FROM shops
    UNION ALL SELECT 'items', COUNT(*) FROM items
    UNION ALL SELECT 'worker_assignments', COUNT(*) FROM worker_assignments
    UNION ALL SELECT 'purchases', COUNT(*) FROM purchases
    UNION ALL SELECT 'orders', COUNT(*) FROM orders
    UNION ALL SELECT 'reviews', COUNT(*) FROM reviews
    UNION ALL SELECT 'career_path', COUNT(*) FROM career_path
    UNION ALL SELECT 'delivery_zones', COUNT(*) FROM delivery_zones
    ) t
ORDER BY table_name;