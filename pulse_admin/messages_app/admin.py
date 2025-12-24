import csv
from django.contrib import admin
from django.utils.html import format_html
from django.utils import timezone
from django.http import HttpResponse, HttpResponseRedirect
from django.contrib import messages
from django.conf import settings
from unfold.admin import ModelAdmin
from .models import PulseMessage, TargetApp
from .forms import PulseMessageAdminForm


admin.site.site_header = "Eventstream Pulse Admin"
admin.site.site_title = "Pulse Admin Portal"
admin.site.index_title = "Centralized In-App Messaging"


@admin.register(TargetApp)
class TargetAppAdmin(ModelAdmin):
    list_display = ('app_name', 'app_id', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('app_name', 'app_id')
    list_editable = ('is_active',)


@admin.register(PulseMessage)
class PulseMessageAdmin(ModelAdmin):
    form = PulseMessageAdminForm
    list_display = (
        'title',
        'message_type',
        'get_status_badge',
        'is_active',
        'priority',
        'get_target_apps_display',
        'start_date',
        'end_date',
        'get_impressions_count',
        'get_taps_count',
        'get_test_link',
    )
    list_filter = (
        'is_active',
        'message_type',
        'priority',
        'target_apps',
        'start_date',
    )
    search_fields = ('title', 'body')
    filter_horizontal = ('target_apps',)
    date_hierarchy = 'created_at'
    list_editable = ('is_active', 'priority')
    readonly_fields = ('created_at', 'updated_at', 'created_by', 'get_analytics_summary', 'get_api_test_urls')
    actions = [
        'duplicate_messages',
        'activate_messages',
        'deactivate_messages',
        'target_all_apps',
        'export_to_csv',
    ]

    fieldsets = (
        ('Content', {
            'fields': (
                ('title', 'title_color'),
                ('body', 'body_color'),
                'image_url',
            ),
            'description': 'Message content that users will see',
        }),
        ('Call to Action', {
            'fields': (
                ('cta_text', 'cta_action'),
                ('button_color', 'button_text_color'),
            ),
        }),
        ('Appearance', {
            'fields': (
                'background_color',
                ('message_type', 'banner_position'),
                ('priority', 'is_dismissible'),
            ),
        }),
        ('Targeting & Schedule', {
            'fields': (
                'target_apps',
                ('start_date', 'end_date'),
                'is_active',
            ),
        }),
        ('Analytics', {
            'fields': ('get_analytics_summary', 'get_api_test_urls', 'created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',),
        }),
    )

    class Media:
        css = {
            'all': ('admin/css/message_admin_unfold.css',)
        }
        js = ('admin/js/message_preview.js',)

    def get_status_badge(self, obj):
        if obj.is_currently_active():
            return format_html(
                '<span style="color: white; background: #27ae60; padding: 3px 8px; '
                'border-radius: 3px; font-size: 11px;">LIVE</span>'
            )
        elif not obj.is_active:
            return format_html(
                '<span style="color: white; background: #95a5a6; padding: 3px 8px; '
                'border-radius: 3px; font-size: 11px;">DRAFT</span>'
            )
        elif obj.start_date > timezone.now():
            return format_html(
                '<span style="color: white; background: #3498db; padding: 3px 8px; '
                'border-radius: 3px; font-size: 11px;">SCHEDULED</span>'
            )
        else:
            return format_html(
                '<span style="color: white; background: #e74c3c; padding: 3px 8px; '
                'border-radius: 3px; font-size: 11px;">ENDED</span>'
            )
    get_status_badge.short_description = 'Status'

    def get_target_apps_display(self, obj):
        apps = obj.target_apps.all()[:3]
        count = obj.target_apps.count()
        display = ', '.join([a.app_name for a in apps])
        if count > 3:
            display += f' (+{count - 3} more)'
        return display or '-'
    get_target_apps_display.short_description = 'Target Apps'

    def get_impressions_count(self, obj):
        return obj.impressions.count()
    get_impressions_count.short_description = 'Impressions'

    def get_taps_count(self, obj):
        return obj.taps.count()
    get_taps_count.short_description = 'Taps'

    def get_analytics_summary(self, obj):
        impressions = obj.impressions.count()
        taps = obj.taps.count()
        ctr = (taps / impressions * 100) if impressions > 0 else 0
        return format_html(
            '<strong>Impressions:</strong> {}<br>'
            '<strong>Taps:</strong> {}<br>'
            '<strong>CTR:</strong> {:.2f}%',
            impressions, taps, ctr
        )
    get_analytics_summary.short_description = 'Analytics Summary'

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

    # --- List display helpers ---

    def get_test_link(self, obj):
        """Show a test link in list view."""
        first_app = obj.target_apps.first()
        if first_app:
            token = getattr(settings, 'API_TOKEN', 'pulse_dev_token')
            return format_html(
                '<a href="/api/messages/?app_id={}&token={}" target="_blank" '
                'style="font-size: 11px;">Test API</a>',
                first_app.app_id, token
            )
        return '-'
    get_test_link.short_description = 'Test'

    def get_api_test_urls(self, obj):
        """Show API test URLs for each target app in detail view."""
        if not obj.pk:
            return "Save the message first to see test URLs."

        apps = obj.target_apps.all()
        if not apps:
            return "No target apps selected."

        token = getattr(settings, 'API_TOKEN', 'pulse_dev_token')
        urls = []
        for app in apps:
            urls.append(
                f'<strong>{app.app_name}:</strong><br>'
                f'<a href="/api/messages/?app_id={app.app_id}&token={token}" target="_blank" '
                f'style="background: #f4f4f4; padding: 2px 6px; font-size: 12px;">'
                f'/api/messages/?app_id={app.app_id}&token={token}</a>'
            )
        return format_html('<br><br>'.join(urls))
    get_api_test_urls.short_description = 'API Test URLs'

    # --- Admin actions ---

    @admin.action(description="Duplicate selected messages (as draft)")
    def duplicate_messages(self, request, queryset):
        duplicated = 0
        for message in queryset:
            # Get target apps before clearing pk
            target_apps = list(message.target_apps.all())

            # Create duplicate
            message.pk = None
            message.id = None
            message.title = f"Copy of {message.title}"[:100]
            message.is_active = False  # Always create as draft
            message.created_by = request.user
            message.save()

            # Restore target apps
            message.target_apps.set(target_apps)
            duplicated += 1

        self.message_user(
            request,
            f"Successfully duplicated {duplicated} message(s) as drafts.",
            messages.SUCCESS
        )

    @admin.action(description="Activate selected messages")
    def activate_messages(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f"Successfully activated {updated} message(s).",
            messages.SUCCESS
        )

    @admin.action(description="Deactivate selected messages")
    def deactivate_messages(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f"Successfully deactivated {updated} message(s).",
            messages.SUCCESS
        )

    @admin.action(description="Target all apps for selected messages")
    def target_all_apps(self, request, queryset):
        all_apps = TargetApp.objects.filter(is_active=True)
        for message in queryset:
            message.target_apps.set(all_apps)
        self.message_user(
            request,
            f"Successfully set all apps as targets for {queryset.count()} message(s).",
            messages.SUCCESS
        )

    @admin.action(description="Export selected messages to CSV")
    def export_to_csv(self, request, queryset):
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="pulse_messages.csv"'

        writer = csv.writer(response)
        writer.writerow([
            'ID', 'Title', 'Body', 'Message Type', 'Priority',
            'Is Active', 'Status', 'Target Apps',
            'Start Date', 'End Date',
            'Impressions', 'Taps', 'CTR %',
            'CTA Text', 'CTA Action', 'Image URL',
            'Created At', 'Created By'
        ])

        for msg in queryset:
            impressions = msg.impressions.count()
            taps = msg.taps.count()
            ctr = (taps / impressions * 100) if impressions > 0 else 0

            # Determine status
            if msg.is_currently_active():
                status = 'LIVE'
            elif not msg.is_active:
                status = 'DRAFT'
            elif msg.start_date > timezone.now():
                status = 'SCHEDULED'
            else:
                status = 'ENDED'

            writer.writerow([
                msg.id,
                msg.title,
                msg.body,
                msg.get_message_type_display(),
                msg.priority,
                msg.is_active,
                status,
                ', '.join(msg.target_app_ids),
                msg.start_date.strftime('%Y-%m-%d %H:%M') if msg.start_date else '',
                msg.end_date.strftime('%Y-%m-%d %H:%M') if msg.end_date else '',
                impressions,
                taps,
                f"{ctr:.2f}",
                msg.cta_text or '',
                msg.cta_action or '',
                msg.image_url or '',
                msg.created_at.strftime('%Y-%m-%d %H:%M'),
                msg.created_by.username if msg.created_by else ''
            ])

        return response
