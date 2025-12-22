from django.db import models
from django.utils import timezone
from django.core.validators import MinLengthValidator, MaxLengthValidator


class TargetApp(models.Model):
    """Registry of all city apps that can receive messages."""
    app_id = models.CharField(
        max_length=50,
        unique=True,
        help_text="Unique identifier (e.g., 'brighton', 'edinburgh')"
    )
    app_name = models.CharField(
        max_length=100,
        help_text="Display name (e.g., 'The Brighton App')"
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['app_name']
        verbose_name = 'Target App'
        verbose_name_plural = 'Target Apps'

    def __str__(self):
        return self.app_name


class PulseMessage(models.Model):
    """Core message model for in-app messaging."""

    MESSAGE_TYPES = [
        ('modal', 'Modal - Centered Popup'),
        ('banner', 'Banner - Top/Bottom Bar'),
        ('bottom_sheet', 'Bottom Sheet - Slides Up'),
        ('full_screen', 'Full Screen - Takeover'),
    ]

    BANNER_POSITIONS = [
        ('top', 'Top of Screen'),
        ('bottom', 'Bottom of Screen'),
    ]

    PRIORITY_LEVELS = [
        (1, 'Critical - Show Immediately'),
        (2, 'High - Show Soon'),
        (3, 'Normal - Standard Queue'),
        (4, 'Low - Background'),
    ]

    # Core Content
    title = models.CharField(
        max_length=100,
        validators=[MinLengthValidator(3)],
        help_text="Main heading of the message (3-100 chars)"
    )
    body = models.TextField(
        validators=[MaxLengthValidator(1000)],
        help_text="Message body content (max 1000 chars)"
    )
    image_url = models.URLField(
        max_length=500,
        blank=True,
        null=True,
        help_text="Optional image URL to display"
    )

    # Call to Action
    cta_text = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text="Button text (e.g., 'Learn More', 'Open')"
    )
    cta_action = models.CharField(
        max_length=500,
        blank=True,
        null=True,
        help_text="Action URL or deep link (e.g., 'https://...' or 'app://events/123')"
    )

    # Display Configuration
    message_type = models.CharField(
        max_length=20,
        choices=MESSAGE_TYPES,
        default='modal'
    )
    banner_position = models.CharField(
        max_length=10,
        choices=BANNER_POSITIONS,
        default='top',
        help_text="Only applies to banner type messages"
    )
    priority = models.PositiveSmallIntegerField(
        choices=PRIORITY_LEVELS,
        default=3
    )
    is_dismissible = models.BooleanField(
        default=True,
        help_text="Can users dismiss this message?"
    )

    # Targeting
    target_apps = models.ManyToManyField(
        TargetApp,
        related_name='messages',
        help_text="Which apps should show this message"
    )

    # Scheduling
    start_date = models.DateTimeField(
        default=timezone.now,
        help_text="When to start showing the message"
    )
    end_date = models.DateTimeField(
        blank=True,
        null=True,
        help_text="When to stop showing (leave blank for no end)"
    )

    # Status
    is_active = models.BooleanField(
        default=False,
        help_text="Enable to make message live"
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'auth.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_messages'
    )

    class Meta:
        ordering = ['priority', '-start_date']
        verbose_name = 'Pulse Message'
        verbose_name_plural = 'Pulse Messages'
        indexes = [
            models.Index(fields=['is_active', 'start_date', 'end_date']),
            models.Index(fields=['message_type']),
        ]

    def __str__(self):
        return f"{self.title} ({self.get_message_type_display()})"

    def is_currently_active(self):
        """Check if message should be shown right now."""
        now = timezone.now()
        if not self.is_active:
            return False
        if self.start_date > now:
            return False
        if self.end_date and self.end_date < now:
            return False
        return True

    @property
    def target_app_ids(self):
        """Return list of app IDs this message targets."""
        return list(self.target_apps.values_list('app_id', flat=True))
