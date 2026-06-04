{{
    config(
        materialized='table'
    )
}}
WITH funnel_counts AS (
    SELECT
        funnel_stage,
        stage_order,
        COUNT(*) AS sessions_reached
    FROM {{ ref('mart_funnel') }}
    GROUP BY funnel_stage, stage_order
),
with_next AS (
    SELECT
        funnel_stage,
        stage_order,
        sessions_reached,
        LEAD(sessions_reached) OVER (
            ORDER BY stage_order
        ) AS next_stage_sessions
    FROM funnel_counts
)
SELECT
    funnel_stage,
    stage_order,
    sessions_reached,
    COALESCE(sessions_reached - next_stage_sessions, 0)     AS sessions_dropped,
    ROUND(
        COALESCE(
            SAFE_DIVIDE(
                sessions_reached - next_stage_sessions,
                sessions_reached
            ) * 100,
        0),
    1)                                                       AS drop_off_rate_pct
FROM with_next
ORDER BY stage_order
