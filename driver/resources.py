import json
from import_export import resources, fields, widgets
from .models import Company, Customer, DriverLoadInfo, DriverProfile

# ------------------------------
# Company & Customer
# ------------------------------
class CompanyResource(resources.ModelResource):
    class Meta:
        model = Company
        import_id_fields = ['name']  # unique identifier
        fields = ('name', 'email', 'scac_code')


class CustomerResource(resources.ModelResource):
    class Meta:
        model = Customer
        import_id_fields = ['name', 'company']  # unique together
        fields = ('name', 'email', 'company')

# ------------------------------
# Custom widget to show "recorded"
# ------------------------------
class RecordedWidget(widgets.Widget):
    def clean(self, value, row=None, *args, **kwargs):
        return value  # not used for import

    def render(self, value, obj=None, **kwargs):  # <-- include **kwargs
        if value:
            return "recorded"
        return ""


# ------------------------------
# JSON Widget for email history
# ------------------------------
class JSONListWidget(widgets.Widget):
    def clean(self, value, row=None, *args, **kwargs):
        if value:
            try:
                return json.loads(value)
            except:
                return []
        return []

    def render(self, value, obj=None, **kwargs):  # <-- include **kwargs
        if not value:
            return ""
        if isinstance(value, list):
            return "; ".join([f"{e.get('email')} ({e.get('status')})" for e in value])
        return str(value)


# ------------------------------
# Driver Load Info Resource
# ------------------------------
class DriverLoadInfoResource(resources.ModelResource):
    # Existing picture fields
    trailer_picture = fields.Field(attribute='trailer_picture', column_name='trailer_picture', widget=RecordedWidget())
    pulp_picture = fields.Field(attribute='pulp_picture', column_name='pulp_picture', widget=RecordedWidget())
    reefer_picture = fields.Field(attribute='reefer_picture', column_name='reefer_picture', widget=RecordedWidget())
    load_secure_picture = fields.Field(attribute='load_secure_picture', column_name='load_secure_picture', widget=RecordedWidget())
    sealed_trailer_picture = fields.Field(attribute='sealed_trailer_picture', column_name='sealed_trailer_picture', widget=RecordedWidget())
    bol = fields.Field(attribute='bol', column_name='bol', widget=RecordedWidget())
    pod = fields.Field(attribute='pod', column_name='pod', widget=RecordedWidget())
    seal_number = fields.Field(attribute='seal_number', column_name='seal_number')

    # New fields
    driver_company = fields.Field(column_name='company', attribute='driver', widget=widgets.ForeignKeyWidget(DriverProfile, 'company'))
    pickup_email_history = fields.Field(attribute='pickup_email_history', column_name='pickup_email_history', widget=JSONListWidget())
    delivery_email_history = fields.Field(attribute='delivery_email_history', column_name='delivery_email_history', widget=JSONListWidget())
    status = fields.Field(attribute='status', column_name='status')
    pulp_reason = fields.Field(attribute='pulp_reason', column_name='pulp_reason')
    reefer_temp_shipper = fields.Field(attribute='reefer_temp_shipper', column_name='reefer_temp_shipper')
    reefer_temp_bol = fields.Field(attribute='reefer_temp_bol', column_name='reefer_temp_bol')
    reefer_temp_unit = fields.Field(attribute='reefer_temp_unit', column_name='reefer_temp_unit')
    equipment_type = fields.Field(
        attribute='equipment_type',
        column_name='equipment_type'
    )


    class Meta:
        model = DriverLoadInfo
        fields = (
            'driver',
            'driver_company',
            'truck_number',
            'trailer_number',
            'customer_name',
            'order_number',
            'load_number',
            'pickup_number',
            'pickup_datetime',
            'trailer_picture',
            'pulp_picture',
            'pulp_reason',
            'reefer_picture',
            'reefer_temp_shipper',    # <-- added
            'reefer_temp_bol',        # <-- added
            'reefer_temp_unit',
            'load_secure_picture',
            'sealed_trailer_picture',
            'bol',
            'seal_number',
            'pickup_notes', 
            'delivery_notes',
            'delivery_number',
            'pod',
            'delivery_datetime',
            'pickup_email_history',
            'delivery_email_history',
            'status',
            'equipment_type',
            'created_at',
            'updated_at',
        )
        export_order = (
            'driver',
            'driver_company',
            'truck_number',
            'trailer_number',
            'customer_name',
            'order_number',
            'load_number',
            'pickup_number',
            'pickup_datetime',
            'trailer_picture',
            'pulp_picture',
            'pulp_reason',
            'reefer_picture',
            'reefer_temp_shipper',
            'reefer_temp_bol',
            'reefer_temp_unit',
            'load_secure_picture',
            'sealed_trailer_picture',
            'bol',
            'seal_number',
            'pickup_notes',
            'delivery_notes',
            'delivery_number',
            'pod',
            'delivery_datetime',
            'pickup_email_history',
            'delivery_email_history',
            'status',
            'equipment_type',
            'created_at',
            'updated_at',
        )



class DriverProfileResource(resources.ModelResource):
    scac_code = fields.Field(
        column_name='scac_code',
        attribute='company',
        widget=widgets.ForeignKeyWidget(Company, 'scac_code')
    )

    class Meta:
        model = DriverProfile
        fields = ('name', 'phone', 'company', 'scac_code', 'license_number', 'language')
        import_id_fields = ['license_number']
