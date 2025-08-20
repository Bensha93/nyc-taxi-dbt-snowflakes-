{{ config(
    alias='dim_vendor',
    materialized='view',
    tags=['dim', 'vendor'],
    unique_key='vendor_id',
    description='Dimension table for vendor information, including vendor ID and name.'
) }}
WITH src_vendor AS (
    SELECT
        *
    FROM {{ ref('src_vendor') }}
)
SELECT
    vendor_id,
    vendor_name
FROM 
    src_vendor
WHERE
    vendor_id IS NOT NULL

{% if is_incremental() %}
    -- only process new/updated rows
    AND vendor_id > (SELECT max(vendor_id) FROM {{ this }})
{% endif %}