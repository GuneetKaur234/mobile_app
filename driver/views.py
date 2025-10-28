# views.py
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.conf import settings
from django.core.mail import EmailMessage
from django.template.loader import render_to_string

from rest_framework.decorators import api_view, parser_classes
from rest_framework.response import Response
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser

from .utils import generate_load_pdf
from django.utils import timezone

import json
import requests
from decimal import Decimal

from .models import (
    DriverProfile,
    DriverLoadInfo,
    DriverLocation,
    Customer,
    DriverLoadPhoto,
    Company
)

from django.utils import timezone
import pytz
from email.utils import make_msgid



# ----------------------------
# DRIVER LANGUAGE
# ----------------------------
@csrf_exempt
@api_view(['POST'])
def set_driver_language_api(request):
    try:
        data = json.loads(request.body)
        driver_id = data.get("driver_id")
        language = data.get("language")

        if not driver_id or not language:
            return JsonResponse({"error": "driver_id and language are required"}, status=400)

        if language not in ["en", "fr"]:
            return JsonResponse({"error": "Invalid language"}, status=400)

        try:
            driver = DriverProfile.objects.get(id=driver_id)
        except DriverProfile.DoesNotExist:
            return JsonResponse({"error": "Driver not found"}, status=404)

        driver.language = language
        driver.save()

        return JsonResponse({"message": "Language updated successfully", "language": driver.language}, status=200)

    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# ----------------------------
# DRIVER VALIDATION
# ----------------------------
@csrf_exempt
@api_view(['POST'])
def validate_driver_api(request):
    try:
        data = json.loads(request.body)
        license_number = data.get("license_number")
        company_name = data.get("company")
        scac_code = data.get("scac_code")
        name = data.get("name", "")
        phone = data.get("phone", "")

        if not license_number or not company_name or not scac_code:
            return JsonResponse({"error": "License number, company, and SCAC code are required"}, status=400)

        # Validate company and SCAC
        if not Company.objects.filter(name__iexact=company_name, scac_code__iexact=scac_code).exists():
            return JsonResponse({"access_granted": False, "error": "Company/SCAC combination not recognized"}, status=403)

        # Get or create driver
        driver, created = DriverProfile.objects.get_or_create(
            license_number=license_number,
            defaults={
                "name": name,
                "phone": phone,
                "company": company_name,
                "scac_code": scac_code
            }
        )

        # Update if company or SCAC changed
        if not created and (driver.company != company_name or driver.scac_code != scac_code):
            driver.company = company_name
            driver.scac_code = scac_code
            driver.save(update_fields=["company", "scac_code"])

        return JsonResponse({"access_granted": True, "driver_id": driver.id})

    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
