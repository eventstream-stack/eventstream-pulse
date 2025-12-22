from django.db import models
from django.utils import timezone


class MessageImpression(models.Model):
    """Track when a message is displayed."""
    message = models.ForeignKey(
        'messages_app.PulseMessage',
        on_delete=models.CASCADE,
        related_name='impressions'
    )
    app_id = models.CharField(max_length=50)
    timestamp = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'Message Impression'
        verbose_name_plural = 'Message Impressions'
        indexes = [
            models.Index(fields=['message', 'app_id', 'timestamp']),
        ]

    def __str__(self):
        return f"Impression: {self.message.title} ({self.app_id})"


class MessageTap(models.Model):
    """Track when a message CTA is tapped."""
    message = models.ForeignKey(
        'messages_app.PulseMessage',
        on_delete=models.CASCADE,
        related_name='taps'
    )
    app_id = models.CharField(max_length=50)
    timestamp = models.DateTimeField(default=timezone.now)

    class Meta:
        ordering = ['-timestamp']
        verbose_name = 'Message Tap'
        verbose_name_plural = 'Message Taps'
        indexes = [
            models.Index(fields=['message', 'app_id', 'timestamp']),
        ]

    def __str__(self):
        return f"Tap: {self.message.title} ({self.app_id})"
