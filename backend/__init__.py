#from .celery import app as celery_app

#__all__ = ['celery_app']

from django.core.files.storage import storages
from backend.azure_storage import AzureMediaStorage

storages._storages['default'] = AzureMediaStorage()
