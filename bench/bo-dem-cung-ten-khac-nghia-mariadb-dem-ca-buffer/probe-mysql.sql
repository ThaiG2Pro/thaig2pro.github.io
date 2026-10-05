-- Same probe for MySQL. MySQL has no Innodb_lsn_flushed status variable, so
-- the last two columns use its redo LSN counters (8.0.30+).
DROP TABLE IF EXISTS samples;
CREATE TABLE samples (t DATETIME(6), n BIGINT, os_log_written BIGINT,
                      lsn_current BIGINT, lsn_flushed BIGINT) ENGINE=MEMORY;
DROP PROCEDURE IF EXISTS probe;
DELIMITER //
CREATE PROCEDURE probe(ms INT)
BEGIN
  DECLARE stop DATETIME(6) DEFAULT SYSDATE(6) + INTERVAL ms * 1000 MICROSECOND;
  WHILE SYSDATE(6) < stop DO
    INSERT INTO samples SELECT SYSDATE(6),
      (SELECT COALESCE(MAX(id),0) FROM t),
      (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Innodb_os_log_written'),
      (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Innodb_redo_log_current_lsn'),
      (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Innodb_redo_log_flushed_to_disk_lsn');
    DO SLEEP(0.005);
  END WHILE;
END//
DELIMITER ;
