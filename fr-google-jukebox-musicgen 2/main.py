from fastapi import FastAPI, Query, HTTPException
from fastapi.responses import StreamingResponse
from model.models import MusicGenRequest
from service.musicgen_generator import MusigGenGenerator


app = FastAPI()
musicGenGenerator = MusigGenGenerator()


@app.get("/generate_audio")
async def generate(
    uuid: str = Query(...),
    prompt: str = Query(...),
    duration: int = Query(...),
):
    try:

        # Validate the request parameters
        request_body = MusicGenRequest(uuid=uuid, prompt=prompt, duration=duration)

        return StreamingResponse(
            musicGenGenerator.generate_audio_stream(
                uuid=request_body.uuid,
                text_prompt=request_body.prompt,
                audio_length_in_s=request_body.duration,
            ),
            media_type="audio/x-wav",
        )

    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Error generating audio.")
