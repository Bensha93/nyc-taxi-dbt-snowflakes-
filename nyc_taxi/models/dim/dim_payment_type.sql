
{{ config(
    materialized='view',
    alias='dim_payment_type',
    tags=['dim', 'payment_type'],
    unique_key='payment_type_id',
    description='Dimension table for payment types'
) }}

WITH src_payment_type AS (
    SELECT * FROM {{ ref('src_payment_type') }}
)
SELECT
    payment_type_id,
    payment_type_desc
FROM
    src_payment_type
WHERE
    payment_type_id IS NOT NULL

{% if is_incremental() %}
  -- only process new/updated rows
    AND payment_type_id > (SELECT max(payment_type_id) FROM {{ this }})
{% endif %}