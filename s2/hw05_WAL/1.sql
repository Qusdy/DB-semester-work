
TRUNCATE wal_measurements;

CREATE TEMP TABLE wal_measurements (
    operation text,
    lsn_before pg_lsn,
    lsn_after pg_lsn,
    wal_bytes bigint,
    ts timestamptz DEFAULT now()
);


DO $$
    DECLARE
        v_lsn_before pg_lsn;
        v_lsn_after pg_lsn;
    BEGIN
        SELECT pg_current_wal_lsn() INTO v_lsn_before;

        INSERT INTO profession (name, salary)
        VALUES ('docker_test_' || clock_timestamp(), floor(random()*100000)::int);

        COMMIT;

        SELECT pg_current_wal_lsn() INTO v_lsn_after;

        INSERT INTO wal_measurements (operation, lsn_before, lsn_after, wal_bytes)
        VALUES ('single_insert', v_lsn_before, v_lsn_after,
                pg_wal_lsn_diff(v_lsn_after, v_lsn_before));
    END;
$$;

DO $$
    DECLARE
        v_lsn_before pg_lsn;
        v_lsn_after pg_lsn;
        v_start_time timestamptz;
    BEGIN
        SELECT pg_current_wal_lsn(), clock_timestamp() INTO v_lsn_before, v_start_time;

        INSERT INTO profession (name, salary)
        SELECT 'bulk_' || i, (random() * 100000)::int
        FROM generate_series(1, 10000) i;

        COMMIT;

        SELECT pg_current_wal_lsn() INTO v_lsn_after;

        INSERT INTO wal_measurements (operation, lsn_before, lsn_after, wal_bytes)
        VALUES ('bulk_10000', v_lsn_before, v_lsn_after,
                pg_wal_lsn_diff(v_lsn_after, v_lsn_before));
    END;
$$;

SELECT
    operation,
    lsn_before,
    lsn_after,
    wal_bytes,
    pg_size_pretty(wal_bytes) as wal_size_human,
    ts
FROM wal_measurements
ORDER BY ts;