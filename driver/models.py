from django.db import models
import os
import uuid

# -------------------------------
# Helper functions for file uploads
# -------------------------------
def load_file_name(instance, filename, file_type):
    """
    Generates file name like:
    LOAD123_POD_1.jpg, LOAD123_POD_2.jpg, etc.
    """
    ext = filename.split('.')[-1]
    # Get load_number
    load_number = getattr(instance, 'load_number', getattr(instance, 'load', None) and getattr(instance.load, 'load_number', 'UNKNOWN'))

    # Count existing files for this load and type
    existing_count = 0
    if hasattr(instance, 'load') and instance.load:
        existing_count = instance.load.photos.filter(photo_type=file_type).count()
    elif hasattr(instance, 'photo_type'):
        # fallback: try instance.photo_type
        existing_count = DriverLoadPhoto.objects.filter(load=getattr(instance, 'load', None), photo_type=file_type).count()

    sequence = existing_count + 1  # start from 1
    new_filename = f"{load_number}_{file_type}_{sequence}.{ext}"
    return os.path.join('driver_uploads', file_type, new_filename)

def bol_upload_to(instance, filename):
    return load_file_name(instance, filename, 'BOL')

def pod_upload_to(instance, filename):
    return load_file_name(instance, filename, 'POD')

def driver_photo_upload_to(instance, filename):
    """
    Save each photo uniquely so multiple uploads coexist.
    """
    file_type = getattr(instance, 'photo_type', 'unknown')
    return load_file_name(instance, filename, file_type)

# -------------------------------
# Driver Info
# -------------------------------
class DriverProfile(models.Model):
    name = models.CharField(max_length=100, null=False, blank=False, db_index=True)
    phone = models.CharField(max_length=20, unique=True, null=False, blank=False)
    company = models.CharField(max_length=100, null=False, blank=False, db_index=True)
    scac_code = models.CharField(max_length=10, null=True, blank=True) 
    license_number = models.CharField(max_length=50, unique=True, null=False, blank=False, default='UNKNOWN')
    language = models.CharField(
        max_length=2,
        choices=[('en', 'English'), ('fr', 'French')],
        default='en',
        null=False,
        blank=False
    )
    device_token = models.CharField(max_length=255, null=True, blank=True)  # FCM token


    def __str__(self):
        return f"{self.name} ({self.phone})"

