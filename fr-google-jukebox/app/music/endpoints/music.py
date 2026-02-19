from io import BytesIO
import logging
import math
import struct
import time
import wave
from typing import Annotated
import uuid
from datetime import datetime

from google.cloud.firestore_v1 import DocumentSnapshot
from fastapi import APIRouter, BackgroundTasks, Depends, status
from fastapi.responses import StreamingResponse, Response

from app.api.deps import raise_404, raise_500
from app.core.google_cloud.cloud_storage import CloudStorageService
from app.core.config import settings
from app.firestore import crud

from app.firestore.models.base import Page
from app.music.dependencies import get_genre
from app.music.models.instrument import InstrumentBase
from app.music.models.music import GenreBase, MusicCreate, MusicRead, MusicUpdate
from app.music.models.prompt import PromptBase, PromptCover, PromptMusic
from app.music.service.generative_ai import CoverGenerator, MusicGenerator
from fastapi.responses import JSONResponse


router = APIRouter()

cloud_storage_service = CloudStorageService()

cover_generator = CoverGenerator()
music_generator = MusicGenerator()


@router.get(
    "/genre/all",
    response_model=Page[GenreBase],
    status_code=status.HTTP_200_OK,
)
async def get_all_genres() -> Page[GenreBase]:
    try:
        genres = await crud.firestore.get_all_documents(settings.JUKEBOX_COLLECTION)
        return Page(items=genres, total=len(genres))
    except Exception as e:
        logging.warning(f"Firestore genres fetch failed: {e}")
        # Return empty list as fallback for local testing
        return Page(items=[], total=0)


@router.get(
    "/instruments/all",
    response_model=Page[InstrumentBase],
    status_code=status.HTTP_200_OK,
)
async def get_all_instruments() -> Page[InstrumentBase]:
    try:
        instruments = await crud.firestore.get_all_documents(settings.INSTRUMENTS_COLLECTION)
        return Page(items=instruments, total=len(instruments))
    except Exception as e:
        logging.warning(f"Firestore instruments fetch failed: {e}")
        # Return empty list as fallback for local testing
        return Page(items=[], total=0)


@router.get(
    "/musics/{genre}",
    response_model=Page[MusicRead],
    status_code=status.HTTP_200_OK,
)
async def get_musics_by_genre(genre: Annotated[str, Depends(get_genre)]) -> Page[MusicRead]:
    try:
        musics = await crud.firestore.get_all_documents_in_subcollection(
            settings.JUKEBOX_COLLECTION, settings.MUSIC_SUB_COLLECTION, genre
        )
        return Page(items=musics, total=len(musics))
    except Exception as e:
        logging.warning(f"Firestore musics by genre fetch failed: {e}")
        # Return empty list as fallback for local testing
        return Page(items=[], total=0)


@router.post("/uuid", status_code=status.HTTP_200_OK)
async def create_new_uuid(uuid_prompt: PromptBase) -> MusicRead:
    current_datetime = datetime.now()
    id_ = str(uuid.uuid4())

    music_data = MusicCreate(
        id=id_,
        title=uuid_prompt.title,
        prompt=uuid_prompt.prompt,
        duration=uuid_prompt.duration,
        genre=uuid_prompt.genre,
        creator=uuid_prompt.creator,
        updated_at=current_datetime,
        created_at=current_datetime,
    )

    try:
        # Try to save to Firestore if credentials are available (optional in local mode)
        doc = await crud.firestore.add_document_in_subcollection(
            settings.JUKEBOX_COLLECTION,
            settings.MUSIC_SUB_COLLECTION,
            uuid_prompt.genre,
            dict(music_data),
        )
        return doc
    except Exception as fs_error:
        # Firestore save failed (expected in local mode without credentials)
        # Return the music data with ID for local testing
        logging.warning(f"Firestore save skipped: {fs_error}")
        return MusicRead(**music_data.dict())


@router.post(
    "/cover",
    response_model=MusicRead,
    status_code=status.HTTP_200_OK,
)
async def generate_cover(cover_prompt: PromptCover) -> MusicCreate:
    try:
        firestore_object: MusicUpdate = await crud.firestore.get_document_in_subcollection(
            settings.JUKEBOX_COLLECTION,
            settings.MUSIC_SUB_COLLECTION,
            cover_prompt.genre,
            cover_prompt.uuid,
        )

        # TODO: Re-enable AI cover generation when Gemini quota/billing is active
        # For now, use a placeholder cover image
        start_time = time.time()
        try:
            cover_response = await cover_generator.generate(cover_prompt)
        except Exception as ai_err:
            logging.warning(f"AI cover generation failed (using placeholder): {ai_err}")
            cover_response = "https://placehold.co/400x400/1a1a2e/e94560?text=" + cover_prompt.title.replace(' ', '+')
        end_time = time.time()

        print(f"Cover generation: {end_time - start_time} seconds")
        firestore_object["title"] = cover_prompt.title
        firestore_object["prompt"] = cover_prompt.prompt
        firestore_object["cover"] = cover_response
        firestore_object["cover_generation_time"] = end_time - start_time
        firestore_object["updated_at"] = datetime.now()

        doc = await crud.firestore.update_document_in_subcollection(
            settings.JUKEBOX_COLLECTION,
            settings.MUSIC_SUB_COLLECTION,
            cover_prompt.genre,
            cover_prompt.uuid,
            dict(firestore_object),
        )

        return doc
    except Exception as e:
        logging.error(e)
        raise_500()


