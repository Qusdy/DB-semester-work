
BEGIN;

-- Смотрим на строку ДО изменений
SELECT ctid, xmin, xmax, worker_id, login, skills
FROM workers WHERE worker_id = 1;

SELECT txid_current();
UPDATE workers SET skills = jsonb_set(skills, '{exp}', '5') WHERE worker_id = 1;

-- Смотрим на строку ПОСЛЕ обновления ВНУТРИ этой же транзакции
SELECT ctid, xmin, xmax, worker_id, login, skills
FROM workers WHERE worker_id = 1;

-- Не закрывайте транзакцию