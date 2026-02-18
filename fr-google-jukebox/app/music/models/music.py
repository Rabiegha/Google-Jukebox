from datetime import datetime


from pydantic import BaseModel, validator

from app.core.config import settings
from app.firestore.models.base import DateTimeModelMixin
from typing import Optional


class MusicBase(DateTimeModelMixin[datetime], BaseModel):
    """Music Model"""

    genre: str
    title: str = "default_title"
    duration: int = 0
    prompt: str = "default_prompt"
    cover: str = "default_cover"
    cover_generation_time: float = 0.0
    audio: str = "default_audio"
    audio_generation_time: float = 0.0
    creator: Optional[str] = "DJ Gemini ✦"

    @validator("genre")
    def validate_genre(cls, value):
        if value not in settings.MUSIC_GENRES:
            raise ValueError(
                f"Genre must be one of the following: {', '.join(settings.MUSIC_GENRES)}"
            )
        return value


class MusicRead(MusicBase):
    id: str


class MusicCreate(MusicBase):
    id: str = None  # Optional ID for local testing


class MusicUpdate(MusicBase):
    pass


class GenreBase(BaseModel):
    id: str
    url: str
