-- ============================================================
-- Table: retail.store_inventory
-- Description: Store-level on-hand inventory snapshot per
--              product, enabling shelf availability and
--              shrinkage tracking at the store grain.
-- Refresh: Daily (full snapshot or CDC from POS/WMS).
-- ============================================================

CREATE TABLE IF NOT EXISTS retail.store_inventory (
    str_inv_id      STRING      COMMENT 'Surrogate key for store-inventory record',
    str_id          STRING      COMMENT 'Store identifier (FK → stores)',
    prod_id         STRING      COMMENT 'Product identifier (FK → products)',
    snapshot_dt     DATE        COMMENT 'Date of the inventory count',
    on_hand_qty     INT         COMMENT 'Units physically on hand at the store',
    on_order_qty    INT         COMMENT 'Units ordered but not yet received',
    shrinkage_qty   INT         COMMENT 'Units lost to theft, damage, or spoilage',
    last_received_dt DATE       COMMENT 'Date product was last restocked at this store',
    last_sold_dt    DATE        COMMENT 'Date product was last sold at this store'
)
USING DELTA
COMMENT 'Daily store-level inventory snapshots for shelf availability and replenishment tracking';
