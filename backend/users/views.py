import secrets
import json

from django.conf import settings
from django.core.cache import cache
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework.parsers import MultiPartParser, FormParser

from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

from .code.models import ArtistProfile
from .serializers import ArtistProfileSerializer


User = get_user_model()

CODE_TTL_SECONDS = 600



# арстист профиль


class ArtistProfileView(APIView):

    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get(self, request):

        profile, created = ArtistProfile.objects.get_or_create(
            user=request.user
        )

        serializer = ArtistProfileSerializer(profile)

        return Response(serializer.data)

    def post(self, request):

        profile, created = ArtistProfile.objects.get_or_create(
            user=request.user
        )

        data = request.data.copy()

        if "songs" in data:

            try:
                data["songs"] = json.loads(data["songs"])
            except:
                data["songs"] = []

        serializer = ArtistProfileSerializer(
            profile,
            data=data,
            partial=True
        )

        if serializer.is_valid():

            serializer.save(user=request.user)

            return Response(serializer.data)

        return Response(serializer.errors, status=400)


#помощник почты

def _cache_key(email: str):
    return f"pending_reg:{email.lower().strip()}"


def _generate_code():
    return f"{secrets.randbelow(1000000):06d}"


def _send_code(email, code):

    print("===== VERIFICATION CODE =====")
    print("EMAIL:", email)
    print("CODE:", code)
    print("=============================")

    try:

        message = Mail(
            from_email=settings.DEFAULT_FROM_EMAIL,
            to_emails=email,
            subject="StageMatch verification code",
            html_content=f"""
            <h2>StageMatch</h2>
            <p>Your verification code:</p>
            <h1>{code}</h1>
            """
        )

        sg = SendGridAPIClient(settings.SENDGRID_API_KEY)
        sg.send(message)

    except:
        print("Sendgrid error")


#register

class RegisterCodeView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get("email")
        password = request.data.get("password")

        if not email or not password:

            return Response(
                {"detail": "email and password required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if User.objects.filter(email=email).exists():

            return Response(
                {"detail": "Email already exists"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        code = _generate_code()

        cache.set(
            _cache_key(email),
            {
                "email": email,
                "password": make_password(password),
                "code": code,
            },
            timeout=CODE_TTL_SECONDS,
        )

        _send_code(email, code)

        return Response({"detail": "Check email"})


#resend code

class ResendCodeView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get("email")

        data = cache.get(_cache_key(email))

        if not data:

            return Response(
                {"detail": "No pending registration"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        code = _generate_code()

        data["code"] = code

        cache.set(_cache_key(email), data, timeout=CODE_TTL_SECONDS)

        _send_code(email, code)

        return Response({"detail": "Code resent"})


#verify code

class VerifyCodeView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get("email")
        code = request.data.get("code")

        data = cache.get(_cache_key(email))

        if not data:

            return Response(
                {"detail": "Code expired"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if code != data["code"]:

            return Response(
                {"detail": "Invalid code"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.create(
            username=email.split("@")[0],
            email=email,
            password=data["password"],
            is_active=True,
        )

        token, _ = Token.objects.get_or_create(user=user)

        cache.delete(_cache_key(email))

        return Response({"token": token.key})


#login

class LoginView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get("email")
        password = request.data.get("password")

        user = User.objects.filter(email=email).first()

        if not user or not user.check_password(password):

            return Response(
                {"detail": "Invalid credentials"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        token, _ = Token.objects.get_or_create(user=user)

        return Response({"token": token.key})