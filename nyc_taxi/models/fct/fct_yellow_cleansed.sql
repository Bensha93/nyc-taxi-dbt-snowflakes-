
{{ config(
  materialized='incremental',
  incremental_strategy='merge',
  description='Cleansed Yellow Taxi Trip Data',
  tags=['yellow', 'taxi', 'cleansed'],
  unique_key='yellow_id',
) }}

WITH src AS (
  SELECT
      VendorID,
      COALESCE(RatecodeID, 99)                 AS RatecodeID,
      COALESCE(payment_type_id, 5)             AS payment_type_id,
      pickup_datetime,
      dropoff_datetime,
      fare_amount,
      tip_amount,
      extra,
      tolls_amount,
      mta_tax,
      total_amount,
      passenger_count,
      PULocationID,
      DOLocationID,
      trip_distance,
      COALESCE(store_and_fwd_flag, 'N')        AS store_and_fwd_flag,
      improvement_surcharge,
      congestion_surcharge,
      cbd_congestion_fee,
      Airport_fee
  FROM {{ ref('src_yellow_trip') }}
  WHERE
      pickup_datetime IS NOT NULL
      AND dropoff_datetime IS NOT NULL
      AND DOlocationID IS NOT NULL
      AND PULocationID IS NOT NULL
      AND trip_distance >= 0
      AND fare_amount >= 0
      AND total_amount >= 0
      AND passenger_count > 0
      AND pickup_datetime < dropoff_datetime
      -- Exclude any future timestamps
      AND pickup_datetime < CURRENT_TIMESTAMP
      AND dropoff_datetime < CURRENT_TIMESTAMP

  {% if is_incremental() %}
      -- Only new rows since the latest we’ve loaded
      AND pickup_datetime > (
        SELECT COALESCE(MAX(pickup_datetime), '1900-01-01'::timestamp)
        FROM {{ this }}
      )
  {% endif %}
)

SELECT
  {{ dbt_utils.generate_surrogate_key(['VendorID', 'pickup_datetime', 'dropoff_datetime', 'passenger_count']) }} AS yellow_id,
  *
FROM src
