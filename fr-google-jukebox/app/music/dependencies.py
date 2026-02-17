from app.api.deps import raise_400
from app.core.config import settings


def get_genre(genre: str):
    if genre not in settings.MUSIC_GENRES:
        raise_400(f"Genre must be one of the following: {', '.join(settings.MUSIC_GENRES)}")
    return genre
