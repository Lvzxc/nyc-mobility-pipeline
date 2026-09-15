WITH metrics AS (
    SELECT
        COUNT(*) AS actual_rows,
        MIN(timestamp) AS min_timestamp,
        MAX(timestamp) AS max_timestamp,

        COUNT_IF(
            timestamp IS NULL
            OR temperature_2m IS NULL
            OR precipitation IS NULL
            OR rain IS NULL
            OR snowfall IS NULL
            OR wind_speed_10m IS NULL
            OR weather_code IS NULL
        ) AS incomplete_rows,

        COUNT(*) - COUNT(DISTINCT timestamp) AS duplicate_timestamps,

        COUNT_IF(source_file IS NULL) AS null_source_file

    FROM nyc.nyc_bronze.open_meteo_bronze
),

expectations AS (
    SELECT
        TIMESTAMP('2026-03-01 00:00:00') AS expected_start,
        TIMESTAMP('2026-05-31 23:00:00') AS expected_end
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
        'Source file is populated',
        '0',
        CAST(null_source_file AS STRING),
        CASE
            WHEN null_source_file = 0 THEN 'PASS'
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
                expected_start,
                expected_end
            ) + 1
            AS STRING
        ),
        CAST(actual_rows AS STRING),
        CASE
            WHEN actual_rows =
                TIMESTAMPDIFF(
                    HOUR,
                    expected_start,
                    expected_end
                ) + 1
            THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics
    CROSS JOIN expectations

    UNION ALL

    -- Validity
    SELECT
        'Validity',
        'Expected timestamp range',
        CONCAT(
            CAST(expected_start AS STRING),
            ' → ',
            CAST(expected_end AS STRING)
        ),
        CONCAT(
            CAST(min_timestamp AS STRING),
            ' → ',
            CAST(max_timestamp AS STRING)
        ),
        CASE
            WHEN min_timestamp = expected_start
             AND max_timestamp = expected_end
            THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics
    CROSS JOIN expectations
)

SELECT
    dimension,
    check_name,
    expected,
    actual,
    status
FROM checks
ORDER BY dimension;