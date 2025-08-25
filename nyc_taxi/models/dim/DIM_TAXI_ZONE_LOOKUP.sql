SELECT
    t.LOCATIONID,
    t.ZONE,
    t.SERVICE_ZONE,
    b.BOROUGH_ID
FROM
    TLC.RAW.TAXI_ZONE_LOOKUP t
LEFT JOIN
    NYC_TAXI.RAW.DIM_BOROUGH b
ON
    -- Exact match first
    UPPER(TRIM(t.borough)) = UPPER(TRIM(b.BOROUGH))
    OR
    -- Handle common variations
    (UPPER(TRIM(t.borough)) = 'MANHATTAN' AND UPPER(TRIM(b.BOROUGH)) LIKE '%MANHATTAN%')
    OR
    (UPPER(TRIM(t.borough)) = 'BROOKLYN' AND UPPER(TRIM(b.BOROUGH)) LIKE '%BROOKLYN%')
    OR
    (UPPER(TRIM(t.borough)) = 'QUEENS' AND UPPER(TRIM(b.BOROUGH)) LIKE '%QUEENS%')
    OR
    (UPPER(TRIM(t.borough)) LIKE '%BRONX%' AND UPPER(TRIM(b.BOROUGH)) LIKE '%BRONX%')
    OR
    (UPPER(TRIM(t.borough)) LIKE '%STATEN%' AND UPPER(TRIM(b.BOROUGH)) LIKE '%STATEN%')
    OR
    (UPPER(TRIM(t.borough)) LIKE '%NEWARK%' AND UPPER(TRIM(b.BOROUGH)) LIKE '%NEWARK%')
    OR
    -- General fuzzy matching
    (
        LENGTH(t.borough) > 3 
        AND LENGTH(b.BOROUGH) > 3
        AND (
            UPPER(TRIM(t.borough)) LIKE '%' || UPPER(TRIM(b.BOROUGH)) || '%'
            OR
            UPPER(TRIM(b.BOROUGH)) LIKE '%' || UPPER(TRIM(t.borough)) || '%'
        )
    )