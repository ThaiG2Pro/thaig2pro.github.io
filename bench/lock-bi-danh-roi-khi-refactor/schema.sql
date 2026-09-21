-- Minimal reconstruction: one shared pool row per SKU, many campaigns draw from it.
CREATE TABLE stock_pools (
    id           INTEGER PRIMARY KEY,
    sku          TEXT    NOT NULL UNIQUE,
    total        INTEGER NOT NULL,
    reserved     INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE campaign_allocations (
    id           INTEGER PRIMARY KEY,
    campaign_id  INTEGER NOT NULL,
    sku          TEXT    NOT NULL,
    quantity     INTEGER NOT NULL,
    FOREIGN KEY (sku) REFERENCES stock_pools(sku)
);

INSERT INTO stock_pools (sku, total, reserved) VALUES ('SKU-A', 100, 0);