# -------------------------------
# Driver Load Info
# -------------------------------
class DriverLoadInfo(models.Model):
    LOAD_STATUS_CHOICES = [
        ('pending_pickup', 'Pending Pickup'),
        ('in_transit', 'In Transit'),
        ('pickup_completed', 'Pickup Completed'),
        ('delivered', 'Delivered'),
    ]

    ALLOWED_STATUS_TRANSITIONS = {
        'pending_pickup': ['in_transit'],
        'in_transit': ['pickup_completed'],
        'pickup_completed': ['delivered'],
        'delivered': [],  # final state
    }

    EQUIPMENT_TYPE_CHOICES = [
        ('dry_van', 'Dry Van'),
        ('reefer', 'Reefer'),
        ('flatbed', 'Flatbed'),
        ('stepdeck', 'Stepdeck'),
        ('heated_van', 'Heated Van'),
        ('straight_truck', 'Straight Truck'),
    ]

    driver = models.ForeignKey(
        DriverProfile,
        on_delete=models.CASCADE,
        related_name="loads",
        db_index=True
    )
    truck_number = models.CharField(max_length=50)
    trailer_number = models.CharField(max_length=50)
    customer_name = models.CharField(max_length=100, db_index=True)
    load_number = models.CharField(max_length=100)
    order_number = models.CharField(max_length=100)
    pickup_number = models.CharField(max_length=100)
    reefer_pre_cool = models.CharField(max_length=50)
    bol = models.FileField(upload_to=bol_upload_to, null=True, blank=True)
    pod = models.FileField(upload_to=pod_upload_to, null=True, blank=True)
    seal_number = models.CharField(max_length=50, null=True, blank=True)
    pickup_notes = models.TextField(blank=True, null=True)
    delivery_notes = models.TextField(blank=True, null=True)
    delivery_number = models.CharField(max_length=100, null=True, blank=True)
    pickup_datetime = models.DateTimeField(null=True, blank=True)
    delivery_datetime = models.DateTimeField(null=True, blank=True)
    pulp_reason = models.TextField(blank=True, null=True)
    reefer_temp_shipper = models.CharField(
        max_length=10, 
        null=True, 
        blank=True, 
        help_text="Temperature set by shipper"
    )
    reefer_temp_bol = models.CharField(
        max_length=10, 
        null=True, 
        blank=True, 
        help_text="Temperature mentioned on BOL"
    )
    reefer_temp_unit = models.CharField(
        max_length=2,
        choices=[('C', 'Celsius'), ('F', 'Fahrenheit')],
        default='C',
        null=False,
        blank=False,
        help_text="Temperature unit"
    )

    # ✅ New dropdown field
    equipment_type = models.CharField(
        max_length=20,
        choices=EQUIPMENT_TYPE_CHOICES,
        default='dry_van',
        help_text="Type of equipment used"
    )

    # -------------------
    # Existing new fields
    # -------------------
    pickup_email_history = models.JSONField(default=list, blank=True)
    delivery_email_history = models.JSONField(default=list, blank=True)
    status = models.CharField(max_length=20, choices=LOAD_STATUS_CHOICES, default='pending_pickup')
    last_notification_sent = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.pickup_number} ({self.customer_name})"

    # Helper methods to display email history as HTML for admin
    def pickup_emails_html(self):
        if not self.pickup_email_history:
            return "-"
        html = "<ul>"
        for entry in self.pickup_email_history:
            html += f"<li>{entry.get('email')} - {entry.get('timestamp')} ({entry.get('status')})</li>"
        html += "</ul>"
        return html
    pickup_emails_html.allow_tags = True
    pickup_emails_html.short_description = "Pickup Emails"

    def delivery_emails_html(self):
        if not self.delivery_email_history:
            return "-"
        html = "<ul>"
        for entry in self.delivery_email_history:
            html += f"<li>{entry.get('email')} - {entry.get('timestamp')} ({entry.get('status')})</li>"
        html += "</ul>"
        return html
    delivery_emails_html.allow_tags = True
    delivery_emails_html.short_description = "Delivery Emails"

# -------------------------------
# Driver Load Photos
# -------------------------------
class DriverLoadPhoto(models.Model):
    load = models.ForeignKey(
        DriverLoadInfo,
        on_delete=models.CASCADE,
        related_name="photos"
    )
    photo_type = models.CharField(
        max_length=50,
        choices=[
            ('trailer', 'Trailer'),
            ('reefer', 'Reefer'),
            ('pulp', 'Pulp'),
            ('load_secure', 'Load Secure'),
            ('sealed_trailer', 'Sealed Trailer'),
            ('POD', 'POD'),
            ('bol', 'BOL'),
        ]
    )
    image = models.ImageField(upload_to=driver_photo_upload_to)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.load.load_number} - {self.photo_type}"

# -------------------------------
# Company & Customer
# -------------------------------
class Company(models.Model):
    name = models.CharField(max_length=100, unique=True, db_index=True)
    email = models.EmailField()
    scac_code = models.CharField(max_length=10, unique=False, null=True, blank=True)
    def __str__(self):
        return f"{self.name} ({self.scac_code})"

class Customer(models.Model):
    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name="customers")
    name = models.CharField(max_length=100, db_index=True)
    email = models.EmailField()

    def __str__(self):
        return f"{self.name} ({self.company.name})"


# -------------------------------
# Driver Location
# -------------------------------
class DriverLocation(models.Model):
    driver = models.ForeignKey(DriverProfile, on_delete=models.CASCADE)
    license_number = models.CharField(max_length=50)  # Unique driver license
    company_name = models.CharField(max_length=100)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    address = models.CharField(max_length=255, blank=True, null=True)
    timestamp = models.DateTimeField(auto_now=True)  # updates on every save

    class Meta:
        unique_together = ('license_number', 'company_name')  # unique driver

    def __str__(self):
        return f"{self.license_number} ({self.company_name}): {self.latitude}, {self.longitude} ({self.address})"
