
-- TRIP TYPE TABLE
-- This table categorizes taxi trips into two types: street-hail and dispatch.
-- It is used to analyze the nature of trips taken by passengers in NYC taxis.
-- The trip type is determined based on the method of how the trip was hailed.
-- A code indicating whether the trip was a street-hail or a dispatch trip.
-- The table contains the following columns:
-- 1 = Street-hail
-- 2 = Dispatch

WITH src_trip_type AS (
    SELECT
        1 AS trip_type_code,
        'Street-hail' AS trip_type_desc
    UNION ALL
    SELECT
        2,
        'Dispatch'
)
SELECT *
FROM src_trip_type

