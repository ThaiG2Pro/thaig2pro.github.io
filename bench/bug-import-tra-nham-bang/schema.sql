-- Two tables that both auto-increment from small numbers.
-- Generic names; this is a reconstruction, not the original schema.

CREATE TABLE product_variants (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    sku_code TEXT NOT NULL UNIQUE
);

CREATE TABLE campaigns (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

-- One row per (campaign, SKU) pair, holding that pair's quota.
-- Its id has nothing to do with product_variants.id.
CREATE TABLE campaign_product_variants (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    campaign_id        INTEGER NOT NULL REFERENCES campaigns(id),
    product_variant_id INTEGER NOT NULL REFERENCES product_variants(id),
    quota              INTEGER NOT NULL DEFAULT 0,
    UNIQUE (campaign_id, product_variant_id)
);
