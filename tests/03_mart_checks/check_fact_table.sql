-- ============================================================
-- FACT_TAXI_TRIP GOLD DATA QUALITY VALIDATION
-- ============================================================

WITH base AS (
    SELECT *
    FROM nyc.nyc_gold.fact_taxi_trip
),

-- Re-derives the fact table's own join logic, so this checks
-- "did the MERGE match the ETL's intent" — not a 1:1 Silver
-- count, since INNER JOINs intentionally drop out-of-range trips.
expectations AS (
    SELECT COUNT(*) AS expected_rows
    FROM nyc.nyc_silver.green_taxi_silver s
    INNER JOIN nyc.nyc_gold.dim_datetime dt_pu
        ON date_trunc('hour', s.lpep_pickup_datetime) = dt_pu.full_datetime
    INNER JOIN nyc.nyc_gold.dim_datetime dt_do
        ON date_trunc('hour', s.lpep_dropoff_datetime) = dt_do.full_datetime
    INNER JOIN nyc.nyc_gold.dim_location dl_pu
        ON s.PULocationID = dl_pu.location_id
    INNER JOIN nyc.nyc_gold.dim_location dl_do
        ON s.DOLocationID = dl_do.location_id
),

dq_results AS (

    -- ========================================================
    -- 1. VOLUME
    -- ========================================================
    SELECT
        'fact_taxi_trip' AS table_name,
        'Row count vs expected join result' AS check_name,
        'VOLUME' AS check_type,
        COUNT(*) AS records_checked,
        ABS(COUNT(*) - e.expected_rows) AS failures,
        CAST(e.expected_rows AS STRING) AS expected_value,
        CAST(COUNT(*) AS STRING) AS actual_value
    FROM base
    CROSS JOIN expectations e
    GROUP BY e.expected_rows


    UNION ALL


    -- ========================================================
    -- 2. NULL - SURROGATE KEY
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Missing trip_key', 'NULL',
        COUNT(*), COUNT_IF(trip_key IS NULL),
        '0', CAST(COUNT_IF(trip_key IS NULL) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 3. UNIQUE - SURROGATE KEY
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Duplicate trip_key', 'UNIQUE',
        COUNT(*), COUNT(*) - COUNT(DISTINCT trip_key),
        '0', CAST(COUNT(*) - COUNT(DISTINCT trip_key) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 4. UNIQUE - COMPOSITE NATURAL KEY
    -- Same key green_taxi_silver deduplicates on. If this fails,
    -- the MERGE's ON clause let duplicates slip through.
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Duplicate natural key', 'UNIQUE',
        COUNT(*),
        COUNT(*) - COUNT(DISTINCT CONCAT(
            COALESCE(CAST(vendor_id AS STRING), ''), '|',
            COALESCE(CAST(lpep_pickup_datetime AS STRING), ''), '|',
            COALESCE(CAST(lpep_dropoff_datetime AS STRING), ''), '|',
            COALESCE(CAST(PULocationID AS STRING), ''), '|',
            COALESCE(CAST(DOLocationID AS STRING), ''), '|',
            COALESCE(CAST(trip_distance AS STRING), ''), '|',
            COALESCE(CAST(total_amount AS STRING), '')
        )),
        '0',
        CAST(COUNT(*) - COUNT(DISTINCT CONCAT(
            COALESCE(CAST(vendor_id AS STRING), ''), '|',
            COALESCE(CAST(lpep_pickup_datetime AS STRING), ''), '|',
            COALESCE(CAST(lpep_dropoff_datetime AS STRING), ''), '|',
            COALESCE(CAST(PULocationID AS STRING), ''), '|',
            COALESCE(CAST(DOLocationID AS STRING), ''), '|',
            COALESCE(CAST(trip_distance AS STRING), ''), '|',
            COALESCE(CAST(total_amount AS STRING), '')
        )) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 5. NULL - REQUIRED FK COLUMNS
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Missing FK columns', 'NULL',
        COUNT(*),
        COUNT_IF(
            lpep_pickup_datetime IS NULL
            OR lpep_dropoff_datetime IS NULL
            OR PULocationID IS NULL
            OR DOLocationID IS NULL
        ),
        '0',
        CAST(COUNT_IF(
            lpep_pickup_datetime IS NULL
            OR lpep_dropoff_datetime IS NULL
            OR PULocationID IS NULL
            OR DOLocationID IS NULL
        ) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 6. REFERENTIAL INTEGRITY - PICKUP LOCATION
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'PULocationID not in dim_location', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(dl.location_id IS NULL),
        '0',
        CAST(COUNT_IF(dl.location_id IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_location dl
        ON b.PULocationID = dl.location_id


    UNION ALL


    -- ========================================================
    -- 7. REFERENTIAL INTEGRITY - DROPOFF LOCATION
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'DOLocationID not in dim_location', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(dl.location_id IS NULL),
        '0',
        CAST(COUNT_IF(dl.location_id IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_location dl
        ON b.DOLocationID = dl.location_id


    UNION ALL


    -- ========================================================
    -- 8. REFERENTIAL INTEGRITY - PICKUP DATETIME
    -- FIXED: now truncates to the hour before matching, since
    -- fact_taxi_trip stores real per-minute timestamps while
    -- dim_datetime only has on-the-hour rows.
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'lpep_pickup_datetime not in dim_datetime', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(dt.full_datetime IS NULL),
        '0',
        CAST(COUNT_IF(dt.full_datetime IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_datetime dt
        ON date_trunc('hour', b.lpep_pickup_datetime) = dt.full_datetime


    UNION ALL


    -- ========================================================
    -- 8b. REFERENTIAL INTEGRITY - DROPOFF DATETIME
    -- NEW: dropoff was never checked in the original script.
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'lpep_dropoff_datetime not in dim_datetime', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(dt.full_datetime IS NULL),
        '0',
        CAST(COUNT_IF(dt.full_datetime IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_datetime dt
        ON date_trunc('hour', b.lpep_dropoff_datetime) = dt.full_datetime


    UNION ALL


    -- ========================================================
    -- 9. REFERENTIAL INTEGRITY - WEATHER (optional FK, informational only)
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'weather_key not in dim_weather (informational, LEFT JOIN is expected)', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(b.weather_key IS NOT NULL AND dw.weather_key IS NULL),
        '0',
        CAST(COUNT_IF(b.weather_key IS NOT NULL AND dw.weather_key IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_weather dw
        ON b.weather_key = dw.weather_key


    UNION ALL


    -- ========================================================
    -- 10. RANGE - TRIP DISTANCE
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Negative trip_distance', 'RANGE',
        COUNT(*), COUNT_IF(trip_distance < 0),
        '>= 0', CAST(COUNT_IF(trip_distance < 0) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 11. RANGE - TRIP DURATION
    -- Dropoff before pickup would produce a negative duration.
    -- Known issue traced back to green_taxi_silver (1 row).
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Negative trip_duration_minutes', 'RANGE',
        COUNT(*), COUNT_IF(trip_duration_minutes < 0),
        '>= 0', CAST(COUNT_IF(trip_duration_minutes < 0) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 12. ACCEPTED VALUE - PAYMENT TYPE
    -- -1 is the Silver sentinel for "was NULL", treated as valid/known-unknown.
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Invalid payment_type', 'ACCEPTED_VALUE',
        COUNT(*),
        COUNT_IF(payment_type NOT IN (1, 2, 3, 4, 5, 6, -1)),
        '1, 2, 3, 4, 5, 6, -1',
        CAST(COUNT_IF(payment_type NOT IN (1, 2, 3, 4, 5, 6, -1)) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 13. ACCEPTED VALUE - TRIP TYPE
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Invalid trip_type', 'ACCEPTED_VALUE',
        COUNT(*),
        COUNT_IF(trip_type NOT IN (1, 2, -1)),
        '1, 2, -1',
        CAST(COUNT_IF(trip_type NOT IN (1, 2, -1)) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 14. ACCEPTED VALUE - RATECODE ID
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Invalid ratecode_id', 'ACCEPTED_VALUE',
        COUNT(*),
        COUNT_IF(ratecode_id NOT IN (1, 2, 3, 4, 5, 6, 99, -1)),
        '1, 2, 3, 4, 5, 6, 99, -1',
        CAST(COUNT_IF(ratecode_id NOT IN (1, 2, 3, 4, 5, 6, 99, -1)) AS STRING)
    FROM base


    UNION ALL


    -- ========================================================
    -- 15. LINEAGE
    -- ========================================================
    SELECT
        'fact_taxi_trip', 'Missing gold_processed_timestamp/date', 'LINEAGE',
        COUNT(*),
        COUNT_IF(gold_processed_timestamp IS NULL OR gold_processed_date IS NULL),
        '0',
        CAST(COUNT_IF(gold_processed_timestamp IS NULL OR gold_processed_date IS NULL) AS STRING)
    FROM base

),


-- ============================================================
-- CALCULATE FAILURE PERCENTAGE
-- ============================================================
measured AS (
    SELECT
        table_name, check_name, check_type,
        records_checked, failures, expected_value, actual_value,
        ROUND(failures * 100.0 / NULLIF(records_checked, 0), 2) AS failure_pct
    FROM dq_results
)


-- ============================================================
-- FINAL DQ RESULT
-- ============================================================
SELECT
    table_name, check_name, check_type,
    records_checked, failures, expected_value, actual_value, failure_pct,

    CASE
        WHEN failures = 0 THEN 'PASS'

        WHEN check_type = 'NULL'
             AND check_name = 'Missing trip_key'
        THEN 'FAIL'

        WHEN check_type = 'UNIQUE' AND failure_pct <= 1 THEN 'WARN'
        WHEN check_type = 'UNIQUE' THEN 'FAIL'

        WHEN check_type = 'RANGE' AND failure_pct <= 1 THEN 'WARN'
        WHEN check_type = 'RANGE' THEN 'FAIL'

        WHEN check_type = 'ACCEPTED_VALUE' AND failure_pct <= 1 THEN 'WARN'
        WHEN check_type = 'ACCEPTED_VALUE' THEN 'FAIL'

        WHEN check_type = 'REFERENTIAL_INTEGRITY'
             AND check_name LIKE '%weather%'
        THEN 'PASS'   -- weather_key mismatch alone should never fail the table

        WHEN check_type = 'REFERENTIAL_INTEGRITY' AND failure_pct <= 1 THEN 'WARN'
        WHEN check_type = 'REFERENTIAL_INTEGRITY' THEN 'FAIL'

        WHEN check_type = 'VOLUME' AND failure_pct <= 2 THEN 'WARN'
        WHEN check_type = 'VOLUME' THEN 'FAIL'

        WHEN check_type = 'NULL' AND failure_pct <= 1 THEN 'WARN'
        WHEN check_type = 'NULL' THEN 'FAIL'

        WHEN check_type = 'LINEAGE' THEN 'FAIL'

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