/*  vw_store_inventory_health
    ─────────────────────────
    Store-level inventory health view joining store_inventory snapshots
    with product, category, store, and region dimensions.  Enriched with
    warehouse-level safety-stock / reorder-point context and risk flags.

    Grain: one row per store × product × snapshot date.
*/

CREATE OR ALTER VIEW retail.vw_store_inventory_health AS
SELECT
    -- Store inventory
    si.str_inv_id,
    si.snapshot_dt,
    si.on_hand_qty,
    si.on_order_qty,
    si.shrinkage_qty,
    si.last_received_dt,
    si.last_sold_dt,

    -- Store
    s.str_id,
    s.str_name,
    s.str_type,

    -- Product
    p.prod_id,
    p.prod_name,
    p.brand_name,
    p.sku,
    p.unit_cost_amt,
    p.is_disc                                       AS is_discontinued,

    -- Category
    pc.prod_cat_id,
    pc.cat_name,
    pc.depa_name,
    pc.is_peri                                      AS is_perishable,
    pc.shelf_life_days,

    -- Region
    r.reg_id,
    r.reg_name,

    -- Warehouse-level supply context (nearest warehouse in same region)
    inv.sfty_stock_qty                              AS safety_stock_qty,
    inv.reord_pt_qty                                AS reorder_point_qty,
    inv.lead_t_days                                 AS lead_time_days,

    -- Calculated fields
    si.on_hand_qty + COALESCE(si.on_order_qty, 0)   AS available_qty,
    DATEDIFF(DAY, si.last_received_dt, si.snapshot_dt) AS days_since_restock,
    DATEDIFF(DAY, si.last_sold_dt, si.snapshot_dt)     AS days_since_last_sale,

    -- Risk flags
    CASE
        WHEN p.is_disc = 1
            THEN 'DISCONTINUED'
        WHEN si.on_hand_qty = 0 AND COALESCE(si.on_order_qty, 0) = 0
            THEN 'OUT_OF_STOCK'
        WHEN si.on_hand_qty = 0 AND si.on_order_qty > 0
            THEN 'OUT_OF_STOCK_REORDER_PENDING'
        WHEN si.on_hand_qty > 0 AND si.on_hand_qty <= COALESCE(inv.sfty_stock_qty, 0)
            THEN 'BELOW_SAFETY_STOCK'
        WHEN si.on_hand_qty > 0 AND si.on_hand_qty <= COALESCE(inv.reord_pt_qty, 0)
            THEN 'BELOW_REORDER_POINT'
        WHEN pc.is_peri = 1 AND inv.lead_t_days > pc.shelf_life_days
            THEN 'PERISHABLE_LEAD_TIME_RISK'
        WHEN si.shrinkage_qty > 0
            THEN 'SHRINKAGE_DETECTED'
        ELSE 'OK'
    END                                             AS risk_flag

FROM      retail.store_inventory      si
JOIN      retail.stores               s   ON s.str_id       = si.str_id
JOIN      retail.products             p   ON p.prod_id      = si.prod_id
JOIN      retail.product_categories   pc  ON pc.prod_cat_id = p.prod_cat_id
JOIN      retail.regions              r   ON r.reg_id       = s.reg_id
LEFT JOIN retail.inventories          inv ON inv.prod_id    = si.prod_id
                                         AND inv.reg_id     = s.reg_id;
GO
