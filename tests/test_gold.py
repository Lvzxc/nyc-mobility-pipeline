from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SRC = REPO_ROOT / "src" / "sql" / "03_gold_model"
DQ = REPO_ROOT / "tests" / "03_mart_checks"

GOLD_FILES = [
    SRC / "dim_datetime.sql",
    SRC / "dim_location.sql",
    SRC / "dim_weather.sql",
    SRC / "fact_taxi_trip.sql",
]

DQ_FILES = [
    DQ / "check_dim_date_time.sql",
    DQ / "check_dim_location.sql",
    DQ / "check_dim_weather.sql",
    DQ / "check_fact_table.sql",
]

def test_gold_files_exist():
    missing = [str(p.relative_to(REPO_ROOT)) for p in GOLD_FILES if not p.is_file()]
    assert not missing, f"Missing Gold SQL files: {missing}"

def test_gold_files_are_not_empty():
    for path in GOLD_FILES:
        assert path.read_text(encoding="utf-8").strip(), f"Empty Gold SQL: {path}"

def test_gold_files_define_tables():
    for path in GOLD_FILES:
        sql = path.read_text(encoding="utf-8").upper()
        assert "CREATE TABLE" in sql, f"No CREATE TABLE in {path.name}"

def test_gold_files_have_expected_table_names():
    expected = {
        "dim_datetime.sql": "DIM_DATETIME",
        "dim_location.sql": "DIM_LOCATION",
        "dim_weather.sql": "DIM_WEATHER",
        "fact_taxi_trip.sql": "FACT_TAXI_TRIP",
    }
    for filename, table_name in expected.items():
        sql = (SRC / filename).read_text(encoding="utf-8").upper()
        assert table_name in sql, f"{table_name} missing from {filename}"

def test_dim_location_has_keys():
    sql = (SRC / "dim_location.sql").read_text(encoding="utf-8").upper()
    assert "LOCATION_KEY" in sql
    assert "LOCATION_ID" in sql
    assert "GENERATED ALWAYS AS IDENTITY" in sql

def test_dim_weather_has_weather_fields():
    sql = (SRC / "dim_weather.sql").read_text(encoding="utf-8").upper()
    assert "WEATHER_DATETIME" in sql
    assert "WEATHER_CODE" in sql
    assert "WEATHER_CONDITION" in sql

def test_fact_table_has_main_dimension_keys():
    sql = (SRC / "fact_taxi_trip.sql").read_text(encoding="utf-8").upper()
    assert "PICKUP_DATETIME_KEY" in sql
    assert "DROPOFF_DATETIME_KEY" in sql
    assert "LOCATION_KEY" in sql

def test_gold_dq_files_exist():
    missing = [str(p.relative_to(REPO_ROOT)) for p in DQ_FILES if not p.is_file()]
    assert not missing, f"Missing Gold DQ files: {missing}"

def test_gold_dq_files_have_pass_fail_logic():
    for path in DQ_FILES:
        sql = path.read_text(encoding="utf-8").upper()
        assert "PASS" in sql, f"No PASS logic in {path.name}"
        assert "FAIL" in sql, f"No FAIL logic in {path.name}"
