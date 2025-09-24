from django.urls import path, include
from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.http import HttpResponse  # <-- add this

urlpatterns = [
    path('admin/', admin.site.urls),

    # All driver-related API routes
    path('api/driver/', include('driver.urls')),

    path('', lambda request: HttpResponse("Hello, Django is running!")),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
