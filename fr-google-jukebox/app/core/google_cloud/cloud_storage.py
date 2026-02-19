from google.cloud.storage import Client

from app.core.config import settings


class CloudStorageService:
    def __init__(self):
        self._client = None

    @property
    def client(self) -> Client:
        # Lazy initialization to avoid requiring Google Cloud credentials
        # until an actual operation is performed
        if self._client is None:
            self._client = Client(project=settings.GCLOUD_PROJECT_ID)
        return self._client

    def delete_file(self, bucket_name, file_name):
        bucket = self.client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        blob.delete()

    def delete_folder(self, bucket_name, folder_name):
        bucket = self.client.bucket(bucket_name)
        for blob in bucket.list_blobs(prefix=folder_name):
            blob.delete()
