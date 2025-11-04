from storages.backends.azure_storage import AzureStorage
import os

class AzureMediaStorage(AzureStorage):
    account_name = os.getenv("AZURE_ACCOUNT_NAME")
    account_key = os.getenv("AZURE_ACCOUNT_KEY")
    azure_container = os.getenv("AZURE_CONTAINER", "media")
    expiration_secs = None


# ----------------------------
# Helper function to fetch blob bytes (for PDFs or direct downloads)
# ----------------------------
def get_blob_bytes(blob_name: str) -> BytesIO:
    account_name = os.getenv("AZURE_ACCOUNT_NAME")
    account_key = os.getenv("AZURE_ACCOUNT_KEY")
    container_name = os.getenv("AZURE_CONTAINER", "media")

    connection_string = f"DefaultEndpointsProtocol=https;AccountName={account_name};AccountKey={account_key};EndpointSuffix=core.windows.net"
    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)

    stream = BytesIO()
    download = blob_client.download_blob()
    download.readinto(stream)
    stream.seek(0)
    return stream
