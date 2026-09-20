from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SRC = REPO_ROOT / "src" / "sql" / "02_silver_clean"
DQ = REPO_ROOT  / "src" / "sql"/ "04_data_quality"/ "02_clean_checks"

SILVER_FILES = [
    SRC / "clean_green_taxi.sql",
    SRC / "clean_taxi_zones.sql",
    SRC / "clean_weather.sql",
]

DQ_FILES = [
    DQ / "check_clean_weather.sql",
    DQ / "check_green_taxi.sql",
    DQ / "check_taxi_zone_silver.sql",
]

def test_silver_files_exist():
    missing = [str(p.relative_to(REPO_ROOT)) for p in SILVER_FILES if not p.is_file()]
    assert not missing, f"Missing Silver SQL files: {missing}"

def test_silver_files_are_not_empty():
    for path in SILVER_FILES:
        assert path.read_text(encoding="utf-8").strip(), f"Empty Silver SQL: {path}"

def test_silver_files_have_select_and_from():
    for path in SILVER_FILES:
        sql = path.read_text(encoding="utf-8").upper()
        assert "SELECT" in sql, f"No SELECT in {path.name}"
        assert "FROM" in sql, f"No FROM in {path.name}"

def test_silver_dq_files_exist():
    missing = [str(p.relative_to(REPO_ROOT)) for p in DQ_FILES if not p.is_file()]
    assert not missing, f"Missing Silver DQ files: {missing}"

def test_silver_dq_files_have_pass_fail_logic():
    for path in DQ_FILES:
        sql = path.read_text(encoding="utf-8").upper()
        assert "PASS" in sql, f"No PASS logic in {path.name}"
        assert "FAIL" in sql, f"No FAIL logic in {path.name}"

def test_green_taxi_silver_references_bronze():
    sql = (SRC / "clean_green_taxi.sql").read_text(encoding="utf-8").lower()
    assert "green_taxi_bronze" in sql

def test_taxi_zone_silver_references_bronze():
    sql = (SRC / "clean_taxi_zone.sql").read_text(encoding="utf-8").lower()
    assert "taxi_zone_bronze" in sql

def test_weather_silver_references_bronze():
    sql = (SRC / "clean_weather.sql").read_text(encoding="utf-8").lower()
    assert "weather_bronze" in sql
