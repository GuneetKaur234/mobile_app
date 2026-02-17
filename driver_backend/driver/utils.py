from io import BytesIO
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from PIL import Image
from django.core.files.base import ContentFile

def generate_load_pdf(load, include_pod=True):
    """
    Generate a single PDF containing all photos (and optionally PODs) of a DriverLoadInfo.
    Debug prints added to trace photo processing and PDF creation.
    """
    buffer = BytesIO()
    c = canvas.Canvas(buffer, pagesize=A4)
    PAGE_WIDTH, PAGE_HEIGHT = A4

    MARGIN = 50  # points (~0.7 inch)
    HEADER_HEIGHT = 30

    photos = load.photos.all().order_by('photo_type')
    if not include_pod:
        photos = photos.exclude(photo_type='POD')

    if not photos.exists():
        print(f"[DEBUG] No photos found for load {load.load_number} (include_pod={include_pod})")

    for idx, photo in enumerate(photos, start=1):
        try:
            print(f"[DEBUG] Processing photo {idx}: {photo.photo_type}, path: {photo.image.path}")
            img = Image.open(photo.image.path)
            img_width, img_height = img.size

            usable_width = PAGE_WIDTH - 2 * MARGIN
            usable_height = PAGE_HEIGHT - 2 * MARGIN - HEADER_HEIGHT

            # Scale image to fit within margins
            scale = min(usable_width / img_width, usable_height / img_height)
            img_width_scaled = img_width * scale
            img_height_scaled = img_height * scale

            # Center image within margins
            x = MARGIN + (usable_width - img_width_scaled) / 2
            y = MARGIN + (usable_height - img_height_scaled) / 2

            c.drawInlineImage(photo.image.path, x, y, img_width, img_height)
            c.showPage()
            
        except Exception as e:
            print(f"[DEBUG] Error adding {photo.image.name}: {e}")

    c.save()
    buffer.seek(0)
    pdf_file = ContentFile(buffer.read(), name=f"{load.load_number}_all_photos.pdf")
    print(f"[DEBUG] PDF generated successfully: {pdf_file.name}, size: {pdf_file.size} bytes")
    return pdf_file


