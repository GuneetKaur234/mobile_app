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

# -----------------------------
# Company & Customer Admin
# -----------------------------
@admin.register(Company)
class CompanyAdmin(ImportExportModelAdmin):
    resource_class = CompanyResource
    list_display = ('name', 'email', 'scac_code')
    search_fields = ('name', 'email', 'scac_code')

    def save_model(self, request, obj, form, change):
        # Ensure SCAC & Company uniqueness match
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
        if obj.image:
            return format_html('<img src="{}" width="50" height="50" />', obj.image.url)
        return "-"
    preview.short_description = "Preview"

    def download_link(self, obj):
        if obj.image:
            filename = obj.image.name.split('/')[-1]
            return format_html('<a href="{}" target="_blank">{}</a>', obj.image.url, filename)
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
            'reefer_temp_shipper', 'reefer_temp_bol', 'reefer_temp_unit', 'equipment_type',  # <-- new fields
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
    # PDF Generation (Corrected)
    # -----------------------------
    def download_load_pdf(self, request, load_id):
        load = self.get_object(request, load_id)
        buffer = io.BytesIO()
        p = canvas.Canvas(buffer, pagesize=A4)
        width, height = A4
        y_start = height - 50

        # Title
        p.setFont("Helvetica-Bold", 18)
        p.drawString(50, y_start, f"Load Report: {str(load.load_number)}")
        p.line(50, y_start-5, width-50, y_start-5)
        y_start -= 40

        styles = getSampleStyleSheet()
        normal_style = styles['Normal']
        normal_style.fontSize = 10
        normal_style.leading = 12

        # Helper to safely convert any value to string
        def safe_str(value):
            if callable(value):
                try:
                    return str(value())
                except:
                    return "-"
            return str(value) if value else "-"

        data = [
            ['Field', 'Value'],
            ['Driver', Paragraph(f"{safe_str(getattr(load.driver, 'name', '-'))} "
                                f"({safe_str(getattr(load.driver, 'company', '-'))})", normal_style)],
            ['Truck Number', Paragraph(safe_str(load.truck_number), normal_style)],
            ['Trailer Number', Paragraph(safe_str(load.trailer_number), normal_style)],
            ['Customer', Paragraph(safe_str(load.customer_name), normal_style)],
            ['Load Number', Paragraph(safe_str(load.load_number), normal_style)],
            ['Order Number', Paragraph(safe_str(load.order_number), normal_style)],
            ['Pickup Number', Paragraph(safe_str(load.pickup_number), normal_style)],
            ['Pickup Datetime', Paragraph(safe_str(load.pickup_datetime), normal_style)],
            ['Delivery Number', Paragraph(safe_str(load.delivery_number), normal_style)],
            ['Delivery Datetime', Paragraph(safe_str(load.delivery_datetime), normal_style)],
            ['Seal Number', Paragraph(safe_str(load.seal_number), normal_style)],
            ['Pickup Notes', Paragraph(safe_str(load.pickup_notes), normal_style)],
            ['Delivery Notes', Paragraph(safe_str(load.delivery_notes), normal_style)],
            ['Reefer Pre Cool', Paragraph(safe_str(load.reefer_pre_cool), normal_style)],
            ['Equipment Type', Paragraph(safe_str(load.equipment_type), normal_style)],  # ✅ added
            ['Pickup Emails', Paragraph(safe_str(load.pickup_emails_html), normal_style)],
            ['Delivery Emails', Paragraph(safe_str(load.delivery_emails_html), normal_style)],
            ['Status', Paragraph(safe_str(load.status), normal_style)],
            ['Reefer Temp (Shipper)', Paragraph(safe_str(load.reefer_temp_shipper), normal_style)],
            ['Reefer Temp (BOL)', Paragraph(safe_str(load.reefer_temp_bol), normal_style)],
            ['Reefer Temp Unit', Paragraph(safe_str(load.reefer_temp_unit), normal_style)],
        ]


        col_widths = [5*cm, width - 7*cm]

        table = Table(data, colWidths=col_widths, hAlign='LEFT')
        table.setStyle(TableStyle([
            ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#4F81BD')),
            ('TEXTCOLOR', (0,0), (-1,0), colors.white),
            ('ALIGN', (0,0), (-1,-1), 'LEFT'),
            ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
            ('FONTSIZE', (0,0), (-1,-1), 10),
            ('BOTTOMPADDING', (0,0), (-1,0), 6),
            ('BACKGROUND', (0,1), (-1,-1), colors.whitesmoke),
            ('GRID', (0,0), (-1,-1), 0.5, colors.grey)
        ]))

        table.wrapOn(p, width-100, height)
        table.drawOn(p, 50, y_start - table._height)

        p.showPage()

        # Images
        photos = DriverLoadPhoto.objects.filter(load=load)
        MARGIN = 50
        HEADER_HEIGHT = 30
        for photo in photos:
            p.setFont("Helvetica-Bold", 14)
            header_y = A4[1] - MARGIN - 15
            p.drawString(MARGIN, header_y, safe_str(photo.photo_type))
            
            if photo.image:
                try:
                    img = Image(photo.image.path)
                    img_width, img_height = img.size

                    # Usable space (exclude margins + header text)
                    max_width = A4[0] - 2 * MARGIN
                    max_height = A4[1] - 2 * MARGIN - HEADER_HEIGHT
        
                    # Scale image while preserving aspect ratio
                    scale = min(max_width / img_width, max_height / img_height)
                    draw_width = img_width * scale
                    draw_height = img_height * scale
        
                    x = MARGIN + (max_width - draw_width) / 2
                    y = MARGIN + (max_height - draw_height) / 2
        
                    p.drawInlineImage(img, x, y, draw_width, draw_height)
                except:
                    p.drawString(MARGIN, MARGIN, f"Cannot load image {safe_str(photo.image.name)}")
            p.showPage()

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

