-- ============================================================
-- Labor Agent — Example Queries
-- ============================================================

-- Q: "How many employees per store?"
SELECT
    str_name,
    str_type,
    reg_name,
    COUNT(DISTINCT emp_id)          AS headcount
FROM retail.vw_labor_coverage
GROUP BY str_name, str_type, reg_name
ORDER BY headcount ASC;


-- Q: "Which stores are understaffed compared to target?"
SELECT
    str_id,
    str_name,
    str_type,
    role_name,
    target_headcount,
    COUNT(DISTINCT emp_id)          AS actual_headcount,
    COUNT(DISTINCT emp_id) - target_headcount AS delta
FROM retail.vw_labor_coverage
WHERE target_headcount IS NOT NULL
GROUP BY str_id, str_name, str_type, role_name, target_headcount
HAVING COUNT(DISTINCT emp_id) < target_headcount
ORDER BY delta ASC;


-- Q: "Which stores are understaffed compared to average for their type?"
WITH store_hc AS (
    SELECT
        str_id,
        str_name,
        str_type,
        reg_name,
        COUNT(DISTINCT emp_id) AS headcount
    FROM retail.vw_labor_coverage
    GROUP BY str_id, str_name, str_type, reg_name
),
type_avg AS (
    SELECT
        str_type,
        AVG(CAST(headcount AS FLOAT)) AS avg_headcount
    FROM store_hc
    GROUP BY str_type
)
SELECT
    s.str_name,
    s.str_type,
    s.reg_name,
    s.headcount,
    ROUND(t.avg_headcount, 1) AS avg_for_type,
    s.headcount - ROUND(t.avg_headcount, 0) AS delta
FROM store_hc s
JOIN type_avg t ON t.str_type = s.str_type
WHERE s.headcount < t.avg_headcount
ORDER BY delta ASC;


-- Q: "Shift coverage breakdown for store STR042"
SELECT
    shift_date,
    shift_start,
    shift_end,
    COUNT(DISTINCT emp_id)          AS employees,
    SUM(orders_managed)             AS total_orders_managed,
    SUM(tasks_completed)            AS total_tasks_completed
FROM retail.vw_labor_coverage
WHERE str_id = 'STR042'
GROUP BY shift_date, shift_start, shift_end
ORDER BY shift_date, shift_start;


-- Q: "Role distribution across all stores"
SELECT
    role_name,
    role_level,
    COUNT(DISTINCT emp_id)                      AS total_employees,
    COUNT(DISTINCT str_id)                      AS stores_with_role,
    AVG(CAST(orders_managed AS FLOAT))          AS avg_orders_per_employee,
    AVG(CAST(tasks_completed AS FLOAT))         AS avg_tasks_per_employee
FROM retail.vw_labor_coverage
GROUP BY role_name, role_level
ORDER BY total_employees DESC;


-- Q: "Shifts with only 1 employee (coverage risk)"
SELECT
    str_name,
    reg_name,
    shift_date,
    shift_start,
    COUNT(DISTINCT emp_id) AS employees
FROM retail.vw_labor_coverage
GROUP BY str_name, reg_name, shift_date, shift_start
HAVING COUNT(DISTINCT emp_id) = 1
ORDER BY str_name, shift_date;


-- Q: "Top 10 most productive employees"
SELECT TOP 10
    emp_id,
    str_name,
    role_name,
    shift_date,
    orders_managed,
    tasks_completed,
    orders_managed + tasks_completed AS total_activity
FROM retail.vw_labor_coverage
ORDER BY total_activity DESC;


-- Q: "Average productivity by region"
SELECT
    reg_name,
    COUNT(DISTINCT emp_id)                  AS headcount,
    AVG(CAST(orders_managed AS FLOAT))      AS avg_orders_managed,
    AVG(CAST(tasks_completed AS FLOAT))     AS avg_tasks_completed
FROM retail.vw_labor_coverage
GROUP BY reg_name
ORDER BY avg_orders_managed DESC;


-- Q: "Overtime analysis by store"
SELECT
    str_name,
    str_type,
    COUNT(DISTINCT emp_id)                                  AS total_employees,
    SUM(CASE WHEN is_overtime = 1 THEN 1 ELSE 0 END)       AS overtime_shifts,
    SUM(CASE WHEN is_overtime = 1 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0)                               AS overtime_pct
FROM retail.vw_labor_coverage
GROUP BY str_name, str_type
ORDER BY overtime_pct DESC;


-- Q: "Labor cost by store this week"
SELECT
    str_name,
    str_type,
    reg_name,
    COUNT(DISTINCT emp_id)                          AS headcount,
    SUM(COALESCE(actual_hours, scheduled_hours))    AS total_hours,
    SUM(hourly_rate * COALESCE(actual_hours, scheduled_hours)) AS estimated_labor_cost
FROM retail.vw_labor_coverage
WHERE shift_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
GROUP BY str_name, str_type, reg_name
ORDER BY estimated_labor_cost DESC;


-- Q: "Attendance issues — who was absent?"
SELECT
    str_name,
    emp_id,
    first_name,
    last_name,
    role_name,
    shift_date,
    scheduled_hours,
    absence_reason
FROM retail.vw_labor_coverage
WHERE absence_reason IS NOT NULL
  AND shift_date >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
ORDER BY shift_date DESC;
