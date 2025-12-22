from django.contrib import admin
from .models import MessageImpression, MessageTap


@admin.register(MessageImpression)
class MessageImpressionAdmin(admin.ModelAdmin):
    list_display = ('message', 'app_id', 'timestamp')
    list_filter = ('app_id', 'timestamp', 'message')
    search_fields = ('message__title', 'app_id')
    date_hierarchy = 'timestamp'
    readonly_fields = ('message', 'app_id', 'timestamp')


@admin.register(MessageTap)
class MessageTapAdmin(admin.ModelAdmin):
    list_display = ('message', 'app_id', 'timestamp')
    list_filter = ('app_id', 'timestamp', 'message')
    search_fields = ('message__title', 'app_id')
    date_hierarchy = 'timestamp'
    readonly_fields = ('message', 'app_id', 'timestamp')
