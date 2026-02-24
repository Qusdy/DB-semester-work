INSERT INTO profession (name, salary, description_search)
SELECT 
    'profession_' || i,
    (random() * 100000 + 30000)::int,
    to_tsvector('russian', 'description ' || i)
FROM generate_series(1, 20) i;

INSERT INTO pvz (address, coordinates)
SELECT 
    'address_' || i,
    point(random()*100, random()*100)
FROM generate_series(1, 50) i;

INSERT INTO workers (login, password_hash, salt, skills)
SELECT 
    'worker' || i || '@mail.com',
    md5(random()::text),
    substr(md5(random()::text), 1, 8),
    CASE WHEN random() < 0.15 THEN NULL 
         ELSE jsonb_build_object('exp', floor(random()*10)) 
    END
FROM generate_series(1, 250000) i;

INSERT INTO buyers (login, password_hash, salt, preferences)
SELECT 
    'buyer' || i || '@mail.com',
    md5(random()::text),
    substr(md5(random()::text), 1, 8),
    CASE WHEN random() < 0.2 THEN NULL 
         ELSE jsonb_build_object('age', floor(random()*50+18)) 
    END
FROM generate_series(1, 200000) i;

INSERT INTO category_of_item (name, description, attributes)
SELECT 
    'category_' || i,
    'desc_' || i,
    jsonb_build_object('popular', random()<0.5)
FROM generate_series(1, 10) i;

INSERT INTO shops (owner_id, name, working_hours)
SELECT 
    floor(random() * 250000 + 1),
    'shop_' || i,
    CASE WHEN random() < 0.1 THEN NULL
         ELSE tsrange(
             '2024-01-01 09:00:00'::timestamp,
             '2024-01-01 21:00:00'::timestamp
         )
    END
FROM generate_series(1, 100) i;

INSERT INTO items (shop_id, name, description, category_id, price, tags)
SELECT 
    floor(random() * 100 + 1),
    'item_' || i,
    CASE WHEN random() < 0.2 THEN NULL ELSE 'desc' END,
    floor(random() * 10 + 1),
    (random() * 10000)::decimal(10,2),
    CASE WHEN random() < 0.2 THEN NULL 
         ELSE ARRAY['tag1', 'tag2']
    END
FROM generate_series(1, 250000) i;

INSERT INTO worker_assignments (worker_id, place_type, place_id, work_id, work_period)
SELECT 
    floor(random() * 250000 + 1),
    CASE WHEN random()<0.7 THEN 'shop' ELSE 'pvz' END,
    CASE WHEN random()<0.7 THEN floor(random()*100+1)
         ELSE floor(random()*50+1) END,
    floor(random() * 20 + 1),
    CASE WHEN random()<0.15 THEN NULL
         ELSE daterange('2024-01-01'::date, '2024-12-31'::date)
    END
FROM generate_series(1, 150000) i;

INSERT INTO purchases (item_id, buyer_id, purchase_date, status, purchase_period)
SELECT 
    floor(random() * 250000 + 1),
    floor(pow(random(),2) * 200000 + 1),
    NOW() - (random() * 365) * interval '1 day',
    CASE 
        WHEN random() < 0.8 THEN 'completed'
        WHEN random() < 0.95 THEN 'pending'
        ELSE 'cancelled'
    END,
    CASE WHEN random() < 0.1 THEN NULL
         ELSE tsrange(
             (NOW() - interval '2 days')::timestamp,
             NOW()::timestamp
         )
    END
FROM generate_series(1, 300000) i;

INSERT INTO orders (purchase_id, pvz_id, status, order_date, delivery_range)
SELECT 
    purchase_id,
    floor(pow(random(),1.5) * 50 + 1),
    CASE 
        WHEN random() < 0.7 THEN 'delivered'
        WHEN random() < 0.9 THEN 'created'
        ELSE 'cancelled'
    END,
    purchase_date + interval '1 hour',
    CASE WHEN random() < 0.15 THEN NULL
         ELSE tsrange(
             (purchase_date + interval '1 day')::timestamp,
             (purchase_date + interval '3 days')::timestamp
         )
    END
FROM purchases 
WHERE random() < 0.83
LIMIT 250000;

INSERT INTO reviews (purchase_id, rating, description, review_text)
SELECT 
    purchase_id,
    CASE 
        WHEN random() < 0.4 THEN 5
        WHEN random() < 0.6 THEN 4
        WHEN random() < 0.75 THEN 3
        WHEN random() < 0.9 THEN 2
        ELSE 1
    END,
    CASE WHEN random() < 0.2 THEN NULL ELSE 'review text' END,
    to_tsvector('russian', 'review')
FROM purchases 
WHERE random() < 0.67
LIMIT 200000;

INSERT INTO delivery_zones (pvz_id, coverage_area)
SELECT 
    floor(random() * 50 + 1),
    '((0,0),(10,0),(10,10),(0,10))'::polygon
FROM generate_series(1, 50) i;

-- Проверка
SELECT 'workers' t, count(*) from workers
union SELECT 'items', count(*) from items
union SELECT 'purchases', count(*) from purchases
union SELECT 'orders', count(*) from orders;