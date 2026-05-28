WITH sessions AS (
    SELECT * FROM {{ ref('int_sessions') }}
),

session_funnel AS (
    SELECT
        session_id,
        user_id,
        MIN(event_ts)                                                        AS session_start,
        MAX(event_ts)                                                        AS session_end,
        MAX(device_type)                                                     AS device_type,
        MAX(traffic_source)                                                  AS traffic_source,
        MAX(country)                                                         AS country,

        MAX(CASE WHEN event_name = 'page_view'       THEN 1 ELSE 0 END)     AS reached_page_view,
        MAX(CASE WHEN event_name = 'view_item'       THEN 1 ELSE 0 END)     AS reached_view_item,
        MAX(CASE WHEN event_name = 'add_to_cart'     THEN 1 ELSE 0 END)     AS reached_add_to_cart,
        MAX(CASE WHEN event_name = 'begin_checkout'  THEN 1 ELSE 0 END)     AS reached_checkout,
        MAX(CASE WHEN event_name = 'purchase'        THEN 1 ELSE 0 END)     AS reached_purchase

    FROM sessions
    GROUP BY session_id, user_id
),

funnel_stage AS (
    SELECT
        *,
        CASE
            WHEN reached_purchase     = 1 THEN '5_purchase'
            WHEN reached_checkout     = 1 THEN '4_checkout'
            WHEN reached_add_to_cart  = 1 THEN '3_add_to_cart'
            WHEN reached_view_item    = 1 THEN '2_view_item'
            ELSE                               '1_page_view'
        END AS funnel_stage
    FROM session_funnel
)

SELECT * FROM funnel_stage
