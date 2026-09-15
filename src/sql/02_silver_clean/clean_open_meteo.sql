CREATE TABLE IF NOT EXISTS nyc.nyc_silver.open_meteo_silver (
    timestamp TIMESTAMP,
    weather_date DATE,
    weather_hour INT,
    temperature_2m DOUBLE,
    precipitation DOUBLE,
    rain DOUBLE,
    snowfall DOUBLE,
    wind_speed_10m DOUBLE,
    weather_code BIGINT,

    source_file STRING,
    ingestion_timestamp TIMESTAMP,
    ingestion_date DATE,

    silver_processed_timestamp TIMESTAMP,
    silver_processed_date DATE
);

MERGE INTO nyc.nyc_silver.open_meteo_silver AS target

USING (
    SELECT
        timestamp,
        CAST(timestamp AS DATE) AS weather_date,
        HOUR(timestamp) AS weather_hour,
        temperature_2m,
        precipitation,
        rain,
        snowfall,
        wind_speed_10m,
        weather_code,
        source_file,
        ingestion_timestamp,
        ingestion_date,
        current_timestamp() AS silver_processed_timestamp,
        current_date() AS silver_processed_date

    FROM nyc.nyc_bronze.open_meteo_bronze
) AS source

ON target.timestamp = source.timestamp

WHEN MATCHED THEN UPDATE SET
    target.weather_date = source.weather_date,
    target.weather_hour = source.weather_hour,
    target.temperature_2m = source.temperature_2m,
    target.precipitation = source.precipitation,
    target.rain = source.rain,
    target.snowfall = source.snowfall,
    target.wind_speed_10m = source.wind_speed_10m,
    target.weather_code = source.weather_code,
    target.source_file = source.source_file,
    target.ingestion_timestamp = source.ingestion_timestamp,
    target.ingestion_date = source.ingestion_date,
    target.silver_processed_timestamp = source.silver_processed_timestamp,
    target.silver_processed_date = source.silver_processed_date

WHEN NOT MATCHED THEN INSERT (
    timestamp,
    weather_date,
    weather_hour,
    temperature_2m,
    precipitation,
    rain,
    snowfall,
    wind_speed_10m,
    weather_code,
    source_file,
    ingestion_timestamp,
    ingestion_date,
    silver_processed_timestamp,
    silver_processed_date
)
VALUES (
    source.timestamp,
    source.weather_date,
    source.weather_hour,
    source.temperature_2m,
    source.precipitation,
    source.rain,
    source.snowfall,
    source.wind_speed_10m,
    source.weather_code,
    source.source_file,
    source.ingestion_timestamp,
    source.ingestion_date,
    source.silver_processed_timestamp,
    source.silver_processed_date
);