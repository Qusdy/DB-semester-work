DO $$
DECLARE
lsn_start pg_lsn := pg_current_wal_lsn();
BEGIN
INSERT INTO profession (name, salary)
SELECT 'mass_' || i, random()*100000
FROM generate_series(1, 10000) i;

RAISE NOTICE 'WAL: % байт',
        pg_wal_lsn_diff(pg_current_wal_lsn(), lsn_start);
END
$$;