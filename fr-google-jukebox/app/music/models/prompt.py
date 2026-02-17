from pydantic import BaseModel, Field, validator
from typing import Optional
from app.core.config import settings


class PromptBase(BaseModel):
    genre: str = Field(..., max_length=100)
    prompt: str
    title: str = Field(..., max_length=100)
    duration: Optional[int] = Field(None, ge=10, le=35)
    creator: str = Field(..., max_length=255)

    @validator("duration")
    def validate_duration(cls, value):
        if value is not None and (value < 10 or value > 35):
            raise ValueError("Duration must be between 10 and 35")
        return value

    @validator("genre")
    def validate_genre(cls, value):
        if value not in settings.MUSIC_GENRES:
            raise ValueError(
                f"Genre must be one of the following: {', '.join(settings.MUSIC_GENRES)}"
            )
        return value

    @validator("title")
    def validate_title(cls, value):
        if len(value.split()) > 100:
            raise ValueError("Title must not exceed 100 tokens")
        return value


class PromptUUID(PromptBase):
    pass


class PromptCover(PromptBase):
    uuid: str = Field(...)


class PromptMusic(PromptBase):
    uuid: str = Field(...)
