"""
Django settings for Eventstream Pulse.
"""

import os
from pathlib import Path
from dotenv import load_dotenv
from django.templatetags.static import static
from django.urls import reverse_lazy

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('SECRET_KEY', 'django-insecure-dev-key-change-in-production')

DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')

# Application definition
INSTALLED_APPS = [
    'unfold',
    'unfold.contrib.filters',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'messages_app',
    'analytics',
    'api_keys',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'pulse_admin.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'pulse_admin.wsgi.application'

# Database
# Use SQLite for local development, PostgreSQL for production
if os.getenv('USE_SQLITE', 'False').lower() == 'true':
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.postgresql',
            'NAME': os.getenv('POSTGRES_DB', 'pulse_db'),
            'USER': os.getenv('POSTGRES_USER', 'pulse_admin'),
            'PASSWORD': os.getenv('POSTGRES_PASSWORD', 'password'),
            'HOST': os.getenv('POSTGRES_HOST', 'localhost'),
            'PORT': os.getenv('POSTGRES_PORT', '5432'),
        }
    }

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# CORS settings
CORS_ALLOW_ALL_ORIGINS = True  # For mobile apps
CORS_URLS_REGEX = r'^/api/.*$'

# CSRF trusted origins
CSRF_TRUSTED_ORIGINS = os.getenv('CSRF_TRUSTED_ORIGINS', 'http://localhost:8000').split(',')

# API Token
API_TOKEN = os.getenv('API_TOKEN', 'pulse_dev_token')

# Django Unfold admin configuration
UNFOLD = {
    "SITE_TITLE": "Pulse Admin",
    "SITE_HEADER": "Eventstream Pulse",
    "SITE_SUBHEADER": "Centralized In-App Messaging",
    "SHOW_HISTORY": True,
    "SHOW_VIEW_ON_SITE": True,
    "STYLES": [
        lambda request: static("admin/css/message_admin_unfold.css"),
    ],
    "SCRIPTS": [
        lambda request: static("admin/js/message_preview.js"),
    ],
    "SIDEBAR": {
        "show_search": True,
        "show_all_applications": True,
        "navigation": [
            {
                "title": "Messaging",
                "separator": True,
                "items": [
                    {
                        "title": "Pulse Messages",
                        "icon": "mail",
                        "link": reverse_lazy("admin:messages_app_pulsemessage_changelist"),
                    },
                    {
                        "title": "Target Apps",
                        "icon": "smartphone",
                        "link": reverse_lazy("admin:messages_app_targetapp_changelist"),
                    },
                ],
            },
            {
                "title": "Analytics",
                "separator": True,
                "items": [
                    {
                        "title": "Impressions",
                        "icon": "visibility",
                        "link": reverse_lazy("admin:analytics_messageimpression_changelist"),
                    },
                    {
                        "title": "Taps",
                        "icon": "touch_app",
                        "link": reverse_lazy("admin:analytics_messagetap_changelist"),
                    },
                ],
            },
            {
                "title": "Authentication",
                "separator": True,
                "collapsible": True,
                "items": [
                    {
                        "title": "Users",
                        "icon": "person",
                        "link": reverse_lazy("admin:auth_user_changelist"),
                    },
                    {
                        "title": "Groups",
                        "icon": "group",
                        "link": reverse_lazy("admin:auth_group_changelist"),
                    },
                ],
            },
            {
                "title": "Security",
                "separator": True,
                "items": [
                    {
                        "title": "API Keys",
                        "icon": "key",
                        "link": reverse_lazy("admin:api_keys_apikey_changelist"),
                    },
                ],
            },
        ],
    },
}
