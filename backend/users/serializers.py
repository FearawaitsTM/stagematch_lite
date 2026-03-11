from rest_framework import serializers
from django.contrib.auth.models import User
from .code.models import ArtistProfile


class RegisterSerializer(serializers.ModelSerializer):

    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = (
            "first_name",
            "last_name",
            "username",
            "email",
            "password",
        )

        extra_kwargs = {
            "email": {"validators": []},
        }

    def validate_email(self, email):

        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError("Email already exists")

        return email

    def create(self, validated_data):

        user = User.objects.create_user(
            username=validated_data["username"],
            email=validated_data["email"],
            password=validated_data["password"],
            first_name=validated_data.get("first_name", ""),
            last_name=validated_data.get("last_name", ""),
        )

        return user


class ArtistProfileSerializer(serializers.ModelSerializer):

    songs = serializers.JSONField(required=False)

    class Meta:
        model = ArtistProfile
        fields = "__all__"
        read_only_fields = ["user"]