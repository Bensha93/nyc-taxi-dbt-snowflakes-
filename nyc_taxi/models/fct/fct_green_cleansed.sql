
{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='green_id',
    tags=['fct', 'green', 'cleansed', 'taxi'],
    alias='FCT_GREEN_CLEANSED',
    description='Cleansed and validated Green Taxi trip data with quality filters and calculated metrics',
    meta={
      'owner': 'Adewole Oyediran',
      'data_source': 'NYC TLC Green Taxi Trip Records',
      'update_frequency': 'Daily',
      'quality_checks': 'Comprehensive data validation applied'
    }
  )
}}

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
      AND passenger_count BETWEEN 1 AND 8
      AND PULocationID IS NOT NULL
      AND YEAR(pickup_datetime) >= 2021
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
      )
    ) < 0.01
)

SELECT
  {{ dbt_utils.generate_surrogate_key(['VendorID', 'payment_type_id', 'pickup_datetime', 'dropoff_datetime', 'passenger_count', 'tip_amount', 'PULocationID', 'DOLocationID', 'fare_per_mile']) }} AS green_id,
  CAST(pickup_datetime AS DATE) AS DateID,
  *
FROM filtered
QUALIFY COUNT(*) OVER (PARTITION BY {{ dbt_utils.generate_surrogate_key(['VendorID', 'payment_type_id', 'pickup_datetime', 'dropoff_datetime', 'passenger_count', 'tip_amount', 'PULocationID', 'DOLocationID', 'fare_per_mile']) }}) = 1

{% if is_incremental() %}
  AND NOT EXISTS (
    SELECT 1
    FROM {{ this }} AS existing
    WHERE existing.green_id = {{ dbt_utils.generate_surrogate_key(['VendorID', 'payment_type_id', 'pickup_datetime', 'dropoff_datetime', 'passenger_count', 'tip_amount', 'PULocationID', 'DOLocationID', 'fare_per_mile']) }}
  )
{% endif %}