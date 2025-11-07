import os
import ssl
from celery import Celery

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

app = Celery('backend')

# ----------------------------
# Azure Redis (SSL) Setup
# ----------------------------
REDIS_HOST = os.getenv('REDIS_HOST')
REDIS_PORT = os.getenv('REDIS_PORT', '6380')  # Azure Redis SSL port
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')

# Use SSL — required for Azure Redis
app.conf.broker_url = f"rediss://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"
app.conf.result_backend = f"rediss://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"

# ----------------------------
# SSL Configuration (Critical!)
# ----------------------------
app.conf.broker_use_ssl = {
    "ssl_cert_reqs": ssl.CERT_NONE,  # Disable cert verification
}

app.conf.redis_backend_use_ssl = {
    "ssl_cert_reqs": ssl.CERT_NONE,
}

# ----------------------------
# General Celery Config
# ----------------------------
app.conf.task_serializer = 'json'
app.conf.result_serializer = 'json'
app.conf.accept_content = ['json']
app.conf.result_expires = 3600
app.conf.timezone = 'America/Toronto'
app.conf.enable_utc = False

# Auto-discover tasks from all Django apps
app.autodiscover_tasks()
