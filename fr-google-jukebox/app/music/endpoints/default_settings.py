from fastapi import APIRouter, status

from app.music.models.music_setting import MusicSetting, parse_music_setting
from app.music.service.generative_ai import SettingsGenerator


router = APIRouter()

setting_generator = SettingsGenerator()


@router.get(
    "",
    response_model=MusicSetting,
    status_code=status.HTTP_200_OK,
)
def get_music_setting_from_song(songName: str) -> MusicSetting:
    try:
        setting_str = setting_generator.generate(songName)
        generated_setting: MusicSetting = parse_music_setting(setting_str)
        return generated_setting
    except Exception as e:
        print(e)
        return MusicSetting()
