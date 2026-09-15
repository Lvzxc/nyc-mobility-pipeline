from pyspark.sql import functions as F
import json
from pathlib import Path


# Raw Open-Meteo JSON file in the Unity Catalog Volume
SOURCE_PATH = Path(
    "/Volumes/nyc/default/nyc-mobility-volume/open_meteo/"
    "open_meteo_2026-03_to_2026-05.json"
)

# Bronze Delta table
BRONZE_TABLE = "nyc.nyc_bronze.open_meteo_bronze"


# Read the raw JSON file
with open(SOURCE_PATH, "r", encoding="utf-8") as file:
    data = json.load(file)


# Get the hourly weather data
hourly = data["hourly"]


# Convert hourly arrays into rows
weather_rows = []

for i in range(len(hourly["time"])):
    weather_rows.append({
        "timestamp": hourly["time"][i],
        "temperature_2m": hourly["temperature_2m"][i],
        "precipitation": hourly["precipitation"][i],
        "rain": hourly["rain"][i],
        "snowfall": hourly["snowfall"][i],
        "wind_speed_10m": hourly["wind_speed_10m"][i],
        "weather_code": hourly["weather_code"][i]
    })


# Create Spark DataFrame
df = spark.createDataFrame(weather_rows)


# Convert timestamp to Spark timestamp type
df = df.withColumn(
    "timestamp",
    F.to_timestamp("timestamp")
)


# Add ingestion metadata
df = (
    df
    .withColumn(
        "ingestion_timestamp",
        F.current_timestamp()
    )
    .withColumn(
        "ingestion_date",
        F.current_date()
    )
)


# Preview
display(df.limit(20))


# Create Bronze table if it doesn't exist
spark.sql(f"""
CREATE TABLE IF NOT EXISTS {BRONZE_TABLE} (
    timestamp TIMESTAMP,
    temperature_2m DOUBLE,
    precipitation DOUBLE,
    rain DOUBLE,
    snowfall DOUBLE,
    wind_speed_10m DOUBLE,
    weather_code INT,
    ingestion_timestamp TIMESTAMP,
    ingestion_date DATE
)
USING DELTA
""")


# Create temporary view for MERGE
df.createOrReplaceTempView("open_meteo_source")


# Merge into Bronze using timestamp as the natural key
spark.sql(f"""
MERGE INTO {BRONZE_TABLE} AS target
USING open_meteo_source AS source
ON target.timestamp = source.timestamp

WHEN MATCHED THEN UPDATE SET
    target.temperature_2m = source.temperature_2m,
    target.precipitation = source.precipitation,
    target.rain = source.rain,
    target.snowfall = source.snowfall,
    target.wind_speed_10m = source.wind_speed_10m,
    target.weather_code = source.weather_code

WHEN NOT MATCHED THEN INSERT (
    timestamp,
    temperature_2m,
    precipitation,
    rain,
    snowfall,
    wind_speed_10m,
    weather_code,
    ingestion_timestamp,
    ingestion_date
)
VALUES (
    source.timestamp,
    source.temperature_2m,
    source.precipitation,
    source.rain,
    source.snowfall,
    source.wind_speed_10m,
    source.weather_code,
    source.ingestion_timestamp,
    source.ingestion_date
)
""")


print(f"Bronze table loaded successfully: {BRONZE_TABLE}")