"""WSGI config for Eventstream Pulse."""

import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'pulse_admin.settings')
application = get_wsgi_application()
