import requests
from pathlib import Path


# Open-Meteo Historical Weather API
BASE_URL = "https://archive-api.open-meteo.com/v1/archive"

# NYC coordinates
LATITUDE = 40.7128
LONGITUDE = -74.0060

# Analysis period
START_DATE = "2026-03-01"
END_DATE = "2026-05-31"

# Databricks Volume path for the raw dataset
OUTPUT_DIR = Path("/Volumes/nyc/default/nyc-mobility-volume/open_meteo/")

# Weather fields to download
HOURLY_FIELDS = [
    "temperature_2m",
    "precipitation",
    "rain",
    "snowfall",
    "wind_speed_10m",
    "weather_code"
]


def download_open_meteo():
    # API parameters
    params = {
        "latitude": LATITUDE,
        "longitude": LONGITUDE,
        "start_date": START_DATE,
        "end_date": END_DATE,
        "hourly": HOURLY_FIELDS,
        "timezone": "America/New_York"
    }

    # Create the Volume folder if it doesn't exist
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Output path in the Databricks Volume
    output_path = OUTPUT_DIR / "open_meteo_2026-03_to_2026-05.json"

    print("Downloading Open-Meteo weather data...")
    print(f"URL: {BASE_URL}")
    print(f"Saving to: {output_path}")

    # Request data from the API
    response = requests.get(
        BASE_URL,
        params=params,
        timeout=60
    )

    # Stop if the request failed
    response.raise_for_status()

    # Save the raw JSON response
    output_path.write_text(
        response.text,
        encoding="utf-8"
    )

    print(f"Downloaded: {output_path}")
    print(f"File size: {output_path.stat().st_size:,} bytes")
    print()


# Run the download
if __name__ == "__main__":
    download_open_meteo()

    print("Open-Meteo data downloaded successfully!")
