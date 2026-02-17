import logging
from typing import List, Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from google.cloud import secretmanager


class Settings(BaseSettings):
    def __get_from_secret_manager(secret_key: str) -> str:
        secret_client = secretmanager.SecretManagerServiceClient()
        secret_value = secret_client.access_secret_version(
            request={
                "name": f"projects/1048249386206/secrets/{secret_key}/versions/latest",
            }
        )
        return secret_value.payload.data.decode("UTF-8")

    ENV: str = "local"
    LOG_LEVEL: int = logging.INFO
    LOG_NAME: str = "jukebox"
    PROJECT_NAME: str = "jukebox"

    API_PREFIX: str = "/api"
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost:5173",
        "http://localhost:3000",
        "http://localhost:4200",
    ]

    SQLALCHEMY_DATABASE_URI: str = (
        "postgresql+asyncpg://postgres:postgres@localhost:5434/jukebox_db"
    )
    DEFAULT_PAGE_SIZE: int = 20
    MAX_PAGE_SIZE: int = 100

    GITHUB_ACCESS_TOKEN: Optional[str] = None
    GCLOUD_PROJECT_ID: Optional[str] = "dgc-ai-jukebox"
    GCLOUD_MUSIC_BUCKET: str = "prompts_results"

    IMAGE_GENARATION_LOCATION: str = "us-central1"
    GEMINI_MODEL: str = "gemini-1.5-flash"
    IMAGEN_MODEL: str = "imagen-3.0-generate-001"

    GEMINI_API_KEY: str = __get_from_secret_manager("GEMINI_API_KEY")

    MUSICGEN_URL: str = Field(env="MUSICGEN_URL")

    GOOGLE_APP_EMAIL: str = Field(env="GOOGLE_APP_EMAIL")
    GOOGLE_APP_PASSWORD: str = __get_from_secret_manager("GOOGLE_APP_PASSWORD")

    INSTRUMENTS_COLLECTION: str = "instrument"
    JUKEBOX_COLLECTION: str = "jukebox"
    MUSIC_SUB_COLLECTION: str = "musics"

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

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
