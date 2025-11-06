from .celery import app as celery_app

__all__ = ('celery_app',)

# ⚠️ Import Django only after Celery setup
from django.core.files.storage import storages
from backend.azure_storage import AzureMediaStorage

# Replace the default file storage with Azure Media Storage
storages._storages['default'] = AzureMediaStorage()
