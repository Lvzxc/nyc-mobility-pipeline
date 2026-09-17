CREATE TABLE IF NOT EXISTS nyc.nyc_gold.dim_location (

    -- Surrogate key
    location_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Business key
    location_id INT NOT NULL,

    -- Descriptive attributes
    borough STRING,
    zone STRING,
    service_zone STRING,

    -- Silver lineage metadata
    silver_ingestion_timestamp TIMESTAMP,
    silver_ingestion_date DATE,

    -- Gold ingestion metadata
    gold_ingestion_timestamp TIMESTAMP,
    gold_ingestion_date DATE

);


MERGE INTO nyc.nyc_gold.dim_location AS target

USING nyc.nyc_silver.taxi_zones_silver AS source

ON target.location_id = source.location_id



WHEN MATCHED THEN

    UPDATE SET

        -- Descriptive attributes
        target.borough = source.Borough,
        target.zone = source.Zone,
        target.service_zone = source.service_zone,

        -- Silver lineage metadata
        target.silver_ingestion_timestamp =
            source.silver_ingestion_timestamp,

        target.silver_ingestion_date =
            source.silver_ingestion_date,

        -- Gold ingestion metadata
        target.gold_ingestion_timestamp =
            CURRENT_TIMESTAMP(),

        target.gold_ingestion_date =
            CURRENT_DATE()



WHEN NOT MATCHED THEN

    INSERT (
        location_id,
        borough,
        zone,
        service_zone,
        silver_ingestion_timestamp,
        silver_ingestion_date,
        gold_ingestion_timestamp,
        gold_ingestion_date
    )

    VALUES (
        source.location_id,
        source.Borough,
        source.Zone,
        source.service_zone,

        -- Silver lineage metadata
        source.silver_ingestion_timestamp,
        source.silver_ingestion_date,

        -- Gold ingestion metadata
        CURRENT_TIMESTAMP(),
        CURRENT_DATE()
    );