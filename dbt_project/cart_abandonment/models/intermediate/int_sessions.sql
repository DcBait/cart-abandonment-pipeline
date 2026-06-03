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
),

first_touch AS (
    SELECT
        session_id,
        traffic_source AS first_touch_source
    FROM session_ids
    WHERE event_ts = (
        SELECT MIN(s2.event_ts)
        FROM session_ids s2
        WHERE s2.session_id = session_ids.session_id
    )
),

last_touch AS (
    SELECT
        session_id,
        traffic_source AS last_touch_source
    FROM session_ids
    WHERE event_ts = (
        SELECT MAX(s2.event_ts)
        FROM session_ids s2
        WHERE s2.session_id = session_ids.session_id
    )
)

SELECT
    s.*,
    ft.first_touch_source,
    lt.last_touch_source
FROM session_ids s
LEFT JOIN first_touch ft ON s.session_id = ft.session_id
LEFT JOIN last_touch lt  ON s.session_id = lt.session_id
