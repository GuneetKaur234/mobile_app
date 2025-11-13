import os
from celery import Celery
import ssl

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")

app = Celery("backend")

REDIS_HOST = os.getenv("REDIS_HOST", "driverapp.redis.cache.windows.net")
REDIS_PORT = os.getenv("REDIS_PORT", "6380")
REDIS_PASSWORD = os.getenv("REDIS_PASSWORD")
REDIS_USERNAME = "default"

CELERY_BROKER_URL = f"rediss://{REDIS_USERNAME}:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"
CELERY_RESULT_BACKEND = CELERY_BROKER_URL

# Correct SSL options: use ssl.CERT_REQUIRED constant
REDIS_SSL_OPTIONS = {
    "ssl_cert_reqs": ssl.CERT_REQUIRED,  # ✅ must be ssl.CERT_REQUIRED / CERT_OPTIONAL / CERT_NONE
    # Optional if your CA certs are custom
    # "ssl_ca_certs": "/etc/ssl/certs/ca-certificates.crt",
}

app.conf.update(
    broker_url=CELERY_BROKER_URL,
    result_backend=CELERY_RESULT_BACKEND,
    broker_use_ssl=REDIS_SSL_OPTIONS,
    result_backend_use_ssl=REDIS_SSL_OPTIONS,
    task_track_started=True,
    task_time_limit=30*60,
    timezone="America/Toronto",
    enable_utc=False,
)

app.autodiscover_tasks()
