from django.contrib import admin
from django.utils.html import format_html
from django.utils import timezone
from .models import PulseMessage, TargetApp


admin.site.site_header = "Eventstream Pulse Admin"
admin.site.site_title = "Pulse Admin Portal"
admin.site.index_title = "Centralized In-App Messaging"


@admin.register(TargetApp)
class TargetAppAdmin(admin.ModelAdmin):
    list_display = ('app_name', 'app_id', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('app_name', 'app_id')
    list_editable = ('is_active',)


@admin.register(PulseMessage)
class PulseMessageAdmin(admin.ModelAdmin):
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
    readonly_fields = ('created_at', 'updated_at', 'created_by', 'get_analytics_summary')

    fieldsets = (
        ('Content', {
            'fields': ('title', 'body', 'image_url'),
        }),
        ('Call to Action', {
            'fields': ('cta_text', 'cta_action'),
            'classes': ('collapse',),
        }),
        ('Display Settings', {
            'fields': ('message_type', 'banner_position', 'priority', 'is_dismissible'),
        }),
        ('Targeting', {
            'fields': ('target_apps',),
        }),
        ('Scheduling', {
            'fields': ('start_date', 'end_date', 'is_active'),
        }),
        ('Analytics', {
            'fields': ('get_analytics_summary',),
            'classes': ('collapse',),
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',),
        }),
    )

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
