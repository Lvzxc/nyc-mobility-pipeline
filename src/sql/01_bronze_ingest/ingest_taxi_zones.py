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

# Show schema
df.printSchema()

# Preview data
display(df)

# Write to Bronze as Delta
(
    df.write
    .format("delta")
    .mode("overwrite")
    .saveAsTable(bronze_table)
)

print(f"Bronze table created: {bronze_table}")