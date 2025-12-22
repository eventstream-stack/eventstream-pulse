from rest_framework import generics, status, exceptions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
from django.db import models
from django.conf import settings
from .models import PulseMessage
from .serializers import PulseMessageSerializer
from analytics.models import MessageImpression, MessageTap


class TokenValidationMixin:
    """Validates API token from query params."""

    def validate_token(self, request):
        token = request.query_params.get('token')
        valid_token = getattr(settings, 'API_TOKEN', 'pulse_dev_token')
        if token != valid_token:
            raise exceptions.AuthenticationFailed(
                "Authentication failed. Invalid token."
            )


class ActiveMessagesView(TokenValidationMixin, generics.ListAPIView):
    """
    GET /api/messages/?app_id=brighton&token=xxx
    Returns active messages for a specific app.
    """
    serializer_class = PulseMessageSerializer

    def get_queryset(self):
        app_id = self.request.query_params.get('app_id')
        now = timezone.now()

        queryset = PulseMessage.objects.filter(
            is_active=True,
            start_date__lte=now,
            target_apps__app_id=app_id
        ).filter(
            models.Q(end_date__isnull=True) | models.Q(end_date__gt=now)
        ).order_by('priority', '-start_date').distinct()

        return queryset

    def get(self, request, *args, **kwargs):
        self.validate_token(request)

        app_id = request.query_params.get('app_id')
        if not app_id:
            return Response(
                {"error": "app_id query parameter is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        return super().get(request, *args, **kwargs)


class RecordImpressionView(TokenValidationMixin, APIView):
    """
    POST /api/messages/{id}/impression/?app_id=brighton&token=xxx
    Records that a message was displayed.
    """

    def post(self, request, message_id):
        self.validate_token(request)

        app_id = request.query_params.get('app_id')
        if not app_id:
            return Response(
                {"error": "app_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            message = PulseMessage.objects.get(id=message_id)
            MessageImpression.objects.create(
                message=message,
                app_id=app_id
            )
            return Response({"status": "recorded"}, status=status.HTTP_201_CREATED)
        except PulseMessage.DoesNotExist:
            return Response(
                {"error": "Message not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class RecordTapView(TokenValidationMixin, APIView):
    """
    POST /api/messages/{id}/tap/?app_id=brighton&token=xxx
    Records that a message CTA was tapped.
    """

    def post(self, request, message_id):
        self.validate_token(request)

        app_id = request.query_params.get('app_id')
        if not app_id:
            return Response(
                {"error": "app_id is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            message = PulseMessage.objects.get(id=message_id)
            MessageTap.objects.create(
                message=message,
                app_id=app_id
            )
            return Response({"status": "recorded"}, status=status.HTTP_201_CREATED)
        except PulseMessage.DoesNotExist:
            return Response(
                {"error": "Message not found"},
                status=status.HTTP_404_NOT_FOUND
            )
