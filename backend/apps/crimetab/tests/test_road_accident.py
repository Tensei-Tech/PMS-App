import json
from django.test import TestCase
from django.db import connection
from apps.core.tenancy import TenantContext
from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategory
from apps.crimetab.models.dynamic_engine import OptionValue
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.models.accident import (
    RoadAccidentRecord,
    RoadAccidentVehicle,
    RoadAccidentInjured,
    RoadAccidentDeceased,
)
from apps.crimetab.serializers import FullCaseDetailSerializer, CaseListSerializer
from apps.crimetab.views import _save_case_child_entities


class RoadAccidentTestCase(TestCase):
    databases = ['default']

    def setUp(self):
        super().setUp()
        nature_opts = [
            'Collision', 'Pedestrian hit', 'Overturning', 'Over speed',
            'Dangerous overtaking', 'Wrong side driving', 'Fall',
            'Stationary vehicle', 'Other'
        ]
        for idx, opt in enumerate(nature_opts, 1):
            OptionValue.objects.get_or_create(
                option_group='nature_of_accident',
                option_value=opt,
                defaults={'display_order': idx, 'is_active': True}
            )

        co_opts = [
            'Maruti Suzuki', 'Tata Motors', 'Hyundai', 'Mahindra', 'Honda',
            'Toyota', 'Kia', 'Bajaj', 'Hero', 'TVS', 'Yamaha', 'Other'
        ]
        for idx, opt in enumerate(co_opts, 1):
            OptionValue.objects.get_or_create(
                option_group='accident_vehicle_company',
                option_value=opt,
                defaults={'display_order': idx, 'is_active': True}
            )

    def test_01_public_form_definition_for_road_accident_categories(self):
        """Verify get_form_definition returns the 46 accident fields for all road accident categories."""
        accident_codes = ['ACC_ROAD', 'ACC_RASH', 'ACC_OTHER', 'STAND_ACC_ROAD', 'STAND_ACC_RASH', 'STAND_ACC_OTHER']
        for code in accident_codes:
            cat = CaseCategory.objects.filter(category_code=code).first()
            if not cat:
                continue
            form_def = get_form_definition(cat.category_id)
            field_keys = {f['field_key'] for f in form_def.get('fields', [])}
            
            # Check requested accident fields exist
            self.assertIn('acc_vehicle_abandoned', field_keys, f"Missing acc_vehicle_abandoned in {code}")
            self.assertIn('acc_driver_subsequently_traced', field_keys, f"Missing acc_driver_subsequently_traced in {code}")
            self.assertIn('acc_nature_of_accident', field_keys, f"Missing acc_nature_of_accident in {code}")
            self.assertIn('acc_nature_of_accident_other', field_keys, f"Missing acc_nature_of_accident_other in {code}")
            
            # Repeating groups
            self.assertIn('acc_vehicles', field_keys, f"Missing acc_vehicles in {code}")
            self.assertIn('acc_veh_number', field_keys, f"Missing acc_veh_number in {code}")
            self.assertIn('acc_veh_name', field_keys, f"Missing acc_veh_name in {code}")
            self.assertIn('acc_veh_company', field_keys, f"Missing acc_veh_company in {code}")
            self.assertIn('acc_veh_company_other', field_keys, f"Missing acc_veh_company_other in {code}")
            self.assertIn('acc_veh_model', field_keys, f"Missing acc_veh_model in {code}")
            self.assertIn('acc_veh_owner_details', field_keys, f"Missing acc_veh_owner_details in {code}")
            self.assertIn('acc_veh_driver_details', field_keys, f"Missing acc_veh_driver_details in {code}")
            
            self.assertIn('acc_injured', field_keys, f"Missing acc_injured in {code}")
            self.assertIn('acc_inj_name', field_keys, f"Missing acc_inj_name in {code}")
            self.assertIn('acc_inj_age', field_keys, f"Missing acc_inj_age in {code}")
            self.assertIn('acc_inj_gender', field_keys, f"Missing acc_inj_gender in {code}")
            self.assertIn('acc_inj_death', field_keys, f"Missing acc_inj_death in {code}")
            self.assertIn('acc_inj_death_date', field_keys, f"Missing acc_inj_death_date in {code}")
            
            self.assertIn('acc_deceased', field_keys, f"Missing acc_deceased in {code}")
            self.assertIn('acc_dec_name', field_keys, f"Missing acc_dec_name in {code}")
            self.assertIn('acc_dec_post_mortem', field_keys, f"Missing acc_dec_post_mortem in {code}")
            self.assertIn('acc_dec_pm_report_received', field_keys, f"Missing acc_dec_pm_report_received in {code}")
            self.assertIn('acc_dec_viscera_sent_fsl', field_keys, f"Missing acc_dec_viscera_sent_fsl in {code}")
            self.assertIn('acc_dec_fsl_report_received', field_keys, f"Missing acc_dec_fsl_report_received in {code}")
            
            self.assertIn('acc_victim_identity_established', field_keys, f"Missing acc_victim_identity_established in {code}")
            self.assertIn('acc_eyewitnesses_identity', field_keys, f"Missing acc_eyewitnesses_identity in {code}")
            self.assertIn('acc_irad', field_keys, f"Missing acc_irad in {code}")
            self.assertIn('acc_irad_date', field_keys, f"Missing acc_irad_date in {code}")
            self.assertIn('acc_dar', field_keys, f"Missing acc_dar in {code}")
            self.assertIn('acc_dar_date', field_keys, f"Missing acc_dar_date in {code}")

    def test_02_option_values_in_public_schema(self):
        """Verify option values for nature_of_accident and accident_vehicle_company."""
        nature_opts = list(OptionValue.objects.filter(option_group='nature_of_accident').values_list('option_value', flat=True))
        expected_nature = [
            'Collision', 'Pedestrian hit', 'Overturning', 'Over speed',
            'Dangerous overtaking', 'Wrong side driving', 'Fall',
            'Stationary vehicle', 'Other'
        ]
        for opt in expected_nature:
            self.assertIn(opt, nature_opts)

        co_opts = list(OptionValue.objects.filter(option_group='accident_vehicle_company').values_list('option_value', flat=True))
        self.assertIn('Other', co_opts)
        self.assertIn('Tata Motors', co_opts)

    def test_03_save_case_with_accident_child_entities_and_hydration(self):
        """Verify persistence into maharashtra tables and serialization via FullCaseDetailSerializer."""
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='ACC_TEST_001',
                case_number='CR/2026/ACC/101',
                title='Accident on Highway',
                sub_category='Death Due to Rash Driving',
                module_key='form_1_5',
                station_name='Central Police Station',
                extra_fields={}
            )

            payload = {
                'acc_nature_of_accident': 'Collision',
                'acc_vehicle_abandoned': 'Yes',
                'acc_driver_subsequently_traced': 'No',
                'acc_victim_identity_established': 'Yes',
                'acc_eyewitnesses_identity': 'Yes',
                'acc_irad': 'Yes',
                'acc_irad_date': '14/10/2026',
                'acc_dar': 'Yes',
                'acc_dar_date': '15/10/2026',
                'acc_vehicles': [
                    {
                        'acc_veh_number': 'MH-12-AB-1234',
                        'acc_veh_name': 'Harrier',
                        'acc_veh_company': 'Tata Motors',
                        'acc_veh_model': 'XZ+',
                        'acc_veh_owner_details': 'Ramesh Kumar, Pune',
                        'acc_veh_driver_details': 'Suresh Patil, Mumbai'
                    }
                ],
                'acc_injured': [
                    {
                        'acc_inj_name': 'Amit Verma',
                        'acc_inj_age': '32',
                        'acc_inj_gender': 'Male',
                        'acc_inj_address': 'Shivaji Nagar, Pune',
                        'acc_inj_occupation': 'Business',
                        'acc_inj_mobile': '9876543210',
                        'acc_inj_death': 'No'
                    }
                ],
                'acc_deceased': [
                    {
                        'acc_dec_name': 'Kishore Shinde',
                        'acc_dec_age': '45',
                        'acc_dec_gender': 'Male',
                        'acc_dec_address': 'Hadapsar, Pune',
                        'acc_dec_occupation': 'Driver',
                        'acc_dec_post_mortem': 'Yes',
                        'acc_dec_pm_report_received': 'Yes',
                        'acc_dec_viscera_sent_fsl': 'Yes',
                        'acc_dec_fsl_report_received': 'No'
                    }
                ]
            }

            _save_case_child_entities(case, payload)

            # Check database persistence in tenant schema
            acc_rec = RoadAccidentRecord.objects.filter(case_id='ACC_TEST_001').first()
            self.assertIsNotNone(acc_rec)
            self.assertEqual(acc_rec.nature_of_accident, 'Collision')
            self.assertEqual(acc_rec.vehicle_abandoned, 'Yes')
            self.assertEqual(acc_rec.driver_subsequently_traced, 'No')
            self.assertEqual(acc_rec.victim_identity_established, 'Yes')

            vehs = list(acc_rec.vehicles.all())
            self.assertEqual(len(vehs), 1)
            self.assertEqual(vehs[0].vehicle_number, 'MH-12-AB-1234')
            self.assertEqual(vehs[0].company_name, 'Tata Motors')

            injs = list(acc_rec.injured_persons.all())
            self.assertEqual(len(injs), 1)
            self.assertEqual(injs[0].name, 'Amit Verma')
            self.assertEqual(injs[0].age, 32)

            decs = list(acc_rec.deceased_persons.all())
            self.assertEqual(len(decs), 1)
            self.assertEqual(decs[0].name, 'Kishore Shinde')
            self.assertEqual(decs[0].post_mortem, 'Yes')

            # Verify FullCaseDetailSerializer hydration
            serializer = FullCaseDetailSerializer(case)
            data = serializer.data
            self.assertIn('road_accident', data)
            self.assertIn('extra_fields', data)
            extra = data['extra_fields']

            self.assertEqual(extra.get('acc_nature_of_accident'), 'Collision')
            self.assertEqual(extra.get('acc_vehicle_abandoned'), 'Yes')
            self.assertEqual(len(extra.get('acc_vehicles', [])), 1)
            self.assertEqual(extra['acc_vehicles'][0]['acc_veh_number'], 'MH-12-AB-1234')
            self.assertEqual(len(extra.get('acc_injured', [])), 1)
            self.assertEqual(extra['acc_injured'][0]['acc_inj_name'], 'Amit Verma')
            self.assertEqual(len(extra.get('acc_deceased', [])), 1)
            self.assertEqual(extra['acc_deceased'][0]['acc_dec_name'], 'Kishore Shinde')

            # Verify CaseListSerializer hydration
            list_serializer = CaseListSerializer(case)
            list_data = list_serializer.data
            self.assertIn('extra_fields', list_data)
            self.assertEqual(list_data['extra_fields'].get('acc_nature_of_accident'), 'Collision')
            self.assertEqual(len(list_data['extra_fields'].get('acc_vehicles', [])), 1)

    def test_05_datetime_and_spot_saved_in_table_not_json(self):
        """Date & Time of Accident and Accident Spot go to road_accident_records; no JSON copy remains."""
        with TenantContext('maharashtra'):
            values = {
                'accident_datetime': '14/10/2026 18:45',
                'accident_spot': 'Pune-Satara Highway, near toll plaza',
                'acc_nature_of_accident': 'Collision',
                'acc_vehicles': [{'acc_veh_number': 'MH-12-XY-9999'}],
            }
            case = CaseRecord.objects.create(
                id='ACC_TEST_DT', case_number='CR/2026/ACC/DT', title='TEST',
                sub_category='Road Accident', module_key='form_1_5',
                station_name='Central Police Station',
                extra_fields={**values, 'keep_me': 'yes', 'extra_field_values': dict(values)},
            )
            _save_case_child_entities(case, {**values, 'extra_fields': dict(case.extra_fields)})

            rec = RoadAccidentRecord.objects.get(case_id='ACC_TEST_DT')
            self.assertEqual(rec.accident_spot, 'Pune-Satara Highway, near toll plaza')
            from django.utils import timezone
            self.assertEqual(timezone.localtime(rec.accident_datetime).strftime('%d/%m/%Y %H:%M'),
                             '14/10/2026 18:45')

            case.refresh_from_db()
            self.assertEqual(case.extra_fields.get('keep_me'), 'yes')
            for key in values:
                self.assertNotIn(key, case.extra_fields)
                self.assertNotIn(key, case.extra_fields['extra_field_values'])
            from apps.crimetab.models import CaseExtraFieldValue
            self.assertFalse(CaseExtraFieldValue.objects.filter(
                case=case, field_def__field_key__in=list(values)).exists())

            extra = FullCaseDetailSerializer(case).data['extra_fields']
            self.assertEqual(extra['accident_datetime'], '14/10/2026 18:45')
            self.assertEqual(extra['accident_spot'], 'Pune-Satara Highway, near toll plaza')
            self.assertEqual(extra['acc_vehicles'][0]['acc_veh_number'], 'MH-12-XY-9999')


