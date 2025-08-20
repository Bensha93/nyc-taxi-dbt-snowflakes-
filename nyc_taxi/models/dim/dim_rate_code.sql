{{ config(
    materialized='view',
    alias='dim_rate_code',
    tags=['dim', 'rate_code'],
    unique_key='rate_code_id',
    description='Dimension table for rate codes'
) }}
WITH src_rate_code AS (
    SELECT * FROM {{ ref('src_rate_code') }}
)
SELECT
    rate_code_id,
    rate_code_desc
FROM
    src_rate_code
WHERE
    RATE_CODE_ID IS NOT NULL


{% if is_incremental() %}
  -- only process new/updated rows
    AND rate_code_id > (SELECT max(rate_code_id) FROM {{ this }})
{% endif %}