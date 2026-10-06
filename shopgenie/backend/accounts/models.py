from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone

class CustomUser(AbstractUser):
    """
    Custom User model representing an authenticated shopkeeper in ShopGenie AI.
    All inventory, embeddings, and invoices are strictly scoped to this user.
    """
    email = models.EmailField(unique=True, db_index=True)
    shop_name = models.CharField(max_length=150, blank=True, default='')
    date_joined = models.DateTimeField(default=timezone.now)

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    class Meta:
        db_table = 'shopgenie_users'
        verbose_name = 'Shopkeeper User'
        verbose_name_plural = 'Shopkeeper Users'

    def __str__(self):
        return f"{self.username} ({self.email})"
