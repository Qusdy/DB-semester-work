## 2. Создаем docker-compose.yml для физической репликации
```
services:
primary:
image: postgres:17
container_name: primary
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5432:5432"
command: >
postgres
-c wal_level=replica
-c max_wal_senders=10
-c max_replication_slots=10
-c hot_standby=on
-c wal_keep_size=500MB
volumes:
- pg_primary_data:/var/lib/postgresql/data

replica1:
image: postgres:17
container_name: replica1
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5434:5432"
depends_on:
- primary
command: tail -f /dev/null
volumes:
- pg_replica1_data:/var/lib/postgresql/data

replica2:
image: postgres:17
container_name: replica2
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5435:5432"
depends_on:
- primary
command: tail -f /dev/null
volumes:
- pg_replica2_data:/var/lib/postgresql/data

volumes:
pg_primary_data:
pg_replica1_data:
pg_replica2_data:
```
## 3 Запускаем и настраиваем primary
```bash
# Запускаем primary
docker compose up -d primary

# Создаем пользователя для репликации
docker exec -it primary psql -U postgres -c "CREATE USER replicator WITH REPLICATION PASSWORD 'pass';"

# Настраиваем pg_hba.conf
docker exec -it primary bash -c "echo 'host replication replicator 172.0.0.0/8 md5' >> /var/lib/postgresql/data/pg_hba.conf"
docker exec -it primary bash -c "echo 'host all all 172.0.0.0/8 md5' >> /var/lib/postgresql/data/pg_hba.conf"

# Перезагружаем конфигурацию
docker exec -it primary psql -U postgres -c "SELECT pg_reload_conf();"

# Проверяем создание пользователя
docker exec -it primary psql -U postgres -c "\du"
```
## 4. Настраиваем replica1
```bash
# Очищаем данные
docker exec -it replica1 bash -c "rm -rf /var/lib/postgresql/data/*"

# Выполняем pg_basebackup
docker exec -it replica1 bash -c "PGPASSWORD=pass pg_basebackup -h primary -p 5432 -D /var/lib/postgresql/data -U replicator -P -R -v"
```
## 5. Настраиваем replica2
```bash
# Очищаем данные
docker exec -it replica2 bash -c "rm -rf /var/lib/postgresql/data/*"

# Выполняем pg_basebackup
docker exec -it replica2 bash -c "PGPASSWORD=pass pg_basebackup -h primary -p 5432 -D /var/lib/postgresql/data -U replicator -P -R -v"
```
## 6. Убираем tail и перезапускаем реплики
Обновляем docker-compose.yml, убираем command: tail -f /dev/null:
```
version: '3.8'

services:
primary:
image: postgres:17
container_name: primary
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5432:5432"
command: >
postgres
-c wal_level=replica
-c max_wal_senders=10
-c max_replication_slots=10
-c hot_standby=on
-c wal_keep_size=500MB
volumes:
- pg_primary_data:/var/lib/postgresql/data

replica1:
image: postgres:17
container_name: replica1
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5434:5432"
depends_on:
- primary
volumes:
- pg_replica1_data:/var/lib/postgresql/data

replica2:
image: postgres:17
container_name: replica2
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5435:5432"
depends_on:
- primary
volumes:
- pg_replica2_data:/var/lib/postgresql/data

volumes:
pg_primary_data:
pg_replica1_data:
pg_replica2_data:
EOF
bash
# Перезапускаем реплики
docker compose up -d
```

