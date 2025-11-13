import os
from celery import Celery
import ssl

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")

app = Celery("backend")

# Broker / backend
REDIS_HOST = os.getenv("REDIS_HOST", "driverapp.redis.cache.windows.net")
REDIS_PORT = os.getenv("REDIS_PORT", "6380")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")
REDIS_USERNAME = "default"

CELERY_BROKER_URL = f"rediss://{REDIS_USERNAME}:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"
CELERY_RESULT_BACKEND = CELERY_BROKER_URL

REDIS_SSL_OPTIONS = {
    "ssl_cert_reqs": ssl.CERT_REQUIRED
}

# Configure Celery
app.conf.update(
    broker_url=CELERY_BROKER_URL,
    result_backend=CELERY_RESULT_BACKEND,
    broker_use_ssl=REDIS_SSL_OPTIONS,
    result_backend_use_ssl=REDIS_SSL_OPTIONS,
    task_track_started=True,
    task_time_limit=30 * 60,
    timezone="America/Toronto",
    enable_utc=False,
)

# Auto-discover tasks
app.autodiscover_tasks()
