from io import BytesIO
import logging
import time
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
    genres = await crud.firestore.get_all_documents(settings.JUKEBOX_COLLECTION)
    return Page(items=genres, total=len(genres))


@router.get(
    "/instruments/all",
    response_model=Page[InstrumentBase],
    status_code=status.HTTP_200_OK,
)
async def get_all_instruments() -> Page[InstrumentBase]:
    instruments = await crud.firestore.get_all_documents(settings.INSTRUMENTS_COLLECTION)
    return Page(items=instruments, total=len(instruments))


@router.get(
    "/musics/{genre}",
    response_model=Page[MusicRead],
    status_code=status.HTTP_200_OK,
)
async def get_musics_by_genre(genre: Annotated[str, Depends(get_genre)]) -> Page[MusicRead]:
    musics = await crud.firestore.get_all_documents_in_subcollection(
        settings.JUKEBOX_COLLECTION, settings.MUSIC_SUB_COLLECTION, genre
    )

    return Page(items=musics, total=len(musics))


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

        start_time = time.time()
        cover_response = await cover_generator.generate(cover_prompt)
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
        async for chunk in music_generator.generate(generation_prompt):
            buffer.write(chunk)

        background_tasks.add_task(buffer.close)

        return JSONResponse(
            content={
                "id": uuid,
                "genre": genre,
                "title": title,
                "creator": creator,
                "audio": storage_uri,
                "duration": 30,
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
