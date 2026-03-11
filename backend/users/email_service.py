from django.core.mail import send_mail
from django.conf import settings

def send_verification_email(email, code):
    subject = "StageMatch verification code"
    message = f"Your verification code: {code}"

    send_mail(
        subject,
        message,
        settings.DEFAULT_FROM_EMAIL,
        [email],
        fail_silently=False,
    )