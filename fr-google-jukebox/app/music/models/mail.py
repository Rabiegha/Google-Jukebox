from pydantic import BaseModel, validator

from app.core.config import settings


class MailRequest(BaseModel):
    recipients: list[str]
    music_id: str
    music_genre: str

    @validator("music_genre")
    def validate_genre(cls, value):
        if value not in settings.MUSIC_GENRES:
            raise ValueError(
                f"Music genre must be one of the following: {', '.join(settings.MUSIC_GENRES)}"
            )
        return value
