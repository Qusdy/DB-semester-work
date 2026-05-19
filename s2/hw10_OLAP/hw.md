# Выбранные аналитические вопросы
Динамика активности по дням — сколько покупок, заказов и отзывов происходит в день.

Самые популярные категории товаров — какие категории приносят больше всего продаж (по количеству и сумме).

Конверсия между статусами заказов — сколько заказов переходят из created в delivered, а сколько отменяются.

Главный факт: fact_sales (продажи/покупки)

Зерно факта:
1 строка = одна позиция заказа (один купленный товар в рамках одной покупки)

таблицы в db/migrations

Перелив данных:

```sql
-- Заполнение dim_date (пример для существующих дат из purchases)
INSERT INTO olap.dim_date (full_date, year, quarter, month, month_name, day_of_month, day_of_week, day_name, week_of_year)
SELECT DISTINCT
    DATE(purchase_date) AS full_date,
    EXTRACT(YEAR FROM purchase_date)::INT AS year,
    EXTRACT(QUARTER FROM purchase_date)::INT AS quarter,
    EXTRACT(MONTH FROM purchase_date)::INT AS month,
    TO_CHAR(purchase_date, 'FMMonth') AS month_name,
    EXTRACT(DAY FROM purchase_date)::INT AS day_of_month,
    EXTRACT(DOW FROM purchase_date)::INT AS day_of_week,
    TO_CHAR(purchase_date, 'FMDay') AS day_name,
    EXTRACT(WEEK FROM purchase_date)::INT AS week_of_year
FROM public.purchases
ON CONFLICT (full_date) DO NOTHING;

-- Заполнение dim_user
INSERT INTO olap.dim_user (user_id, login)
SELECT buyer_id, login FROM public.buyers
ON CONFLICT (user_id) DO NOTHING;

-- Заполнение dim_category
INSERT INTO olap.dim_category (category_id, category_name, description)
SELECT category_id, name, description FROM public.category_of_item
ON CONFLICT (category_id) DO NOTHING;

-- Заполнение dim_product
INSERT INTO olap.dim_product (product_id, name, price, shop_name, category_id)
SELECT 
    i.item_id,
    i.name,
    i.price,
    s.name AS shop_name,
    i.category_id
FROM public.items i
JOIN public.shops s ON i.shop_id = s.shop_id
ON CONFLICT (product_id) DO NOTHING;

-- Заполнение fact_sales
INSERT INTO olap.fact_sales (date_id, user_id, product_id, category_id, purchase_id, order_id, quantity, revenue, purchase_status, order_status)
SELECT 
    d.date_id,
    p.buyer_id AS user_id,
    p.item_id AS product_id,
    i.category_id,
    p.purchase_id,
    o.order_id,
    1 AS quantity,
    i.price AS revenue,
    p.status AS purchase_status,
    o.status AS order_status
FROM public.purchases p
JOIN public.items i ON p.item_id = i.item_id
JOIN olap.dim_date d ON d.full_date = DATE(p.purchase_date)
LEFT JOIN public.orders o ON p.purchase_id = o.purchase_id;
```

Запросы
1. Динамика активности по дням (количество продаж, сумма выручки, количество заказов)

```sql
SELECT 
    d.full_date,
    COUNT(f.sale_id) AS total_sales,
    COUNT(DISTINCT f.user_id) AS unique_users,
    SUM(f.revenue) AS total_revenue,
    COUNT(DISTINCT f.order_id) AS total_orders
FROM olap.fact_sales f
JOIN olap.dim_date d ON f.date_id = d.date_id
GROUP BY d.full_date
ORDER BY d.full_date;
```

2. Самые популярные категории товаров (по количеству продаж и выручке)

```sql
SELECT 
    c.category_name,
    COUNT(f.sale_id) AS sales_count,
    SUM(f.revenue) AS total_revenue,
    ROUND(AVG(f.revenue), 2) AS avg_revenue_per_sale,
    COUNT(DISTINCT f.product_id) AS distinct_products_sold
FROM olap.fact_sales f
JOIN olap.dim_category c ON f.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY total_revenue DESC;
```