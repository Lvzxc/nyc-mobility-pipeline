import requests
from pathlib import Path

# Official NYC TLC Taxi Zone CSV
URL = "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"

# Local path for the raw dataset
OUTPUT_PATH = Path("/Volumes/nyc/default/nyc-mobility-volume/taxi_zones/taxi_zone_lookup.csv")


def download_taxi_zones():
    # Create data/raw if it doesn't exist
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    # Download the CSV
    response = requests.get(URL, timeout=30)

    # Stop if the request failed
    response.raise_for_status()

    # Save the CSV locally
    OUTPUT_PATH.write_bytes(response.content)

    print(f"Downloaded: {OUTPUT_PATH}")
    print(f"File size: {OUTPUT_PATH.stat().st_size:,} bytes")


# Run the function when this script is executed
if __name__ == "__main__":
    download_taxi_zones()