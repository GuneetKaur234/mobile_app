from django.core.files.storage import storages
from backend.azure_storage import AzureMediaStorage

# Replace the default file storage with Azure Media Storage
storages._storages['default'] = AzureMediaStorage()

