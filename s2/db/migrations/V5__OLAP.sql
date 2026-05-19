-- Измерение даты
CREATE TABLE olap.dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20),
    day_of_month INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(20),
    week_of_year INT NOT NULL
);

-- Измерение пользователя (покупателя)
CREATE TABLE olap.dim_user (
    user_id INT PRIMARY KEY,  -- buyer_id из OLTP
    login VARCHAR(255) NOT NULL
);

-- Измерение товара
CREATE TABLE olap.dim_product (
    product_id INT PRIMARY KEY,  -- item_id
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2),
    shop_name VARCHAR(255),
    category_id INT
);

-- Измерение категории
CREATE TABLE olap.dim_category (
    category_id INT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL,
    description TEXT
);

-- Факт продаж (зерно: одна позиция заказа)
CREATE TABLE olap.fact_sales (
    sale_id SERIAL PRIMARY KEY,
    date_id INT REFERENCES olap.dim_date(date_id),
    user_id INT REFERENCES olap.dim_user(user_id),
    product_id INT REFERENCES olap.dim_product(product_id),
    category_id INT REFERENCES olap.dim_category(category_id),
    purchase_id INT NOT NULL,          -- для связи с OLTP
    order_id INT,                      -- если есть заказ
    quantity INT DEFAULT 1,            -- количество (в вашей схеме 1 покупка = 1 товар)
    revenue DECIMAL(10,2) NOT NULL,    -- цена товара
    purchase_status VARCHAR(50),
    order_status VARCHAR(50)
);