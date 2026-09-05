/*  vw_labor_coverage
    ──────────────────
    Joins schedule, employee, role, task, attendance, staffing-target, and wage
    data across the labor and retail schemas.
    Enables analysis of staffing levels, shift distribution, role mix,
    productivity, attendance, and labor cost per store.

    Grain: one row per scheduled shift (employee × store × shift_date).
*/

CREATE OR ALTER VIEW retail.vw_labor_coverage AS
WITH

-- Aggregate tasks per employee × store × shift_date
task_agg AS (
    SELECT
        emp_id,
        str_id,
        shift_date,
        SUM(orders_managed)     AS orders_managed,
        SUM(units_completed)    AS tasks_completed
    FROM labor.task_assignments
    GROUP BY emp_id, str_id, shift_date
),

-- Aggregate attendance per employee × store × date
attendance_agg AS (
    SELECT
        emp_id,
        str_id,
        CAST(clock_in AS DATE)              AS attend_date,
        SUM(actual_hours)                   AS actual_hours,
        MAX(CAST(is_overtime AS INT))       AS is_overtime,
        MAX(absence_reason)                 AS absence_reason
    FROM labor.time_attendance
    GROUP BY emp_id, str_id, CAST(clock_in AS DATE)
)

SELECT
    -- Store
    s.str_id,
    s.str_name,
    s.str_type,

    -- Region
    r.reg_id,
    r.reg_name,

    -- Employee
    sc.emp_id,
    e.first_name,
    e.last_name,
    e.status                                        AS emp_status,
    e.emp_type,

    -- Schedule
    sc.shift_date,
    sc.shift_start,
    sc.shift_end,
    sc.scheduled_hours,

    -- Role
    ro.role_id,
    ro.role_name,
    ro.role_level,
    ro.min_headcount_per_shift,

    -- Productivity
    COALESCE(ta.orders_managed, 0)                  AS orders_managed,
    COALESCE(ta.tasks_completed, 0)                 AS tasks_completed,

    -- Attendance
    att.actual_hours,
    COALESCE(att.is_overtime, 0)                     AS is_overtime,
    att.absence_reason,

    -- Staffing target
    sst.target_headcount,

    -- Wage
    wr.hourly_rate

FROM      labor.schedules               sc
JOIN      labor.employees               e    ON e.emp_id    = sc.emp_id
JOIN      labor.roles                   ro   ON ro.role_id  = sc.role_id
JOIN      retail.stores                 s    ON s.str_id    = sc.str_id
JOIN      retail.regions                r    ON r.reg_id    = s.reg_id
LEFT JOIN task_agg                      ta   ON ta.emp_id     = sc.emp_id
                                             AND ta.str_id     = sc.str_id
                                             AND ta.shift_date = sc.shift_date
LEFT JOIN attendance_agg                att  ON att.emp_id      = sc.emp_id
                                             AND att.str_id      = sc.str_id
                                             AND att.attend_date = sc.shift_date
LEFT JOIN labor.store_staffing_targets  sst  ON sst.str_id   = sc.str_id
                                             AND sst.role_id  = sc.role_id
                                             AND sc.shift_date >= sst.effective_date
                                             AND (sst.end_date IS NULL
                                                  OR sc.shift_date <= sst.end_date)
LEFT JOIN labor.wage_rates              wr   ON wr.emp_id    = sc.emp_id
                                             AND wr.role_id   = sc.role_id
                                             AND sc.shift_date >= wr.effective_date
                                             AND (wr.end_date IS NULL
                                                  OR sc.shift_date <= wr.end_date);
GO
