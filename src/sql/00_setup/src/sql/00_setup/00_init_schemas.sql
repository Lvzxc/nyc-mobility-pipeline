CREATE CATALOG IF NOT EXISTS nyc;

USE CATALOG nyc;

-- Raw tables loaded from the original CSV files.
CREATE SCHEMA IF NOT EXISTS nyc_bronze;

-- Cleaned and standardized tables.
CREATE SCHEMA IF NOT EXISTS nyc_silver;

-- Dimension and fact tables.
CREATE SCHEMA IF NOT EXISTS nyc_gold;

-- Data-quality results and invalid records.
CREATE SCHEMA IF NOT EXISTS nyc_quality;


-- Check that the project schemas are available.
SHOW SCHEMAS IN nyc;