@api_view(['POST', 'PUT'])
def save_or_update_truck_info_api(request):
    """
    Save or update truck/load info for a driver.
    - Supports creating new load or updating existing.
    - Status update only happens if `update_status` is True.
    """
    try:
        data = json.loads(request.body)
        driver_id = data.get("driver_id")
        force_new_load = data.get("force_new_load", False)
        validate_required = data.get("validate_required", False)
        post_load_id = data.get("load_id")  # optional for updates

        if not driver_id:
            return JsonResponse({"error": "driver_id is required"}, status=400)

        driver = DriverProfile.objects.filter(id=driver_id).first()
        if not driver:
            return JsonResponse({"error": "Driver profile not found"}, status=404)

        # Extract optional fields
        truck_number = data.get("truck_number")
        trailer_number = data.get("trailer_number")
        customer_id = data.get("customer_id")
        customer_name = data.get("customer_name")
        load_number = data.get("load_number")
        pickup_number = data.get("pickup_number")
        order_number = data.get("order_number")
        reefer_pre_cool = data.get("reefer_pre_cool")
        equipment_type = data.get("equipment_type")
        new_status = data.get("status")  # status sent by frontend
        update_status = data.get("update_status", False)  # only update if True

        print(f"💡 Incoming POST data: truck={truck_number}, trailer={trailer_number}, "
      f"customer_name={customer_name}, load_number={load_number}, "
      f"pickup_number={pickup_number}, equipment_type={equipment_type}")


        # Validate required fields if requested
        required_fields = [truck_number, trailer_number, load_number, pickup_number]
        if validate_required:
            if not all(required_fields) or not (customer_id or customer_name):
                return JsonResponse({"error": "All required fields must be filled"}, status=400)
            if equipment_type and "reefer" in equipment_type.lower() and not reefer_pre_cool:
                return JsonResponse({"error": "Reefer pre-cool is required for Reefer equipment"}, status=400)

        # Validate or get customer
        customer = None
        customer_qs = Customer.objects.filter(company__name__iexact=driver.company)
        if customer_id:
            customer = customer_qs.filter(id=customer_id).first()
        elif customer_name:
            customer = customer_qs.filter(name__iexact=customer_name).first()

        if (customer_id or customer_name) and not customer:
            return JsonResponse({"error": "Customer does not belong to your company"}, status=403)

        # Get existing load
        load_obj = None
        if post_load_id:
            load_obj = DriverLoadInfo.objects.filter(id=post_load_id, driver=driver).first()

        # Create new load
        if not load_obj or force_new_load:
            load_obj = DriverLoadInfo.objects.create(
                driver=driver,
                truck_number=truck_number or "",
                trailer_number=trailer_number or "",
                customer_name=customer.name if customer else customer_name or "",
                load_number=load_number or "",
                pickup_number=pickup_number or "",
                order_number=order_number or "",
                reefer_pre_cool=reefer_pre_cool or "",
                equipment_type=equipment_type or "",
                status="pending_pickup"
            )
            status_code = 201
            message = "Step 1 data saved successfully"

        # Update existing load
        else:
            load_obj.truck_number = truck_number if truck_number is not None else ""
            load_obj.trailer_number = trailer_number if trailer_number is not None else ""
            load_obj.load_number = load_number if load_number is not None else ""
            load_obj.pickup_number = pickup_number if pickup_number is not None else ""
            load_obj.order_number = order_number if order_number is not None else ""
            load_obj.reefer_pre_cool = reefer_pre_cool if reefer_pre_cool is not None else ""
            load_obj.equipment_type = equipment_type if equipment_type is not None else ""
            load_obj.customer_name = customer.name if customer else customer_name or ""

            # Update status only if requested
            if update_status and new_status:
                load_obj.status = new_status

            load_obj.save()
            status_code = 200
            message = "Step 1 data updated successfully"

        return JsonResponse({
            "message": message,
            "load_id": load_obj.id,
            "load_number": load_obj.load_number,
            "pickup_number": load_obj.pickup_number,
            "order_number": load_obj.order_number,
            "truck_number": load_obj.truck_number,
            "trailer_number": load_obj.trailer_number,
            "customer_name": load_obj.customer_name,
            "reefer_pre_cool": load_obj.reefer_pre_cool,
            "equipment_type": load_obj.equipment_type,
            "status": load_obj.status
        }, status=status_code)

    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)



@csrf_exempt
@api_view(['GET'])
def get_truck_info_api(request, load_id=None):
    if not load_id:
        return JsonResponse({"error": "load_id is required for GET"}, status=400)

    load_info = DriverLoadInfo.objects.filter(id=load_id).first()
    if not load_info:
        return JsonResponse({"error": "Load not found"}, status=404)

    return JsonResponse({
        "load_id": load_info.id,
        "load_number": load_info.load_number,
        "pickup_number": load_info.pickup_number,
        "order_number": load_info.order_number,
        "truck_number": load_info.truck_number,
        "trailer_number": load_info.trailer_number,
        "customer_name": load_info.customer_name,
        "reefer_pre_cool": load_info.reefer_pre_cool,
        "equipment_type": load_info.equipment_type,
        "status": load_info.status
    }, status=200)


@csrf_exempt
@api_view(['GET'])
def get_equipment_types_api(request):
    """
    Return list of available equipment types based on DriverLoadInfo model choices.
    """
    equipment_types = [
        {"id": key, "name": label} 
        for key, label in DriverLoadInfo.EQUIPMENT_TYPE_CHOICES
    ]
    return JsonResponse({"equipment_types": equipment_types}, status=200)

