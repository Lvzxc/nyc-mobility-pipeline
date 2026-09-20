WITH metrics AS (

    SELECT
        COUNT(*) AS actual_rows,

        -- Required trip fields should not be NULL
        COUNT_IF(
            lpep_pickup_datetime IS NULL
            OR lpep_dropoff_datetime IS NULL
            OR PULocationID IS NULL
            OR DOLocationID IS NULL
        ) AS incomplete_rows,

        -- One row per unique composite trip key
        COUNT(*) - COUNT(DISTINCT STRUCT(
            VendorID,
            lpep_pickup_datetime,
            lpep_dropoff_datetime,
            PULocationID,
            DOLocationID,
            trip_distance,
            total_amount
        )) AS duplicate_trip_keys,

        -- Fields created or preserved for data lineage
        COUNT_IF(
            bronze_source_file IS NULL
            OR bronze_source_month IS NULL
            OR bronze_ingestion_timestamp IS NULL
            OR bronze_ingestion_date IS NULL
            OR silver_ingestion_timestamp IS NULL
            OR silver_ingestion_date IS NULL
        ) AS null_lineage,

        -- Fields cleaned using COALESCE() should not remain NULL
        COUNT_IF(
            RatecodeID IS NULL
            OR passenger_count IS NULL
            OR payment_type IS NULL
            OR trip_type IS NULL
            OR congestion_surcharge IS NULL
        ) AS incomplete_cleaned_fields,

        -- store_and_fwd_flag should contain only standardized values
        COUNT_IF(
            store_and_fwd_flag IS NULL
            OR store_and_fwd_flag != TRIM(store_and_fwd_flag)
            OR store_and_fwd_flag NOT IN ('Y', 'N', 'Unknown')
        ) AS invalid_store_flag

    FROM nyc.nyc_silver.green_taxi_silver
),

expected AS (

    -- Expected Silver row count after:
    -- 1. Filtering out records with missing required fields
    -- 2. Deduplicating using the 7-column composite trip key
    SELECT
        COUNT(*) AS expected_rows
    FROM (
        SELECT DISTINCT
            VendorID,
            lpep_pickup_datetime,
            lpep_dropoff_datetime,
            PULocationID,
            DOLocationID,
            trip_distance,
            total_amount
        FROM nyc.nyc_bronze.green_taxi_bronze
        WHERE
            lpep_pickup_datetime IS NOT NULL
            AND lpep_dropoff_datetime IS NOT NULL
            AND PULocationID IS NOT NULL
            AND DOLocationID IS NOT NULL
            AND date_format(lpep_pickup_datetime, 'yyyy-MM') = source_month
    )

),

checks AS (

    -- ============================================================
    -- 1. Completeness
    -- ============================================================

    SELECT
        'Completeness' AS check_name,
        incomplete_rows AS failed_rows,
        CASE
            WHEN incomplete_rows = 0 THEN 'PASS'
            ELSE 'FAIL'
        END AS status
    FROM metrics

    UNION ALL

    -- ============================================================
    -- 2. Uniqueness
    -- ============================================================

    SELECT
        'Uniqueness',
        duplicate_trip_keys,
        CASE
            WHEN duplicate_trip_keys = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    -- ============================================================
    -- 3. Lineage
    -- ============================================================

    SELECT
        'Lineage',
        null_lineage,
        CASE
            WHEN null_lineage = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    -- ============================================================
    -- 4. Standardization
    -- ============================================================

    SELECT
        'Standardization',
        invalid_store_flag,
        CASE
            WHEN invalid_store_flag = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    -- ============================================================
    -- 5. Cleaned Fields
    -- ============================================================

    SELECT
        'Cleaned Fields',
        incomplete_cleaned_fields,
        CASE
            WHEN incomplete_cleaned_fields = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    -- ============================================================
    -- 6. Volume
    -- ============================================================

    SELECT
        'Volume',
        ABS(metrics.actual_rows - expected.expected_rows),
        CASE
            WHEN metrics.actual_rows = expected.expected_rows THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics
    CROSS JOIN expected
)

SELECT *
FROM checks
ORDER BY check_name;
