import google.generativeai as genai
import requests
import vertexai
import replicate
import io

from vertexai.preview.vision_models import ImageGenerationModel

from app.core.config import settings
from app.music.models.prompt import PromptBase, PromptCover, PromptMusic


class GenerativeAI:
    def __init__(self, text_model=None, img_model=None):
        self.text_model = text_model
        self.img_model = img_model

    async def generate(self, prompt: PromptBase):
        raise NotImplementedError("Subclasses should implement this method.")


class CoverGenerator(GenerativeAI):
    def __init__(self):
        self._text_model = None
        self._img_model = None

    @property
    def text_model(self):
        # Lazy initialization to avoid authentication issues during app startup
        if self._text_model is None:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self._text_model = genai.GenerativeModel(
                settings.GEMINI_MODEL,
                generation_config=genai.GenerationConfig(
                    temperature=0,
                ),
            )
        return self._text_model

    @property
    def img_model(self):
        # Lazy initialization to avoid authentication issues during app startup
        if self._img_model is None:
            vertexai.init(
                project=settings.GCLOUD_PROJECT_ID, location=settings.IMAGE_GENARATION_LOCATION
            )
            self._img_model = ImageGenerationModel.from_pretrained(settings.IMAGEN_MODEL)
        return self._img_model

    async def generate(self, prompt: PromptCover):
        try:
            context = """You are an AI trained to generate cover images from music prompts.
            Each prompt describes a piece of music with details such as time signature, tempo, bitrate, sample rate,
            and instrumentation. You should create a cover image description for music description
            and take inspiration from the title of the song.
            """

            customPrompt = f"""Create a vibrant album cover for a musical piece in the style of "{prompt.genre}".
            The cover should feature elements inspired by this description: "{prompt.prompt}", reflecting the mood and energy described.
            The design should incorporate a blend of colors and artistic elements that evoke the ambiance of "{prompt.genre}" music style.
            Include the name "{prompt.creator}" in a creative, bold typography that fits the overall aesthetic.
            """

            gemini_response = self.text_model.generate_content(
                [context, customPrompt, prompt.title]
            )

            # Imagen 3 image generation
            image_response = self.img_model.generate_images(
                prompt=gemini_response.text,
                number_of_images=1,
                aspect_ratio="1:1",
                safety_filter_level="block_some",
                person_generation="allow_all",
                output_gcs_uri=f"gs://{settings.GCLOUD_MUSIC_BUCKET}/{prompt.uuid}",
            )

            image_url = image_response.images[0]._gcs_uri

            return image_url.replace("gs://", "https://storage.googleapis.com/")

        except Exception as e:
            raise e


class MusicGenerator(GenerativeAI):
    def __init__(self):
        self._client = None

    @property
    def client(self):
        if self._client is None:
            self._client = replicate.Client(api_token=settings.REPLICATE_API_TOKEN)
        return self._client

    async def generate(self, prompt: PromptMusic):
        try:
            # Use Replicate MusicGen model
            output = self.client.run(
                "meta/musicgen:671ac645ce5e552cc63a54a2bbff63fcf798043055d2dac5fc9e36a837eedcfb",
                input={
                    "prompt": prompt.prompt,
                    "duration": prompt.duration,
                    "model_version": "stereo-large",
                },
            )

            # output is a URL to the generated audio file
            # Download it and yield as chunks
            response = requests.get(output, stream=True)
            response.raise_for_status()

            for chunk in response.iter_content(chunk_size=1024):
                if chunk:
                    yield chunk

        except Exception as e:
            raise e


class SettingsGenerator(GenerativeAI):
    def __init__(self):
        self._text_model = None

    @property
    def text_model(self):
        # Lazy initialization to avoid authentication issues during app startup
        if self._text_model is None:
            genai.configure(api_key=settings.GEMINI_API_KEY)
            self._text_model = genai.GenerativeModel(
                settings.GEMINI_MODEL,
                generation_config=genai.GenerationConfig(
                    temperature=0,
                ),
            )
        return self._text_model

    def generate(self, song: str):
        try:
            context = """You are an AI trained to generate music settings from song names or short descriptions. 
            Each song name has a unique identifier for a piece of music with details such as:
            - time signature (possible values: "4/4", "6/8", "3/4", "2/4", "12/8", "3/8", "2/2"), 
            - tempo (BPM range: 40-200), 
            - bitrate (kbps range: 16-450) and
            - sample rate (possible values: "44.1kHz", "48kHz", "96kHz"). 
            
            Based on these details, generate a string that describes the music settings in the following format: 
            '<bpm>bpm <rhythm> <quality>kbps <sound range>kHz'. 
            
            Make sure you only give the music settings as the output.
       
            Here is an example song name: 'Dance Monkey with low quality'. 
            Expected output: '120bpm 4/4 120kbps 44.1kHz'
            Here is another example song name: 'Eine kleine Nachtmusik by Mozart'.
            Expected output: '140bpm 3/4 320kbps 44.1kHz'
            Here is another example song name: 'Slow pased and complex song'.
            Expected output: '90bpm 12/8 320kbps 44.1kHz'
            """

            response = self.text_model.generate_content([context, song])

            return response.text

        except Exception as e:
            raise e
