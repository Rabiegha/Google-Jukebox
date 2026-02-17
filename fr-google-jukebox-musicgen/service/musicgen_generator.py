import os
from threading import Thread
from google.cloud import storage
import numpy as np
from service.musicgen_stream import MusicgenStreamer
import torch
import time
from transformers import MusicgenForConditionalGeneration, MusicgenProcessor, set_seed
from dotenv import load_dotenv


load_dotenv()


class MusigGenGenerator:
    def __init__(self):
        # Defaults
        self.model_name = os.getenv("MODEL_NAME", "facebook/musicgen-large")
        self.bucket_name = os.getenv("BUCKET_NAME")

        # Load the model
        print("Loading model...")
        start_time = time.time()
        self.model = MusicgenForConditionalGeneration.from_pretrained(self.model_name)

        device = "cuda:0" if torch.cuda.is_available() else "cpu"
        print(f"Current Device: {self.model.device}")
        if device != self.model.device:
            print("Loading model into  GPU")
            self.model.to(device)
            if device == "cuda:0":
                self.model.half()

        self.processor = MusicgenProcessor.from_pretrained(self.model_name)

        self.sampling_rate = self.model.audio_encoder.config.sampling_rate
        self.frame_rate = self.model.audio_encoder.config.frame_rate

        end_time = time.time()
        print(f"Model loaded in {end_time - start_time} seconds.")

    def genHeader(self, sampleRate, bitsPerSample, channels):
        datasize = 2000 * 10**6
        o = bytes("RIFF", "ascii")  # (4byte) Marks file as RIFF
        o += (datasize + 36).to_bytes(
            4, "little"
        )  # (4byte) File size in bytes excluding this and RIFF marker
        o += bytes("WAVE", "ascii")  # (4byte) File type
        o += bytes("fmt ", "ascii")  # (4byte) Format Chunk Marker
        o += (16).to_bytes(4, "little")  # (4byte) Length of above format data
        o += (1).to_bytes(2, "little")  # (2byte) Format type (1 - PCM)
        o += (channels).to_bytes(2, "little")  # (2byte)
        o += (sampleRate).to_bytes(4, "little")  # (4byte)
        o += (sampleRate * channels * bitsPerSample // 8).to_bytes(
            4, "little"
        )  # (4byte)
        o += (channels * bitsPerSample // 8).to_bytes(2, "little")  # (2byte)
        o += (bitsPerSample).to_bytes(2, "little")  # (2byte)
        o += bytes("data", "ascii")  # (4byte) Data Chunk Marker
        o += (datasize).to_bytes(4, "little")  # (4byte) Data size in bytes
        return o

    def generate_audio_stream(
        self, uuid, text_prompt, audio_length_in_s=10.0, play_steps_in_s=4.0, seed=0
    ):
        max_new_tokens = int(self.frame_rate * audio_length_in_s)
        play_steps = int(self.frame_rate * play_steps_in_s)

        inputs = self.processor(
            text=text_prompt,
            padding=True,
            return_tensors="pt",
        )

        streamer = MusicgenStreamer(
            self.model, device=self.model.device, play_steps=play_steps
        )

        generation_kwargs = dict(
            **inputs.to(self.model.device),
            streamer=streamer,
            max_new_tokens=max_new_tokens,
        )
        thread = Thread(target=self.model.generate, kwargs=generation_kwargs)
        thread.start()

        set_seed(seed)


        bitsPerSample = 16
        channels = 1
        wav_header = self.genHeader(self.sampling_rate, bitsPerSample, channels)

        source_file_name = "output.wav"
        binary_chunks_to_write = []

        # yielding the audio as stream
        first_run = True
        for new_audio in streamer:
            print(
                f"Sample of length: {round(new_audio.shape[0] / self.sampling_rate, 2)} seconds"
            )
            if first_run:
                data = wav_header + np.int16(new_audio * self.sampling_rate).tobytes()
                first_run = False
            else:
                data = np.int16(new_audio * self.sampling_rate).tobytes()
            binary_chunks_to_write.append(data)
            yield data


        reassembled_binary_data = b"".join(binary_chunks_to_write)

        # Save the binary data to a .wav file
        with open("output.wav", "wb") as wav_file:
            wav_file.write(reassembled_binary_data)

        print("Audio file has been reassembled and saved as 'output.wav'.")
        
        self.__upload_to_gcs(uuid, source_file_name)
        self.__delete_local_file(source_file_name)

    def __delete_local_file(self, file_name):
        if os.path.exists(file_name):
            os.remove(file_name)
            print(f"File {file_name} deleted from local filesystem.")
        else:
            print(f"File {file_name} not found.")

    def __upload_to_gcs(self, uuid, source_file_name):
        file_uri = f"{uuid}/{source_file_name}"
        storage_client = storage.Client()
        bucket = storage_client.bucket(self.bucket_name)
        blob = bucket.blob(file_uri)

        blob.upload_from_filename(source_file_name)

        print(f"File {source_file_name} uploaded to {file_uri}.")
