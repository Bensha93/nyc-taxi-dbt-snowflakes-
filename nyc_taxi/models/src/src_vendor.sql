
-- VENDOR TABLE
-- This SQL script creates a table to store vendor information for NYC taxi trips.
-- This table contains the vendor codes used in NYC taxi trips.
-- Each vendor is represented by a unique ID and a description.
-- It defines the source table for payment types used in NYC taxi trips.
-- A code indicating the TPEP provider that provided the record.
-- 1 = Creative Mobile Technologies, LLC
-- 2 = Curb Mobility, LLC
-- 6 = Myle Technologies Inc
-- 7 = Helix

WITH src_vendor AS (
    SELECT 1 AS vendor_id, 'Creative Mobile Technologies, LLC' AS vendor_desc
    UNION ALL
    SELECT 2, 'Curb Mobility, LLC'
    UNION ALL
    SELECT 6, 'Myle Technologies Inc'
    UNION ALL
    SELECT 7, 'Helix'
)
SELECT *
FROM src_vendor
