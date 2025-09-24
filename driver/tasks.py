from celery import shared_task
from django.utils import timezone
from .models import DriverLoadInfo
from .notifications import send_push_notification

@shared_task
def notify_drivers_in_transit():
    """
    Send push notifications to all drivers whose loads are 'in_transit'.
    Runs twice daily (10 AM and 6 PM) via Celery Beat.
    """
    now = timezone.localtime()

    # Only run at 10 AM or 6 PM
    if now.hour not in [10, 18]:
        return

    # Fetch all in-transit loads
    loads = DriverLoadInfo.objects.filter(status='in_transit')
    for load in loads:
        # Skip if already sent in this hour
        last_sent = load.last_notification_sent
        if last_sent and last_sent.date() == now.date() and last_sent.hour == now.hour:
            continue

        # Send notification
        send_push_notification(load.driver, f"Reminder: Load {load.load_number} is in transit.")

        # Update last_notification_sent
        load.last_notification_sent = now
        load.save()
