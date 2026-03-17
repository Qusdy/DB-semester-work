INSERT INTO profession (profession_id, name, salary)
VALUES (1, 'Продавец-консультант', 45000)
    ON CONFLICT (profession_id) DO NOTHING;

SELECT COUNT(*) FROM profession WHERE profession_id = 1;

INSERT INTO profession (profession_id, name, salary)
VALUES (1, 'Продавец-консультант', 45000)
    ON CONFLICT (profession_id) DO NOTHING;

SELECT COUNT(*) FROM profession WHERE profession_id = 1;

INSERT INTO profession (profession_id, name, salary)
VALUES (1, 'Продавец-консультант', 45000)
    ON CONFLICT (profession_id) DO NOTHING;

SELECT COUNT(*) FROM profession WHERE profession_id = 1;