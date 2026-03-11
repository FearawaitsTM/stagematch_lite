from django.db import models
from django.contrib.auth.models import User


class ArtistProfile(models.Model):

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="artist_profile"
    )

    photo = models.ImageField(
        upload_to="artists/",
        null=True,
        blank=True
    )

    first_name = models.CharField(
        max_length=100,
        blank=True
    )

    last_name = models.CharField(
        max_length=100,
        blank=True
    )

    genre = models.CharField(
        max_length=100,
        blank=True
    )

    songs = models.JSONField(
        default=list,
        blank=True
    )

    country = models.CharField(
        max_length=100,
        blank=True
    )

    city = models.CharField(
        max_length=100,
        blank=True
    )

    rating = models.FloatField(default=0)

    def __str__(self):
        return f"{self.first_name} {self.last_name}"