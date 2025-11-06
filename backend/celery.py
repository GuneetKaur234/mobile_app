import os
from celery import Celery

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

app = Celery('backend')

# Fetch Redis credentials from Azure App Settings
REDIS_HOST = os.getenv('REDIS_HOST')
REDIS_PORT = os.getenv('REDIS_PORT', '6380')
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD')

# Use SSL (Azure requires this by default)
app.conf.broker_url = f"rediss://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"
app.conf.result_backend = f"rediss://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}/0"

# Serialization formats
app.conf.task_serializer = 'json'
app.conf.result_serializer = 'json'
app.conf.accept_content = ['json']

# Optional: Task result expiration (in seconds)
app.conf.result_expires = 3600

# Auto-discover tasks from all Django apps
app.autodiscover_tasks()
