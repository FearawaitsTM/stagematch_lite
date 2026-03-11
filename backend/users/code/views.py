import json
import traceback
from datetime import timedelta

from django.contrib.auth.models import User
from django.http import JsonResponse
from django.utils import timezone

from backend.users.code.models import EmailVerification
from backend.users.code.utils import generate_code

from backend.users.email_service import send_verification_email


def register(request):

    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=400)

    try:
        data = json.loads(request.body)

        email = data.get("email")
        password = data.get("password")

        if not email or not password:
            return JsonResponse({"detail": "Email and password required"}, status=400)

        if User.objects.filter(email=email).exists():
            return JsonResponse({"detail": "User already exists"}, status=409)

        user = User.objects.create_user(
            username=email,
            email=email,
            password=password,
            is_active=False,
        )

        code = generate_code()

        EmailVerification.objects.create(
            user=user,
            code=code
        )

        # отправка через сенгрид
        send_verification_email(email, code)

        return JsonResponse({
            "message": "verification code sent"
        })

    except Exception as e:
        print("REGISTER ERROR:")
        traceback.print_exc()
        return JsonResponse({"detail": "Email service unavailable"}, status=503)


def verify(request):

    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=400)

    try:
        data = json.loads(request.body)

        email = data.get("email")
        code = data.get("code")

        user = User.objects.filter(email=email).first()

        if not user:
            return JsonResponse({"detail": "User not found"}, status=404)

        verification = EmailVerification.objects.filter(
            user=user,
            code=code
        ).first()

        if not verification:
            return JsonResponse({"detail": "Invalid code"}, status=400)

        if verification.created_at < timezone.now() - timedelta(minutes=10):
            verification.delete()
            return JsonResponse({"detail": "Code expired"}, status=400)

        user.is_active = True
        user.save()

        verification.delete()

        return JsonResponse({
            "message": "Account verified"
        })

    except Exception as e:
        print("VERIFY ERROR:")
        traceback.print_exc()
        return JsonResponse({"detail": "Verification failed"}, status=500)