class RoadAccidentCaseLinkTests(TestCase):
    """Accident rows are tied to their case by a real foreign key (migration 0174)."""

    def _case(self, case_id='ACC_FK_1'):
        return CaseRecord.objects.create(
            id=case_id, case_number=f'CR/{case_id}', title='TEST', sub_category='Road Accident',
            module_key='form_1_5', station_name='Central Police Station', extra_fields={},
        )

    def _accident_with_children(self, case):
        rec = RoadAccidentRecord.objects.create(case=case, station_name=case.station_name)
        RoadAccidentVehicle.objects.create(accident_record=rec, case=case, vehicle_number='MH-12-FK-1')
        RoadAccidentInjured.objects.create(accident_record=rec, case=case, name='TEST Injured')
        RoadAccidentDeceased.objects.create(accident_record=rec, case=case, name='TEST Deceased')
        return rec

    def test_deleting_case_deletes_accident_and_children(self):
        with TenantContext('maharashtra'):
            case = self._case()
            self._accident_with_children(case)
            other = self._case('ACC_FK_KEEP')
            self._accident_with_children(other)

            case.delete()

            for model in (RoadAccidentRecord, RoadAccidentVehicle, RoadAccidentInjured, RoadAccidentDeceased):
                self.assertFalse(model.objects.filter(case_id='ACC_FK_1').exists(), model.__name__)
                self.assertTrue(model.objects.filter(case_id='ACC_FK_KEEP').exists(), model.__name__)

    def test_case_id_still_reads_and_filters_as_text(self):
        with TenantContext('maharashtra'):
            case = self._case()
            rec = self._accident_with_children(case)
            self.assertEqual(rec.case_id, 'ACC_FK_1')
            self.assertEqual(RoadAccidentRecord.objects.get(case_id='ACC_FK_1'), rec)
            self.assertEqual(case.road_accident, rec)

    def test_database_refuses_unknown_case(self):
        from django.db import IntegrityError, transaction
        with TenantContext('maharashtra'):
            with self.assertRaises(IntegrityError), transaction.atomic():
                RoadAccidentRecord.objects.create(case_id='NO_SUCH_CASE')
                connection.check_constraints()

    def test_api_serializer_checks_case_id(self):
        from apps.crimetab.serializers_accident import RoadAccidentRecordSerializer
        with TenantContext('maharashtra'):
            self._case()
            bad = RoadAccidentRecordSerializer(data={'case_id': 'NO_SUCH_CASE'})
            self.assertFalse(bad.is_valid())
            self.assertIn('case_id', bad.errors)

            good = RoadAccidentRecordSerializer(data={'case_id': 'ACC_FK_1', 'accident_spot': 'TEST spot'})
            self.assertTrue(good.is_valid(), good.errors)
            rec = good.save()
            self.assertEqual(rec.case_id, 'ACC_FK_1')
            self.assertEqual(RoadAccidentRecordSerializer(rec).data['case_id'], 'ACC_FK_1')

            standalone = RoadAccidentRecordSerializer(data={'accident_spot': 'TEST no case'})
            self.assertTrue(standalone.is_valid(), standalone.errors)
            self.assertIsNone(standalone.save().case_id)
