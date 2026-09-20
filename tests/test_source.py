from pathlib import Path
import ast

REPO_ROOT = Path(__file__).resolve().parents[1]
SRC = REPO_ROOT / "src" / "sql"
DQ = REPO_ROOT / "tests" / "01_source_checks"

SOURCE_PY_FILES = [
    SRC / "00_setup" / "download_green_taxi.py",
    SRC / "00_setup" / "download_open_meteo.py",
    SRC / "00_setup" / "download_taxi_zones.py",
    SRC / "00_setup" / "volume_creation.py",
    SRC / "01_bronze_ingest" / "ingest_green_taxi.py",
    SRC / "01_bronze_ingest" / "ingest_open_meteo.py",
    SRC / "01_bronze_ingest" / "ingest_taxi_zones.py",
]

def test_source_python_files_exist():
    missing = [str(p.relative_to(REPO_ROOT)) for p in SOURCE_PY_FILES if not p.is_file()]
    assert not missing, f"Missing source/Bronze Python files: {missing}"

def test_source_python_files_are_valid_python():
    for path in SOURCE_PY_FILES:
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))

def test_source_python_files_are_not_empty():
    for path in SOURCE_PY_FILES:
        assert path.read_text(encoding="utf-8").strip(), f"Empty file: {path}"

def test_source_dq_file_exists():
    path = DQ / "checks_weather_bronze.sql"
    assert path.is_file(), f"Missing source DQ file: {path}"

def test_source_dq_file_has_basic_sql_and_status_logic():
    sql = (DQ / "checks_weather_bronze.sql").read_text(encoding="utf-8").upper()
    assert "SELECT" in sql
    assert "FROM" in sql
    assert "PASS" in sql
    assert "FAIL" in sql
