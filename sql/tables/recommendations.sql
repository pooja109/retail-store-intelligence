-- ============================================================
-- Table: retail.recommendations
-- Description: Stores daily AI-generated insights per store
--              produced by the Store Intelligence Report notebook.
-- Refresh: Daily per store (idempotent — deletes existing
--          rows for store+date before inserting).
-- ============================================================

CREATE TABLE IF NOT EXISTS retail.recommendations (
    report_date     STRING      COMMENT 'Report date (YYYY-MM-DD)',
    str_id          STRING      COMMENT 'Store identifier',
    str_name        STRING      COMMENT 'Store name',
    str_type        STRING      COMMENT 'Store type (Urban, Suburban, Rural)',
    reg_id          STRING      COMMENT 'Region identifier',
    reg_name        STRING      COMMENT 'Region name',
    insight_type    STRING      COMMENT 'RISK | OPPORTUNITY | CORRELATION | EXECUTIVE_SUMMARY | KPI_SNAPSHOT',
    severity        STRING      COMMENT 'For risks: CRITICAL | WARNING | MONITORING',
    domain          STRING      COMMENT 'Business domain (Sales, Inventory, Labor, All)',
    title           STRING      COMMENT 'Short insight title',
    detail          STRING      COMMENT 'Full description or JSON payload for KPI_SNAPSHOT',
    reasoning       STRING      COMMENT 'Evidence and logic behind the insight',
    dollar_impact   FLOAT       COMMENT 'Estimated dollar value (risk exposure or opportunity gain)',
    generated_at    STRING      COMMENT 'Timestamp when insight was generated'
)
USING DELTA
COMMENT 'Daily AI-generated store recommendations for the Recommendation Data Agent';