# ----------------------------
# HELPER: build file response
# ----------------------------
def _build_file_response(load_info):
    photos = DriverLoadPhoto.objects.filter(load=load_info)
    file_map = {
        "trailer": [],
        "pulp": [],
        "load_secure": [],
        "sealed_trailer": [],
        "bol": [],
    }

    # Only include reefer files if equipment type is Reefer
    is_reefer = (getattr(load_info, 'equipment_type', '') or '').lower() == 'reefer'
    print(f"💡 _build_file_response: load_id={load_info.id}, equipment_type={load_info.equipment_type}, is_reefer={is_reefer}")
    if is_reefer:
        file_map["reefer"] = []

    for photo in photos:
        key = photo.photo_type.lower().replace(" ", "_")
        if key in file_map:
            file_map[key].append({
                "id": photo.id,
                "url": settings.MEDIA_URL + str(photo.image)
            })

    response = {
        "load_id": load_info.id,
        "pickup_notes": load_info.pickup_notes or "",
        "seal_number": load_info.seal_number or "",
        "equipment_type": load_info.equipment_type or "", 
        **file_map,
    }

    # Only include reefer temp fields if equipment type is Reefer
    if is_reefer:
        response.update({
            "reefer_temp_shipper": load_info.reefer_temp_shipper or "",
            "reefer_temp_bol": load_info.reefer_temp_bol or "",
            "reefer_temp_unit": load_info.reefer_temp_unit or "C",
            "pulp_reason": load_info.pulp_reason or "",
            
        })

    return response

# ----------------------------
# UPLOAD FILES (STEP 3) - PICKUP
# ----------------------------
@api_view(['POST', 'PUT'])
def save_upload_api(request):
    load_id = request.data.get("load_id")
    if not load_id:
        return Response({"error": "load_id is required"}, status=400)

    load_info = DriverLoadInfo.objects.filter(id=load_id).first()
    if not load_info:
        return Response({"error": "Load info not found"}, status=404)

    # Save pickup notes
    pickup_notes = request.data.get("pickup_notes", "").strip()
    if pickup_notes:
        existing_notes = load_info.pickup_notes or ""
        if existing_notes:
            existing_notes += "\n"
        existing_notes += pickup_notes
        load_info.pickup_notes = existing_notes

    # Save seal number
    load_info.seal_number = request.data.get("seal_number") or None

    # Save pulp reason
    pulp_reason = request.data.get("pulp_reason", "").strip()
    if pulp_reason:
        load_info.pulp_reason = pulp_reason

    # ----------------------------
    # Save new reefer temp fields only if equipment is Reefer
    # ----------------------------
    if (getattr(load_info, 'equipment_type', '') or '').lower() == 'reefer':
        load_info.reefer_temp_shipper = request.data.get("reefer_temp_shipper") or None
        load_info.reefer_temp_bol = request.data.get("reefer_temp_bol") or None
        load_info.reefer_temp_unit = request.data.get("reefer_temp_unit") or "C"

    load_info.status = "in_transit"
    load_info.save()

    # Save uploaded photos
    file_map = {
        "trailer_picture": "trailer",
        "pulp_picture": "pulp",
        "reefer_picture": "reefer",
        "load_secure_picture": "load_secure",
        "sealed_trailer_picture": "sealed_trailer",
        "bol_picture": "bol",
    }

    for key, photo_type in file_map.items():
        uploaded_files = request.FILES.getlist(key)
        for uploaded_file in uploaded_files:
            DriverLoadPhoto.objects.create(
                load=load_info,
                photo_type=photo_type,
                image=uploaded_file
            )

    return Response(
        {"message": "Step 3 data saved successfully", "data": _build_file_response(load_info)},
        status=201
    )


