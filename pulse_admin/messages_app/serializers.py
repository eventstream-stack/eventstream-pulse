from rest_framework import serializers
from .models import PulseMessage, TargetApp


class TargetAppSerializer(serializers.ModelSerializer):
    class Meta:
        model = TargetApp
        fields = ['app_id', 'app_name']


class PulseMessageSerializer(serializers.ModelSerializer):
    target_app_ids = serializers.SerializerMethodField()
    is_currently_active = serializers.SerializerMethodField()

    class Meta:
        model = PulseMessage
        fields = [
            'id',
            'title',
            'body',
            'image_url',
            'cta_text',
            'cta_action',
            'message_type',
            'banner_position',
            'priority',
            'is_dismissible',
            'background_color',
            'title_color',
            'body_color',
            'button_color',
            'button_text_color',
            'target_app_ids',
            'start_date',
            'end_date',
            'is_currently_active',
            'created_at',
            'updated_at',
        ]

    def get_target_app_ids(self, obj):
        return obj.target_app_ids

    def get_is_currently_active(self, obj):
        return obj.is_currently_active()
