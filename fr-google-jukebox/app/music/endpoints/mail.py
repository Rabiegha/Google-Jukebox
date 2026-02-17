from fastapi import APIRouter, Response, status

from app.api.deps import raise_404, raise_500
from app.music.models.mail import MailRequest
from app.music.models.music import MusicRead
from app.music.service.mail_service import MailService
from app.core.config import settings
from app.firestore.crud import firestore


router = APIRouter()

mailservice = MailService()


@router.post(
    "",
    status_code=status.HTTP_200_OK,
)
async def send_mail(mail: MailRequest):
    music: dict = await firestore.get_document_in_subcollection(
        settings.JUKEBOX_COLLECTION,
        settings.MUSIC_SUB_COLLECTION,
        mail.music_genre,
        mail.music_id,
    )

    if music is None:
        raise_404("Music not found")
    else:
        try:
            # Send the email
            mailservice.send_mail(mail, MusicRead(**music))
        except Exception as e:
            raise_500()

    return Response(content="Email sent successfully")
