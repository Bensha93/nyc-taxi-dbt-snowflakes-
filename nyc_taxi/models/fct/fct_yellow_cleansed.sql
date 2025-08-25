
{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='yellow_id',
    tags=['fct', 'yellow', 'cleansed', 'taxi'],
    alias='FCT_YELLOW_CLEANSED',
    description='Cleansed and validated Yellow Taxi trip data with quality filters and calculated metrics',
    meta={
      'owner': 'Data Engineering Team',
      'data_source': 'NYC TLC Yellow Taxi Trip Records',
      'update_frequency': 'Daily',
      'quality_checks': 'Comprehensive data validation applied'
    }
  )
}}

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
      AND YEAR(pickup_datetime) >= 2021
      AND trip_distance >= 0
      AND fare_amount >= 0
      AND total_amount >= 0
      AND passenger_count BETWEEN 1 AND 8
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
),

features as (
  select
    *,
    datediff('second', pickup_datetime, dropoff_datetime) / 60.0 as trip_minutes,
    datediff('second', pickup_datetime, dropoff_datetime) / 3600.0 as trip_hours,
    case when trip_distance > 0 and datediff('second', pickup_datetime, dropoff_datetime) > 0
         then trip_distance / (datediff('second', pickup_datetime, dropoff_datetime)/3600.0)
         end as mph,
    case when trip_distance > 0 then fare_amount / trip_distance end as fare_per_mile
  from src
),

filtered as (
  select *
  from features
  where
    -- distance must be reasonable for NYC trips
    trip_distance <= 100
    -- duration must be at least 1 minute and at most 8 hours
    and trip_minutes between 1 and 480
    -- realistic speeds (generous upper bound)
    and (mph is null or (mph >= 1 and mph <= 80))
    -- avoid absurd pricing artifacts
    and (fare_per_mile is null or (fare_per_mile between 0.5 and 20))
    -- total ≈ sum of parts (allow 1 cent rounding)
    and abs(
      total_amount - (
        coalesce(fare_amount,0)
        + coalesce(tip_amount,0)
        + coalesce(tolls_amount,0)
        + coalesce(extra,0)
        + coalesce(mta_tax,0)
        + coalesce(improvement_surcharge,0)
        + coalesce(congestion_surcharge,0)
        + coalesce(cbd_congestion_fee,0)
        + coalesce(Airport_fee,0)
      )
    ) < 0.01
)


SELECT
  {{ dbt_utils.generate_surrogate_key(['VendorID', 'payment_type_id', 'pickup_datetime', 'dropoff_datetime', 'passenger_count', 'tip_amount', 'PULocationID', 'DOLocationID', 'fare_per_mile']) }} AS yellow_id,
  CAST(pickup_datetime AS DATE) AS DateID,
  *
FROM filtered
QUALIFY COUNT(*) OVER (PARTITION BY {{ dbt_utils.generate_surrogate_key(['VendorID', 'payment_type_id', 'pickup_datetime', 'dropoff_datetime', 'passenger_count', 'tip_amount', 'PULocationID', 'DOLocationID', 'fare_per_mile']) }}) = 1