# ----------------------------
# UPDATE FILES (STEP 3)
# ----------------------------
@api_view(['POST', 'PUT'])
def update_upload_api(request, load_id):
    load_info = DriverLoadInfo.objects.filter(id=load_id).first()
    if not load_info:
        return Response({"error": "Load info not found"}, status=404)

    # ----------------------------
    # Update text fields
    # ----------------------------
    fields_to_update = ["pickup_notes", "seal_number", "pulp_reason"]
    # Only include reefer fields if equipment is Reefer
    if (getattr(load_info, 'equipment_type', '') or '').lower() == 'reefer':
        fields_to_update += ["reefer_temp_shipper", "reefer_temp_bol", "reefer_temp_unit"]

    for field in fields_to_update:
        value = request.data.get(field)
        if value is not None:
            setattr(load_info, field, value)
    load_info.save()

    # ----------------------------
    # Update uploaded photos
    # ----------------------------
    file_map = {
        "trailer_picture": "trailer",
        "pulp_picture": "pulp",
        "reefer_picture": "reefer",
        "load_secure_picture": "load_secure",
        "sealed_trailer_picture": "sealed_trailer",
        "bol_picture": "bol",
    }

    for key, photo_type in file_map.items():
        # 1️⃣ Get existing IDs from frontend (if any)
        existing_ids_str = request.data.get(f"{key}_existing_ids", "")
        existing_ids_list = [int(x) for x in existing_ids_str.split(",") if x.isdigit()]

        # 2️⃣ Delete photos that are no longer included
        DriverLoadPhoto.objects.filter(load=load_info, photo_type=photo_type)\
            .exclude(id__in=existing_ids_list).delete()

        # 3️⃣ Save new uploaded files, avoiding duplicates
        uploaded_files = request.FILES.getlist(key)
        for uploaded_file in uploaded_files:
            duplicate_exists = DriverLoadPhoto.objects.filter(
                load=load_info,
                photo_type=photo_type,
                image__icontains=uploaded_file.name
            ).exists()

            if not duplicate_exists:
                DriverLoadPhoto.objects.create(
                    load=load_info,
                    photo_type=photo_type,
                    image=uploaded_file
                )

    return Response(
        {"message": "Step 3 data updated successfully", "data": _build_file_response(load_info)},
        status=200
    )


# ----------------------------
# GET UPLOAD FILES (STEP 3)
# ----------------------------
@api_view(['GET'])
def get_uploads_api(request, load_id):
    load_info = DriverLoadInfo.objects.filter(id=load_id).first()
    if not load_info:
        return Response({"error": "Load info not found"}, status=404)

    response_data = _build_file_response(load_info)
    return Response(response_data, status=200)

# ----------------------------
# DELIVERY INFO (STEP 4)
# ----------------------------
@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def save_delivery_info_api(request):
    load_id = request.data.get("load_id")
    if not load_id:
        return Response({"error": "load_id is required"}, status=400)

    load_info = DriverLoadInfo.objects.filter(id=load_id).first()
    if not load_info:
        return Response({"error": "Load info not found"}, status=404)

    # Update delivery number (allow empty string)
    delivery_number = request.data.get("delivery_number") or request.data.get("deliveryNumber")
    if delivery_number is not None:
        load_info.delivery_number = delivery_number

    # Save delivery notes (append new notes)
    delivery_notes = request.data.get("notes", "").strip()
    if delivery_notes:
        existing_notes = load_info.delivery_notes or ""
        if existing_notes:
            existing_notes += "\n"
        existing_notes += f"Delivery notes: {delivery_notes}"
        load_info.delivery_notes = existing_notes

    load_info.save()

    # Handle POD files
    existing_ids_str = request.data.get("pod_existing_ids", "")
    existing_ids_list = [int(x) for x in existing_ids_str.split(",") if x.isdigit()]
    
    # Delete PODs not in existing IDs
    DriverLoadPhoto.objects.filter(load=load_info, photo_type="POD").exclude(id__in=existing_ids_list).delete()

    # Upload new POD files
    uploaded_files = request.FILES.getlist("pod_files")
    for uploaded_file in uploaded_files:
        DriverLoadPhoto.objects.create(
            load=load_info,
            photo_type="POD",
            image=uploaded_file
        )

    # Build response including Step 3 files
    response_data = _build_file_response(load_info)

    # Add POD files
    pod_photos = DriverLoadPhoto.objects.filter(load=load_info, photo_type="POD")
    response_data["pod"] = [
        {"id": photo.id, "url": settings.MEDIA_URL + str(photo.image)} for photo in pod_photos
    ]

    # Add delivery info
    response_data["delivery_number"] = load_info.delivery_number or ""
    response_data["status"] = load_info.status

    return Response({
        "message": "Step 4 data saved successfully",
        "data": response_data
    }, status=200)


