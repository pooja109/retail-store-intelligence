/*  vw_oos_classification
    ──────────────────────
    Infers out-of-stock status by combining sales velocity patterns with
    inventory parameters (safety stock, reorder point, lead time).

    Because the inventories table has no on-hand quantity, OOS is estimated
    from sales drop-offs: an active product that suddenly stops selling is
    likely out of stock.

    The anchor date is the latest order date in the dataset (not GETDATE()),
    so the view works correctly even when data is not real-time.

    Sales velocity is computed per product × region over two windows
    relative to the anchor date:
      • 14-day baseline  — establishes normal demand
      • 7-day recent     — detects sudden sales cessation

    OOS Categories:
      CHRONIC_OOS  — active product with 0 sales for 14+ days        (CRITICAL)
      LIKELY_OOS   — active product with 0 sales for 7–13 days       (CRITICAL)
      AT_RISK      — safety-stock coverage < lead time                (WARNING)
      SLOW_MOVING  — recent velocity dropped > 50% vs baseline       (MONITORING)
      DISCONTINUED — product discontinued (excluded from OOS counts)  (MONITORING)
      OK           — normal velocity and adequate coverage

    Grain: one row per inventory record (product × warehouse).
           Sales velocity is at product × region level.
*/

CREATE OR ALTER VIEW retail.vw_oos_classification AS
WITH latest_order AS (
    SELECT MAX(CAST(ord_dt AS DATE)) AS anchor_date
    FROM   retail.orders
),

sales_velocity AS (
    SELECT
        ol.prod_id,
        o.reg_id,

        -- 14-day baseline (relative to anchor date)
        SUM(ol.qty)                                                          AS total_units_14d,
        CAST(SUM(ol.qty) AS FLOAT) / 14.0                                   AS avg_daily_units_14d,
        MAX(CAST(o.ord_dt AS DATE))                                          AS last_sale_date,
        DATEDIFF(DAY, MAX(CAST(o.ord_dt AS DATE)), lo.anchor_date)           AS days_since_last_sale,

        -- 7-day recent window (last 7 days before anchor)
        SUM(CASE WHEN CAST(o.ord_dt AS DATE) >= DATEADD(DAY, -7, lo.anchor_date)
                 THEN ol.qty ELSE 0 END)                                     AS total_units_7d,
        CAST(SUM(CASE WHEN CAST(o.ord_dt AS DATE) >= DATEADD(DAY, -7, lo.anchor_date)
                      THEN ol.qty ELSE 0 END) AS FLOAT) / 7.0               AS avg_daily_units_7d

    FROM      retail.orders      o
    JOIN      retail.order_lines ol ON ol.ord_id = o.ord_id
    CROSS JOIN latest_order       lo
    WHERE     CAST(o.ord_dt AS DATE) >= DATEADD(DAY, -14, lo.anchor_date)
    GROUP BY  ol.prod_id, o.reg_id, lo.anchor_date
),

inventory_base AS (
    SELECT
        i.inv_id,
        i.prod_id,
        i.wh_id,
        i.reg_id,
        i.sfty_stock_qty                            AS safety_stock_qty,
        i.reord_pt_qty                              AS reorder_point_qty,
        i.lead_t_days                               AS lead_time_days,

        p.prod_name,
        p.brand_name,
        p.sku,
        p.unit_cost_amt,
        p.is_disc                                   AS is_discontinued,

        pc.prod_cat_id,
        pc.cat_name,
        pc.depa_name,
        pc.is_peri                                  AS is_perishable,
        pc.shelf_life_days,

        w.wh_name,
        w.city_name                                 AS wh_city,
        w.state_or_prov                             AS wh_state,

        r.reg_name

    FROM      retail.inventories        i
    JOIN      retail.products           p   ON p.prod_id      = i.prod_id
    JOIN      retail.product_categories pc  ON pc.prod_cat_id = p.prod_cat_id
    JOIN      retail.warehouses         w   ON w.wh_id        = i.wh_id
    JOIN      retail.regions            r   ON r.reg_id       = i.reg_id
)

