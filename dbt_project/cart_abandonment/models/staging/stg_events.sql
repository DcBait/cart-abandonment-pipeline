WITH raw AS (
    SELECT
        user_pseudo_id                          AS user_id,
        TIMESTAMP_MICROS(event_timestamp)       AS event_ts,
        event_name,
        device.category                         AS device_type,
        traffic_source.source                   AS traffic_source,
        geo.country                             AS country
    FROM {{ source('ga4', 'events_*') }}
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    -- NOTE: GA4 public dataset is static (Nov 2020 - Jan 2021)
    -- In production, replace BETWEEN clause with dynamic 90-day lookback:
    -- WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY))
    AND event_name IN (
        'page_view',
        'view_item',
        'add_to_cart',
        'begin_checkout',
        'purchase'
    )
)
SELECT * FROM raw
WHERE user_id IS NOT NULL
