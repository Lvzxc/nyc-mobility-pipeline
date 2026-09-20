WITH metrics AS (
    SELECT
        COUNT(*) AS actual_rows,

        -- Required weather fields should not be NULL
        COUNT_IF(
            weather_datetime IS NULL
            OR temperature_2m IS NULL
            OR precipitation IS NULL
            OR rain IS NULL
            OR snowfall IS NULL
            OR wind_speed_10m IS NULL
            OR weather_code IS NULL
            OR weather_condition IS NULL
        ) AS incomplete_rows,

        -- One weather record per hourly timestamp
        COUNT(*) - COUNT(DISTINCT weather_datetime) AS duplicate_timestamps,

        -- Weather measurements should not contain negative values
        COUNT_IF(
            precipitation < 0
            OR rain < 0
            OR snowfall < 0
            OR wind_speed_10m < 0
        ) AS invalid_measurements,

        -- Every weather code should have a mapped condition
        COUNT_IF(
            weather_condition = 'Unknown'
            OR weather_condition IS NULL
        ) AS unmapped_conditions,

        -- Weather key should be populated and unique
        COUNT_IF(weather_key IS NULL) AS null_weather_keys,

        COUNT(*) - COUNT(DISTINCT weather_key) AS duplicate_weather_keys,

        MIN(weather_datetime) AS min_datetime,
        MAX(weather_datetime) AS max_datetime

    FROM nyc.nyc_gold.dim_weather
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
        'Measurement Validity',
        invalid_measurements,
        CASE
            WHEN invalid_measurements = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    SELECT
        'Weather Code Mapping',
        unmapped_conditions,
        CASE
            WHEN unmapped_conditions = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    SELECT
        'Weather Key Completeness',
        null_weather_keys,
        CASE
            WHEN null_weather_keys = 0 THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics

    UNION ALL

    SELECT
        'Weather Key Uniqueness',
        duplicate_weather_keys,
        CASE
            WHEN duplicate_weather_keys = 0 THEN 'PASS'
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

    UNION ALL

    SELECT
        'Timestamp Range',
        CASE
            WHEN min_datetime = '2026-03-01 00:00:00'
             AND max_datetime = '2026-05-31 23:00:00'
            THEN 0
            ELSE 1
        END,
        CASE
            WHEN min_datetime = '2026-03-01 00:00:00'
             AND max_datetime = '2026-05-31 23:00:00'
            THEN 'PASS'
            ELSE 'FAIL'
        END
    FROM metrics
)

SELECT *
FROM checks
ORDER BY check_name;
