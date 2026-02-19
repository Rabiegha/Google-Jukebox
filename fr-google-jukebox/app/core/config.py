import logging
import os
from typing import List, Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from google.cloud import secretmanager


def get_env_file() -> str | None:
    """
    Determine which .env file to load based on ENV variable.
    
    Returns None if ENV is already set (e.g., in Docker via env_file or environment)
    to avoid conflicts with pre-loaded environment variables.
    
    - If ENV already in os.environ: return None (don't load file, use env vars)
    - If ENV=production: loads .env.prod (for Cloud Run secret manager setup)
    - Otherwise (local, development, etc.): loads .env.local
    
    Returns:
        Path to the appropriate .env file, or None to skip file loading
    """
    # If ENV is already set in environment, don't try to load from file
    # This happens in Docker when env_file: or environment: is used
    if "ENV" in os.environ:
        return None
        
    env = os.getenv("ENV", "local")
    return ".env.prod" if env == "production" else ".env.local"


def get_secret(secret_key: str, required: bool = True) -> str:
    """
    Retrieve secret from Google Secret Manager or environment variables.
    
    - If ENV != "production": reads from environment variables (loaded via .env)
    - If ENV == "production": reads from Google Secret Manager
    
    Args:
        secret_key: The name of the secret (e.g., "GEMINI_API_KEY")
        required: If False, returns empty string instead of raising on missing secret
        
    Returns:
        The secret value as a string
    """
    env_mode = os.getenv("ENV", "local")
    
    # In local/development mode, read from environment (via .env)
    if env_mode != "production":
        value = os.getenv(secret_key)
        if not value:
            if not required:
                return ""
            raise ValueError(
                f"Secret '{secret_key}' not found in environment variables. "
                f"Please add it to .env file (ENV={env_mode})"
            )
        return value
    
    # In production mode, read from Google Secret Manager
    try:
        project_number = os.getenv("GCLOUD_PROJECT_NUMBER")
        if not project_number:
            raise ValueError(
                "GCLOUD_PROJECT_NUMBER not set. Required for Secret Manager access in production."
            )
        
        secret_client = secretmanager.SecretManagerServiceClient()
        secret_value = secret_client.access_secret_version(
            request={
                "name": f"projects/{project_number}/secrets/{secret_key}/versions/latest",
            }
        )
        return secret_value.payload.data.decode("UTF-8")
    except Exception as e:
        if not required:
            logging.warning(f"Optional secret '{secret_key}' not available: {e}")
            return ""
        raise RuntimeError(
            f"Failed to retrieve secret '{secret_key}' from Google Secret Manager: {e}"
        ) from e


class Settings(BaseSettings):
    # Environment and basic settings
    ENV: str = Field(default="local", env="ENV")
    LOG_LEVEL: int = logging.INFO
    LOG_NAME: str = "jukebox"
    PROJECT_NAME: str = "jukebox"

    # API configuration
    API_PREFIX: str = "/api"
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:5173",
        "http://localhost:3000",
        "http://localhost:4200",
    ]

    # Database
    SQLALCHEMY_DATABASE_URI: str = Field(
        default="postgresql+asyncpg://postgres:postgres@localhost:5434/jukebox_db",
        env="SQLALCHEMY_DATABASE_URI"
    )
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    # GitHub (optional)
    GITHUB_ACCESS_TOKEN: Optional[str] = Field(default=None, env="GITHUB_ACCESS_TOKEN")

    # Google Cloud Platform
    GCLOUD_PROJECT_ID: str = Field(env="GCLOUD_PROJECT_ID")
    GCLOUD_PROJECT_NUMBER: Optional[str] = Field(default=None, env="GCLOUD_PROJECT_NUMBER")
    GCLOUD_MUSIC_BUCKET: str = Field(env="GCLOUD_MUSIC_BUCKET")

    # AI/ML Models
    IMAGE_GENARATION_LOCATION: str = Field(default="us-central1", env="IMAGE_GENERATION_LOCATION")
    GEMINI_MODEL: str = Field(default="gemini-2.0-flash", env="GEMINI_MODEL")
    IMAGEN_MODEL: str = Field(default="imagen-3.0-generate-001", env="IMAGEN_MODEL")

    # API Keys (secrets)
    GEMINI_API_KEY: str = Field(default_factory=lambda: get_secret("GEMINI_API_KEY"))
    REPLICATE_API_TOKEN: str = Field(default_factory=lambda: get_secret("REPLICATE_API_TOKEN"))

    # External services
    MUSICGEN_URL: str = Field(default="", env="MUSICGEN_URL")

    # Email service (optional)
    GOOGLE_APP_EMAIL: str = Field(default="", env="GOOGLE_APP_EMAIL")
    GOOGLE_APP_PASSWORD: str = Field(default_factory=lambda: get_secret("GOOGLE_APP_PASSWORD", required=False))

    # Firestore
    FIRESTORE_DATABASE: str = Field(default="(default)", env="FIRESTORE_DATABASE")
    INSTRUMENTS_COLLECTION: str = Field(default="instrument", env="INSTRUMENTS_COLLECTION")
    JUKEBOX_COLLECTION: str = Field(default="jukebox", env="JUKEBOX_COLLECTION")
    MUSIC_SUB_COLLECTION: str = Field(default="musics", env="MUSIC_SUB_COLLECTION")

    # Music genres
    MUSIC_GENRES: list[str] = [
        "Ambiente",
        "Chill Out",
        "Classic",
        "Corporate",
        "Country",
        "EDM",
        "Folk",
        "Funk",
        "Hip Hop",
        "Jazz",
        "Rock",
        "Videogames",
    ]

    model_config = SettingsConfigDict(env_file=get_env_file(), env_file_encoding="utf-8")

    def __init__(self, **data):
        """Initialize settings with validation."""
        super().__init__(**data)
        
        # Validate required fields for local vs production
        if self.ENV != "production":
            # Local mode: ensure required secrets are available
            if not self.GEMINI_API_KEY:
                raise ValueError(
                    "GEMINI_API_KEY is required in local mode. Add it to .env file."
                )
            if not self.REPLICATE_API_TOKEN:
                raise ValueError(
                    "REPLICATE_API_TOKEN is required in local mode. Add it to .env file."
                )
        else:
            # Production mode: ensure project number is set for Secret Manager
            if not self.GCLOUD_PROJECT_NUMBER:
                raise ValueError(
                    "GCLOUD_PROJECT_NUMBER is required in production mode for Secret Manager access."
                )


settings = Settings()
