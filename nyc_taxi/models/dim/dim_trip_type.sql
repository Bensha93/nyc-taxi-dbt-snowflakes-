{{
    config(
        materialized='view',
        alias='dim_trip_type',
        tags=['dim', 'trip_type'],
        unique_key='trip_type_id',
        description='Dimension table for trip type information, including trip type ID and description.'
    )
}}
WITH src_trip_type AS (
    SELECT
        *
    FROM {{ ref('src_trip_type') }}
)
SELECT
    trip_type_id,
    trip_type_desc
FROM 
    src_trip_type
WHERE
    TRIP_TYPE_ID IS NOT NULL

{% if is_incremental() %}
    -- only process new/updated rows
    AND TRIP_TYPE_ID > (SELECT max(TRIP_TYPE_ID) FROM {{ this }})
{% endif %}
    