WITH metrics AS (
    SELECT
        COUNT(*) AS actual_rows,

        -- Required fields should not be NULL
        COUNT_IF(
            timestamp IS NULL
            OR temperature_2m IS NULL
            OR precipitation IS NULL
            OR rain IS NULL
            OR snowfall IS NULL
            OR wind_speed_10m IS NULL
            OR weather_code IS NULL
        ) AS incomplete_rows,

        -- One row per hourly timestamp
        COUNT(*) - COUNT(DISTINCT timestamp) AS duplicate_timestamps,

        -- Lineage and Silver processing metadata should exist
        COUNT_IF(
            source_file IS NULL
            OR ingestion_timestamp IS NULL
            OR ingestion_date IS NULL
            OR silver_processed_timestamp IS NULL
            OR silver_processed_date IS NULL
        ) AS null_lineage,

        -- Weather measurements should not be negative
        COUNT_IF(
            precipitation < 0
            OR rain < 0
            OR snowfall < 0
            OR wind_speed_10m < 0
        ) AS invalid_values

    FROM nyc.nyc_silver.clean_weather
),

checks AS (

    SELECT
        'Completeness' AS check_name,
        incomplete_rows AS failed_rows,
        CASE
            WHEN incomplete_rows = 0 THEN 'PASS'
            ELSE 'FAIL'
        END AS status
    FROM metrics

    UNION ALL

    SELECT
        'Uniqueness',
        duplicate_timestamps,
        CASE
            WHEN duplicate_timestamps = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    SELECT
        'Lineage',
        null_lineage,
        CASE
            WHEN null_lineage = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    SELECT
        'Validity',
        invalid_values,
        CASE
            WHEN invalid_values = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    SELECT
        'Volume',
        ABS(actual_rows - 2208),
        CASE
            WHEN actual_rows = 2208 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics
)

SELECT *
FROM checks
ORDER BY check_name;