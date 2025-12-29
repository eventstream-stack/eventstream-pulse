from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
from messages_app.views import TokenValidationMixin
from .models import APIKey
from .encryption import decrypt_value


from django.db import models


class ListAPIKeysView(TokenValidationMixin, APIView):
    """
    GET /api/keys/?token=xxx
    Returns list of available API key names (not values).
    Excludes expired keys.
    """

    def get(self, request):
        self.validate_token(request)

        now = timezone.now()
        keys = APIKey.objects.filter(
            is_active=True
        ).filter(
            models.Q(expires_at__isnull=True) | models.Q(expires_at__gt=now)
        ).values(
            'name', 'service_name', 'description', 'expires_at'
        )

        return Response({
            'keys': list(keys)
        }, status=status.HTTP_200_OK)


class GetAPIKeyValueView(TokenValidationMixin, APIView):
    """
    GET /api/keys/<name>/value/?token=xxx
    Returns the decrypted value of an API key.
    Returns 404 for expired keys.
    """

    def get(self, request, key_name):
        self.validate_token(request)

        try:
            api_key = APIKey.objects.get(name=key_name, is_active=True)

            # Check if key is expired
            if api_key.is_expired:
                return Response(
                    {'error': f"API key '{key_name}' has expired"},
                    status=status.HTTP_410_GONE
                )

            # Update last accessed timestamp
            api_key.last_accessed_at = timezone.now()
            api_key.save(update_fields=['last_accessed_at'])

            # Decrypt and return
            decrypted_value = decrypt_value(api_key.encrypted_value)

            response_data = {
                'name': api_key.name,
                'value': decrypted_value,
                'service_name': api_key.service_name,
            }

            # Include expiry info if set
            if api_key.expires_at:
                response_data['expires_at'] = api_key.expires_at.isoformat()

            return Response(response_data, status=status.HTTP_200_OK)

        except APIKey.DoesNotExist:
            return Response(
                {'error': f"API key '{key_name}' not found or inactive"},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception:
            return Response(
                {'error': 'Failed to decrypt key'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
