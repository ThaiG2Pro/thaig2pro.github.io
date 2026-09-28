-- Measures one correlated EXISTS lookup by voucher code at a given table size.
-- Invoked by run.sh once per size with @n set. Pure SQL, no client-side timing.
DROP DATABASE IF EXISTS vb;
CREATE DATABASE vb;
USE vb;

CREATE TABLE orders (id INT UNSIGNED PRIMARY KEY, code VARCHAR(20) NOT NULL);
CREATE TABLE order_vouchers (
  id INT UNSIGNED PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL,
  voucher_code CHAR(10) NOT NULL,     -- 10 digits, stored as text
  voucher_serial CHAR(11) NOT NULL    -- 11 alphanumerics, always has a letter
) ENGINE=InnoDB;

-- ~2.14 vouchers per order, matching the staging average in the post.
SET @orders = GREATEST(1, FLOOR(@n / 2.14));
INSERT INTO orders SELECT seq, CONCAT('ORD', seq) FROM seq_1_to_1000000 WHERE seq <= @orders;
INSERT INTO order_vouchers
SELECT seq,
       1 + ((seq * 7919) MOD @orders),
       LPAD(seq * 3 + 1000, 10, '0'),
       CONCAT('V', LPAD(CONV(seq * 5 + 77, 10, 36), 10, '0'))
FROM seq_1_to_1000000 WHERE seq <= @n;
ANALYZE TABLE orders, order_vouchers;

CREATE TABLE results (variant VARCHAR(40), run INT, ms DECIMAL(10,3), hits INT);

DELIMITER //
CREATE PROCEDURE measure(IN variant VARCHAR(40), IN runs INT)
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE code CHAR(10); DECLARE ser CHAR(11); DECLARE t0 DATETIME(6); DECLARE c INT;
  WHILE i < runs DO
    -- a different existing target each run, so nothing is served from a cache
    SELECT voucher_code, voucher_serial INTO code, ser
      FROM order_vouchers WHERE id = 1 + ((i * 104729) MOD @n);
    SET t0 = SYSDATE(6);
    IF variant LIKE 'or-%' THEN
      SELECT COUNT(*) INTO c FROM orders o
       WHERE EXISTS (SELECT 1 FROM order_vouchers v
                      WHERE v.order_id = o.id AND (v.voucher_code = code OR v.voucher_serial = ser));
    ELSE
      SELECT COUNT(*) INTO c FROM orders o
       WHERE EXISTS (SELECT 1 FROM order_vouchers v
                      WHERE v.order_id = o.id AND v.voucher_code = code);
    END IF;
    INSERT INTO results VALUES (variant, i, TIMESTAMPDIFF(MICROSECOND, t0, SYSDATE(6)) / 1000, c);
    SET i = i + 1;
  END WHILE;
END //
DELIMITER ;

-- V1: as shipped — no index on either voucher column, lookup by one column
SET @code = (SELECT voucher_code FROM order_vouchers WHERE id = 1);
SET @ser  = (SELECT voucher_serial FROM order_vouchers WHERE id = 1);
EXPLAIN SELECT COUNT(*) FROM orders o WHERE EXISTS (SELECT 1 FROM order_vouchers v WHERE v.order_id = o.id AND v.voucher_code = @code);
CALL measure('single-noindex', 5);
-- V2: the deferred fix — a NON-UNIQUE index on voucher_code
CREATE INDEX ix_code ON order_vouchers (voucher_code);
CALL measure('single-index', 5);
-- V3: the rejected "OR both columns" shape, even with both columns indexed
CREATE INDEX ix_serial ON order_vouchers (voucher_serial);
CALL measure('or-both-indexed', 5);

SELECT @n AS rows_in_order_vouchers, @orders AS rows_in_orders;
SELECT variant,
       MIN(ms) AS min_ms,
       (SELECT ms FROM results r2 WHERE r2.variant = r.variant ORDER BY ms LIMIT 1 OFFSET 2) AS median_ms,
       MAX(ms) AS max_ms,
       MIN(hits) AS hits
FROM results r GROUP BY variant ORDER BY FIELD(variant, 'single-noindex', 'single-index', 'or-both-indexed');

-- plans with indexes present: ref, and index_merge for the OR shape
EXPLAIN SELECT COUNT(*) FROM orders o WHERE EXISTS (SELECT 1 FROM order_vouchers v WHERE v.order_id = o.id AND v.voucher_code = @code);
EXPLAIN SELECT COUNT(*) FROM orders o WHERE EXISTS (SELECT 1 FROM order_vouchers v WHERE v.order_id = o.id AND (v.voucher_code = @code OR v.voucher_serial = @ser));
