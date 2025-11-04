from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from PIL import Image
from django.core.files.base import ContentFile
import re

def generate_load_pdf(load, include_pod=True):
    """
    Generate a single PDF containing all photos (and optionally PODs) of a DriverLoadInfo.
    Works with local or cloud storage and handles PNG/JPG images safely.
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
            img = img.convert("RGB")  # Ensure compatibility with PDF

            img_width, img_height = img.size

            # Scale image to fit page while preserving aspect ratio
            scale = min(page_width / img_width, page_height / img_height) * 0.95  # 5% margin
            img_width_scaled = img_width * scale
            img_height_scaled = img_height * scale
            x = (page_width - img_width_scaled) / 2
            y = (page_height - img_height_scaled) / 2

            # Draw image onto PDF page
            c.drawInlineImage(img, x, y, img_width_scaled, img_height_scaled)
            c.showPage()

            img.close()
            photo.image.close()
        except Exception as e:
            print(f"[DEBUG] Error adding photo {getattr(photo.image, 'name', 'unknown')}: {e}")

    c.save()
    buffer.seek(0)

    # Sanitize load_number for filename
    safe_load_number = re.sub(r'[^\w\-]', '_', load.load_number or "load")
    pdf_file = ContentFile(buffer.read(), name=f"{safe_load_number}_all_photos.pdf")
    print(f"[DEBUG] PDF generated successfully: {pdf_file.name}, size: {pdf_file.size} bytes")
    return pdf_file
