
CREATE TABLE IF NOT EXISTS nyc.nyc_gold.dim_location (
    location_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_id INT NOT NULL,
    borough STRING,
    zone STRING,
    service_zone STRING
);

MERGE INTO nyc.nyc_gold.dim_location AS target

USING nyc.nyc_silver.taxi_zones_silver AS source

ON target.location_id = source.location_id

-- Existing location
WHEN MATCHED THEN
    UPDATE SET
        target.borough = source.Borough,
        target.zone = source.Zone,
        target.service_zone = source.service_zone

-- New location
WHEN NOT MATCHED THEN
    INSERT (
        location_id,
        borough,
        zone,
        service_zone
    )
    VALUES (
        source.location_id,
        source.Borough,
        source.Zone,
        source.service_zone
    );
