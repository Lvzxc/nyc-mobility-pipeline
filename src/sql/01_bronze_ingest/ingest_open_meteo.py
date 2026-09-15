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


# Get the source filename for lineage
source_file = SOURCE_PATH.name


# Read the raw JSON file
with open(SOURCE_PATH, "r", encoding="utf-8") as file:
    data = json.load(file)


# Get the hourly weather data from the source
hourly = data["hourly"]


# Convert the source arrays into rows
weather_rows = []

for i in range(len(hourly["time"])):
    weather_rows.append({
        "timestamp": hourly["time"][i],
        "temperature_2m": hourly["temperature_2m"][i],
        "precipitation": hourly["precipitation"][i],
        "rain": hourly["rain"][i],
        "snowfall": hourly["snowfall"][i],
        "wind_speed_10m": hourly["wind_speed_10m"][i],
        "weather_code": hourly["weather_code"][i],
        "source_file": source_file
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


# Write to Bronze as Delta
(
    df.write
    .format("delta")
    .mode("overwrite")
    .saveAsTable(BRONZE_TABLE)
)

print(f"Bronze table created successfully: {BRONZE_TABLE}")