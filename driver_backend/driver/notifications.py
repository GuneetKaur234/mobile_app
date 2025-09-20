# notifications.py
from firebase_admin import messaging
from .firebase import firebase_admin

def send_push_notification(driver, message):
    if not getattr(driver, 'device_token', None):
        return

    message_obj = messaging.Message(
        notification=messaging.Notification(
            title="Load Update",
            body=message,
        ),
        token=driver.device_token,
    )

    try:
        response = messaging.send(message_obj)
        print("Successfully sent message:", response)
    except Exception as e:
        print("Error sending message:", e)
