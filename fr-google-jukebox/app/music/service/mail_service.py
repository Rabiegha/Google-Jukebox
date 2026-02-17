from app.music.models.mail import MailRequest
from app.core.config import settings

from app.music.models.music import MusicRead
from app.music.service.email_template import email_template

import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import ssl


class MailService:
    def __init__(self):
        self.from_email = settings.GOOGLE_APP_EMAIL
        self.google_app_password = settings.GOOGLE_APP_PASSWORD

    def send_mail(self, mail: MailRequest, music: MusicRead):
        recipients = mail.recipients

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
            raise e

    def __send_mail_internally(self, recipients, subject, content, content_type="HTML"):
        self.server = context = ssl.create_default_context()
        self.server = smtplib.SMTP("smtp.gmail.com", 587)
        self.server.ehlo()
        self.server.starttls(context=context)
        self.server.login(self.from_email, self.google_app_password)

        # Create the email message
        msg = MIMEMultipart()
        msg["From"] = self.from_email
        msg["To"] = ", ".join(recipients)
        msg["Subject"] = subject
        msg.attach(MIMEText(content, content_type))

        try:
            self.server.sendmail(self.from_email, recipients, msg.as_string())
            self.server.quit()
            print("Email sent successfully")
        except Exception as e:
            print(f"Failed to send email: {e}")
            raise e

    def __create_mail_content(self, music: MusicRead):

        html_content = email_template

        # Substitute placeholders with properties from the mail object
        html_content = html_content.replace("$song-title$", music.title)
        html_content = html_content.replace("$cover-url$", music.cover)
        html_content = html_content.replace("$audio-url$", music.audio)

        return html_content