# ----------------------------
# GET DELIVERY INFO (STEP 4)
# ----------------------------
@api_view(['GET'])
def get_delivery_info_api(request, load_id):
    load_info = DriverLoadInfo.objects.filter(id=load_id).first()
    if not load_info:
        return Response({"error": "Load info not found"}, status=404)

    # POD files
    pod_photos = DriverLoadPhoto.objects.filter(load=load_info, photo_type="POD")
    pod_list = [{"id": photo.id, "url": settings.MEDIA_URL + str(photo.image)} for photo in pod_photos]

    # Include Step 3 files as well
    response_data = _build_file_response(load_info)
    response_data["pod"] = pod_list
    response_data["delivery_number"] = load_info.delivery_number or ""
    response_data["delivery_notes"] = load_info.delivery_notes or ""
    response_data["status"] = load_info.status

    return Response({"data": response_data}, status=200)


# ----------------------------
# DRIVER LOCATION
# ----------------------------
@api_view(['POST'])
def update_driver_location(request):
    try:
        driver_id = request.data.get('driver_id')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')

        if not driver_id or latitude is None or longitude is None:
            return Response({"error": "driver_id, latitude, and longitude are required"}, status=400)

        driver = DriverProfile.objects.get(id=driver_id)

        # Convert to Decimal for storage
        latitude_dec, longitude_dec = Decimal(latitude), Decimal(longitude)

        # Reverse geocode using Azure Maps
        address = "Unknown location"
        try:
            resp = requests.get(
                f"https://atlas.microsoft.com/search/address/reverse/json?api-version=1.0&query={latitude},{longitude}&subscription-key={settings.AZURE_MAPS_KEY}",
                timeout=5
            )
            resp.raise_for_status()
            data = resp.json()
            if data.get('addresses'):
                address = data['addresses'][0]['address'].get('freeformAddress', address)
        except Exception:
            pass  # Keep address as "Unknown location" if Azure fails

        # Save or update driver location
        DriverLocation.objects.update_or_create(
            license_number=driver.license_number,
            company_name=driver.company,
            defaults={
                'driver': driver,
                'latitude': latitude_dec,
                'longitude': longitude_dec,
                'address': address
            }
        )

        return Response({
            "status": "success",
            "latitude": latitude_dec,
            "longitude": longitude_dec,
            "address": address
        }, status=200)

    except DriverProfile.DoesNotExist:
        return Response({"error": "Driver not found"}, status=404)
    except (TypeError, ValueError):
        return Response({"error": "Invalid latitude or longitude"}, status=400)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


# ----------------------------
# GET LAST ACTIVE LOAD (Pending Pickup or In Transit)
# ----------------------------
@csrf_exempt
@api_view(['GET'])
def get_last_load_info_api(request, driver_id):
    try:
        driver = DriverProfile.objects.get(id=driver_id)
    except DriverProfile.DoesNotExist:
        return JsonResponse({"error": "Driver not found"}, status=404)

    # Filter loads with status pending_pickup or in_transit
    load = DriverLoadInfo.objects.filter(
        driver=driver,
        status__in=["pending_pickup", "in_transit"]
    ).order_by('-id').first()

    if not load:
        return JsonResponse({"error": "No active load found"}, status=404)

    customer = Customer.objects.filter(
        name__iexact=load.customer_name,
        company__name__iexact=driver.company
    ).first()
    customer_id = customer.id if customer else None

    data = {
        "id": load.id,
        "truck_number": load.truck_number,
        "trailer_number": load.trailer_number,
        "load_number": load.load_number,
        "pickup_number": load.pickup_number,
        "order_number": load.order_number,
        "customer_name": load.customer_name,
        "customer_id": customer_id,
        "reefer_pre_cool": load.reefer_pre_cool,
        "status": load.status
    }

    return JsonResponse(data, status=200)



