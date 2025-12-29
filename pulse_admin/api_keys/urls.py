from django.urls import path
from . import views

urlpatterns = [
    path('keys/', views.ListAPIKeysView.as_view(), name='list-keys'),
    path('keys/<str:key_name>/value/', views.GetAPIKeyValueView.as_view(), name='get-key-value'),
]
