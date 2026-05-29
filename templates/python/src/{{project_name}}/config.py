from pathlib import Path
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Project paths (resolved relative to project root)
    project_root: Path = Path(__file__).parent.parent.parent
    data_dir: Path = Path("data")
    artifacts_dir: Path = Path("artifacts")

    # API Configuration
    api_timeout: int = 30
    api_max_retries: int = 3

    # Model Configuration
    random_seed: int = 42
    test_size: float = 0.2

    @property
    def raw_data_dir(self) -> Path:
        return self.project_root / self.data_dir / "raw"

    @property
    def processed_data_dir(self) -> Path:
        return self.project_root / self.data_dir / "processed"


# Singleton — import this everywhere
settings = Settings()
