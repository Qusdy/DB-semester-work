BEGIN;
SELECT pg_current_wal_lsn() AS lsn_before_commit;

INSERT INTO profession (name, salary) VALUES ('minimal_test', 77777);

SELECT pg_current_wal_lsn() AS lsn_after_insert;
COMMIT;

SELECT pg_current_wal_lsn() AS lsn_after_commit;