## 7. Проверка физической репликации
```bash
# Проверяем статус репликации
docker exec -it primary psql -U postgres -d marketplace_db -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"

 client_addr |   state   | sync_state 
-------------+-----------+------------
 172.18.0.3  | streaming | async
 172.18.0.4  | streaming | async
(2 rows)

# Проверяем, что реплики в режиме recovery
docker exec -it replica1 psql -U postgres -d marketplace_db -c "SELECT pg_is_in_recovery();"
 pg_is_in_recovery 
-------------------
 t
(1 row)
docker exec -it replica2 psql -U postgres -d marketplace_db -c "SELECT pg_is_in_recovery();"
 pg_is_in_recovery 
-------------------
 t
(1 row)
# Создаем тестовую таблицу
docker exec -it primary psql -U postgres -d marketplace_db -c "
CREATE TABLE repl_test (id serial, data text);
INSERT INTO repl_test (data) VALUES ('Hello from Master!');
"
CREATE TABLE
INSERT 0 1

# Проверяем на replica1
docker exec -it replica1 psql -U postgres -d marketplace_db -c "SELECT * FROM repl_test;"

 id |        data        
----+--------------------
  1 | Hello from Master!
(1 row)


# Проверяем на replica2
docker exec -it replica2 psql -U postgres -d marketplace_db -c "SELECT * FROM repl_test;"

 id |        data        
----+--------------------
  1 | Hello from Master!
(1 row)


# Проверяем read-only
docker exec -it replica1 psql -U postgres -d marketplace_db -c "INSERT INTO repl_test (data) VALUES ('Try to insert into replica');"

ERROR:  cannot execute INSERT in a read-only transaction

```
8. Анализ replication lag
```bash
# Создаем нагрузку (3,000,000 строк)
docker exec -it primary psql -U postgres -d marketplace_db -c "INSERT INTO repl_test (data) SELECT 'Load test ' || gs FROM generate_series(1, 3000000) AS gs;"

# Мониторим lag (выполнить несколько раз)
docker exec -it primary psql -U postgres -d marketplace_db -c "SELECT client_addr, state, pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes FROM pg_stat_replication;"
 client_addr |   state   | lag_bytes 
-------------+-----------+-----------
 172.18.0.3  | streaming |         0
 172.18.0.4  | streaming |         0
(2 rows)
почему-то всегда так
```
## 9. Переход к логической репликации
   ### 9.1. Останавливаем всё и меняем wal_level
   ```bash
   docker compose down
version: '3.8'

services:
primary:
image: postgres:17
container_name: primary
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5432:5432"
command: >
postgres
-c wal_level=logical
-c max_wal_senders=10
-c max_replication_slots=10
-c hot_standby=on
-c wal_keep_size=500MB
volumes:
- pg_primary_data:/var/lib/postgresql/data

replica1:
image: postgres:17
container_name: replica1
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5434:5432"
depends_on:
- primary
volumes:
- pg_replica1_data:/var/lib/postgresql/data

replica2:
image: postgres:17
container_name: replica2
environment:
POSTGRES_DB: marketplace_db
POSTGRES_USER: postgres
POSTGRES_PASSWORD: qwerty007
ports:
- "5435:5432"
depends_on:
- primary
volumes:
- pg_replica2_data:/var/lib/postgresql/data

volumes:
pg_primary_data:
pg_replica1_data:
pg_replica2_data:

# Запускаем кластер
docker compose up -d
```

