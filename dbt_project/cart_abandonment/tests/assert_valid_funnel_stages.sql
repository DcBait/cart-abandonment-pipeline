SELECT CAST(funnel_stage AS STRING) AS funnel_stage
FROM `project-681013b1-bc3e-47ed-b3a`.`cart_abandonment_dev`.`mart_funnel`
WHERE CAST(funnel_stage AS STRING) NOT IN (
    'page_view',
    'view_item',
    'add_to_cart',
    'checkout',
    'purchase'
)
