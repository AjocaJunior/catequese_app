"""
Envio de email via SMTP — usado só para recuperação de palavra-passe.

Configuração (variáveis de ambiente / .env):
    SMTP_HOST     (default: smtp.gmail.com)
    SMTP_PORT     (default: 587)
    SMTP_USER     — o email que envia (ex: catequeseassuncao@gmail.com)
    SMTP_PASSWORD — "palavra-passe de aplicação" do Gmail, NÃO a palavra-passe normal
                    (Conta Google → Segurança → Verificação em 2 passos → Palavras-passe de app)

Se SMTP_USER/SMTP_PASSWORD não estiverem definidos, lança um erro claro
em vez de falhar de forma confusa a meio do envio.
"""
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.core.config import get_settings

settings = get_settings()


def enviar_email(destinatario: str, assunto: str, corpo_texto: str) -> None:
    if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
        raise RuntimeError(
            "Envio de email não configurado (faltam SMTP_USER/SMTP_PASSWORD nas variáveis de ambiente)"
        )

    msg = MIMEMultipart()
    msg["From"] = settings.SMTP_USER
    msg["To"] = destinatario
    msg["Subject"] = assunto
    msg.attach(MIMEText(corpo_texto, "plain", "utf-8"))

    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as servidor:
        servidor.starttls()
        servidor.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        servidor.sendmail(settings.SMTP_USER, destinatario, msg.as_string())
