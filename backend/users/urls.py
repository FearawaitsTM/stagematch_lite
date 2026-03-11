from django.urls import path

from .views import (
    RegisterCodeView,
    VerifyCodeView,
    ResendCodeView,
    LoginView,
    ArtistProfileView,
)

urlpatterns = [

    path(
        "auth/register/",
        RegisterCodeView.as_view(),
        name="register"
    ),

    path(
        "auth/verify/",
        VerifyCodeView.as_view(),
        name="verify"
    ),

    path(
        "auth/resend/",
        ResendCodeView.as_view(),
        name="resend"
    ),

    path(
        "auth/login/",
        LoginView.as_view(),
        name="login"
    ),

    path(
        "artist/profile/",
        ArtistProfileView.as_view(),
        name="artist-profile"
    ),
]