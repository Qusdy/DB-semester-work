# Домашнее задание:

### Задание 1: Инициализация БД с репликацией

- Создайте файл docker-compose.yml с содержимым из readme.md, запустите его
- Создайте Keyspace `university` с фактором репликации **2** (чтобы данные дублировались на обе ноды).

```cassandraql
cqlsh> CREATE KEYSPACE university
   ... WITH REPLICATION = {
   ...     'class': 'SimpleStrategy',
   ...     'replication_factor': 2
   ... };
cqlsh> SELECT * FROM system_schema.keyspaces WHERE keyspace_name = 'university';

 keyspace_name | durable_writes | replication
---------------+----------------+-------------------------------------------------------------------------------------
    university |           True | {'class': 'org.apache.cassandra.locator.SimpleStrategy', 'replication_factor': '2'}

(1 rows)

```
---
### Задание 2: Создание таблицы и данных

- Создайте таблицу `student_grades`: `student_id(uuid)`, `created_at`, `subject`, `grade`.
- Настройте ключи: **Partition Key** — `student_id`, **Clustering Key** — `created_at`.
- Выполните по 2 вставки  для двух разных студентов. Для генерации ID используйте функцию `uuid()`.

```cassandraql
cqlsh:university> INSERT INTO student_grades (student_id, created_at, subject, grade)
              ... VALUES (uuid(), toTimestamp(now()), 'Mathematics', 85);
cqlsh:university> INSERT INTO student_grades(student_id, created_at, subject, grade) VALUES (e245344a-3f3a-4145-b8c9-d663d3b7c3b3, toTimestamp(now()), 'database', 100);
cqlsh:university> INSERT INTO student_grades(student_id, created_at, subject, grade) VALUES (uuid(), toTimestamp(now()), 'я задолбался, почему не 4 студента просто', 100);
cqlsh:university> INSERT INTO student_grades(student_id, created_at, subject, grade) VALUES (9a160722-a2c7-415b-828c-316c27de50cf, toTimestamp(now()), 'database', 100);
cqlsh:university> SELECT * FROM student_grades;

student_id                           | created_at                      | grade | subject
--------------------------------------+---------------------------------+-------+-------------------------------------------
 9a160722-a2c7-415b-828c-316c27de50cf | 2026-05-03 10:09:50.778000+0000 |   100 | я задолбался, почему не 4 студента просто
 9a160722-a2c7-415b-828c-316c27de50cf | 2026-05-03 10:10:15.697000+0000 |   100 |                                  database
 e245344a-3f3a-4145-b8c9-d663d3b7c3b3 | 2026-05-03 10:01:46.142000+0000 |    85 |                               Mathematics
 e245344a-3f3a-4145-b8c9-d663d3b7c3b3 | 2026-05-03 10:08:49.533000+0000 |   100 |                                  database

(4 rows)

```

### Задание 3: Проверка распределения данных (Partitioning)

- Найдите UUID ваших студентов: `SELECT student_id FROM student_grades;`.
- В терминале выполните команду для получения ip нод с данными каждого UUID: `nodetool getendpoints keyspace table_name <UUID>`, посмотрите результат

```cassandraql
student_id                           | created_at                      | grade | subject
--------------------------------------+---------------------------------+-------+-------------------------------------------
 9a160722-a2c7-415b-828c-316c27de50cf | 2026-05-03 10:09:50.778000+0000 |   100 | я задолбался, почему не 4 студента просто
 9a160722-a2c7-415b-828c-316c27de50cf | 2026-05-03 10:10:15.697000+0000 |   100 |                                  database
 e245344a-3f3a-4145-b8c9-d663d3b7c3b3 | 2026-05-03 10:01:46.142000+0000 |    85 |                               Mathematics
 e245344a-3f3a-4145-b8c9-d663d3b7c3b3 | 2026-05-03 10:08:49.533000+0000 |   100 |                                  database

(4 rows)
```

```bash
PS C:\Users\user\DB-semester-work\s2\hw08_NoSQL_othersTasks\cassandra> docker exec -it cassandra-node1 nodetool getendpoints university student_grades  9a160722-a2c7-415b-828c-316c27de50cf
172.20.0.3
172.20.0.2
PS C:\Users\user\DB-semester-work\s2\hw08_NoSQL_othersTasks\cassandra> docker exec -it cassandra-node1 nodetool getendpoints university student_grades e245344a-3f3a-4145-b8c9-d663d3b7c3b3
172.20.0.2
172.20.0.3
```

### Задание 4: Работа с фильтрацией

- Попробуйте выполнить поиск по предмету (не ключевое поле), зафиксируйте ошибку
- Выполните этот же запрос, добавив `ALLOW FILTERING`.  Посмотрите результаты.

```bash
cqlsh:university> SELECT * FROM student_grades WHERE subject = 'Mathematics';
InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
```

```bash
cqlsh:university> SELECT * FROM student_grades WHERE subject = 'Mathematics' ALLOW FILTERING;

 student_id                           | created_at                      | grade | subject
--------------------------------------+---------------------------------+-------+-------------
 e245344a-3f3a-4145-b8c9-d663d3b7c3b3 | 2026-05-03 10:01:46.142000+0000 |    85 | Mathematics

(1 rows)
```