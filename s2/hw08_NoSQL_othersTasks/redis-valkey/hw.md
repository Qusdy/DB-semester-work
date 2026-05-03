# Redis / Valkey — Домашнее задание

---

## Задание 1. Hash — данные о студентах

Создайте 3 студентов, используя Hash. Каждый ключ — `student:<id>`, поля: `name`, `group`, `gpa`.
Проверьте, что данные записались
---

```bash
127.0.0.1:6379> HSET student:1 name "Damir" group "11-400" gpa 4.5
(integer) 3
127.0.0.1:6379> HSET student:2 name "Michael" group "11-400" gpa 4.89
(integer) 3
127.0.0.1:6379> HSET student:3 name "Zhenechek" group "11-400" gpa 5.01
(integer) 3
127.0.0.1:6379> HSET student:4 name "Kamil" group "11-401" gpa 4.0
(integer) 3
127.0.0.1:6379> HSET student:5 name "ArturAbdul" group "11-400" gpa 6.0
(integer) 3
```

```bash
127.0.0.1:6379> HGET student:1 name
"Damir"
127.0.0.1:6379> HGET student:2 name
"Michael"
127.0.0.1:6379> HGET student:3 name
"Zhenechek"
127.0.0.1:6379> HGET student:4 name
"Kamil"
127.0.0.1:6379> HGET student:5 name
"ArturAbdul"
```

---

## Задание 2. Sorted Set — лидерборд по GPA

Создайте рейтинг студентов по среднему баллу. В Sorted Set score = GPA, member = имя.
Выведите топ-3 по убыванию GPA:

---

```bash
127.0.0.1:6379> ZADD student:gpa 4.5 "Damir" 4.89 "Michael" 5.01 "Zhenechek" 4.0 "Kamil" 6.0 "ArturAbdul"
(integer) 5
127.0.0.1:6379> ZREVRANGE student:gpa 0 2 WITHSCORES
1) "ArturAbdul"
2) "6"
3) "Zhenechek"
4) "5.01"
5) "Michael"
6) "4.89"
```

---

## Задание 3. List — очередь задач

Добавьте 5 задач в очередь через `RPUSH`:
Заберите 3 задачи из очереди (FIFO — первый вошёл, первый вышел):

---

```bash
127.0.0.1:6379> RPUSH tasks "a" "b" "c" "d" "e"
(integer) 5
127.0.0.1:6379> LPOP tasks
"a"
127.0.0.1:6379> LPOP tasks
"b"
127.0.0.1:6379> LPOP tasks
"c"
127.0.0.1:6379> LLEN tasks
(integer) 2
```

---

## Задание 4. TTL — время жизни ключа

Создайте ключ с TTL 10 секунд:
Сразу проверьте оставшееся время:
Подождите и попробуйте получить значение:

---

```bash
127.0.0.1:6379> SET session:abc token123 EX 10
OK
127.0.0.1:6379> TTL session:abc
(integer) 9
127.0.0.1:6379> GET session:abc
(nil)
```

---

## Задание 5. Транзакция MULTI/EXEC

Смоделируйте «перевод» 1 балла GPA от студента 1 к студенту 2.

---

```bash
127.0.0.1:6379> MULTI
OK
127.0.0.1:6379(TX)> HINCRBYFLOAT student:1 gpa 1
QUEUED
127.0.0.1:6379(TX)> HINCRBYFLOAT student:2 gpa -1
QUEUED
127.0.0.1:6379(TX)> EXEC
1) "5.5"
2) "3.89"

```

---

## Задание 6 (бонус). Pub/Sub

Откройте **два** терминала с `redis-cli`.

**Терминал 1** — подписчик:

```bash
docker exec -it redis redis-cli
```

```
SUBSCRIBE news
```

**Терминал 2** — издатель:

```bash
docker exec -it redis redis-cli
```

```
PUBLISH news "Hello from Redis!"
PUBLISH news "Second message"
```

```bash
127.0.0.1:6379> SUBSCRIBE news
1) "subscribe"
2) "news"
3) (integer) 1
1) "message"
2) "news"
3) "Hello from Redis!"
1) "message"
2) "news"
3) "Second message"
```