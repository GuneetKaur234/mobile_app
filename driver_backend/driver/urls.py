from django.urls import path
from . import views

urlpatterns = [
    # Driver validation
    path('driver/validate/', views.validate_driver_api, name='validate_driver_api'),

    # Step 1: Save/Update truck info (POST/PUT)
    path('driver/save-or-update-truck-info/', views.save_or_update_truck_info_api, name='save_or_update_truck_info_api'),

    # Step 1: Get truck info (GET)
    path('driver/get-truck-info/<int:load_id>/', views.get_truck_info_api, name='get_truck_info_api'),

    # Equipment types
    path('driver/get-equipment-types/', views.get_equipment_types_api, name='get_equipment_types_api'),

    # Step 3: File uploads
    path('driver/save-upload/', views.save_upload_api, name='save_upload_api'),
    path('driver/update-upload/<int:load_id>/', views.update_upload_api, name='update_upload_api'),
    path('driver/get-uploads/<int:load_id>/', views.get_uploads_api, name='get_uploads_api'),

    # Step 4: Delivery info
    path('driver/save-delivery-info/', views.save_delivery_info_api, name='save_delivery_info_api'),

    # Step 4: Delivery info GET
    path('driver/get-delivery-info/<int:load_id>/', views.get_delivery_info_api, name='get_delivery_info_api'),

    # Customers for driver
    path('driver/get-customers/', views.get_customers_for_driver_api, name='get_customers_for_driver_api'),

    # Pickup / Delivery emails
    path('driver/send-pickup-email/<int:load_id>/', views.send_pickup_email_api, name='send_pickup_email_api'),
    path('driver/send-delivery-email/<int:load_id>/', views.send_delivery_email_api, name='send_delivery_email_api'),

    # Driver location
    path('driver/update-location/', views.update_driver_location, name='update_driver_location'),

    # Last load info
    path('driver/get-last-load/<int:driver_id>/', views.get_last_load_info_api, name='get_last_load_info_api'),

    # New: Latest 10 loads for homepage
    path('driver/get-latest-loads/<int:driver_id>/', views.get_latest_loads_api, name='get_latest_loads_api'),

    # Driver profile
    path('driver/get-profile/<int:driver_id>/', views.get_driver_profile_api, name='get_driver_profile'),
    path('driver/update-profile/', views.update_driver_profile_api, name='update_driver_profile'),

    # Load details
    path('driver/get-load-detail/<int:load_id>/', views.get_load_detail_api, name='get_load_detail_api'),

    # Create new driver load
    path('driver/create-new-load/', views.create_new_driver_load_api, name='create_new_driver_load_api'),
]
