import os
import random
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
from dotenv import load_dotenv

load_dotenv()

OTP_EXPIRY_MINUTES = 5


def generate_otp() -> str:
    return f"{random.randint(0, 999999):06d}"


def get_otp_expiry() -> datetime:
    return datetime.utcnow() + timedelta(minutes=OTP_EXPIRY_MINUTES)


def send_otp_email(to_email: str, otp_code: str) -> bool:
    smtp_host = os.getenv("SMTP_HOST", "")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER", "")
    smtp_password = os.getenv("SMTP_PASSWORD", "")
    smtp_from = os.getenv("SMTP_FROM", smtp_user)

    if not all([smtp_host, smtp_user, smtp_password]):
        print("[EMAIL] SMTP not configured — skipping email send", flush=True)
        return False

    msg = MIMEMultipart("alternative")
    msg["Subject"] = f"MRI Analysis — Your verification code: {otp_code}"
    msg["From"] = smtp_from
    msg["To"] = to_email

    html = f"""\
    <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px;">
      <h2 style="color:#0077B6;margin-bottom:8px;">MRI Analysis</h2>
      <p>Your email verification code is:</p>
      <div style="font-size:32px;letter-spacing:8px;font-weight:bold;
                  color:#023E8A;background:#F0F7FF;border-radius:12px;
                  padding:16px 24px;text-align:center;margin:16px 0;">
        {otp_code}
      </div>
      <p style="color:#666;font-size:13px;">
        This code expires in {OTP_EXPIRY_MINUTES} minutes.<br>
        If you did not request this, please ignore this email.
      </p>
    </div>
    """
    msg.attach(MIMEText(html, "html"))

    try:
        with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as server:
            server.ehlo()
            server.starttls()
            server.ehlo()
            server.login(smtp_user, smtp_password)
            server.sendmail(smtp_from, to_email, msg.as_string())
        print(f"[EMAIL] OTP sent to {to_email}", flush=True)
        return True
    except Exception as exc:
        print(f"[EMAIL] Failed to send OTP: {type(exc).__name__}: {exc}", flush=True)
        return False
