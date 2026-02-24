CREATE TABLE profession (
    profession_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    salary INT NOT NULL CHECK (salary > 0)
);

CREATE TABLE career_path (
    path_id SERIAL PRIMARY KEY,
    current_profession_id INT NOT NULL REFERENCES profession(profession_id),
    next_profession_id INT NOT NULL REFERENCES profession(profession_id)
);

CREATE TABLE workers (
    worker_id SERIAL PRIMARY KEY,
    login VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(50) NOT NULL
);

CREATE TABLE buyers (
    buyer_id SERIAL PRIMARY KEY,
    login VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(50) NOT NULL
);

CREATE TABLE pvz (
    pvz_id SERIAL PRIMARY KEY,
    address VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE shops (
    shop_id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES workers(worker_id),
    name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE category_of_item (
    category_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE items (
    item_id SERIAL PRIMARY KEY,
    shop_id INT NOT NULL REFERENCES shops(shop_id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id INT NOT NULL REFERENCES category_of_item(category_id),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE worker_assignments (
    worker_id INT REFERENCES workers(worker_id),
    place_type VARCHAR(20) CHECK (
        place_type = 'shop' OR place_type = 'pvz'
    ),
    place_id INT,
    work_id INT REFERENCES profession(profession_id)
);

CREATE TABLE purchases (
    purchase_id SERIAL PRIMARY KEY,
    item_id INT NOT NULL REFERENCES items(item_id),
    buyer_id INT NOT NULL REFERENCES buyers(buyer_id),
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled'))
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    purchase_id INT NOT NULL UNIQUE REFERENCES purchases(purchase_id),
    pvz_id INT NOT NULL REFERENCES pvz(pvz_id),
    status VARCHAR(50) NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'delivered', 'cancelled')),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    purchase_id INT NOT NULL UNIQUE REFERENCES purchases(purchase_id),
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    description TEXT
);