-- ============================================================
-- Inventory Agent — Example Queries
-- ============================================================

-- Q: "Which products have inventory risk?"
SELECT
    prod_name,
    brand_name,
    cat_name,
    wh_name,
    reg_name,
    safety_stock_qty,
    reorder_point_qty,
    lead_time_days,
    risk_flag
FROM retail.vw_inventory_health
WHERE risk_flag <> 'OK'
ORDER BY risk_flag, prod_name;


-- Q: "Show perishable products where lead time exceeds shelf life"
SELECT
    prod_name,
    cat_name,
    wh_name,
    reg_name,
    lead_time_days,
    shelf_life_days,
    lead_time_days - shelf_life_days  AS days_over
FROM retail.vw_inventory_health
WHERE is_perishable = 1
  AND lead_time_days > shelf_life_days
ORDER BY days_over DESC;


-- Q: "Inventory overview for the Northwest warehouse"
SELECT
    prod_name,
    cat_name,
    safety_stock_qty,
    reorder_point_qty,
    lead_time_days,
    demand_channel,
    forecast_horizon_days,
    risk_flag
FROM retail.vw_inventory_health
WHERE wh_name LIKE '%Northwest%'
ORDER BY risk_flag DESC, prod_name;


-- Q: "Products with the longest lead times"
SELECT TOP 10
    prod_name,
    brand_name,
    cat_name,
    wh_name,
    reg_name,
    lead_time_days,
    safety_stock_qty,
    reorder_point_qty
FROM retail.vw_inventory_health
ORDER BY lead_time_days DESC;


-- Q: "Inventory risk summary by region"
SELECT
    reg_name,
    risk_flag,
    COUNT(*) AS product_count
FROM retail.vw_inventory_health
GROUP BY reg_name, risk_flag
ORDER BY reg_name, risk_flag;


-- Q: "Discontinued products still in inventory"
SELECT
    prod_name,
    brand_name,
    cat_name,
    wh_name,
    reg_name,
    safety_stock_qty
FROM retail.vw_inventory_health
WHERE risk_flag = 'DISCONTINUED'
ORDER BY reg_name, wh_name;


-- Q: "Which warehouses carry the most at-risk products?"
SELECT
    wh_name,
    reg_name,
    COUNT(*) AS risk_products,
    COUNT(CASE WHEN risk_flag = 'PERISHABLE_LEAD_TIME_RISK' THEN 1 END) AS perishable_risk,
    COUNT(CASE WHEN risk_flag = 'DISCONTINUED' THEN 1 END) AS discontinued
FROM retail.vw_inventory_health
WHERE risk_flag <> 'OK'
GROUP BY wh_name, reg_name
ORDER BY risk_products DESC;


-- ============================================================
-- Out-of-Stock Classification Queries  (vw_oos_classification)
-- ============================================================

-- Q: "How many products are out of stock?"
SELECT
    oos_category,
    oos_severity,
    COUNT(*)                AS product_count,
    COUNT(DISTINCT prod_id) AS distinct_products
FROM retail.vw_oos_classification
WHERE oos_category <> 'OK'
GROUP BY oos_category, oos_severity
ORDER BY
    CASE oos_severity
        WHEN 'CRITICAL'   THEN 1
        WHEN 'WARNING'    THEN 2
        WHEN 'MONITORING' THEN 3
    END;


-- Q: "Show me all critical out-of-stock products"
SELECT
    prod_name,
    brand_name,
    cat_name,
    wh_name,
    reg_name,
    oos_category,
    days_since_last_sale,
    avg_daily_units_14d,
    total_units_14d,
    last_sale_date
FROM retail.vw_oos_classification
WHERE oos_category IN ('CHRONIC_OOS', 'LIKELY_OOS')
ORDER BY days_since_last_sale DESC, avg_daily_units_30d DESC;


-- Q: "Which regions have the most out-of-stock products?"
SELECT
    reg_name,
    oos_category,
    COUNT(*)                AS product_count,
    COUNT(DISTINCT prod_id) AS distinct_products
FROM retail.vw_oos_classification
WHERE oos_category IN ('CHRONIC_OOS', 'LIKELY_OOS', 'AT_RISK')
GROUP BY reg_name, oos_category
ORDER BY reg_name,
    CASE oos_category
        WHEN 'CHRONIC_OOS' THEN 1
        WHEN 'LIKELY_OOS'  THEN 2
        WHEN 'AT_RISK'     THEN 3
    END;


-- Q: "Products at risk of running out before replenishment"
SELECT
    prod_name,
    brand_name,
    cat_name,
    wh_name,
    reg_name,
    safety_stock_qty,
    lead_time_days,
    avg_daily_units_14d,
    ROUND(est_days_of_coverage, 1) AS est_days_of_coverage,
    lead_time_days - ROUND(est_days_of_coverage, 0) AS coverage_gap_days
FROM retail.vw_oos_classification
WHERE oos_category = 'AT_RISK'
ORDER BY est_days_of_coverage ASC;


-- Q: "Which products are slowing down?"
SELECT
    prod_name,
    brand_name,
    cat_name,
    wh_name,
    reg_name,
    avg_daily_units_14d,
    avg_daily_units_7d,
    ROUND(velocity_change_pct * 100, 1) AS velocity_change_pct
FROM retail.vw_oos_classification
WHERE oos_category = 'SLOW_MOVING'
ORDER BY velocity_change_pct ASC;


-- Q: "OOS summary by department"
SELECT
    depa_name,
    COUNT(CASE WHEN oos_category = 'CHRONIC_OOS' THEN 1 END)  AS chronic_oos,
    COUNT(CASE WHEN oos_category = 'LIKELY_OOS'  THEN 1 END)  AS likely_oos,
    COUNT(CASE WHEN oos_category = 'AT_RISK'     THEN 1 END)  AS at_risk,
    COUNT(CASE WHEN oos_category = 'SLOW_MOVING' THEN 1 END)  AS slow_moving,
    COUNT(CASE WHEN oos_category = 'OK'          THEN 1 END)  AS ok,
    COUNT(*)                                                    AS total
FROM retail.vw_oos_classification
WHERE is_discontinued = 0
GROUP BY depa_name
ORDER BY chronic_oos + likely_oos DESC;


-- Q: "Perishable products by department"
SELECT
    depa_name,
    cat_name,
    COUNT(*)                      AS product_count,
    AVG(CAST(lead_time_days AS FLOAT))  AS avg_lead_time,
    AVG(CAST(shelf_life_days AS FLOAT)) AS avg_shelf_life
FROM retail.vw_inventory_health
WHERE is_perishable = 1
GROUP BY depa_name, cat_name
ORDER BY avg_lead_time DESC;
