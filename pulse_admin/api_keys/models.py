from django.db import models
from django.core.validators import RegexValidator
from django.utils import timezone


class APIKey(models.Model):
    """Encrypted storage for third-party API keys."""

    name = models.CharField(
        max_length=100,
        unique=True,
        validators=[RegexValidator(
            regex=r'^[a-z][a-z0-9_]*$',
            message='Name must start with lowercase letter, contain only lowercase letters, numbers, and underscores'
        )],
        help_text="Unique identifier for the key (e.g., 'brightdata_api_key')"
    )
    service_name = models.CharField(
        max_length=100,
        blank=True,
        help_text="Third-party service name (e.g., 'Brightdata')"
    )
    description = models.TextField(
        blank=True,
        help_text="Purpose and usage notes for this API key"
    )
    encrypted_value = models.TextField(
        help_text="The encrypted API key value"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Inactive keys will not be returned by the API"
    )
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Optional expiration date. Leave blank for keys that don't expire."
    )

    # Audit fields
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'auth.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_api_keys'
    )
    last_accessed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Last time this key was retrieved via API"
    )

    class Meta:
        ordering = ['name']
        verbose_name = 'API Key'
        verbose_name_plural = 'API Keys'
        indexes = [
            models.Index(fields=['name', 'is_active']),
        ]

    def __str__(self):
        if self.service_name:
            return f"{self.name} ({self.service_name})"
        return self.name

    @property
    def is_expired(self):
        """Check if the key has expired."""
        if self.expires_at is None:
            return False
        return timezone.now() > self.expires_at

    @property
    def is_expiring_soon(self):
        """Check if the key expires within the next 7 days."""
        if self.expires_at is None:
            return False
        from datetime import timedelta
        return not self.is_expired and (self.expires_at - timezone.now()) < timedelta(days=7)

    @property
    def is_valid(self):
        """Check if the key is active and not expired."""
        return self.is_active and not self.is_expired
