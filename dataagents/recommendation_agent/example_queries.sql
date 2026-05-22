-- ============================================================
-- Recommendation Agent — Example Queries
-- Paste these as example Q&A pairs when configuring the
-- Fabric Data Agent to improve SQL generation accuracy.
-- ============================================================

-- Q: "What are today's critical risks for store STR001?"
SELECT
    title,
    domain,
    detail,
    reasoning,
    dollar_impact
FROM retail.recommendations
WHERE str_id = 'STR001'
  AND insight_type = 'RISK'
  AND severity = 'CRITICAL'
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations WHERE str_id = 'STR001')
ORDER BY dollar_impact DESC;


-- Q: "Show me all opportunities for the Northeast region"
SELECT
    str_name,
    title,
    domain,
    detail,
    reasoning,
    dollar_impact
FROM retail.recommendations
WHERE reg_name = 'Northeast'
  AND insight_type = 'OPPORTUNITY'
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations WHERE reg_name = 'Northeast')
ORDER BY dollar_impact DESC;


-- Q: "What should I focus on today at store STR003?"
SELECT
    insight_type,
    severity,
    domain,
    title,
    detail,
    reasoning,
    dollar_impact
FROM retail.recommendations
WHERE str_id = 'STR003'
  AND insight_type IN ('RISK', 'OPPORTUNITY')
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations WHERE str_id = 'STR003')
ORDER BY
    CASE WHEN insight_type = 'RISK' AND severity = 'CRITICAL' THEN 1
         WHEN insight_type = 'RISK' AND severity = 'WARNING' THEN 2
         WHEN insight_type = 'OPPORTUNITY' THEN 3
         ELSE 4 END,
    dollar_impact DESC;


-- Q: "Give me the executive summary for store STR005"
SELECT
    title,
    detail AS executive_summary,
    report_date
FROM retail.recommendations
WHERE str_id = 'STR005'
  AND insight_type = 'EXECUTIVE_SUMMARY'
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations WHERE str_id = 'STR005');


-- Q: "Which stores have the most critical risks today?"
SELECT
    str_name,
    reg_name,
    COUNT(*) AS critical_risk_count,
    SUM(dollar_impact) AS total_dollar_at_risk
FROM retail.recommendations
WHERE insight_type = 'RISK'
  AND severity = 'CRITICAL'
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations)
GROUP BY str_name, reg_name
ORDER BY total_dollar_at_risk DESC;


-- Q: "What cross-domain correlations were found for store STR002?"
SELECT
    title,
    domain,
    detail,
    reasoning
FROM retail.recommendations
WHERE str_id = 'STR002'
  AND insight_type = 'CORRELATION'
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations WHERE str_id = 'STR002');


-- Q: "Show me the highest dollar opportunities across all stores"
SELECT TOP 10
    str_name,
    reg_name,
    title,
    domain,
    detail,
    dollar_impact
FROM retail.recommendations
WHERE insight_type = 'OPPORTUNITY'
  AND dollar_impact IS NOT NULL
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations)
ORDER BY dollar_impact DESC;


-- Q: "How have risks changed for store STR001 over the past week?"
SELECT
    report_date,
    severity,
    COUNT(*) AS risk_count,
    SUM(dollar_impact) AS total_dollar_impact
FROM retail.recommendations
WHERE str_id = 'STR001'
  AND insight_type = 'RISK'
  AND report_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
GROUP BY report_date, severity
ORDER BY report_date DESC, severity;


-- Q: "What are the KPIs for store STR004 today?"
SELECT
    report_date,
    detail AS kpi_json
FROM retail.recommendations
WHERE str_id = 'STR004'
  AND insight_type = 'KPI_SNAPSHOT'
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations WHERE str_id = 'STR004');


-- Q: "Show me inventory-related risks across all stores"
SELECT
    str_name,
    reg_name,
    severity,
    title,
    detail,
    reasoning,
    dollar_impact
FROM retail.recommendations
WHERE insight_type = 'RISK'
  AND domain = 'Inventory'
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations)
ORDER BY
    CASE severity WHEN 'CRITICAL' THEN 1 WHEN 'WARNING' THEN 2 ELSE 3 END,
    dollar_impact DESC;


-- Q: "Compare recommendations between store STR001 and STR002"
SELECT
    str_name,
    insight_type,
    COUNT(*) AS insight_count,
    SUM(CASE WHEN dollar_impact IS NOT NULL THEN dollar_impact ELSE 0 END) AS total_dollar_impact
FROM retail.recommendations
WHERE str_id IN ('STR001', 'STR002')
  AND report_date = (SELECT MAX(report_date) FROM retail.recommendations WHERE str_id IN ('STR001', 'STR002'))
GROUP BY str_name, insight_type
ORDER BY str_name, insight_type;
