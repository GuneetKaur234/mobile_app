import os
from celery import Celery
import ssl

# Set Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

app = Celery('backend')

# Fetch Redis credentials from environment variables
REDIS_HOST = os.getenv('REDIS_HOST')
REDIS_PORT = os.getenv('REDIS_PORT', 6380)
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')
REDIS_USERNAME = "default"  # Azure Redis uses 'default' as username

# SSL options
ssl_options = {
    "ssl_cert_reqs": ssl.CERT_REQUIRED  # Secure: verifies Redis identity
}

# Build broker & backend URLs
CELERY_BROKER_URL = f"rediss://{REDIS_USERNAME}:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"
CELERY_RESULT_BACKEND = CELERY_BROKER_URL

# Apply SSL options
app.conf.broker_use_ssl = ssl_options
app.conf.result_backend_use_ssl = ssl_options

# Serialization & expiration
app.conf.task_serializer = 'json'
app.conf.result_serializer = 'json'
app.conf.accept_content = ['json']
app.conf.result_expires = 3600

# Timezone & task settings
app.conf.timezone = 'America/Toronto'
app.conf.enable_utc = False
app.conf.task_track_started = True
app.conf.task_time_limit = 30 * 60  # 30 min max per task

# Auto-discover tasks in all Django apps
app.autodiscover_tasks()
