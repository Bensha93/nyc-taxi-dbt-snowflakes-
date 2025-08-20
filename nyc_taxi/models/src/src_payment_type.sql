
-- PAYMENT TYPE TABLE
-- This SQL script creates a table to store payment type information for NYC taxi trips.
-- This table contains the payment type codes used in NYC taxi trips.
-- Each payment type is represented by a unique ID and a description.
-- The payment types are as follows:
-- 0 = Flex Fare trip
-- 1 = Credit card
-- 2 = Cash
-- 3 = No charge
-- 4 = Dispute
-- 5 = Unknown
-- 6 = Voided trip

WITH src_payment_type AS (
    SELECT 0 AS payment_type_id, 'Flex Fare trip' AS payment_type_desc
    UNION ALL
    SELECT 1, 'Credit card'
    UNION ALL
    SELECT 2, 'Cash'
    UNION ALL
    SELECT 3, 'No charge'
    UNION ALL
    SELECT 4, 'Dispute'
    UNION ALL
    SELECT 5, 'Unknown'
    UNION ALL
    SELECT 6, 'Voided trip'
)
SELECT *
FROM src_payment_type