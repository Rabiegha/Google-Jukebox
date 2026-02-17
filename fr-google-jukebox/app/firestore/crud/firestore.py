from typing import Any

import google.cloud.firestore as firestore
from google.cloud.firestore_v1 import DocumentSnapshot

from app.core.cloud_logging import Singleton
from app.core.config import settings


class Firestore(metaclass=Singleton):
    def __init__(self) -> None:
        # Searches first from .env, or infer if not specified
        if settings.GCLOUD_PROJECT_ID:
            self.client = firestore.AsyncClient(project=settings.GCLOUD_PROJECT_ID)
        else:
            self.client = firestore.AsyncClient()

    async def get_all_documents(self, collection_name: str, as_dict=True) -> list[dict]:
        doc_list = await self.client.collection(collection_name).get()
        if not as_dict:
            return doc_list

        dict_list = []
        for document in doc_list:
            dict_list.append(Firestore._get_doc_as_dict(document))
        return dict_list

    async def get_document(
        self, collection_name: str, document_id: str, as_dict=True
    ) -> DocumentSnapshot | dict:
        doc = await self.client.collection(collection_name).document(document_id).get()
        if not as_dict:
            return doc

        return Firestore._get_doc_as_dict(doc)

    async def add_document(self, collection_name: str, data: dict) -> tuple[Any, Any]:
        return await self.client.collection(collection_name).add(data)

    async def add_document_in_subcollection(
        self, collection_name: str, subcollection_name: str, genre: str, data: dict
    ) -> dict:
        genre_ref = self.client.collection(collection_name).document(genre)
        genre_doc = await genre_ref.get()

        if not genre_doc.exists:
            await genre_ref.set({})

        songs_ref = genre_ref.collection(subcollection_name)
        new_song_ref = songs_ref.document()
        data["id"] = new_song_ref.id
        await new_song_ref.set(data)
        return data

    async def get_all_documents_in_subcollection(
        self, collection_name: str, subcollection_name: str, genre: str, as_dict=True
    ) -> list[dict]:
        doc_list = (
            await self.client.collection(collection_name)
            .document(genre)
            .collection(subcollection_name)
            .get()
        )
        if not as_dict:
            return doc_list

        dict_list = []
        for document in doc_list:
            dict_list.append(Firestore._get_doc_as_dict(document))
        return dict_list

    async def get_document_in_subcollection(
        self,
        collection_name: str,
        subcollection_name: str,
        genre: str,
        document_id: str,
        as_dict=True,
    ) -> DocumentSnapshot | dict:
        doc = (
            await self.client.collection(collection_name)
            .document(genre)
            .collection(subcollection_name)
            .document(document_id)
            .get()
        )
        if not as_dict:
            return doc

        return Firestore._get_doc_as_dict(doc)

    async def update_document_in_subcollection(
        self,
        collection_name: str,
        subcollection_name: str,
        genre: str,
        document_id: str,
        data: dict,
    ) -> firestore.DocumentReference:

        await self.client.collection(collection_name).document(genre).collection(
            subcollection_name
        ).document(document_id).update(data)

        return data

    def update_document(
        self, collection_name: str, document_id: str, data: dict
    ) -> firestore.DocumentReference:
        return self.client.collection(collection_name).document(document_id).update(data)

    def delete_document(self, collection_name: str, document_id: str):
        return self.client.collection(collection_name).document(document_id).delete()

    @staticmethod
    def _get_doc_as_dict(doc: firestore.DocumentSnapshot) -> dict:
        if not doc.exists:
            return None
        element = doc.to_dict()
        element["id"] = doc.id
        return element