# ----------------------------
# GET CUSTOMERS FOR DRIVER
# ----------------------------
@csrf_exempt
@api_view(['POST'])
def get_customers_for_driver_api(request):
    try:
        data = json.loads(request.body)
        driver_id = data.get("driver_id")
        if not driver_id:
            return JsonResponse({"error": "driver_id is required"}, status=400)

        try:
            driver = DriverProfile.objects.get(id=driver_id)
        except DriverProfile.DoesNotExist:
            return JsonResponse({"error": "Driver profile not found"}, status=404)

        customers = Customer.objects.filter(company__name__iexact=driver.company).values("id", "name")
        return JsonResponse({"customers": list(customers)}, status=200)

    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# ----------------------------
# SEND PICKUP / DELIVERY EMAILS
# ----------------------------
@api_view(['POST'])
def send_pickup_email_api(request, load_id):
    return send_email_api(request, load_id=load_id, include_pod=False, email_type="Pickup")

@api_view(['POST'])
def send_delivery_email_api(request, load_id):
    return send_email_api(request, load_id=load_id, include_pod=True, email_type="Delivery")


def send_email_api(request, load_id, include_pod, email_type):
    try:
        load = DriverLoadInfo.objects.get(id=load_id)

        # Fetch latest location for the driver
        driver_location = DriverLocation.objects.filter(driver=load.driver).order_by('-id').first()
        location_address = driver_location.address if driver_location else "Unknown location"


        # Automatically update pickup/delivery datetime and status
        now = timezone.now()
        if email_type.lower() == "pickup":
            load.pickup_datetime = now
            load.status = "pickup_completed"
            load.save(update_fields=['pickup_datetime', 'status'])
        elif email_type.lower() == "delivery":
            load.delivery_datetime = now
            load.status = "delivered"
            load.save(update_fields=['delivery_datetime', 'status'])

        # Fetch recipient emails
        recipient_emails = []
        # Fetch customer email under same company
        customer = Customer.objects.filter(
            name__iexact=load.customer_name,
            company__name__iexact=load.driver.company
        ).first()
        if customer and customer.email:
            recipient_emails.append(customer.email)

        # Fetch company email
        company = Company.objects.filter(name__iexact=load.driver.company).first()
        if company and company.email:
            recipient_emails.append(company.email)

        if not recipient_emails:
            return Response({"error": "No recipient emails found"}, status=404)


        # Define your timezone
        est = pytz.timezone('America/Toronto')
        
        # Convert datetimes to EST
        pickup_dt = load.pickup_datetime.astimezone(est) if load.pickup_datetime else ""
        delivery_dt = load.delivery_datetime.astimezone(est) if load.delivery_datetime else ""

        # Build table rows
        rows = [
            ("Driver", load.driver.name),
            ("Truck Number", load.truck_number),
            ("Trailer Number", load.trailer_number),
            ("Customer", load.customer_name),
            ("Order Number", load.order_number or ""),
            ("Pick Number", load.pickup_number),
            ("Seal Number", load.seal_number),
            ("Delivery Number", load.delivery_number),
            ("Pickup Notes", load.pickup_notes or ""),
            ("Delivery Notes", load.delivery_notes or ""),
            ("Pickup Date/Time", pickup_dt),
            ("Delivery Date/Time", delivery_dt),
            ("Current Location", location_address),
        ]

        # Include pulp reason if present
        if load.pulp_reason:
            rows.append(("Pulp Reason", load.pulp_reason))

        # Include Reefer fields only if equipment_type is Reefer
        if getattr(load, "equipment_type", "").lower() == "reefer":
            rows.extend([
                ("Reefer Temp (Set by Shipper)", getattr(load, "reefer_temp_shipper", "")),
                ("Reefer Temp on BOL", getattr(load, "reefer_temp_bol", "")),
                ("Temperature Unit", getattr(load, "reefer_temp_unit", "")),
            ])

        # Build HTML table
        html_rows = "".join([f"<tr><td>{label}</td><td>{value}</td></tr>" for label, value in rows])
        html_body = f"""
        <html>
        <body>
            <h2 style="color:#2E86C1;">{email_type} Report: {load.load_number}</h2>
            <table style="border-collapse: collapse; width: 100%; border: 1px solid #333;">
                <thead>
                    <tr>
                        <th style="border: 1px solid #333; padding: 8px; text-align: left; background-color: #f2f2f2;">Field</th>
                        <th style="border: 1px solid #333; padding: 8px; text-align: left; background-color: #f2f2f2;">Details</th>
                    </tr>
                </thead>
                <tbody>
                    {html_rows}
                </tbody>
            </table>
        </body>
        </html>
        """

        # Generate PDF (existing function)
        pdf_file = generate_load_pdf(load, include_pod=include_pod)

        # Send email
        email = EmailMessage(
            subject=f"{email_type} Report: {load.pickup_number}",
            body=html_body,
            to=recipient_emails
        )
        email.content_subtype = "html"

        pdf_file.seek(0)
        email.attach(pdf_file.name, pdf_file.read(), 'application/pdf')

        # Inside send_email_api
        if email_type.lower() == "pickup":
            # Generate Message-ID and assign
            msg_id = make_msgid()
            email.extra_headers = {"Message-ID": msg_id}
            
            # Save to pickup_email_history
            load.pickup_email_history.append({
                "email": recipient_emails,
                "timestamp": str(now),
                "status": "sent",
                "message_id": msg_id
            })
            load.save(update_fields=['pickup_email_history'])
        
        elif email_type.lower() == "delivery":
            # Thread under first pickup email
            if load.pickup_email_history:
                first_msg_id = load.pickup_email_history[0].get("message_id")
                if first_msg_id:
                    email.extra_headers = {
                        "In-Reply-To": first_msg_id,
                        "References": first_msg_id
                    }
        
        # Send email once
        email.send()


        return Response({
            "message": f"{email_type} email sent successfully",
            "recipients": recipient_emails,
            "load_data": {label.lower().replace(" ", "_"): value for label, value in rows}
        }, status=200)

    except DriverLoadInfo.DoesNotExist:
        return Response({"error": "Load info not found"}, status=404)
    except Exception as e:
        return Response({"error": str(e)}, status=500)

