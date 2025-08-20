-- RATE CODE TABLE
-- This SQL script creates a table to store rate code information for NYC taxi trips.
-- It creates a table to store rate code information for NYC taxi trips.
-- Each rate code is represented by a unique ID and a description.
-- The final rate code in effect at the end of the trip.
-- 1 = Standard rate
-- 2 = JFK
-- 3 = Newark
-- 4 = Nassau or Westchester
-- 5 = Negotiated fare
-- 6 = Group ride
-- 99 = Null/unknown

WITH src_rate_code AS (
    SELECT 1 AS rate_code_id, 'Standard rate' AS rate_code_desc
    UNION ALL
    SELECT 2, 'JFK'
    UNION ALL
    SELECT 3, 'Newark'
    UNION ALL
    SELECT 4, 'Nassau or Westchester'
    UNION ALL
    SELECT 5, 'Negotiated fare'
    UNION ALL
    SELECT 6, 'Group ride'
    UNION ALL
    SELECT 99, 'Null/unknown'
)
SELECT *
FROM src_rate_code