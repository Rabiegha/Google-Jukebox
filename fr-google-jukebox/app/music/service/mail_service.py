import logging
import smtplib
import ssl
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.music.models.mail import MailRequest
from app.core.config import settings
from app.music.models.music import MusicRead
from app.music.service.email_template import email_template

logger = logging.getLogger(__name__)


class MailService:
    def __init__(self):
        self.from_email = settings.GOOGLE_APP_EMAIL.strip()
        self.google_app_password = settings.GOOGLE_APP_PASSWORD.strip().replace('\xa0', '').replace(' ', '')
        logger.info(f"[MailService] Initialized with from_email={self.from_email} | password_set={'yes' if self.google_app_password else 'NO - MISSING'}")

    def send_mail(self, mail: MailRequest, music: MusicRead):
        recipients = mail.recipients
        logger.info(f"[MailService.send_mail] Preparing email | to={recipients} | song={music.title}")

        subject = "Jukebox - Generated Music"

        content = self.__create_mail_content(music)

        try:
            # Send the email
            self.__send_mail_internally(
                recipients=recipients,
                subject=subject,
                content=content,
            )

        except Exception as e:
            logger.exception(f"[MailService.send_mail] Exception: {e}")
            raise e

    def __send_mail_internally(self, recipients, subject, content, content_type="HTML"):
        logger.info(f"[MailService.__send_mail_internally] Connecting to smtp.gmail.com:587 | from={self.from_email}")
        context = ssl.create_default_context()
        self.server = smtplib.SMTP("smtp.gmail.com", 587)
        self.server.ehlo()
        self.server.starttls(context=context)
        logger.info("[MailService.__send_mail_internally] TLS started, logging in...")
        self.server.login(self.from_email, self.google_app_password)
        logger.info("[MailService.__send_mail_internally] Login successful")

        # Create the email message
        msg = MIMEMultipart()
        msg["From"] = self.from_email
        msg["To"] = ", ".join(recipients)
        msg["Subject"] = subject
        msg.attach(MIMEText(content, content_type))

        try:
            self.server.sendmail(self.from_email, recipients, msg.as_string())
            self.server.quit()
            logger.info("[MailService.__send_mail_internally] Email sent successfully")
        except Exception as e:
            logger.exception(f"[MailService.__send_mail_internally] Failed to send email: {e}")
            raise e

    def __create_mail_content(self, music: MusicRead):

        html_content = email_template

        # Substitute placeholders with properties from the mail object
        html_content = html_content.replace("$song-title$", music.title)
        html_content = html_content.replace("$cover-url$", music.cover)
        html_content = html_content.replace("$audio-url$", music.audio)

        return html_content
