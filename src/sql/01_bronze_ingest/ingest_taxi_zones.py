from pyspark.sql import functions as F

# TAXI ZONE LOOKUP - BRONZE INGESTION

# Raw CSV in Databricks Volume
source_path = "/Volumes/nyc/default/nyc-mobility-volume/taxi_zones/taxi_zone_lookup.csv"

# Bronze table
bronze_table = "nyc.nyc_bronze.taxi_zone_bronze"

# Read CSV
df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv(source_path)
)

# Add ingestion metadata
df = (
    df
    .withColumn("bronze_ingestion_timestamp", F.current_timestamp())
    .withColumn("bronze_ingestion_date", F.current_date())
)

# Show schema
df.printSchema()

# Preview data
display(df.limit(20))

# Write to Bronze as Delta
(
    df.write
    .format("delta")
    .mode("overwrite")
    .option("overwriteSchema", "true")
    .saveAsTable(bronze_table)
)

print(f"Bronze table created: {bronze_table}")