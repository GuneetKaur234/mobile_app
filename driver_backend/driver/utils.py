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
    width, height = A4

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

            # scale image to fit page
            scale = min(width / img_width, height / img_height)
            img_width *= scale
            img_height *= scale
            x = (width - img_width) / 2
            y = (height - img_height) / 2

            c.drawInlineImage(photo.image.path, x, y, img_width, img_height)
            c.showPage()
        except Exception as e:
            print(f"[DEBUG] Error adding {photo.image.name}: {e}")

    c.save()
    buffer.seek(0)
    pdf_file = ContentFile(buffer.read(), name=f"{load.load_number}_all_photos.pdf")
    print(f"[DEBUG] PDF generated successfully: {pdf_file.name}, size: {pdf_file.size} bytes")
    return pdf_file
