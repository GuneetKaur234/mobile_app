from django.contrib import admin
from import_export.admin import ImportExportModelAdmin
from django.utils.html import format_html
from .models import (
    DriverProfile, DriverLoadInfo, DriverLoadPhoto, Company,
    Customer, DriverLocation
)
from .resources import (
    CompanyResource, CustomerResource,
    DriverLoadInfoResource
)
import io
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.platypus import Table, TableStyle, Image, Paragraph
from reportlab.lib import colors
from django.urls import path, reverse
from django.http import HttpResponse
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib.units import cm

import pytz

from PIL import Image as PILImage
import os
import tempfile
from reportlab.platypus import Image as RLImage
from django.core.files.storage import default_storage

# -----------------------------
# Company & Customer Admin
# -----------------------------
@admin.register(Company)
class CompanyAdmin(ImportExportModelAdmin):
    resource_class = CompanyResource
    list_display = ('name', 'email', 'scac_code')
    search_fields = ('name', 'email', 'scac_code')

    def save_model(self, request, obj, form, change):
        if Company.objects.filter(scac_code=obj.scac_code).exclude(pk=obj.pk).exists():
            from django.core.exceptions import ValidationError
            raise ValidationError(f"SCAC code '{obj.scac_code}' already exists for another company.")
        super().save_model(request, obj, form, change)


@admin.register(Customer)
class CustomerAdmin(ImportExportModelAdmin):
    resource_class = CustomerResource
    list_display = ('name', 'company', 'email')
    search_fields = ('name', 'company__name', 'email')
    list_filter = ('company',)


# -----------------------------
# DriverProfile Admin
# -----------------------------
@admin.register(DriverProfile)
class DriverProfileAdmin(ImportExportModelAdmin):
    list_display = ('name', 'phone', 'company', 'scac_code', 'license_number', 'language')
    search_fields = ('name', 'phone', 'company__name', 'license_number', 'company__scac_code')
    list_filter = ('language', 'company')

    def scac_code(self, obj):
        return obj.company.scac_code if obj.company else "-"
    scac_code.short_description = "SCAC Code"


# -----------------------------
# Inline for DriverLoadPhoto
# -----------------------------
class DriverLoadPhotoInline(admin.TabularInline):
    model = DriverLoadPhoto
    extra = 0
    readonly_fields = ('photo_type', 'preview', 'download_link')
    fields = ('photo_type', 'preview', 'download_link')
    can_delete = False
    show_change_link = False

    def preview(self, obj):
        img_url = obj.resized_image.url if obj.resized_image else obj.image.url if obj.image else None
        if img_url:
            return format_html('<img src="{}" width="50" height="50" />', img_url)
        return "-"
    preview.short_description = "Preview"

    def download_link(self, obj):
        file_url = obj.resized_image.url if obj.resized_image else obj.image.url if obj.image else None
        if file_url:
            filename = os.path.basename(file_url)
            return format_html('<a href="{}" target="_blank">{}</a>', file_url, filename)
        return "-"
    download_link.short_description = "Download"


