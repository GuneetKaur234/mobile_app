"""
WSGI config for backend project with detailed startup logging.
"""

import os
import sys
import traceback

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

try:
    application = get_wsgi_application()
except Exception:
    # Print full traceback to stdout so Azure logs capture it
    traceback.print_exc()
    sys.stderr.flush()
    sys.stdout.flush()
    sys.exit(1)  # Exit so container fails visibly
