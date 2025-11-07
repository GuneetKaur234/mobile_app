import os
from celery import Celery
import ssl

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

app = Celery('backend')

REDIS_HOST = os.getenv('REDIS_HOST', 'driverapp.redis.cache.windows.net')
REDIS_PORT = os.getenv('REDIS_PORT', '6380')
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')

redis_ssl_options = {
    "ssl_cert_reqs": ssl.CERT_REQUIRED,  # More secure than CERT_NONE
    # Optionally, "ssl_ca_certs": "/etc/ssl/certs/ca-certificates.crt"
}

# Broker and backend URLs
app.conf.broker_url = f"rediss://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"
app.conf.result_backend = f"rediss://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"

# SSL options
app.conf.broker_use_ssl = redis_ssl_options
app.conf.redis_backend_use_ssl = redis_ssl_options  # <-- corrected

# Serialization & result settings
app.conf.task_serializer = 'json'
app.conf.result_serializer = 'json'
app.conf.accept_content = ['json']
app.conf.result_expires = 3600

# Auto-discover tasks
app.autodiscover_tasks()
