WITH metrics AS (
    SELECT
        COUNT(*) AS actual_rows,
        MIN(timestamp) AS min_timestamp,
        MAX(timestamp) AS max_timestamp,

        COUNT_IF(
            timestamp IS NULL
            OR weather_date IS NULL
            OR weather_hour IS NULL
            OR temperature_2m IS NULL
            OR precipitation IS NULL
            OR rain IS NULL
            OR snowfall IS NULL
            OR wind_speed_10m IS NULL
            OR weather_code IS NULL
        ) AS incomplete_rows,

        COUNT(*) - COUNT(DISTINCT timestamp) AS duplicate_timestamps,

        COUNT_IF(
            source_file IS NULL
            OR ingestion_timestamp IS NULL
            OR ingestion_date IS NULL
            OR silver_processed_timestamp IS NULL
            OR silver_processed_date IS NULL
        ) AS null_lineage,

        COUNT_IF(
            weather_date != CAST(timestamp AS DATE)
            OR weather_hour != HOUR(timestamp)
        ) AS transformation_errors,

        COUNT_IF(
            precipitation < 0
            OR rain < 0
            OR snowfall < 0
            OR wind_speed_10m < 0
            OR weather_hour NOT BETWEEN 0 AND 23
        ) AS invalid_values

    FROM nyc.nyc_silver.open_meteo_silver
),

checks AS (

    -- Completeness
    SELECT
        'Completeness' AS dimension,
        'Required fields are not NULL' AS check_name,
        '0' AS expected,
        CAST(incomplete_rows AS STRING) AS actual,
        CASE
            WHEN incomplete_rows = 0 THEN 'PASS'
            ELSE 'FAIL'
        END AS status
    FROM metrics

    UNION ALL

    -- Uniqueness
    SELECT
        'Uniqueness',
        'Timestamp is unique',
        '0',
        CAST(duplicate_timestamps AS STRING),
        CASE
            WHEN duplicate_timestamps = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    -- Lineage
    SELECT
        'Lineage',
        'Required lineage fields are populated',
        '0',
        CAST(null_lineage AS STRING),
        CASE
            WHEN null_lineage = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    -- Transformation
    SELECT
        'Transformation',
        'Weather date and hour match timestamp',
        '0',
        CAST(transformation_errors AS STRING),
        CASE
            WHEN transformation_errors = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    -- Validity
    SELECT
        'Validity',
        'Weather values are within valid ranges',
        '0',
        CAST(invalid_values AS STRING),
        CASE
            WHEN invalid_values = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    -- Volume
    SELECT
        'Volume',
        'Expected hourly row count',
        CAST(
            TIMESTAMPDIFF(
                HOUR,
                min_timestamp,
                max_timestamp
            ) + 1
            AS STRING
        ),
        CAST(actual_rows AS STRING),
        CASE
            WHEN actual_rows =
                TIMESTAMPDIFF(
                    HOUR,
                    min_timestamp,
                    max_timestamp
                ) + 1
            THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics
)

SELECT
    dimension,
    check_name,
    expected,
    actual,
    status
FROM checks
ORDER BY dimension;