import pytest
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Generator
from {{PACKAGE_NAME}}.config import Settings, settings


@pytest.fixture(scope="session")
def sample_dataframe() -> pd.DataFrame:
    """Fixture providing a standard sample DataFrame for testing."""
    np.random.seed(42)
    dates = pd.date_range(start="2026-01-01", periods=100)
    data = {
        "date": dates,
        "feature_a": np.random.normal(loc=10, scale=2, size=100),
        "feature_b": np.random.uniform(low=0, high=100, size=100),
        "target": np.random.choice([0, 1], size=100),
    }
    return pd.DataFrame(data)


@pytest.fixture(scope="function")
def temp_data_dir(tmp_path: Path) -> Generator[Path, None, None]:
    """Fixture providing a temporary data directory and setting it in settings."""
    original_data_dir = settings.data_dir
    settings.data_dir = tmp_path
    yield tmp_path
    settings.data_dir = original_data_dir


@pytest.fixture(scope="function")
def settings_override() -> Generator[Settings, None, None]:
    """Fixture providing settings override capabilities for testing."""
    original_seed = settings.random_seed
    yield settings
    settings.random_seed = original_seed
