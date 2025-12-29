from django.contrib import admin
from django.utils.html import format_html
from django.conf import settings
from unfold.admin import ModelAdmin
from .models import APIKey
from .forms import APIKeyAdminForm
from .encryption import decrypt_value


@admin.register(APIKey)
class APIKeyAdmin(ModelAdmin):
    form = APIKeyAdminForm
    list_display = (
        'name',
        'service_name',
        'get_status_badge',
        'get_expiry_badge',
        'get_masked_value',
        'last_accessed_at',
        'updated_at',
    )
    list_filter = ('is_active', 'service_name', 'expires_at')
    search_fields = ('name', 'description', 'service_name')
    list_editable = ()
    readonly_fields = (
        'created_at',
        'updated_at',
        'created_by',
        'last_accessed_at',
        'get_api_test_url',
    )

    fieldsets = (
        ('Key Information', {
            'fields': ('name', 'service_name', 'description'),
        }),
        ('Value', {
            'fields': ('key_value',),
            'description': 'Enter the plaintext API key. It will be encrypted before storage.',
        }),
        ('Status & Expiry', {
            'fields': ('is_active', 'expires_at'),
        }),
        ('API Access', {
            'fields': ('get_api_test_url',),
            'classes': ('collapse',),
        }),
        ('Audit', {
            'fields': ('created_at', 'updated_at', 'created_by', 'last_accessed_at'),
            'classes': ('collapse',),
        }),
    )

    def get_status_badge(self, obj):
        if obj.is_active:
            return format_html(
                '<span style="color: white; background: #27ae60; padding: 3px 8px; '
                'border-radius: 3px; font-size: 11px; font-weight: 500;">ACTIVE</span>'
            )
        return format_html(
            '<span style="color: white; background: #95a5a6; padding: 3px 8px; '
            'border-radius: 3px; font-size: 11px; font-weight: 500;">INACTIVE</span>'
        )
    get_status_badge.short_description = 'Status'

    def get_expiry_badge(self, obj):
        if obj.expires_at is None:
            return format_html(
                '<span style="color: #666; font-size: 11px;">No expiry</span>'
            )
        if obj.is_expired:
            return format_html(
                '<span style="color: white; background: #e74c3c; padding: 3px 8px; '
                'border-radius: 3px; font-size: 11px; font-weight: 500;">EXPIRED</span>'
            )
        if obj.is_expiring_soon:
            return format_html(
                '<span style="color: white; background: #f39c12; padding: 3px 8px; '
                'border-radius: 3px; font-size: 11px; font-weight: 500;">EXPIRING SOON</span>'
            )
        return format_html(
            '<span style="color: #666; font-size: 11px;">{}</span>',
            obj.expires_at.strftime('%Y-%m-%d')
        )
    get_expiry_badge.short_description = 'Expiry'

    def get_masked_value(self, obj):
        """Show only last 4 characters of the decrypted key."""
        try:
            value = decrypt_value(obj.encrypted_value)
            if len(value) > 4:
                return f"{'*' * 16}...{value[-4:]}"
            return '*' * len(value)
        except Exception:
            return '(decryption error)'
    get_masked_value.short_description = 'Key Value'

    def get_api_test_url(self, obj):
        if not obj.pk:
            return "Save the key first to see test URL."
        token = getattr(settings, 'API_TOKEN', 'pulse_dev_token')
        url = f"/api/keys/{obj.name}/value/?token={token}"
        return format_html(
            '<code style="background: #f4f4f4; padding: 4px 8px; '
            'border-radius: 3px; font-size: 12px;">{}</code>',
            url
        )
    get_api_test_url.short_description = 'API Test URL'

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
