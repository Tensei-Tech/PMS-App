from rest_framework import serializers
from .models.accident import (
    RoadAccidentRecord,
    RoadAccidentVehicle,
    RoadAccidentInjured,
    RoadAccidentDeceased,
)


class RoadAccidentVehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoadAccidentVehicle
        fields = [
            'id', 'accident_record', 'case_id', 'display_order',
            'vehicle_number', 'vehicle_name', 'company_name',
            'company_name_other', 'model', 'owner_name_address',
            'driver_name_address', 'created_at'
        ]


class RoadAccidentInjuredSerializer(serializers.ModelSerializer):
    death_date_display = serializers.SerializerMethodField()

    class Meta:
        model = RoadAccidentInjured
        fields = [
            'id', 'accident_record', 'case_id', 'display_order',
            'name', 'age', 'gender', 'address', 'occupation',
            'mobile_no', 'aadhaar_card', 'pan_card', 'caste',
            'religion', 'death', 'death_date', 'death_date_display',
            'created_at'
        ]

    def get_death_date_display(self, obj):
        if obj.death_date:
            return obj.death_date.strftime('%d/%m/%Y')
        return None


class RoadAccidentDeceasedSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoadAccidentDeceased
        fields = [
            'id', 'accident_record', 'case_id', 'display_order',
            'name', 'age', 'gender', 'address', 'occupation',
            'mobile_no', 'aadhaar_card', 'pan_card', 'caste',
            'religion', 'post_mortem', 'pm_report_received',
            'viscera_sent_fsl', 'fsl_report_received', 'created_at'
        ]


class RoadAccidentRecordSerializer(serializers.ModelSerializer):
    vehicles = RoadAccidentVehicleSerializer(many=True, read_only=True)
    injured_persons = RoadAccidentInjuredSerializer(many=True, read_only=True)
    deceased_persons = RoadAccidentDeceasedSerializer(many=True, read_only=True)
    irad_date_display = serializers.SerializerMethodField()
    dar_date_display = serializers.SerializerMethodField()

    class Meta:
        model = RoadAccidentRecord
        fields = [
            'id', 'case_id', 'station_id', 'station_name',
            'nature_of_accident', 'nature_of_accident_other',
            'vehicle_abandoned', 'driver_subsequently_traced',
            'victim_identity_established', 'eye_witnesses_identity',
            'irad', 'irad_date', 'irad_date_display',
            'dar', 'dar_date', 'dar_date_display',
            'accident_datetime', 'accident_spot',
            'created_at', 'updated_at',
            'vehicles', 'injured_persons', 'deceased_persons'
        ]

    def get_irad_date_display(self, obj):
        if obj.irad_date:
            return obj.irad_date.strftime('%d/%m/%Y')
        return None

    def get_dar_date_display(self, obj):
        if obj.dar_date:
            return obj.dar_date.strftime('%d/%m/%Y')
        return None

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Expose both raw and prefixed keys for seamless DynamicFormScreen hydration
        data['acc_nature_of_accident'] = instance.nature_of_accident
        data['acc_nature_of_accident_other'] = instance.nature_of_accident_other
        data['acc_vehicle_abandoned'] = instance.vehicle_abandoned
        data['acc_driver_subsequently_traced'] = instance.driver_subsequently_traced
        data['acc_victim_identity_established'] = instance.victim_identity_established
        data['acc_eyewitnesses_identity'] = instance.eye_witnesses_identity
        data['acc_irad'] = instance.irad
        data['acc_irad_date'] = data.get('irad_date_display') or (instance.irad_date.isoformat() if instance.irad_date else None)
        data['acc_dar'] = instance.dar
        data['acc_dar_date'] = data.get('dar_date_display') or (instance.dar_date.isoformat() if instance.dar_date else None)
        # Same text the form's date-time picker uses (dd/mm/yyyy HH:MM, local time)
        from django.utils import timezone
        data['accident_datetime'] = (
            timezone.localtime(instance.accident_datetime).strftime('%d/%m/%Y %H:%M')
            if instance.accident_datetime else None
        )
        data['accident_spot'] = instance.accident_spot

        # Vehicles repeating group with acc_veh_* prefixed child fields
        veh_rows = []
        for v in instance.vehicles.all():
            v_dict = RoadAccidentVehicleSerializer(v).data
            v_dict.update({
                'acc_veh_number': v.vehicle_number,
                'acc_veh_name': v.vehicle_name,
                'acc_veh_company': v.company_name,
                'acc_veh_company_other': v.company_name_other,
                'acc_veh_model': v.model,
                'acc_veh_owner_details': v.owner_name_address,
                'acc_veh_driver_details': v.driver_name_address,
            })
            veh_rows.append(v_dict)
        data['acc_vehicles'] = veh_rows
        data['vehicles'] = veh_rows

        # Injured repeating group with acc_inj_* prefixed child fields
        inj_rows = []
        for inj in instance.injured_persons.all():
            inj_dict = RoadAccidentInjuredSerializer(inj).data
            d_date = inj.death_date.strftime('%d/%m/%Y') if inj.death_date else None
            inj_dict.update({
                'acc_inj_name': inj.name,
                'acc_inj_age': inj.age,
                'acc_inj_gender': inj.gender,
                'acc_inj_address': inj.address,
                'acc_inj_occupation': inj.occupation,
                'acc_inj_mobile': inj.mobile_no,
                'acc_inj_aadhaar': inj.aadhaar_card,
                'acc_inj_pan': inj.pan_card,
                'acc_inj_caste': inj.caste,
                'acc_inj_religion': inj.religion,
                'acc_inj_death': inj.death,
                'acc_inj_death_date': d_date,
            })
            inj_rows.append(inj_dict)
        data['acc_injured'] = inj_rows
        data['injured'] = inj_rows

        # Deceased repeating group with acc_dec_* prefixed child fields
        dec_rows = []
        for dec in instance.deceased_persons.all():
            dec_dict = RoadAccidentDeceasedSerializer(dec).data
            dec_dict.update({
                'acc_dec_name': dec.name,
                'acc_dec_age': dec.age,
                'acc_dec_gender': dec.gender,
                'acc_dec_address': dec.address,
                'acc_dec_occupation': dec.occupation,
                'acc_dec_mobile': dec.mobile_no,
                'acc_dec_aadhaar': dec.aadhaar_card,
                'acc_dec_pan': dec.pan_card,
                'acc_dec_caste': dec.caste,
                'acc_dec_religion': dec.religion,
                'acc_dec_post_mortem': dec.post_mortem,
                'acc_dec_pm_report_received': dec.pm_report_received,
                'acc_dec_viscera_sent_fsl': dec.viscera_sent_fsl,
                'acc_dec_fsl_report_received': dec.fsl_report_received,
            })
            dec_rows.append(dec_dict)
        data['acc_deceased'] = dec_rows
        data['deceased'] = dec_rows

        return data