# -----------------------------
# DriverLoadInfo Admin
# -----------------------------
@admin.register(DriverLoadInfo)
class DriverLoadInfoAdmin(ImportExportModelAdmin):
    resource_class = DriverLoadInfoResource
    inlines = [DriverLoadPhotoInline]

    readonly_fields = [
        'driver', 'driver_company', 'truck_number', 'trailer_number',
        'customer_name', 'load_number', 'order_number', 'pickup_number',
        'pickup_datetime', 'delivery_number', 'delivery_datetime', 
        'seal_number', 'pickup_notes', 'delivery_notes', 'reefer_pre_cool',
        'pickup_emails_html', 'delivery_emails_html', 'status',
        'download_pdf_button', 'pulp_reason', 'equipment_type',
    ]

    fieldsets = (
        ('Driver Info', {'fields': ('driver', 'driver_company')}),
        ('Load Details', {'fields': (
            'truck_number', 'trailer_number', 'customer_name',
            'load_number', 'order_number', 'pickup_number',
            'pickup_datetime', 'delivery_number', 'delivery_datetime',
            'seal_number', 'pickup_notes', 'delivery_notes', 'reefer_pre_cool',
            'reefer_temp_shipper', 'reefer_temp_bol', 'reefer_temp_unit', 'equipment_type',
            'pickup_emails_html', 'delivery_emails_html', 'status',
            'download_pdf_button', 'pulp_reason',
        )}),
    )

    list_display = (
        'load_number', 'order_number', 'driver', 'driver_company',
        'truck_number', 'trailer_number', 'customer_name', 'pickup_number',
        'delivery_number', 'seal_number', 'pickup_datetime', 'delivery_datetime',
        'status'
    )

    search_fields = (
        'load_number', 'order_number', 'driver__name', 'driver__company',
        'truck_number', 'trailer_number', 'customer_name'
    )

    list_filter = ('status', 'driver__company', 'customer_name')

    def driver_company(self, obj):
        return obj.driver.company if obj.driver else "-"
    driver_company.short_description = "Driver's Company"

    def download_pdf_button(self, obj):
        if obj and obj.id:
            url = reverse('admin:driverloadinfo_download', args=[obj.id])
            return format_html('<a class="button" href="{}" target="_blank">Download Load PDF</a>', url)
        return "-"
    download_pdf_button.short_description = "Download PDF"

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('<int:load_id>/download/', self.admin_site.admin_view(self.download_load_pdf), name='driverloadinfo_download'),
        ]
        return custom_urls + urls

    # -----------------------------
    # Helper to load image directly from Azure via default_storage
    # -----------------------------
    def get_pil_image_from_storage(self, photo_file):
        try:
            if not photo_file:
                return None, None

            # Read file bytes from Azure storage
            file_bytes = default_storage.open(photo_file.name, 'rb')
            with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
                tmp.write(file_bytes.read())
                tmp.flush()
                pil_img = PILImage.open(tmp.name)
                pil_img.load()
                return pil_img, tmp.name
        except Exception as e:
            print(f"⚠️ Error loading image {photo_file.name} from storage: {e}")
            return None, None

    # -----------------------------
    # PDF Generation
    # -----------------------------
    def download_load_pdf(self, request, load_id):
        load = self.get_object(request, load_id)
        buffer = io.BytesIO()
        p = canvas.Canvas(buffer, pagesize=A4)
        width, height = A4
        y_start = height - 50
        page_num = 1  # ✅ page counter
    
        def safe_str(value):
            if callable(value):
                try:
                    return str(value())
                except:
                    return "-"
            return str(value) if value else "-"
    
        # ✅ footer helper (OUTSIDE loops)
        def draw_page_footer(canvas_obj, page_num):
            canvas_obj.setFont("Helvetica", 8)
            canvas_obj.setStrokeColor(colors.lightgrey)
            canvas_obj.line(50, 35, width - 50, 35)
            canvas_obj.drawString(50, 20, "Created by FOH")
            canvas_obj.drawRightString(width - 50, 20, f"Page {page_num}")
    
        # -----------------------------
        # Header
        # -----------------------------
        p.setFont("Helvetica-Bold", 11)
        p.drawString(50, height - 30, safe_str(load.driver.company))
    
        p.setFont("Helvetica", 9)
        p.drawRightString(
            width - 50,
            height - 30,
            f"Generated: {timezone.now().strftime('%Y-%m-%d %H:%M')}"
        )
    
        # -----------------------------
        # Title
        # -----------------------------
        p.setFont("Helvetica-Bold", 18)
        p.drawCentredString(
            width / 2,
            y_start,
            f"Load Report (Pickup Number: {safe_str(load.pickup_number)})"
        )
    
        p.setStrokeColor(colors.grey)
        p.line(50, y_start - 5, width - 50, y_start - 5)
        y_start -= 40
    
        # -----------------------------
        # Styles
        # -----------------------------
        styles = getSampleStyleSheet()
        normal_style = styles['Normal']
        normal_style.fontSize = 10
        normal_style.leading = 12
    
        est = pytz.timezone('America/New_York')
        pickup_dt = load.pickup_datetime.astimezone(est) if load.pickup_datetime else "-"
        delivery_dt = load.delivery_datetime.astimezone(est) if load.delivery_datetime else "-"
    
        # -----------------------------
        # Table Data
        # -----------------------------
        data = [
            ['Field', 'Value'],
            ['Driver', Paragraph(f"{safe_str(getattr(load.driver, 'name', '-'))} ({safe_str(getattr(load.driver, 'company', '-'))})", normal_style)],
            ['Truck Number', Paragraph(safe_str(load.truck_number), normal_style)],
            ['Trailer Number', Paragraph(safe_str(load.trailer_number), normal_style)],
            ['Customer', Paragraph(safe_str(load.customer_name), normal_style)],
            ['Load Number', Paragraph(safe_str(load.load_number), normal_style)],
            ['Order Number', Paragraph(safe_str(load.order_number), normal_style)],
            ['Pickup Number', Paragraph(safe_str(load.pickup_number), normal_style)],
            ['Pickup Datetime', Paragraph(safe_str(pickup_dt), normal_style)],
            ['Delivery Number', Paragraph(safe_str(load.delivery_number), normal_style)],
            ['Delivery Datetime', Paragraph(safe_str(delivery_dt), normal_style)],
            ['Seal Number', Paragraph(safe_str(load.seal_number), normal_style)],
            ['Pickup Notes', Paragraph(safe_str(load.pickup_notes), normal_style)],
            ['Delivery Notes', Paragraph(safe_str(load.delivery_notes), normal_style)],
            ['Equipment Type', Paragraph(safe_str(load.equipment_type), normal_style)],
            ['Status', Paragraph(safe_str(load.status), normal_style)],
        ]
    
        if getattr(load, 'equipment_type', '').lower() == 'reefer':
            data.extend([
                ['Reefer Pre Cool', Paragraph(safe_str(load.reefer_pre_cool), normal_style)],
                ['Reefer Temp (Shipper)', Paragraph(safe_str(load.reefer_temp_shipper), normal_style)],
                ['Reefer Temp (BOL)', Paragraph(safe_str(load.reefer_temp_bol), normal_style)],
                ['Reefer Temp Unit', Paragraph(safe_str(load.reefer_temp_unit), normal_style)],
            ])
    
        # -----------------------------
        # Table
        # -----------------------------
        usable_width = width - 100
        col_widths = [6 * cm, usable_width - 6 * cm]
    
        table = Table(data, colWidths=col_widths, hAlign='LEFT')
        table.setStyle(TableStyle([
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.whitesmoke, colors.lightgrey]),
            ('LEFTPADDING', (0, 0), (-1, -1), 6),
            ('RIGHTPADDING', (0, 0), (-1, -1), 6),
            ('TOPPADDING', (0, 0), (-1, -1), 4),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
            ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#4F81BD')),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ]))
    
        table.wrapOn(p, usable_width, height)
        table.drawOn(p, 50, y_start - table._height)
    
        # ✅ footer for first page
        draw_page_footer(p, page_num)
        page_num += 1
        p.showPage()
    
        # -----------------------------
        # Images
        # -----------------------------
        photos = DriverLoadPhoto.objects.filter(load=load)
    
        for photo in photos:
            top_margin = height - 50
    
            p.setFont("Helvetica-Bold", 14)
    
            raw_type = safe_str(photo.photo_type).lower()
            PHOTO_LABELS = {"pod": "POD", "bol": "BOL"}
            title_text = PHOTO_LABELS.get(raw_type, raw_type.replace("_", " ").title())
    
            # ✅ title then line (correct order)
            p.drawString(50, top_margin, title_text)
            p.setStrokeColor(colors.grey)
            p.line(50, top_margin - 5, width - 50, top_margin - 5)
    
            photo_file = photo.resized_image if photo.resized_image else photo.image
    
            if photo_file:
                try:
                    pil_img, tmp_path = self.get_pil_image_from_storage(photo_file)
    
                    if pil_img:
                        pil_img = pil_img.convert('RGB')
                        max_width = width - 100
                        max_height = height - 150
                        pil_img.thumbnail((max_width, max_height), PILImage.LANCZOS)
                        pil_img.save(tmp_path)
    
                        rl_img = RLImage(tmp_path)
                        rl_img.wrapOn(p, width, height)
    
                        image_y = top_margin - 30 - rl_img.drawHeight
    
                        if image_y < 50:
                            scale_factor = (height - 200) / rl_img.drawHeight
                            rl_img.drawWidth *= scale_factor
                            rl_img.drawHeight *= scale_factor
                            image_y = top_margin - 30 - rl_img.drawHeight
    
                        # border
                        p.setStrokeColor(colors.lightgrey)
                        p.rect(
                            45,
                            image_y - 5,
                            rl_img.drawWidth + 10,
                            rl_img.drawHeight + 10,
                            stroke=1,
                            fill=0
                        )
    
                        rl_img.drawOn(p, 50, image_y)
                        os.unlink(tmp_path)
    
                    else:
                        p.drawString(50, height - 100, f"Cannot load image {safe_str(photo_file.name)}")
    
                except Exception as e:
                    p.drawString(50, height - 100, f"Cannot load image {safe_str(photo_file.name)}: {e}")
    
            # ✅ footer for each image page
            draw_page_footer(p, page_num)
            page_num += 1
            p.showPage()
    
        # -----------------------------
        # Finalize
        # -----------------------------
        p.save()
        buffer.seek(0)
        return HttpResponse(buffer, content_type='application/pdf')

    # -----------------------------
    # Permissions
    # -----------------------------
    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


# -----------------------------
# DriverLocation Admin
# -----------------------------
@admin.register(DriverLocation)
class DriverLocationAdmin(admin.ModelAdmin):
    list_display = (
        'license_number',
        'company_name',
        'driver_name',
        'latitude',
        'longitude',
        'address',
        'timestamp',
    )
    search_fields = ('license_number', 'company_name', 'driver__name', 'address')
    list_filter = ('company_name',)
    readonly_fields = ('timestamp',)

    def driver_name(self, obj):
        return obj.driver.name if obj.driver else "-"
    driver_name.short_description = "Driver Name"





