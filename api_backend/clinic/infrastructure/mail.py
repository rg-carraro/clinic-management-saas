import smtplib
import ssl
from email.message import EmailMessage
from urllib.parse import quote

from clinic.shared.config import get_settings


def send_reset(email: str, token: str):
    settings = get_settings()
    if not settings.smtp_host:
        # Local developer retrieves tokens only through a test mail adapter.
        # No token, recipient or message is ever logged.
        return
    message = EmailMessage()
    message["Subject"] = "Redefinição de senha"
    message["From"] = settings.smtp_from
    message["To"] = email
    message.set_content(
        "Abra o aplicativo e use este código para redefinir sua senha:\n"
        + token
        + "\n\nLink: "
        + settings.public_app_url
        + "/?reset="
        + quote(token)
        + "\nVálido por 30 minutos. Se não solicitou, ignore."
    )
    with smtplib.SMTP(settings.smtp_host, settings.smtp_port, timeout=10) as smtp:
        smtp.starttls(context=ssl.create_default_context())
        if settings.smtp_username:
            smtp.login(settings.smtp_username, settings.smtp_password)
        smtp.send_message(message)
