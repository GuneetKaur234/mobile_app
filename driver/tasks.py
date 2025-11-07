# driver/tasks.py
from celery import shared_task
from django.core.mail import EmailMessage
from django.conf import settings
from django.utils import timezone
from .models import DriverLoadInfo
from .utils import generate_load_pdf

@shared_task(bind=True, max_retries=3)
def send_pickup_or_delivery_email(self, load_id, email_type):
    """
    Sends pickup or delivery confirmation emails for a given load.
    Uses generate_load_pdf() to attach load details + photos.
    """
    try:
        load = DriverLoadInfo.objects.get(id=load_id)
        include_pod = (email_type == "delivery")

        # Generate PDF
        pdf_file = generate_load_pdf(load, include_pod=include_pod)

        # Determine recipient (you can later replace this with a real logic)
        to_emails = []
        # ✅ Option 1: if you’ll store customer_email in model later
        if hasattr(load, "customer_email") and load.customer_email:
            to_emails.append(load.customer_email)
        # ✅ Option 2: temporary fallback (for testing)
        else:
            to_emails.append(settings.DEFAULT_TEST_EMAIL or "your_test_email@example.com")

        subject = f"{email_type.title()} Confirmation for Load #{load.load_number}"
        body = (
            f"Hi {load.customer_name},\n\n"
            f"Please find attached the {email_type} confirmation PDF for Load #{load.load_number}."
        )

        # Send email
        email = EmailMessage(
            subject=subject,
            body=body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=to_emails,
        )
        email.attach(pdf_file.name, pdf_file.read(), "application/pdf")
        email.send(fail_silently=False)

        # Update history
        entry = {
            "email": ", ".join(to_emails),
            "timestamp": timezone.now().strftime("%Y-%m-%d %H:%M:%S"),
            "status": "Sent"
        }
        if email_type == "pickup":
            load.pickup_email_history.append(entry)
        else:
            load.delivery_email_history.append(entry)
        load.save(update_fields=["pickup_email_history", "delivery_email_history"])

        print(f"[DEBUG] {email_type.title()} email sent successfully for Load {load.id}")
        return f"{email_type.title()} email sent successfully for Load {load.id}"

    except Exception as e:
        print(f"[ERROR] send_pickup_or_delivery_email: {e}")
        self.retry(exc=e, countdown=10)
        return f"Error sending {email_type} email for load {load_id}: {e}"