SELECT
    -- Anchor date (latest order date in dataset)
    lo.anchor_date,

    -- Inventory
    ib.inv_id,
    ib.safety_stock_qty,
    ib.reorder_point_qty,
    ib.lead_time_days,

    -- Product
    ib.prod_id,
    ib.prod_name,
    ib.brand_name,
    ib.sku,
    ib.unit_cost_amt,
    ib.is_discontinued,

    -- Category
    ib.prod_cat_id,
    ib.cat_name,
    ib.depa_name,
    ib.is_perishable,
    ib.shelf_life_days,

    -- Warehouse
    ib.wh_id,
    ib.wh_name,
    ib.wh_city,
    ib.wh_state,

    -- Region
    ib.reg_id,
    ib.reg_name,

    -- Sales velocity metrics
    COALESCE(sv.total_units_14d, 0)                 AS total_units_14d,
    COALESCE(sv.avg_daily_units_14d, 0)             AS avg_daily_units_14d,
    COALESCE(sv.total_units_7d, 0)                  AS total_units_7d,
    COALESCE(sv.avg_daily_units_7d, 0)              AS avg_daily_units_7d,
    sv.last_sale_date,
    COALESCE(sv.days_since_last_sale, 999)          AS days_since_last_sale,

    -- Estimated days of safety-stock coverage at current velocity
    CASE WHEN COALESCE(sv.avg_daily_units_14d, 0) > 0
         THEN CAST(ib.safety_stock_qty AS FLOAT) / sv.avg_daily_units_14d
         ELSE NULL
    END                                             AS est_days_of_coverage,

    -- Velocity change: recent 7d vs 14d baseline (negative = slowing)
    CASE WHEN COALESCE(sv.avg_daily_units_14d, 0) > 0
         THEN (COALESCE(sv.avg_daily_units_7d, 0) - sv.avg_daily_units_14d)
              / sv.avg_daily_units_14d
         ELSE NULL
    END                                             AS velocity_change_pct,

    -- ── OOS classification ──────────────────────────────────────
    CASE
        WHEN ib.is_discontinued = 1
            THEN 'DISCONTINUED'

        -- No sales for 14+ days despite baseline activity
        WHEN COALESCE(sv.total_units_14d, 0) > 0
             AND COALESCE(sv.total_units_7d, 0) = 0
             AND COALESCE(sv.days_since_last_sale, 999) >= 14
            THEN 'CHRONIC_OOS'

        -- No sales for 7–13 days despite baseline activity
        WHEN COALESCE(sv.total_units_14d, 0) > 0
             AND COALESCE(sv.total_units_7d, 0) = 0
             AND COALESCE(sv.days_since_last_sale, 999) >= 7
            THEN 'LIKELY_OOS'

        -- Safety stock won't last until replenishment arrives
        WHEN COALESCE(sv.avg_daily_units_14d, 0) > 0
             AND CAST(ib.safety_stock_qty AS FLOAT) / sv.avg_daily_units_14d
                 < ib.lead_time_days
            THEN 'AT_RISK'

        -- Velocity dropped > 50% in the last 7 days vs 14-day baseline
        WHEN COALESCE(sv.avg_daily_units_14d, 0) > 0
             AND COALESCE(sv.avg_daily_units_7d, 0) > 0
             AND sv.avg_daily_units_7d < 0.5 * sv.avg_daily_units_14d
            THEN 'SLOW_MOVING'

        ELSE 'OK'
    END                                             AS oos_category,

    -- ── Severity ────────────────────────────────────────────────
    CASE
        WHEN ib.is_discontinued = 1
            THEN 'MONITORING'

        WHEN COALESCE(sv.total_units_14d, 0) > 0
             AND COALESCE(sv.total_units_7d, 0) = 0
             AND COALESCE(sv.days_since_last_sale, 999) >= 14
            THEN 'CRITICAL'

        WHEN COALESCE(sv.total_units_14d, 0) > 0
             AND COALESCE(sv.total_units_7d, 0) = 0
             AND COALESCE(sv.days_since_last_sale, 999) >= 7
            THEN 'CRITICAL'

        WHEN COALESCE(sv.avg_daily_units_14d, 0) > 0
             AND CAST(ib.safety_stock_qty AS FLOAT) / sv.avg_daily_units_14d
                 < ib.lead_time_days
            THEN 'WARNING'

        WHEN COALESCE(sv.avg_daily_units_14d, 0) > 0
             AND COALESCE(sv.avg_daily_units_7d, 0) > 0
             AND sv.avg_daily_units_7d < 0.5 * sv.avg_daily_units_14d
            THEN 'MONITORING'

        ELSE NULL
    END                                             AS oos_severity

FROM      inventory_base   ib
LEFT JOIN sales_velocity   sv  ON sv.prod_id = ib.prod_id
                              AND sv.reg_id  = ib.reg_id
CROSS JOIN latest_order    lo;
GO
