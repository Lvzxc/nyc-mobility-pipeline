-- TAXI ZONES SILVER DATA QUALITY VALIDATION

WITH base AS (
    SELECT * 
    FROM nyc.nyc_silver.taxi_zones_silver
),

bronze_expectations AS (
    SELECT COUNT(*) AS bronze_count 
    FROM nyc.nyc_bronze.taxi_zone_bronze
),

dq_results AS (
    -- \Volume Check (Bronze-to-Silver record count alignment)
    SELECT 
        'taxi_zones_silver' AS table_name,
        'Bronze-to-Silver row count match' AS check_name,
        'VOLUME' AS check_type,
        COUNT(*) AS records_checked,
        CASE 
            WHEN COUNT(*) = e.bronze_count THEN 0 
            ELSE ABS(COUNT(*) - e.bronze_count) 
        END AS failures,
        CAST(e.bronze_count AS STRING) AS expected_value
    FROM base 
    CROSS JOIN bronze_expectations e 
    GROUP BY e.bronze_count

    UNION ALL

    -- 2. Primary Key Mandatory NULL Check
    SELECT 
        'taxi_zones_silver', 
        'Missing location_id', 
        'NULL', 
        COUNT(*), 
        COUNT_IF(location_id IS NULL), 
        '0' 
    FROM base

    UNION ALL

    -- 3. Dimension Field NULL Checks
    SELECT 
        'taxi_zones_silver', 
        'Missing borough', 
        'NULL', 
        COUNT(*), 
        COUNT_IF(borough IS NULL), 
        '0' 
    FROM base

    UNION ALL

    SELECT 
        'taxi_zones_silver', 
        'Missing zone', 
        'NULL', 
        COUNT(*), 
        COUNT_IF(zone IS NULL), 
        '0' 
    FROM base

    UNION ALL

    SELECT 
        'taxi_zones_silver', 
        'Missing service_zone', 
        'NULL', 
        COUNT(*), 
        COUNT_IF(service_zone IS NULL), 
        '0' 
    FROM base

    UNION ALL

    -- 4. Primary Key Uniqueness Check
    SELECT 
        'taxi_zones_silver', 
        'Duplicate location_id primary key', 
        'UNIQUE', 
        COUNT(*), 
        COUNT(*) - COUNT(DISTINCT location_id), 
        '0' 
    FROM base

    UNION ALL

    -- 5. Standardization Check (Untrimmed Whitespace Detection)
    SELECT 
        'taxi_zones_silver', 
        'Unstandardized text values', 
        'STANDARDIZATION', 
        COUNT(*), 
        COUNT_IF(
            borough <> TRIM(borough) 
            OR zone <> TRIM(zone) 
            OR service_zone <> TRIM(service_zone)
        ), 
        '0' 
    FROM base

    UNION ALL

    -- 6. Borough Validity Check (must be one of the known NYC boroughs)
    SELECT 
        'taxi_zones_silver', 
        'Invalid borough value', 
        'VALIDITY', 
        COUNT(*), 
        COUNT_IF(
            borough NOT IN ('EWR', 'Queens', 'Bronx', 'Manhattan', 'Staten Island', 'Brooklyn', 'Unknown')
        ), 
        'EWR, Queens, Bronx, Manhattan, Staten Island, Brooklyn, Unknown' 
    FROM base

    UNION ALL

    -- 7. Service Zone Validity Check (must be one of the known service zones)
    SELECT 
        'taxi_zones_silver', 
        'Invalid service_zone value', 
        'VALIDITY', 
        COUNT(*), 
        COUNT_IF(
            service_zone NOT IN ('EWR', 'Boro Zone', 'Yellow Zone', 'Airports')
        ), 
        'EWR, Boro Zone, Yellow Zone, Airports' 
    FROM base

    UNION ALL

    -- 8. Audit Lineage Checks
    SELECT 
        'taxi_zones_silver', 
        'Missing silver_ingestion_timestamp', 
        'LINEAGE', 
        COUNT(*), 
        COUNT_IF(silver_ingestion_timestamp IS NULL), 
        '0' 
    FROM base

    UNION ALL

    SELECT 
        'taxi_zones_silver', 
        'Missing silver_ingestion_date', 
        'LINEAGE', 
        COUNT(*), 
        COUNT_IF(silver_ingestion_date IS NULL), 
        '0' 
    FROM base
),

-- Calculate failure percentages prior to threshold evaluation
measured AS (
    SELECT 
        table_name,
        check_name,
        check_type,
        records_checked,
        failures,
        expected_value,
        ROUND(failures * 100.0 / NULLIF(records_checked, 0), 2) AS failure_pct
    FROM dq_results
)

-- Apply DQ framework status rules and threshold evaluations
SELECT 
    table_name,
    check_name,
    check_type,
    records_checked,
    failures,
    expected_value,
    failure_pct,
    CASE 
        -- Absolute pass when zero failures occur
        WHEN failures = 0 THEN 'PASS'
        
        -- Mandatory Primary Key NULL check: any failure triggers FAIL
        WHEN check_name = 'Missing location_id' THEN 'FAIL'
        
        -- Uniqueness checks: 1% warning threshold
        WHEN check_type = 'UNIQUE' AND failure_pct <= 1.0 THEN 'WARN'
        WHEN check_type = 'UNIQUE' THEN 'FAIL'
        
        -- Dimension NULL checks: 1% warning threshold
        WHEN check_type = 'NULL' AND failure_pct <= 1.0 THEN 'WARN'
        WHEN check_type = 'NULL' THEN 'FAIL'
        
        -- Volume checks: 2% warning threshold
        WHEN check_type = 'VOLUME' AND failure_pct <= 2.0 THEN 'WARN'
        WHEN check_type = 'VOLUME' THEN 'FAIL'
        
        -- Standardization, Lineage & Validity checks: 1% warning threshold
        WHEN check_type IN ('STANDARDIZATION', 'LINEAGE', 'VALIDITY') AND failure_pct <= 1.0 THEN 'WARN'
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