@router.get(
    "/song",
    responses={
        200: {
            "content": {"audio/wav": {}},
            "description": "Returning a generated wav file",
        }
    },
)
async def generate_music(
    uuid: str,
    genre: Annotated[str, Depends(get_genre)],
    title: str,
    prompt: str,
    duration: int,
    creator: str,
    background_tasks: BackgroundTasks,
):

    generation_prompt = PromptMusic(
        uuid=uuid, genre=genre, title=title, prompt=prompt, duration=duration, creator=creator
    )

    storage_uri = f"https://storage.googleapis.com/{settings.GCLOUD_MUSIC_BUCKET}/{generation_prompt.uuid}/output.wav"

    id_ = generation_prompt.uuid
    firestore_object: MusicUpdate = await crud.firestore.get_document_in_subcollection(
        settings.JUKEBOX_COLLECTION, settings.MUSIC_SUB_COLLECTION, generation_prompt.genre, id_
    )

    firestore_object["duration"] = generation_prompt.duration
    firestore_object["audio"] = storage_uri
    firestore_object["updated_at"] = datetime.now()

    await crud.firestore.update_document_in_subcollection(
        settings.JUKEBOX_COLLECTION,
        settings.MUSIC_SUB_COLLECTION,
        generation_prompt.genre,
        id_,
        dict(firestore_object),
    )

    buffer = BytesIO()

    try:
        try:
            async for chunk in music_generator.generate(generation_prompt):
                buffer.write(chunk)
        except Exception as ai_err:
            # TODO: Re-enable when Replicate credits are available
            logging.warning(f"AI music generation failed (using test tone): {ai_err}")
            buffer = BytesIO()
            # Generate a simple test WAV tone
            sample_rate = 44100
            duration_secs = generation_prompt.duration
            frequency = 440.0  # A4 note
            num_samples = sample_rate * duration_secs
            wav_buffer = BytesIO()
            with wave.open(wav_buffer, 'w') as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(sample_rate)
                for i in range(num_samples):
                    # Simple sine wave with fade in/out
                    t = i / sample_rate
                    fade = min(1.0, i / (sample_rate * 0.1), (num_samples - i) / (sample_rate * 0.1))
                    value = int(16000 * fade * math.sin(2 * math.pi * frequency * t))
                    wav_file.writeframes(struct.pack('<h', value))
            buffer = wav_buffer

        # Upload the WAV to GCS
        buffer.seek(0)
        destination_blob = f"{generation_prompt.uuid}/output.wav"
        cloud_storage_service.upload_file(
            settings.GCLOUD_MUSIC_BUCKET,
            destination_blob,
            buffer.read(),
            content_type="audio/wav",
        )

        return JSONResponse(
            content={
                "id": uuid,
                "genre": genre,
                "title": title,
                "creator": creator,
                "audio": storage_uri,
                "duration": generation_prompt.duration,
            },
        )

    except Exception as e:
        logging.error(e)
        raise_500()
    finally:
        buffer.close()


@router.get(
    "/song/stream",
    responses={
        200: {
            "content": {"audio/wav": {}},
            "description": "Returning a generated wav file",
        }
    },
)
async def generate_music_stream(
    uuid: str, genre: Annotated[str, Depends(get_genre)], title: str, prompt: str, duration: int, creator: str = "Unknown"
) -> StreamingResponse:

    generation_prompt = PromptMusic(
        uuid=uuid, genre=genre, title=title, prompt=prompt, duration=duration, creator=creator
    )

    storage_uri = f"https://storage.googleapis.com/{settings.GCLOUD_MUSIC_BUCKET}/{generation_prompt.uuid}/output.wav"

    try:
        # Try to update Firestore if credentials are available (optional in local mode)
        id_ = generation_prompt.uuid
        firestore_object: MusicUpdate = await crud.firestore.get_document_in_subcollection(
            settings.JUKEBOX_COLLECTION, settings.MUSIC_SUB_COLLECTION, generation_prompt.genre, id_
        )

        firestore_object["duration"] = generation_prompt.duration
        firestore_object["audio"] = storage_uri
        firestore_object["updated_at"] = datetime.now()

        await crud.firestore.update_document_in_subcollection(
            settings.JUKEBOX_COLLECTION,
            settings.MUSIC_SUB_COLLECTION,
            generation_prompt.genre,
            id_,
            dict(firestore_object),
        )
    except Exception as fs_error:
        # Firestore update failed (expected in local mode without credentials)
        # Continue with music generation anyway
        logging.warning(f"Firestore update skipped: {fs_error}")

    try:

        return StreamingResponse(
            music_generator.generate(generation_prompt),
            media_type="audio/x-wav",
        )

    except Exception as e:
        logging.error(e)
        raise_500()


@router.put(
    "/{id}",
    response_model=MusicUpdate,
    status_code=status.HTTP_200_OK,
)
async def update_music(id: str, music_data: MusicUpdate) -> MusicUpdate:

    await crud.firestore.update_document_in_subcollection(
        settings.JUKEBOX_COLLECTION,
        settings.MUSIC_SUB_COLLECTION,
        music_data.genre,
        id,
        dict(music_data),
    )
    return music_data


@router.delete(
    "/{genre}/{id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_music(id: str, genre: Annotated[str, Depends(get_genre)]):

    doc: DocumentSnapshot = await crud.firestore.get_document_in_subcollection(
        settings.JUKEBOX_COLLECTION, settings.MUSIC_SUB_COLLECTION, genre, id, as_dict=False
    )

    if doc.exists:
        await doc.reference.delete()
        cloud_storage_service.delete_folder(settings.GCLOUD_MUSIC_BUCKET, id)
    else:
        raise_404()

    return Response(status_code=status.HTTP_204_NO_CONTENT)
