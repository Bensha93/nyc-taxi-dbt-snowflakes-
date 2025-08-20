
-- This file is part of the NYC Taxi dbt project.
-- It extracts and transforms data from the NYC Green Taxi Trip dataset.
-- It selects various fields, converts them to appropriate data types, and handles timestamp conversion.
-- The data is sourced from the NYC_TAXI.RAW.GREEN_TAXI_TRIP table.
-- The output is a structured table with the relevant fields for further cleaning and analysis.
-- The script assumes the data is stored in a VARIANT column named VARIANT_COL.
-- convert from VARIANT to specific types and handle timestamps (parquet format to structured data)
-- ephemeral model
-- model: src_green_trip
-- This model is ephemeral and will not create a physical table in the database.
-- It is used to prepare the data for further transformations in the dbt pipeline.


WITH src_green_trip AS (
    SELECT
        VARIANT_COL:"VendorID"::int                AS VendorID,
        VARIANT_COL:"RatecodeID"::int              AS RatecodeID,
        VARIANT_COL:"PULocationID"::int            AS PULocationID,
        VARIANT_COL:"DOLocationID"::int            AS DOLocationID,
        VARIANT_COL:"passenger_count"::int         AS passenger_count,
        VARIANT_COL:"trip_distance"::float         AS trip_distance,
        VARIANT_COL:"fare_amount"::float           AS fare_amount,
        VARIANT_COL:"extra"::float                 AS extra,
        VARIANT_COL:"mta_tax"::float               AS mta_tax,
        VARIANT_COL:"tip_amount"::float            AS tip_amount,
        VARIANT_COL:"tolls_amount"::float          AS tolls_amount,
        VARIANT_COL:"improvement_surcharge"::float AS improvement_surcharge,
        VARIANT_COL:"total_amount"::float          AS total_amount,
        VARIANT_COL:"congestion_surcharge"::float  AS congestion_surcharge,
        VARIANT_COL:"cbd_congestion_fee"::float    AS cbd_congestion_fee,
        VARIANT_COL:"trip_type"::float             AS trip_type_id,
        VARIANT_COL:"payment_type"::int            AS payment_type_id,
        VARIANT_COL:"store_and_fwd_flag"::string   AS store_and_fwd_flag,
                -- Convert timestamps (all are valid microseconds)
        TO_TIMESTAMP_NTZ(VARIANT_COL:"lpep_pickup_datetime"::number / 1000000.0) AS pickup_datetime,
        TO_TIMESTAMP_NTZ(VARIANT_COL:"lpep_dropoff_datetime"::number / 1000000.0) AS dropoff_datetime
    FROM NYC_TAXI.RAW.GREEN_TAXI_TRIP
)
SELECT 
    * 
FROM src_green_trip