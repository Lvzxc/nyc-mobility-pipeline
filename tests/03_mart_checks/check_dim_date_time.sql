-- Data Quality Audit Report for nyc_gold.dim_datetime (March - May 2026)
WITH metrics AS (
    SELECT 
        COUNT(*) AS total_records,
        COUNT(DISTINCT datetime_key) AS unique_keys,
        
        -- Lineage / Audit Metadata Checks
        SUM(CASE WHEN gold_ingestion_date IS NULL THEN 1 ELSE 0 END) AS missing_ingestion_date,
        SUM(CASE WHEN gold_ingestion_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_ingestion_timestamp,
        
        -- NULL Checks across key dimension columns
        SUM(CASE WHEN datetime_key IS NULL THEN 1 ELSE 0 END) AS missing_datetime_key,
        SUM(CASE WHEN full_datetime IS NULL THEN 1 ELSE 0 END) AS missing_full_datetime,
        SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS missing_date,
        SUM(CASE WHEN day_name IS NULL THEN 1 ELSE 0 END) AS missing_day_name,
        SUM(CASE WHEN month_name IS NULL THEN 1 ELSE 0 END) AS missing_month_name,
        SUM(CASE WHEN time_period IS NULL THEN 1 ELSE 0 END) AS missing_time_period,
        
        -- Standardization & Business Logic Checks
        SUM(CASE WHEN time_period NOT IN ('Morning', 'Afternoon', 'Evening', 'Night', 'Unknown') THEN 1 ELSE 0 END) AS invalid_time_period,
        SUM(CASE 
            WHEN datetime_key > 0 AND (
                (day_of_week IN (1, 7) AND is_weekend = FALSE) OR 
                (day_of_week BETWEEN 2 AND 6 AND is_weekend = TRUE)
            ) THEN 1 ELSE 0 
        END) AS invalid_weekend_flag,
        SUM(CASE 
            WHEN datetime_key > 0 AND (
                (day_of_week BETWEEN 2 AND 6 AND hour IN (7, 8, 9, 16, 17, 18, 19) AND is_rush_hour = FALSE) OR
                ((day_of_week IN (1, 7) OR hour NOT IN (7, 8, 9, 16, 17, 18, 19)) AND is_rush_hour = TRUE)
            ) THEN 1 ELSE 0 
        END) AS invalid_rush_hour_flag,
        
        -- Date Range Check (only March 1 - May 31, 2026 allowed, excluding Unknown row)
        SUM(CASE WHEN datetime_key > 0 AND (date < '2026-03-01' OR date > '2026-05-31') THEN 1 ELSE 0 END) AS out_of_range_dates
    FROM nyc.nyc_gold.dim_datetime
),
dq_results AS (
    -- 1. LINEAGE CHECKS
    SELECT 
        'dim_datetime' AS table_name,
        'Missing gold_ingestion_date' AS check_name,
        'LINEAGE' AS check_type,
        total_records AS records_checked,
        missing_ingestion_date AS failures,
        0 AS expected_value,
        ROUND((missing_ingestion_date / total_records) * 100, 2) AS failure_pct,
        CASE WHEN missing_ingestion_date = 0 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM metrics

    UNION ALL

    SELECT 
        'dim_datetime',
        'Missing gold_ingestion_timestamp',
        'LINEAGE',
        total_records,
        missing_ingestion_timestamp,
        0,
        ROUND((missing_ingestion_timestamp / total_records) * 100, 2),
        CASE WHEN missing_ingestion_timestamp = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    -- 2. NULL CHECKS
    SELECT 
        'dim_datetime',
        'Missing datetime_key',
        'NULL',
        total_records,
        missing_datetime_key,
        0,
        ROUND((missing_datetime_key / total_records) * 100, 2),
        CASE WHEN missing_datetime_key = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    SELECT 
        'dim_datetime',
        'Missing full_datetime',
        'NULL',
        total_records,
        missing_full_datetime,
        0,
        ROUND((missing_full_datetime / total_records) * 100, 2),
        CASE WHEN missing_full_datetime = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    SELECT 
        'dim_datetime',
        'Missing date',
        'NULL',
        total_records,
        missing_date,
        0,
        ROUND((missing_date / total_records) * 100, 2),
        CASE WHEN missing_date = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    SELECT 
        'dim_datetime',
        'Missing day_name',
        'NULL',
        total_records,
        missing_day_name,
        0,
        ROUND((missing_day_name / total_records) * 100, 2),
        CASE WHEN missing_day_name = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    SELECT 
        'dim_datetime',
        'Missing month_name',
        'NULL',
        total_records,
        missing_month_name,
        0,
        ROUND((missing_month_name / total_records) * 100, 2),
        CASE WHEN missing_month_name = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    -- 3. STANDARDIZATION & LOGIC CHECKS
    SELECT 
        'dim_datetime',
        'Unstandardized text values',
        'STANDARDIZATION',
        total_records,
        invalid_time_period,
        0,
        ROUND((invalid_time_period / total_records) * 100, 2),
        CASE WHEN invalid_time_period = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    SELECT 
        'dim_datetime',
        'Invalid weekend flag logic',
        'STANDARDIZATION',
        total_records,
        invalid_weekend_flag,
        0,
        ROUND((invalid_weekend_flag / total_records) * 100, 2),
        CASE WHEN invalid_weekend_flag = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    SELECT 
        'dim_datetime',
        'Invalid rush hour flag logic',
        'STANDARDIZATION',
        total_records,
        invalid_rush_hour_flag,
        0,
        ROUND((invalid_rush_hour_flag / total_records) * 100, 2),
        CASE WHEN invalid_rush_hour_flag = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    -- 4. PRIMARY KEY UNIQUENESS CHECK
    SELECT 
        'dim_datetime',
        'Duplicate datetime_key primary key',
        'UNIQUE',
        total_records,
        (total_records - unique_keys),
        0,
        ROUND(((total_records - unique_keys) / total_records) * 100, 2),
        CASE WHEN total_records = unique_keys THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    -- 5. VOLUME CHECK (March 1 – May 31, 2026: 2,208 hours + 1 Unknown row = 2,209 records)
    SELECT 
        'dim_datetime',
        'Expected hourly row count match (March-May 2026)',
        'VOLUME',
        total_records,
        ABS(total_records - 2209),
        2209,
        ROUND((ABS(total_records - 2209) / 2209.0) * 100, 2),
        CASE WHEN total_records = 2209 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics

    UNION ALL

    -- 6. DATE RANGE CHECK (only March 1 - May 31, 2026 expected)
    SELECT 
        'dim_datetime',
        'Records outside March-May 2026 date range',
        'DATE_RANGE',
        total_records,
        out_of_range_dates,
        0,
        ROUND((out_of_range_dates / total_records) * 100, 2),
        CASE WHEN out_of_range_dates = 0 THEN 'PASS' ELSE 'FAIL' END
    FROM metrics
)
SELECT 
    table_name,
    check_name,
    check_type,
    records_checked,
    failures,
    expected_value,
    failure_pct,
    status
FROM dq_results;
