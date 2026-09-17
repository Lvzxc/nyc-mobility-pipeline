-- Create Silver target table for NYC Taxi Zones if it does not already exist
CREATE TABLE IF NOT EXISTS nyc.nyc_silver.taxi_zones_silver (
    location_id INT,
    borough STRING,
    zone STRING,
    service_zone STRING,
    bronze_ingestion_timestamp TIMESTAMP,
    bronze_ingestion_date DATE,
    silver_ingestion_timestamp TIMESTAMP,
    silver_ingestion_date DATE
);

-- Execute MERGE INTO operation to synchronize Silver from Bronze
MERGE INTO nyc.nyc_silver.taxi_zones_silver AS target
USING (
    SELECT
        location_id,
        borough,
        zone,
        service_zone,
        bronze_ingestion_timestamp,
        bronze_ingestion_date,
        -- Explicitly cast current execution timestamp and date
        CAST(current_timestamp() AS TIMESTAMP) AS silver_ingestion_timestamp,
        CAST(current_date() AS DATE) AS silver_ingestion_date
    FROM (
        SELECT
            -- Safely cast LocationID to INT (returns NULL on invalid text)
            TRY_CAST(LocationID AS INT) AS location_id,
            -- Trim leading/trailing whitespace and explicitly cast to STRING
            CAST(TRIM(Borough) AS STRING) AS borough,
            CAST(TRIM(Zone) AS STRING) AS zone,
            CAST(TRIM(service_zone) AS STRING) AS service_zone,
            -- Extract Bronze ingestion metadata
            CAST(ingestion_timestamp AS TIMESTAMP) AS bronze_ingestion_timestamp,
            CAST(ingestion_date AS DATE) AS bronze_ingestion_date,
            -- Assign row numbers per location_id to identify duplicates
            ROW_NUMBER() OVER (
                PARTITION BY TRY_CAST(LocationID AS INT)
                ORDER BY TRY_CAST(LocationID AS INT) ASC
            ) AS rn
        FROM nyc.nyc_bronze.taxi_zone_bronze
    ) ranked
    -- Retain only the first ranked record and drop records with NULL primary keys
    WHERE rn = 1 AND location_id IS NOT NULL
) AS source
-- Join condition matching incoming Bronze records to existing Silver records by primary key
ON target.location_id = source.location_id
-- Refresh existing zone records with latest cleaned values and processing timestamp
WHEN MATCHED THEN UPDATE SET
    target.borough = source.borough,
    target.zone = source.zone,
    target.service_zone = source.service_zone,
    target.bronze_ingestion_timestamp = source.bronze_ingestion_timestamp,
    target.bronze_ingestion_date = source.bronze_ingestion_date,
    target.silver_ingestion_timestamp = source.silver_ingestion_timestamp,
    target.silver_ingestion_date = source.silver_ingestion_date
-- Add brand-new location IDs to the Silver table
WHEN NOT MATCHED THEN INSERT (
    location_id,
    borough,
    zone,
    service_zone,
    bronze_ingestion_timestamp,
    bronze_ingestion_date,
    silver_ingestion_timestamp,
    silver_ingestion_date
) VALUES (
    source.location_id,
    source.borough,
    source.zone,
    source.service_zone,
    source.bronze_ingestion_timestamp,
    source.bronze_ingestion_date,
    source.silver_ingestion_timestamp,
    source.silver_ingestion_date
);