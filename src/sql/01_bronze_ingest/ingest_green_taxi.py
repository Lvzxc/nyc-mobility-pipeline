from pyspark.sql import functions as F

# Raw Green Taxi files in the Unity Catalog Volume
SOURCE_PATH = "/Volumes/nyc/default/nyc-mobility-volume/green_taxi/*.parquet"

# Bronze Delta table
BRONZE_TABLE = "nyc.nyc_bronze.green_taxi"

# Read the raw Parquet files
df = (
    spark.read
    .parquet(SOURCE_PATH)
    .select(
        "*",
        "_metadata.file_name",
        "_metadata.file_path"
    )
)

# Add ingestion metadata
df = (
    df
    .withColumn(
        "source_file",
        F.col("file_name")
    )
    .withColumn(
        "source_month",
        F.date_format(
            F.col("lpep_pickup_datetime"),
            "yyyy-MM"
        )
    )
    .withColumn(
        "ingestion_timestamp",
        F.current_timestamp()
    )
    .withColumn(
        "ingestion_date",
        F.current_date()
    )
    .drop("file_name", "file_path")
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