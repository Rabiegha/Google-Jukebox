import logging

from fastapi import APIRouter, Response, status

from app.api.deps import raise_404, raise_500
from app.music.models.mail import MailRequest
from app.music.models.music import MusicRead
from app.music.service.mail_service import MailService
from app.core.config import settings
from app.firestore.crud import firestore

logger = logging.getLogger(__name__)


router = APIRouter()

mailservice = MailService()


@router.post(
    "",
    status_code=status.HTTP_200_OK,
)
async def send_mail(mail: MailRequest):
    logger.info(f"[send_mail] Request received | music_id={mail.music_id} | genre={mail.music_genre} | recipients={mail.recipients}")

    music: dict = await firestore.get_document_in_subcollection(
        settings.JUKEBOX_COLLECTION,
        settings.MUSIC_SUB_COLLECTION,
        mail.music_genre,
        mail.music_id,
    )

    if music is None:
        logger.error(f"[send_mail] Music not found | music_id={mail.music_id} | genre={mail.music_genre}")
        raise_404("Music not found")
    else:
        logger.info(f"[send_mail] Music found: {music.get('title', 'N/A')}")
        try:
            # Send the email
            mailservice.send_mail(mail, MusicRead(**music))
            logger.info("[send_mail] Email sent successfully")
        except Exception as e:
            logger.exception(f"[send_mail] Failed to send email: {e}")
            raise_500()

    return Response(content="Email sent successfully")
