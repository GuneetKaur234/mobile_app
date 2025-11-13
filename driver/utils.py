from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from PIL import Image
from django.core.files.base import ContentFile
import re

def generate_load_pdf(load, include_pod=True, max_image_width=1200, max_image_height=1600, jpeg_quality=70):
    """
    Generate an optimized PDF containing all photos (and optionally PODs) of a DriverLoadInfo.
    Images are resized and compressed to reduce PDF size.
    """
    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=A4)
    page_width, page_height = A4

    photos = load.photos.all().order_by('photo_type')
    if not include_pod:
        photos = photos.exclude(photo_type='POD')

    if not photos.exists():
        print(f"[DEBUG] No photos found for load {load.load_number} (include_pod={include_pod})")

    for idx, photo in enumerate(photos, start=1):
        try:
            print(f"[DEBUG] Processing photo {idx}: {photo.photo_type}")

            # Open image safely from any storage backend
            photo.image.open()
            img = Image.open(photo.image)
            img = img.convert("RGB")  # Ensure PDF compatibility

            # Resize if too large
            img.thumbnail((max_image_width, max_image_height), Image.LANCZOS)

            # Save compressed version to BytesIO
            img_buffer = BytesIO()
            img.save(img_buffer, format="JPEG", quality=jpeg_quality)
            img_buffer.seek(0)

            img_width, img_height = img.size
            scale = min(page_width / img_width, page_height / img_height) * 0.95
            img_width_scaled = img_width * scale
            img_height_scaled = img_height * scale
            x = (page_width - img_width_scaled) / 2
            y = (page_height - img_height_scaled) / 2

            # Draw image onto PDF
            c.drawInlineImage(img_buffer, x, y, img_width_scaled, img_height_scaled)
            c.showPage()

            img.close()
            photo.image.close()
        except Exception as e:
            print(f"[DEBUG] Error adding photo {getattr(photo.image, 'name', 'unknown')}: {e}")

    c.save()
    buffer.seek(0)

    safe_load_number = re.sub(r'[^\w\-]', '_', load.load_number or "load")
    pdf_file = ContentFile(buffer.read(), name=f"{safe_load_number}_all_photos.pdf")
    print(f"[DEBUG] PDF generated successfully: {pdf_file.name}, size: {pdf_file.size} bytes")
    return pdf_file