# ----------------------------
# GET DRIVER PROFILE
# ----------------------------
@csrf_exempt
@api_view(['GET'])
def get_driver_profile_api(request, driver_id):
    try:
        print(f"[DEBUG] Requested driver_id: {driver_id}")
        driver = DriverProfile.objects.get(id=driver_id)
        data = {
            "id": driver.id,
            "name": driver.name,
            "phone": driver.phone,
            "company": driver.company,  # <- included company
            "license_number": driver.license_number,
            "language": driver.language,
            "device_token": driver.device_token,
        }
        return JsonResponse(data, status=200)
    except DriverProfile.DoesNotExist:
        return JsonResponse({"error": "Driver not found"}, status=404)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# ----------------------------
# UPDATE DRIVER PROFILE
# ----------------------------
@csrf_exempt
@api_view(['PUT'])
def update_driver_profile_api(request):
    try:
        data = json.loads(request.body)
        driver_id = data.get("driver_id")

        if not driver_id:
            return JsonResponse({"error": "driver_id is required"}, status=400)

        try:
            driver = DriverProfile.objects.get(id=driver_id)
        except DriverProfile.DoesNotExist:
            return JsonResponse({"error": "Driver not found"}, status=404)

        # Update fields if provided
        name = data.get("name")
        phone = data.get("phone")
        license_number = data.get("license_number")
        company = data.get("company")  # <- fetch from request

        if name:
            driver.name = name.strip()
        if phone:
            driver.phone = phone.strip()
        if license_number:
            driver.license_number = license_number.strip()
        if company:
            driver.company = company.strip()  # <- update company

        driver.save()

        return JsonResponse({
            "message": "Profile updated successfully",
            "driver": {
                "id": driver.id,
                "name": driver.name,
                "phone": driver.phone,
                "license_number": driver.license_number,
                "company": driver.company,  # <- include company
                "language": driver.language,
            }
        }, status=200)

    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# ----------------------------
