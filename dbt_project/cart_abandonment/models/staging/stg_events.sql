WITH raw AS (
    SELECT
        user_pseudo_id                          AS user_id,
        TIMESTAMP_MICROS(event_timestamp)       AS event_ts,
        event_name,
        device.category                         AS device_type,
        traffic_source.source                   AS traffic_source,
        geo.country                             AS country
    FROM {{ source('ga4', 'events_*') }}
    WHERE event_name IN (
        'page_view',
        'view_item',
        'add_to_cart',
        'begin_checkout',
        'purchase'
    )
)

SELECT * FROM raw
WHERE user_id IS NOT NULL
