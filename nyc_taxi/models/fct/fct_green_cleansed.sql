{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  unique_key='green_id',
  tags=['fct','green','cleansed'],
  alias='FCT_GREEN_CLEANSED',
  description='Cleansed Green Taxi Trips Fact Table'
) }}

WITH src AS (
  SELECT
        VendorID,
        COALESCE(RatecodeID, 99)::int            AS RatecodeID,
        COALESCE(payment_type_id, 5)::int        AS payment_type_id,
        pickup_datetime::timestamp               AS pickup_datetime,
        dropoff_datetime::timestamp              AS dropoff_datetime,
        fare_amount::number(10,2)                AS fare_amount,
        COALESCE(tip_amount, 0)::number(10,2)    AS tip_amount,
        COALESCE(tolls_amount, 0)::number(10,2)  AS tolls_amount,
        improvement_surcharge::number(10,2)      AS improvement_surcharge,
        extra::number(10,2)                      AS extra,
        mta_tax::number(10,2)                    AS mta_tax,
        total_amount::number(10,2)               AS total_amount,
        passenger_count::int                     AS passenger_count,
        trip_type_id::int                        AS trip_type_id,
        PULocationID::int                        AS PULocationID,
        DOLocationID::int                        AS DOLocationID,
        trip_distance::number(10,2)              AS trip_distance,
        COALESCE(store_and_fwd_flag, 'N')        AS store_and_fwd_flag,
        congestion_surcharge::number(10,2)       AS congestion_surcharge,
        cbd_congestion_fee::number(10,2)         AS cbd_congestion_fee
  FROM {{ ref('src_green_trip') }}
  WHERE
      pickup_datetime IS NOT NULL
      AND dropoff_datetime IS NOT NULL
      AND trip_type_id IS NOT NULL
      AND DOlocationID IS NOT NULL
      AND PULocationID IS NOT NULL
      AND trip_distance >= 0
      AND fare_amount >= 0
      AND total_amount >= 0
      AND passenger_count > 0
      AND pickup_datetime < dropoff_datetime
      -- exclude future rows
      AND pickup_datetime < CURRENT_TIMESTAMP
      AND dropoff_datetime < CURRENT_TIMESTAMP

  {% if is_incremental() %}
      -- Only load new rows
      AND pickup_datetime > (
        SELECT COALESCE(MAX(pickup_datetime), '1900-01-01'::timestamp)
        FROM {{ this }}
      )
  {% endif %}
)

SELECT
  {{ dbt_utils.generate_surrogate_key(['VendorID', 'pickup_datetime', 'dropoff_datetime', 'passenger_count', 'fare_amount', 'trip_distance']) }} AS green_id,
  *
FROM src
