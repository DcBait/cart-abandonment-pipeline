{{
    config(
        materialized='incremental',
        unique_key='session_id',
        incremental_strategy='merge'
    )
}}

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
    {% if is_incremental() %}
        WHERE event_ts >= TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY))
    {% endif %}
    GROUP BY session_id, user_id
),

funnel_stage AS (
    SELECT
        session_id,
        user_id,
        session_start,
        session_end,
        device_type,
        traffic_source,
        country,
        reached_page_view,
        reached_view_item,
        reached_add_to_cart,
        reached_checkout,
        reached_purchase,
        CASE
            WHEN reached_purchase     = 1 THEN 'purchase'
            WHEN reached_checkout     = 1 THEN 'checkout'
            WHEN reached_add_to_cart  = 1 THEN 'add_to_cart'
            WHEN reached_view_item    = 1 THEN 'view_item'
            ELSE                               'page_view'
        END AS funnel_stage,
        CASE
            WHEN reached_purchase     = 1 THEN 5
            WHEN reached_checkout     = 1 THEN 4
            WHEN reached_add_to_cart  = 1 THEN 3
            WHEN reached_view_item    = 1 THEN 2
            ELSE                               1
        END AS stage_order
    FROM session_funnel
)

SELECT
    session_id,
    user_id,
    session_start,
    session_end,
    device_type,
    traffic_source,
    country,
    funnel_stage,
    stage_order,
    reached_page_view,
    reached_view_item,
    reached_add_to_cart,
    reached_checkout,
    reached_purchase
FROM funnel_stage
