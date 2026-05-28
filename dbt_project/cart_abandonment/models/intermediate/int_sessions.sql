WITH events AS (
    SELECT * FROM {{ ref('stg_events') }}
),

lagged AS (
    SELECT
        *,
        LAG(event_ts) OVER (
            PARTITION BY user_id
            ORDER BY event_ts
        ) AS prev_event_ts
    FROM events
),

session_flags AS (
    SELECT
        *,
        CASE
            WHEN prev_event_ts IS NULL THEN 1
            WHEN TIMESTAMP_DIFF(event_ts, prev_event_ts, MINUTE) > 30 THEN 1
            ELSE 0
        END AS is_new_session
    FROM lagged
),

session_ids AS (
    SELECT
        *,
        CONCAT(
            user_id, '-',
            CAST(SUM(is_new_session) OVER (
                PARTITION BY user_id
                ORDER BY event_ts
            ) AS STRING)
        ) AS session_id
    FROM session_flags
)

SELECT * FROM session_ids
