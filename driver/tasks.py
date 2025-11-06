# driver/tasks.py
from celery import shared_task
from django.core.mail import EmailMessage
from django.conf import settings
from .models import Load, DriverLoadInfo
from .utils import generate_load_pdf


@shared_task(bind=True, max_retries=3)
def send_pickup_or_delivery_email(self, load_id, email_type):
    """
    email_type: 'pickup' or 'delivery'
    Uses your generate_load_pdf() utility to attach photos/PODs to the email.
    """
    try:
        load = Load.objects.get(id=load_id)

        # Determine whether to include PODs based on email type
        include_pod = (email_type == "delivery")

        # Generate the PDF
        pdf_file = generate_load_pdf(load, include_pod=include_pod)

        # Build email
        subject = f"{email_type.title()} confirmation for Load #{load.load_number}"
        body = (
            f"Hi {load.customer.name if hasattr(load, 'customer') else ''},\n\n"
            f"Please find attached the {email_type} confirmation PDF for Load #{load.load_number}."
        )

        to_emails = []
        if hasattr(load, 'customer') and load.customer.email:
            to_emails.append(load.customer.email)

        if not to_emails:
            print(f"[DEBUG] No recipient email found for load {load.id}")
            return f"No recipient email for load {load.id}"

        email = EmailMessage(
            subject=subject,
            body=body,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=to_emails,
        )

        email.attach(pdf_file.name, pdf_file.read(), "application/pdf")
        email.send(fail_silently=False)

        print(f"[DEBUG] {email_type.title()} email sent successfully for load {load.id}")
        return f"{email_type.title()} email sent successfully for load {load.id}"

    except Exception as e:
        print(f"[DEBUG] Error in send_pickup_or_delivery_email: {e}")
        self.retry(exc=e, countdown=10)
        return f"Error sending {email_type} email for load {load_id}: {e}"
