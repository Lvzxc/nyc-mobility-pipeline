-- ============================================================
-- FACT_TAXI_TRIP GOLD DATA QUALITY VALIDATION
-- ============================================================

WITH base AS (
    SELECT *
    FROM nyc.nyc_gold.fact_taxi_trip
),

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

    -- 1. VOLUME
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

    -- 2. NULL - SURROGATE PRIMARY KEY
    SELECT
        'fact_taxi_trip', 'Missing trip_key', 'NULL',
        COUNT(*), COUNT_IF(trip_key IS NULL),
        '0', CAST(COUNT_IF(trip_key IS NULL) AS STRING)
    FROM base

    UNION ALL

    -- 3. NULL - SURROGATE FOREIGN KEYS
    SELECT
        'fact_taxi_trip', 'Missing surrogate FK columns', 'NULL',
        COUNT(*),
        COUNT_IF(
            pickup_datetime_key IS NULL OR dropoff_datetime_key IS NULL
            OR pickup_location_key IS NULL OR dropoff_location_key IS NULL
        ),
        '0',
        CAST(COUNT_IF(
            pickup_datetime_key IS NULL OR dropoff_datetime_key IS NULL
            OR pickup_location_key IS NULL OR dropoff_location_key IS NULL
        ) AS STRING)
    FROM base

    UNION ALL

    -- 4. UNIQUE - SURROGATE KEY
    SELECT
        'fact_taxi_trip', 'Duplicate trip_key', 'UNIQUE',
        COUNT(*), COUNT(*) - COUNT(DISTINCT trip_key),
        '0', CAST(COUNT(*) - COUNT(DISTINCT trip_key) AS STRING)
    FROM base

    UNION ALL

    -- 5. UNIQUE - COMPOSITE NATURAL KEY
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

    -- 6. NULL - REQUIRED NATURAL FK COLUMNS
    SELECT
        'fact_taxi_trip', 'Missing natural FK columns', 'NULL',
        COUNT(*),
        COUNT_IF(
            lpep_pickup_datetime IS NULL OR lpep_dropoff_datetime IS NULL
            OR PULocationID IS NULL OR DOLocationID IS NULL
        ),
        '0',
        CAST(COUNT_IF(
            lpep_pickup_datetime IS NULL OR lpep_dropoff_datetime IS NULL
            OR PULocationID IS NULL OR DOLocationID IS NULL
        ) AS STRING)
    FROM base

    UNION ALL

    -- 7. REFERENTIAL INTEGRITY - PICKUP LOCATION
    SELECT
        'fact_taxi_trip', 'pickup_location_key not in dim_location', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(b.pickup_location_key IS NOT NULL AND dl.location_key IS NULL),
        '0',
        CAST(COUNT_IF(b.pickup_location_key IS NOT NULL AND dl.location_key IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_location dl ON b.pickup_location_key = dl.location_key

    UNION ALL

    -- 8. REFERENTIAL INTEGRITY - DROPOFF LOCATION
    SELECT
        'fact_taxi_trip', 'dropoff_location_key not in dim_location', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(b.dropoff_location_key IS NOT NULL AND dl.location_key IS NULL),
        '0',
        CAST(COUNT_IF(b.dropoff_location_key IS NOT NULL AND dl.location_key IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_location dl ON b.dropoff_location_key = dl.location_key

    UNION ALL

    -- 9. REFERENTIAL INTEGRITY - PICKUP DATETIME
    SELECT
        'fact_taxi_trip', 'pickup_datetime_key not in dim_datetime', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(b.pickup_datetime_key IS NOT NULL AND dt.datetime_key IS NULL),
        '0',
        CAST(COUNT_IF(b.pickup_datetime_key IS NOT NULL AND dt.datetime_key IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_datetime dt ON b.pickup_datetime_key = dt.datetime_key

    UNION ALL

    -- 10. REFERENTIAL INTEGRITY - DROPOFF DATETIME
    SELECT
        'fact_taxi_trip', 'dropoff_datetime_key not in dim_datetime', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(b.dropoff_datetime_key IS NOT NULL AND dt.datetime_key IS NULL),
        '0',
        CAST(COUNT_IF(b.dropoff_datetime_key IS NOT NULL AND dt.datetime_key IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_datetime dt ON b.dropoff_datetime_key = dt.datetime_key

    UNION ALL

    -- 11. REFERENTIAL INTEGRITY - WEATHER (optional FK, informational only)
    SELECT
        'fact_taxi_trip', 'weather_key not in dim_weather (informational, LEFT JOIN is expected)', 'REFERENTIAL_INTEGRITY',
        COUNT(*),
        COUNT_IF(b.weather_key IS NOT NULL AND dw.weather_key IS NULL),
        '0',
        CAST(COUNT_IF(b.weather_key IS NOT NULL AND dw.weather_key IS NULL) AS STRING)
    FROM base b
    LEFT JOIN nyc.nyc_gold.dim_weather dw ON b.weather_key = dw.weather_key

    UNION ALL

    -- 12. RANGE - TRIP DISTANCE
    -- TIGHTENED: Silver now requires trip_distance > 0 (was >= 0).
    -- A stale Gold row with distance = 0 would now be flagged.
    SELECT
        'fact_taxi_trip', 'Invalid trip_distance', 'RANGE',
        COUNT(*), COUNT_IF(trip_distance <= 0),
        '> 0', CAST(COUNT_IF(trip_distance <= 0) AS STRING)
    FROM base

    UNION ALL

    -- 13. RANGE - TRIP DURATION
    SELECT
        'fact_taxi_trip', 'Negative trip_duration_minutes', 'RANGE',
        COUNT(*), COUNT_IF(trip_duration_minutes < 0),
        '>= 0', CAST(COUNT_IF(trip_duration_minutes < 0) AS STRING)
    FROM base

    UNION ALL

    -- 14. RANGE - FARE AMOUNT
    -- NEW: mirrors Silver's fare_amount >= 0 filter.
    SELECT
        'fact_taxi_trip', 'Negative fare_amount', 'RANGE',
        COUNT(*), COUNT_IF(fare_amount < 0),
        '>= 0', CAST(COUNT_IF(fare_amount < 0) AS STRING)
    FROM base

    UNION ALL

    -- 15. RANGE - TOTAL AMOUNT
    -- NEW: mirrors Silver's total_amount >= 0 filter.
    SELECT
        'fact_taxi_trip', 'Negative total_amount', 'RANGE',
        COUNT(*), COUNT_IF(total_amount < 0),
        '>= 0', CAST(COUNT_IF(total_amount < 0) AS STRING)
    FROM base

    UNION ALL

    -- 16. RANGE - PASSENGER COUNT
    -- NEW: mirrors Silver's passenger_count > 0 filter. Note this
    -- also now catches the old -1 COALESCE sentinel, since Silver
    -- drops those rows entirely under the new rule.
    SELECT
        'fact_taxi_trip', 'Invalid passenger_count', 'RANGE',
        COUNT(*), COUNT_IF(passenger_count <= 0),
        '> 0', CAST(COUNT_IF(passenger_count <= 0) AS STRING)
    FROM base

    UNION ALL

    -- 17. ACCEPTED VALUE - PAYMENT TYPE
    SELECT
        'fact_taxi_trip', 'Invalid payment_type', 'ACCEPTED_VALUE',
        COUNT(*),
        COUNT_IF(payment_type NOT IN (1, 2, 3, 4, 5, 6, -1)),
        '1, 2, 3, 4, 5, 6, -1',
        CAST(COUNT_IF(payment_type NOT IN (1, 2, 3, 4, 5, 6, -1)) AS STRING)
    FROM base

    UNION ALL

    -- 18. ACCEPTED VALUE - TRIP TYPE
    SELECT
        'fact_taxi_trip', 'Invalid trip_type', 'ACCEPTED_VALUE',
        COUNT(*),
        COUNT_IF(trip_type NOT IN (1, 2, -1)),
        '1, 2, -1',
        CAST(COUNT_IF(trip_type NOT IN (1, 2, -1)) AS STRING)
    FROM base

    UNION ALL

    -- 19. ACCEPTED VALUE - RATECODE ID
    SELECT
        'fact_taxi_trip', 'Invalid ratecode_id', 'ACCEPTED_VALUE',
        COUNT(*),
        COUNT_IF(ratecode_id NOT IN (1, 2, 3, 4, 5, 6, 99, -1)),
        '1, 2, 3, 4, 5, 6, 99, -1',
        CAST(COUNT_IF(ratecode_id NOT IN (1, 2, 3, 4, 5, 6, 99, -1)) AS STRING)
    FROM base

    UNION ALL

    -- 20. LINEAGE
    SELECT
        'fact_taxi_trip', 'Missing gold_processed_timestamp/date', 'LINEAGE',
        COUNT(*),
        COUNT_IF(gold_processed_timestamp IS NULL OR gold_processed_date IS NULL),
        '0',
        CAST(COUNT_IF(gold_processed_timestamp IS NULL OR gold_processed_date IS NULL) AS STRING)
    FROM base

),

measured AS (
    SELECT
        table_name, check_name, check_type,
        records_checked, failures, expected_value, actual_value,
        ROUND(failures * 100.0 / NULLIF(records_checked, 0), 2) AS failure_pct
    FROM dq_results
)

SELECT
    table_name, check_name, check_type,
    records_checked, failures, expected_value, actual_value, failure_pct,

    CASE
        WHEN failures = 0 THEN 'PASS'

        WHEN check_type = 'NULL'
             AND check_name IN ('Missing trip_key', 'Missing surrogate FK columns')
        THEN 'FAIL'

        WHEN check_type = 'UNIQUE' AND failure_pct <= 1 THEN 'WARN'
        WHEN check_type = 'UNIQUE' THEN 'FAIL'

        WHEN check_type = 'RANGE' AND failure_pct <= 1 THEN 'WARN'
        WHEN check_type = 'RANGE' THEN 'FAIL'

        WHEN check_type = 'ACCEPTED_VALUE' AND failure_pct <= 1 THEN 'WARN'
        WHEN check_type = 'ACCEPTED_VALUE' THEN 'FAIL'

        WHEN check_type = 'REFERENTIAL_INTEGRITY'
             AND check_name LIKE '%weather%'
        THEN 'PASS'

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