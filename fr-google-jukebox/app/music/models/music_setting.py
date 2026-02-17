import re
from typing import Literal
from pydantic import BaseModel, Field, validator


class MusicSetting(BaseModel):
    bpm: int = Field(ge=40, le=200, default=120)
    time_signature: Literal["4/4", "6/8", "3/4", "2/4", "12/8", "3/8", "2/2"] = Field(
        default="4/4"
    )
    bitrate: int = Field(ge=16, le=450, default=320)
    sample_range: float = Field(default=44.1)

    @validator("sample_range")
    def check_sound_range(cls, v):
        allowed_values = {44.1, 48, 96}
        if v not in allowed_values:
            raise ValueError(f"sample_range must be one of {allowed_values}")
        return v


def parse_music_setting(setting_str: str) -> MusicSetting:
    # Extract BPM
    bpm_match = re.search(r"(\d+)bpm", setting_str)
    bpm = int(bpm_match.group(1)) if bpm_match else 120

    # Extract time signature
    time_signature_match = re.search(r"(\d/\d)", setting_str)
    time_signature = time_signature_match.group(1) if time_signature_match else "4/4"

    # Extract bitrate
    bitrate_match = re.search(r"(\d+)kbps", setting_str)
    bitrate = int(bitrate_match.group(1)) if bitrate_match else 320

    # Extract sample rate
    sample_range_match = re.search(r"(\d+\.?\d*)kHz", setting_str)
    sample_range = float(sample_range_match.group(1)) if sample_range_match else 44.1

    return MusicSetting(
        bpm=bpm, time_signature=time_signature, bitrate=bitrate, sample_range=sample_range
    )
