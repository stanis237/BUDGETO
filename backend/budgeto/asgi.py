"""
ASGI config for Budgeto project.
"""
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'budgeto.settings')
application = get_asgi_application()
