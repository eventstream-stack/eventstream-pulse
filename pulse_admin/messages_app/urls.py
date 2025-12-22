from django.urls import path
from . import views

urlpatterns = [
    path('messages/', views.ActiveMessagesView.as_view(), name='active-messages'),
    path('messages/<int:message_id>/impression/', views.RecordImpressionView.as_view(), name='record-impression'),
    path('messages/<int:message_id>/tap/', views.RecordTapView.as_view(), name='record-tap'),
]
