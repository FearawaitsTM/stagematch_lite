from django.utils import timezone
from datetime import timedelta
from django.contrib.auth import get_user_model
from allauth.account.models import EmailAddress

User = get_user_model()

expired = timezone.now() - timedelta(seconds=1)

users = User.objects.filter(
    is_active=False,
    date_joined__lt=expired
)

for user in users:
    EmailAddress.objects.filter(user=user, verified=True).exists() or user.delete()