# GET LATEST 10 LOADS FOR DRIVER
# ----------------------------
@csrf_exempt
@api_view(['GET'])
def get_latest_loads_api(request, driver_id):
    """
    Returns latest 10 loads for a driver with load_number, customer_name, and status.
    """
    try:
        driver = DriverProfile.objects.get(id=driver_id)
    except DriverProfile.DoesNotExist:
        return JsonResponse({"error": "Driver not found"}, status=404)

    # Get latest 10 loads (order by creation date descending)
    loads = DriverLoadInfo.objects.filter(driver=driver).order_by('-created_at')[:3]

    data = []
    for load in loads:
        # Ensure customer_name exists
        customer = Customer.objects.filter(
            name__iexact=load.customer_name,
            company__name__iexact=driver.company
        ).first()
        customer_display = customer.name if customer else load.customer_name

        data.append({
            "load_id": load.id,
            "load_number": load.load_number,
            "customer_name": customer_display,
            "status": load.status
        })

    return JsonResponse({"loads": data}, status=200)


@api_view(['GET'])
def get_load_detail_api(request, load_id):
    """
    Returns detailed info about a load for Flutter.
    Step completion flags now follow status:
      - Pickup completed if status is in_transit or delivered
      - Trailer upload completed if any trailer photos exist
      - Delivery completed if status is delivered
    """
    try:
        # Fetch the load by ID
        load = DriverLoadInfo.objects.filter(id=load_id).first()
        if not load:
            return JsonResponse({"error": "Load not found"}, status=404)

        # Step completion flags based on status
        pickup_info_completed = load.status in ["in_transit", "delivered"]
        trailer_upload_completed = load.photos.filter(photo_type="trailer").exists()
        delivery_info_completed = load.status == "delivered"

        # Fetch all files for this load
        photos = load.photos.all()
        file_map = {
            "trailer": [],
            "pulp": [],
            "reefer": [],
            "load_secure": [],
            "sealed_trailer": [],
            "bol": [],
            "pod": []
        }

        for photo in photos:
            key = photo.photo_type.lower().replace(" ", "_")
            if key in file_map:
                file_map[key].append({
                    "id": photo.id,
                    "url": photo.image.url if photo.image else ""
                })

        # Response data for Flutter
        response_data = {
            "load_id": load.id,
            "load_number": load.load_number,
            "pickup_number": load.pickup_number,
            "customer_name": load.customer_name,  # no customer_id needed
            "truck_number": load.truck_number,
            "trailer_number": load.trailer_number,
            "order_number": load.order_number,
            "equipment_type":load.equipment_type,
            "reefer_pre_cool": load.reefer_pre_cool,
            "status": load.status,
            "pickup_info_completed": pickup_info_completed,
            "trailer_upload_completed": trailer_upload_completed,
            "delivery_info_completed": delivery_info_completed,
            "files": file_map
        }

        return JsonResponse(response_data, status=200)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# ----------------------------
# CREATE NEW DRIVER LOAD
# ----------------------------
@csrf_exempt
@api_view(['POST'])
def create_new_driver_load_api(request):
    try:
        data = json.loads(request.body)
        driver_id = data.get("driver_id")

        if not driver_id:
            return JsonResponse({"error": "driver_id is required"}, status=400)

        # Create a new load record with default status
        new_load = DriverLoadInfo.objects.create(
            driver_id=driver_id,
            status="Pickup Pending"
        )

        return JsonResponse({
            "message": "New load created successfully",
            "load_id": new_load.id,
            "status": new_load.status
        }, status=201)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)




