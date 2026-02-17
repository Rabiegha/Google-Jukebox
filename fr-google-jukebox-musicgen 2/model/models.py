from pydantic import BaseModel, Field, validator
from typing import Optional


class MusicGenRequest(BaseModel):
    prompt: str = Field(..., max_length=200)
    uuid: str
    duration: Optional[int] = Field(None, ge=10, le=45)

    @validator("prompt")
    def validate_prompt(cls, value):
        if len(value.split()) > 200:
            raise ValueError("Prompt must not exceed 200 tokens")
        return value

    @validator("duration")
    def validate_duration(cls, value):
        if value is not None and (value < 10 or value > 45):
            raise ValueError("Duration must be between 10 and 45")
        return value


class MusicGenResponse(BaseModel):
    storage_url: str
