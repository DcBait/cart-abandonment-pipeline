SELECT funnel_stage
FROM {{ ref('mart_funnel') }}
WHERE funnel_stage NOT IN (
    'page_view',
    'view_item', 
    'add_to_cart',
    'checkout',
    'purchase'
)
