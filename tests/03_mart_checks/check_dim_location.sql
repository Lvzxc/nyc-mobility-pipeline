-- ============================================================
-- DIM_LOCATION GOLD DATA QUALITY VALIDATION
-- ============================================================

WITH base AS (
    SELECT *
    FROM nyc.nyc_gold.dim_location
),

-- Expected values are derived from Silver.
-- Since location_id is the business key, we compare the
-- number of unique locations in Silver against Gold.
expectations AS (
    SELECT
        COUNT(DISTINCT location_id) AS silver_count
    FROM nyc.nyc_silver.taxi_zones_silver
),

dq_results AS (

    -- ========================================================
    -- 1. VOLUME
    -- Gold should contain one row for every unique location
    -- in the Silver source.
    -- ========================================================

    SELECT
        'dim_location' AS table_name,
        'Row count' AS check_name,
        'VOLUME' AS check_type,
        COUNT(*) AS records_checked,
        ABS(COUNT(*) - e.silver_count) AS failures,
        CAST(e.silver_count AS STRING) AS expected_value,
        CAST(COUNT(*) AS STRING) AS actual_value
    FROM base
    CROSS JOIN expectations e
    GROUP BY e.silver_count


    UNION ALL


    -- ========================================================
    -- 2. NULL - SURROGATE KEY
    -- location_key must always be populated.
    -- ========================================================

    SELECT
        'dim_location',
        'Missing location_key',
        'NULL',
        COUNT(*),
        COUNT_IF(location_key IS NULL),
        '0',
        CAST(
            COUNT_IF(location_key IS NULL)
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 3. UNIQUE - SURROGATE KEY
    -- location_key should uniquely identify each row.
    -- ========================================================

    SELECT
        'dim_location',
        'Duplicate location_key',
        'UNIQUE',
        COUNT(*),
        COUNT(*) - COUNT(DISTINCT location_key),
        '0',
        CAST(
            COUNT(*) - COUNT(DISTINCT location_key)
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 4. NULL - BUSINESS KEY
    -- location_id is the natural/business key and must exist.
    -- ========================================================

    SELECT
        'dim_location',
        'Missing location_id',
        'NULL',
        COUNT(*),
        COUNT_IF(location_id IS NULL),
        '0',
        CAST(
            COUNT_IF(location_id IS NULL)
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 5. UNIQUE - BUSINESS KEY
    -- Each location_id should occur only once in Gold.
    -- ========================================================

    SELECT
        'dim_location',
        'Duplicate location business key',
        'UNIQUE',
        COUNT(*),
        COUNT(*) - COUNT(DISTINCT location_id),
        '0',
        CAST(
            COUNT(*) - COUNT(DISTINCT location_id)
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 6. NULL - BOROUGH
    -- ========================================================

    SELECT
        'dim_location',
        'Missing borough',
        'NULL',
        COUNT(*),
        COUNT_IF(
            borough IS NULL
            OR TRIM(borough) = ''
        ),
        '0',
        CAST(
            COUNT_IF(
                borough IS NULL
                OR TRIM(borough) = ''
            )
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 7. NULL - ZONE
    -- ========================================================

    SELECT
        'dim_location',
        'Missing zone',
        'NULL',
        COUNT(*),
        COUNT_IF(
            zone IS NULL
            OR TRIM(zone) = ''
        ),
        '0',
        CAST(
            COUNT_IF(
                zone IS NULL
                OR TRIM(zone) = ''
            )
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 8. NULL - SERVICE ZONE
    -- ========================================================

    SELECT
        'dim_location',
        'Missing service_zone',
        'NULL',
        COUNT(*),
        COUNT_IF(
            service_zone IS NULL
            OR TRIM(service_zone) = ''
        ),
        '0',
        CAST(
            COUNT_IF(
                service_zone IS NULL
                OR TRIM(service_zone) = ''
            )
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 9. RANGE - LOCATION ID
    -- location_id should be a positive value.
    -- ========================================================

    SELECT
        'dim_location',
        'Invalid location_id',
        'RANGE',
        COUNT(*),
        COUNT_IF(
            location_id IS NULL
            OR location_id <= 0
        ),
        '> 0',
        CAST(
            COUNT_IF(
                location_id IS NULL
                OR location_id <= 0
            )
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 10. ACCEPTED VALUE - BOROUGH
    -- Check against expected NYC TLC borough values.
    -- ========================================================

    SELECT
        'dim_location',
        'Invalid borough value',
        'ACCEPTED_VALUE',
        COUNT(*),
        COUNT_IF(
            borough IS NOT NULL
            AND UPPER(TRIM(borough)) NOT IN (
                'BRONX',
                'BROOKLYN',
                'MANHATTAN',
                'QUEENS',
                'STATEN ISLAND',
                'EWR'
            )
        ),
        'BRONX, BROOKLYN, MANHATTAN, QUEENS, STATEN ISLAND, EWR',
        CAST(
            COUNT_IF(
                borough IS NOT NULL
                AND UPPER(TRIM(borough)) NOT IN (
                    'BRONX',
                    'BROOKLYN',
                    'MANHATTAN',
                    'QUEENS',
                    'STATEN ISLAND',
                    'EWR'
                )
            )
            AS STRING
        )
    FROM base


    UNION ALL


    -- ========================================================
    -- 11. BUSINESS RULE
    -- A location_id should always map to the same combination
    -- of borough, zone, and service_zone.
    -- ========================================================

    SELECT
        'dim_location',
        'Location has conflicting attributes',
        'BUSINESS_RULE',
        COUNT(*),
        COUNT(*),
        '0',
        CAST(COUNT(*) AS STRING)
    FROM (
        SELECT
            location_id
        FROM base
        GROUP BY location_id
        HAVING COUNT(
            DISTINCT CONCAT(
                COALESCE(UPPER(TRIM(borough)), ''),
                '|',
                COALESCE(UPPER(TRIM(zone)), ''),
                '|',
                COALESCE(UPPER(TRIM(service_zone)), '')
            )
        ) > 1
    )


    UNION ALL


    -- ========================================================
    -- 12. SOURCE COMPLETENESS
    -- Every location_id in Silver should exist in Gold.
    -- ========================================================

    SELECT
        'dim_location',
        'Silver locations missing from Gold',
        'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(g.location_id IS NULL),
        '0',
        CAST(
            COUNT_IF(g.location_id IS NULL)
            AS STRING
        )
    FROM (
        SELECT DISTINCT location_id
        FROM nyc.nyc_silver.taxi_zones_silver
        WHERE location_id IS NOT NULL
    ) s
    LEFT JOIN base g
        ON s.location_id = g.location_id


    UNION ALL


    -- ========================================================
    -- 13. SOURCE CONSISTENCY
    -- Every Gold location_id should exist in Silver.
    -- ========================================================

    SELECT
        'dim_location',
        'Gold locations missing from Silver',
        'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(s.location_id IS NULL),
        '0',
        CAST(
            COUNT_IF(s.location_id IS NULL)
            AS STRING
        )
    FROM base g
    LEFT JOIN (
        SELECT DISTINCT location_id
        FROM nyc.nyc_silver.taxi_zones_silver
        WHERE location_id IS NOT NULL
    ) s
        ON g.location_id = s.location_id
),


-- ============================================================
-- CALCULATE FAILURE PERCENTAGE
-- ============================================================

measured AS (
    SELECT
        table_name,
        check_name,
        check_type,
        records_checked,
        failures,
        expected_value,
        actual_value,

        ROUND(
            failures * 100.0
            / NULLIF(records_checked, 0),
            2
        ) AS failure_pct

    FROM dq_results
)


-- ============================================================
-- FINAL DQ RESULT
-- ============================================================

SELECT
    table_name,
    check_name,
    check_type,
    records_checked,
    failures,
    expected_value,
    actual_value,
    failure_pct,

    CASE

        -- No failures = PASS
        WHEN failures = 0
        THEN 'PASS'


        -- ====================================================
        -- Mandatory NULL checks
        -- ====================================================

        WHEN check_type = 'NULL'
             AND check_name IN (
                 'Missing location_key',
                 'Missing location_id',
                 'Missing borough',
                 'Missing zone',
                 'Missing service_zone'
             )
        THEN 'FAIL'


        -- ====================================================
        -- UNIQUE checks
        -- Up to 1% = WARN
        -- More than 1% = FAIL
        -- ====================================================

        WHEN check_type = 'UNIQUE'
             AND failure_pct <= 1
        THEN 'WARN'

        WHEN check_type = 'UNIQUE'
        THEN 'FAIL'


        -- ====================================================
        -- RANGE checks
        -- ====================================================

        WHEN check_type = 'RANGE'
             AND failure_pct <= 1
        THEN 'WARN'

        WHEN check_type = 'RANGE'
        THEN 'FAIL'


        -- ====================================================
        -- ACCEPTED VALUE checks
        -- ====================================================

        WHEN check_type = 'ACCEPTED_VALUE'
             AND failure_pct <= 1
        THEN 'WARN'

        WHEN check_type = 'ACCEPTED_VALUE'
        THEN 'FAIL'


        -- ====================================================
        -- BUSINESS RULE checks
        -- ====================================================

        WHEN check_type = 'BUSINESS_RULE'
             AND failure_pct <= 1
        THEN 'WARN'

        WHEN check_type = 'BUSINESS_RULE'
        THEN 'FAIL'


        -- ====================================================
        -- SOURCE / REFERENTIAL INTEGRITY checks
        -- ====================================================

        WHEN check_type = 'REFERENTIAL_INTEGRITY'
             AND failure_pct <= 1
        THEN 'WARN'

        WHEN check_type = 'REFERENTIAL_INTEGRITY'
        THEN 'FAIL'


        -- ====================================================
        -- VOLUME
        -- Up to 2% difference = WARN
        -- More than 2% = FAIL
        -- ====================================================

        WHEN check_type = 'VOLUME'
             AND failure_pct <= 2
        THEN 'WARN'

        WHEN check_type = 'VOLUME'
        THEN 'FAIL'


        -- ====================================================
        -- Other NULL checks
        -- ====================================================

        WHEN check_type = 'NULL'
             AND failure_pct <= 1
        THEN 'WARN'

        WHEN check_type = 'NULL'
        THEN 'FAIL'


        ELSE 'FAIL'

    END AS status

FROM measured

ORDER BY
    CASE
        WHEN status = 'FAIL' THEN 1
        WHEN status = 'WARN' THEN 2
        ELSE 3
    END,
    check_type,
    check_name;

