# NYC Mobility Gold Data Model

The Gold layer provides the analytical data warehouse for the NYC Mobility pipeline.

It uses a **star schema** to organize taxi trip events around descriptive dimensions for **datetime, location, and weather**.

The model consists of:

* **1 fact table**
* **3 dimension tables**

```text
                         dim_datetime
                              │
                              │
                              ▼
                       fact_taxi_trip
                         /          \
                        /            \
                       ▼              ▼
                dim_location      dim_weather
```

---

# Fact Table

## `fact_taxi_trip`

The fact table represents the central **taxi trip event**.

**Grain:** One row per taxi trip.

It contains:

* Trip identifiers
* Pickup and drop-off datetime keys
* Pickup and drop-off location keys
* Weather key
* Taxi and payment attributes
* Passenger information
* Trip distance and duration
* Fare and surcharge amounts
* Total trip amount

The fact table connects the taxi trip to the relevant dimensions through foreign keys.

---

# Dimension Tables

## `dim_datetime`

Provides date and time information for taxi trips.

The dimension combines both **date and time attributes** in a single table.

It supports analysis such as:

* Trips by hour
* Trips by day
* Weekday vs. weekend activity
* Monthly and yearly trends
* Morning, afternoon, evening, and night activity
* Rush-hour analysis

Both pickup and drop-off timestamps reference this dimension.

---

## `dim_location`

Provides information about NYC taxi zones.

It contains descriptive information such as:

* Taxi zone ID
* Borough
* Zone name
* Service zone

The same dimension is used for both **pickup** and **drop-off** locations.

This allows trips to be analyzed geographically without duplicating the location data.

---

## `dim_weather`

Provides hourly weather information associated with taxi activity.

It contains weather measurements and conditions such as:

* Temperature
* Precipitation
* Rain
* Snowfall
* Wind speed
* Weather code
* Weather condition

The fact table connects to this dimension through `weather_key`.

This allows weather conditions to be considered alongside taxi trip activity.

---

# Relationships

The Gold model uses the following relationships:

| Fact Relationship      | Dimension      |
| ---------------------- | -------------- |
| `pickup_datetime_key`  | `dim_datetime` |
| `dropoff_datetime_key` | `dim_datetime` |
| `pickup_location_key`  | `dim_location` |
| `dropoff_location_key` | `dim_location` |
| `weather_key`          | `dim_weather`  |

---

# Why a Star Schema?

The star schema separates:

**Facts**

The measurable taxi trip events stored in `fact_taxi_trip`.

**Dimensions**

The descriptive information used to analyze those events:

* When did the trip occur? → `dim_datetime`
* Where did the trip occur? → `dim_location`
* What were the weather conditions? → `dim_weather`

This structure makes the Gold layer easier to query and provides a consistent foundation for NYC Mobility analytics.

---

# Model Summary

| Table            | Type      | Grain                    | Purpose                              |
| ---------------- | --------- | ------------------------ | ------------------------------------ |
| `fact_taxi_trip` | Fact      | One row per taxi trip    | Stores taxi trip events and measures |
| `dim_datetime`   | Dimension | One row per datetime     | Date and time analysis               |
| `dim_location`   | Dimension | One row per taxi zone    | Geographic analysis                  |
| `dim_weather`    | Dimension | One row per weather hour | Weather analysis                     |

---

# Design Decisions

### Single Datetime Dimension

Date and time are kept together in `dim_datetime` rather than being separated into different dimensions.

### Role-Playing Location Dimension

`dim_location` is referenced twice by the fact table:

* Pickup location
* Drop-off location

This allows the same location dimension to describe both sides of a taxi trip.

### Role-Playing Datetime Dimension

`dim_datetime` is also referenced twice:

* Pickup datetime
* Drop-off datetime

This allows pickup and drop-off activity to be analyzed using the same consistent datetime attributes.

### Weather Integration

Weather data is modeled as a separate dimension and linked to taxi trips through the weather key, allowing mobility activity to be analyzed alongside environmental conditions.
