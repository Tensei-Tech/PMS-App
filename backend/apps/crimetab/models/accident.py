from django.db import models


class RoadAccidentRecord(models.Model):
    """
    Main road accident record stored inside tenant state schema (e.g. `<schema>.road_accident_records`).
    Can link to a CaseRecord via case_id.
    """
    id = models.BigAutoField(primary_key=True)
    case_id = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    station_id = models.BigIntegerField(blank=True, null=True)
    station_name = models.CharField(max_length=255, blank=True, null=True)
    nature_of_accident = models.CharField(max_length=100, blank=True, null=True)
    nature_of_accident_other = models.CharField(max_length=255, blank=True, null=True)
    vehicle_abandoned = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    driver_subsequently_traced = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    victim_identity_established = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    eye_witnesses_identity = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    irad = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    irad_date = models.DateField(blank=True, null=True)
    dar = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    dar_date = models.DateField(blank=True, null=True)
    accident_datetime = models.DateTimeField(blank=True, null=True)
    accident_spot = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'road_accident_records'
        verbose_name = 'Road Accident Record'
        verbose_name_plural = 'Road Accident Records'
        ordering = ['-created_at']

    def __str__(self):
        return f"RoadAccident #{self.id} (Case: {self.case_id or 'Standalone'})"


class RoadAccidentVehicle(models.Model):
    """
    Vehicles involved in the accident stored in `<schema>.road_accident_vehicles`.
    """
    id = models.BigAutoField(primary_key=True)
    accident_record = models.ForeignKey(
        RoadAccidentRecord,
        on_delete=models.CASCADE,
        related_name='vehicles',
        db_column='accident_record_id'
    )
    case_id = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    display_order = models.SmallIntegerField(default=1)
    vehicle_number = models.CharField(max_length=100, blank=True, null=True)
    vehicle_name = models.CharField(max_length=100, blank=True, null=True)
    company_name = models.CharField(max_length=100, blank=True, null=True)
    company_name_other = models.CharField(max_length=100, blank=True, null=True)
    model = models.CharField(max_length=100, blank=True, null=True)
    owner_name_address = models.TextField(blank=True, null=True)
    driver_name_address = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'road_accident_vehicles'
        verbose_name = 'Road Accident Vehicle'
        verbose_name_plural = 'Road Accident Vehicles'
        ordering = ['display_order', 'id']

    def __str__(self):
        return f"Vehicle {self.vehicle_number or self.vehicle_name or '-'} (Accident #{self.accident_record_id})"


class RoadAccidentInjured(models.Model):
    """
    Injured persons stored in `<schema>.road_accident_injured`.
    """
    id = models.BigAutoField(primary_key=True)
    accident_record = models.ForeignKey(
        RoadAccidentRecord,
        on_delete=models.CASCADE,
        related_name='injured_persons',
        db_column='accident_record_id'
    )
    case_id = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    display_order = models.SmallIntegerField(default=1)
    name = models.CharField(max_length=255, blank=True, null=True)
    age = models.IntegerField(blank=True, null=True)
    gender = models.CharField(max_length=50, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    occupation = models.CharField(max_length=255, blank=True, null=True)
    mobile_no = models.CharField(max_length=20, blank=True, null=True)
    aadhaar_card = models.CharField(max_length=50, blank=True, null=True)
    pan_card = models.CharField(max_length=50, blank=True, null=True)
    caste = models.CharField(max_length=100, blank=True, null=True)
    religion = models.CharField(max_length=100, blank=True, null=True)
    death = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    death_date = models.DateField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'road_accident_injured'
        verbose_name = 'Road Accident Injured Person'
        verbose_name_plural = 'Road Accident Injured Persons'
        ordering = ['display_order', 'id']

    def __str__(self):
        return f"Injured: {self.name or '-'} (Accident #{self.accident_record_id})"


class RoadAccidentDeceased(models.Model):
    """
    Deceased persons stored in `<schema>.road_accident_deceased`.
    """
    id = models.BigAutoField(primary_key=True)
    accident_record = models.ForeignKey(
        RoadAccidentRecord,
        on_delete=models.CASCADE,
        related_name='deceased_persons',
        db_column='accident_record_id'
    )
    case_id = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    display_order = models.SmallIntegerField(default=1)
    name = models.CharField(max_length=255, blank=True, null=True)
    age = models.IntegerField(blank=True, null=True)
    gender = models.CharField(max_length=50, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    occupation = models.CharField(max_length=255, blank=True, null=True)
    mobile_no = models.CharField(max_length=20, blank=True, null=True)
    aadhaar_card = models.CharField(max_length=50, blank=True, null=True)
    pan_card = models.CharField(max_length=50, blank=True, null=True)
    caste = models.CharField(max_length=100, blank=True, null=True)
    religion = models.CharField(max_length=100, blank=True, null=True)
    post_mortem = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    pm_report_received = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    viscera_sent_fsl = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    fsl_report_received = models.CharField(max_length=10, blank=True, null=True)  # 'Yes' or 'No'
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'road_accident_deceased'
        verbose_name = 'Road Accident Deceased Person'
        verbose_name_plural = 'Road Accident Deceased Persons'
        ordering = ['display_order', 'id']

    def __str__(self):
        return f"Deceased: {self.name or '-'} (Accident #{self.accident_record_id})"
