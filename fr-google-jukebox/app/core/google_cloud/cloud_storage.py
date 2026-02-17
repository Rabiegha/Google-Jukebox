from google.cloud.storage import Client


class CloudStorageService:
    def __init__(self):
        self.client = Client(project="dgc-ai-jukebox")

    def delete_file(self, bucket_name, file_name):
        bucket = self.client.bucket(bucket_name)
        blob = bucket.blob(file_name)
        blob.delete()

    def delete_folder(self, bucket_name, folder_name):
        bucket = self.client.bucket(bucket_name)
        for blob in bucket.list_blobs(prefix=folder_name):
            blob.delete()