### 9.2. Продвигаем replica2 в мастер
```bash
# Продвигаем replica2
docker exec -it replica2 psql -U postgres -d marketplace_db -c "SELECT pg_promote();"
 pg_promote 
------------
 t
(1 row)

# Проверяем выход из recovery
docker exec -it replica2 psql -U postgres -d marketplace_db -c "SELECT pg_is_in_recovery();"
 pg_is_in_recovery 
-------------------
 f
(1 row)
```
### 9.3. Создаем таблицы для логической репликации
```bash
# На primary создаем таблицы
docker exec -it primary psql -U postgres -d marketplace_db -c "
CREATE SCHEMA IF NOT EXISTS marketplace;
CREATE TABLE marketplace.items (
item_id SERIAL PRIMARY KEY,
shop_id INTEGER NOT NULL,
name VARCHAR(255) NOT NULL,
description TEXT,
category_id INTEGER NOT NULL,
price NUMERIC(10,2) NOT NULL,
tags TEXT[],
metadata JSONB
);
"
CREATE SCHEMA
CREATE TABLE

# На replica2 создаем такую же структуру
docker exec -it replica2 psql -U postgres -d marketplace_db -c "
CREATE SCHEMA IF NOT EXISTS marketplace;
CREATE TABLE marketplace.items (
item_id SERIAL PRIMARY KEY,
shop_id INTEGER NOT NULL,
name VARCHAR(255) NOT NULL,
description TEXT,
category_id INTEGER NOT NULL,
price NUMERIC(10,2) NOT NULL,
tags TEXT[],
metadata JSONB
);
"
```
### 9.4. Создаем публикацию и подписку
```bash
# Создаем публикацию на primary
docker exec -it primary psql -U postgres -d marketplace_db -c "CREATE PUBLICATION my_pub FOR TABLE marketplace.items;"
CREATE PUBLICATION

# Выдаем права
docker exec -it primary psql -U postgres -d marketplace_db -c "GRANT USAGE ON SCHEMA marketplace TO replicator;"
docker exec -it primary psql -U postgres -d marketplace_db -c "GRANT SELECT ON ALL TABLES IN SCHEMA marketplace TO replicator;"
GRANT
GRANT

# Создаем подписку на replica2
docker exec -it replica2 psql -U postgres -d marketplace_db -c "CREATE SUBSCRIPTION my_sub CONNECTION 'host=primary port=5432 user=replicator password=pass dbname=marketplace_db' PUBLICATION my_pub;"

NOTICE:  created replication slot "my_sub" on publisher
CREATE SUBSCRIPTION
```
### 9.5. Проверка DML репликации
```bash
# Вставляем данные на primary
docker exec -it primary psql -U postgres -d marketplace_db -c "INSERT INTO marketplace.items (shop_id, name, category_id, price) VALUES (1, 'Logical Rep Item', 1, 999.99);"

# Проверяем на replica2
docker exec -it replica2 psql -U postgres -d marketplace_db -c "SELECT * FROM marketplace.items WHERE name = 'Logical Rep Item';"

 item_id | shop_id |       name       | description | category_id | price  | tags | metadata 
---------+---------+------------------+-------------+-------------+--------+------+----------
       1 |       1 | Logical Rep Item |             |           1 | 999.99 |      |
(1 row)
```
### 9.6. Проверка DDL (не реплицируется)
```bash
# Добавляем колонку на primary
docker exec -it primary psql -U postgres -d marketplace_db -c "ALTER TABLE marketplace.items ADD COLUMN logical_test_col TEXT;"

# Проверяем структуру на primary (колонка есть)
docker exec -it primary psql -U postgres -d marketplace_db -c "\d marketplace.items"
![ddl1.png](img%2Fddl1.png)
# Проверяем структуру на replica2 (колонки нет)
docker exec -it replica2 psql -U postgres -d marketplace_db -c "\d marketplace.items"
![ddl2.png](img%2Fddl2.png)
```
### 9.7. Проверка REPLICA IDENTITY
```bash
# Создаем таблицу без PK на primary
docker exec -it primary psql -U postgres -d marketplace_db -c "
CREATE TABLE no_pk_test (id int, data text);
ALTER PUBLICATION my_pub ADD TABLE no_pk_test;
"

# Создаем таблицу на replica2
docker exec -it replica2 psql -U postgres -d marketplace_db -c "
CREATE TABLE no_pk_test (id int, data text);
ALTER SUBSCRIPTION my_sub REFRESH PUBLICATION;
"

# INSERT работает
docker exec -it primary psql -U postgres -d marketplace_db -c "INSERT INTO no_pk_test VALUES (1, 'Test data');"

# Проверяем INSERT на replica2
docker exec -it replica2 psql -U postgres -d marketplace_db -c "SELECT * FROM no_pk_test;"

# UPDATE не работает
docker exec -it primary psql -U postgres -d marketplace_db -c "UPDATE no_pk_test SET data = 'Updated data' WHERE id = 1;"
```
### 9.8. Проверка статуса логической репликации
```bash
# На replica2 (подписчик)
docker exec -it replica2 psql -U postgres -d marketplace_db -c "SELECT subname, pid, worker_type FROM pg_stat_subscription;"

# На primary (публикатор)
docker exec -it primary psql -U postgres -d marketplace_db -c "SELECT application_name, state, sync_state FROM pg_stat_replication WHERE application_name = 'my_sub';"
```
### 9.9. Использование pg_dump/pg_restore
```bash
# Экспорт схемы с primary
docker exec -it primary pg_dump -U postgres -s -d marketplace_db > schema_dump.sql

# Копируем в replica2
docker cp schema_dump.sql replica2:/tmp/schema_dump.sql

# Восстанавливаем схему на replica2
docker exec -it replica2 psql -U postgres -d marketplace_db -f /tmp/schema_dump.sql
```