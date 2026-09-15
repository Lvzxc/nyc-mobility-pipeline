import requests
from pathlib import Path

# Official NYC TLC Taxi Zone CSV
URL = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

# Databricks Volume path
OUTPUT_PATH = Path(
    "/Volumes/nyc/default/nyc-mobility-volume/taxi_zones/taxi_zone_lookup.csv"
)


def download_taxi_zones():
    # Create the folder if it doesn't exist
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    # Download the CSV
    response = requests.get(URL, timeout=30)
    response.raise_for_status()

    # Save the CSV
    OUTPUT_PATH.write_bytes(response.content)

    print(f"Downloaded: {OUTPUT_PATH}")
    print(f"File size: {OUTPUT_PATH.stat().st_size:,} bytes")


if __name__ == "__main__":
    download_taxi_zones()
