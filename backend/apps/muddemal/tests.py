from decimal import Decimal
from datetime import date, timedelta
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status

from apps.cases.models import CaseRecord
from apps.crimetab.models import SeizureRecords
from apps.muddemal.models import (
    MuddemalRegister,
    MuddemalPropertyCategory,
    MuddemalFieldDefinition,
    MuddemalProperty,
    MuddemalPropertyMovement,
    MuddemalFSLRecord,
    MuddemalDisposal,
    MuddemalAuditLog,
    MuddemalConfig,
)
from apps.muddemal.services.id_generator import (
    generate_unique_register_number,
    generate_unique_property_uid,
)
from apps.muddemal.services.valuation_service import (
    compute_item_value,
    calculate_register_valuations,
)
from apps.muddemal.services.cross_module_service import (
    discover_case_source_properties,
    link_source_property_to_muddemal,
)
from apps.muddemal.services.fsl_alert_service import get_fsl_alerts
from apps.muddemal.services.dashboard_service import (
    get_stolen_property_dashboard,
    get_seized_property_dashboard,
    get_pending_muddemal_dashboard,
    get_month_year_reports,
)


class MuddemalBackendTests(TestCase):
    @classmethod
    def setUpClass(cls):
        from django.db import connection
        if connection.connection and hasattr(connection.connection, 'closed') and connection.connection.closed:
            connection.connect()
        from apps.core.tenancy import _get_schema_stack, set_tenant_schema
        stack = _get_schema_stack()
        if not stack or stack[-1] != 'maharashtra':
            stack.append('maharashtra')
        set_tenant_schema('maharashtra')
        super().setUpClass()

    @classmethod
    def tearDownClass(cls):
        try:
            from apps.core.tenancy import set_tenant_schema, _get_schema_stack
            _get_schema_stack().clear()
            set_tenant_schema('public')
        except Exception:
            pass
        super().tearDownClass()

    def _pre_setup(self):
        from django.db import connection
        if connection.connection and hasattr(connection.connection, 'closed') and connection.connection.closed:
            connection.connect()
        from apps.core.tenancy import _get_schema_stack, set_tenant_schema
        stack = _get_schema_stack()
        if not stack or stack[-1] != 'maharashtra':
            stack.append('maharashtra')
        set_tenant_schema('maharashtra')
        super()._pre_setup()

    def setUp(self):
        from django.db import connection
        if connection.connection and hasattr(connection.connection, 'closed') and connection.connection.closed:
            connection.connect()
        from apps.core.tenancy import _get_schema_stack, set_tenant_schema
        stack = _get_schema_stack()
        if not stack or stack[-1] != 'maharashtra':
            stack.append('maharashtra')
        set_tenant_schema('maharashtra')

        self.client = APIClient()
        self.client.credentials(HTTP_X_TENANT_SCHEMA='maharashtra', HTTP_X_STATE_CODE='MH')

        # Ensure seed data exists FIRST so category foreign keys are present
        self.ensure_seed_data()

        # Create a sample CaseRecord
        self.case = CaseRecord.objects.create(
            id='test-cr-case-125',
            module_key='crime',
            title='Theft of Car and Gold',
            case_number='CR-125/2026',
            complainant='Suresh Patil',
            accused='Ramesh Shinde',
            station_name='Khadak Police Station',
            assigned_officer='PI Jadhav',
            assigned_officer_uid='io-jadhav-01',
            extra_fields={
                'stolenProperties': [
                    {
                        'property': 'Gold Chain 24K',
                        'description': '24 karat gold chain weighing 20g',
                        'quantity': '1',
                        'estValue': '120000',
                        'from': 'Complainant Residence',
                        'recovered': 'no',
                    }
                ]
            }
        )

    def tearDown(self):
        try:
            from apps.core.tenancy import _get_schema_stack, set_tenant_schema
            stack = _get_schema_stack()
            if not stack or stack[-1] != 'maharashtra':
                stack.append('maharashtra')
            set_tenant_schema('maharashtra')
        except Exception:
            pass
        super().tearDown()

    def ensure_seed_data(self):
        # 1. Configs
        MuddemalConfig.objects.get_or_create(
            config_key='fsl_alert_thresholds',
            defaults={'config_value': {'threshold_1_days': 7, 'threshold_2_days': 15, 'threshold_3_days': 30}}
        )
        MuddemalConfig.objects.get_or_create(
            config_key='property_statuses',
            defaults={'config_value': ['Seized', 'Recovered', 'Stolen – Not Recovered', 'Sent to FSL']}
        )
        MuddemalConfig.objects.get_or_create(
            config_key='measurement_units',
            defaults={'config_value': ['Numbers', 'Bottles', 'Litres', 'Grams', 'Kg']}
        )

        # 2. Categories
        cats = [
            ('VEHICLE', 'Vehicle', 1),
            ('ALCOHOL', 'Alcohol / Prohibition Property', 2),
            ('WEAPON', 'Weapon / Dangerous Article', 3),
            ('GAMBLING', 'Gambling Property', 4),
            ('CASH', 'Cash / Currency', 5),
            ('GOLD_SILVER', 'Gold / Silver / Jewellery', 6),
            ('ELECTRONIC', 'Electronic / Digital Device', 7),
            ('BIOLOGICAL_SAMPLE', 'Biological Sample', 8),
            ('STOLEN_PROPERTY', 'Stolen Property', 9),
            ('RECOVERED_STOLEN_PROPERTY', 'Recovered Stolen Property', 10),
            ('SEIZED_PROPERTY', 'Seized Property', 11),
        ]
        for code, name, order in cats:
            c, _ = MuddemalPropertyCategory.objects.get_or_create(
                category_code=code,
                defaults={'category_name': name, 'display_order': order, 'is_active': True}
            )
            # Add a field definition for testing
            MuddemalFieldDefinition.objects.get_or_create(
                category=c,
                field_key='registration_number' if code == 'VEHICLE' else 'description',
                defaults={'display_label': 'Test Field', 'field_type': 'text', 'is_required': True}
            )

    def test_01_categories_and_fields_api(self):
        """Verify dynamic property categories and category field definitions are fetched from backend."""
        res = self.client.get('/api/muddemal/categories/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(res.data), 11)

        # Check vehicle category fields
        res_fields = self.client.get('/api/muddemal/categories/VEHICLE/fields/')
        self.assertEqual(res_fields.status_code, status.HTTP_200_OK)
        self.assertTrue(res_fields.data['success'])
        self.assertEqual(res_fields.data['category_code'], 'VEHICLE')
        self.assertGreaterEqual(len(res_fields.data['fields']), 1)

    def test_02_config_tokens_api(self):
        """Verify all config tokens (thresholds, units, statuses) come dynamically from backend."""
        res = self.client.get('/api/muddemal/configs/')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(res.data['success'])
        configs = res.data['configs']
        self.assertIn('fsl_alert_thresholds', configs)
        self.assertEqual(configs['fsl_alert_thresholds']['threshold_1_days'], 7)

    def test_03_create_register_linked_to_cr(self):
        """Verify creation of Muddemal Register linked to a valid CR."""
        payload = {
            'cr_case_id': self.case.id,
            'station_name': self.case.station_name,
            'cr_number_snapshot': self.case.case_number,
            'remarks': 'Testing Register Creation',
        }
        res = self.client.post('/api/muddemal/registers/', payload, format='json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('muddemal_register_no', res.data)
        self.assertTrue(res.data['muddemal_register_no'].startswith('MUDD/'))
        self.assertEqual(res.data['station_name'], self.case.station_name)

    def test_04_multiple_properties_unique_uids_under_single_cr(self):
        """Verify adding multiple distinct properties under a single CR generates unique IDs."""
        reg = MuddemalRegister.objects.create(
            muddemal_register_no='MUDD/KHADAK/2026/0001',
            police_station_id='KHADAK',
            station_name='Khadak Police Station',
            cr_case=self.case,
            cr_number_snapshot='CR-125/2026',
        )

        veh_cat = MuddemalPropertyCategory.objects.get(category_code='VEHICLE')
        alc_cat = MuddemalPropertyCategory.objects.get(category_code='ALCOHOL')
        weap_cat = MuddemalPropertyCategory.objects.get(category_code='WEAPON')
        gold_cat = MuddemalPropertyCategory.objects.get(category_code='GOLD_SILVER')

        # Property 1: Vehicle (Single Car with manual valuation)
        p1_res = self.client.post('/api/muddemal/properties/', {
            'muddemal_record': reg.id,
            'category_code': 'VEHICLE',
            'description': 'Hyundai Creta MH12AB1234',
            'quantity': 1,
            'unit': 'Numbers',
            'unit_value': 0,
            'total_item_value': 850000.00,
            'seized_from': 'Ramesh Shinde',
            'extra_fields': {'registration_number': 'MH12AB1234', 'make': 'Hyundai'}
        }, format='json')
        self.assertEqual(p1_res.status_code, status.HTTP_201_CREATED)
        self.assertIn('CR-125/2026', p1_res.data['property_uid'])
        self.assertEqual(float(p1_res.data['total_item_value']), 850000.00)

        # Property 2: Alcohol (12 bottles x ₹200 = ₹2,400)
        p2_res = self.client.post('/api/muddemal/properties/', {
            'muddemal_record': reg.id,
            'category_code': 'ALCOHOL',
            'description': 'Desi Daaru Bottles',
            'quantity': 12,
            'unit': 'Bottles',
            'unit_value': 200.00,
            'total_item_value': 0, # Trigger backend auto-calculation
            'seized_from': 'Spot A',
        }, format='json')
        self.assertEqual(p2_res.status_code, status.HTTP_201_CREATED)
        self.assertIn('/P-02', p2_res.data['property_uid'])
        self.assertEqual(float(p2_res.data['total_item_value']), 2400.00)

        # Property 3: Weapon
        p3_res = self.client.post('/api/muddemal/properties/', {
            'muddemal_record': reg.id,
            'category_code': 'WEAPON',
            'description': 'Iron Knife 10 inches',
            'quantity': 1,
            'unit': 'Numbers',
            'unit_value': 500.00,
            'total_item_value': 500.00,
            'fsl_required': True,
        }, format='json')
        self.assertEqual(p3_res.status_code, status.HTTP_201_CREATED)
        self.assertIn('/P-03', p3_res.data['property_uid'])

        # Property 4: Gold Jewellery
        p4_res = self.client.post('/api/muddemal/properties/', {
            'muddemal_record': reg.id,
            'category_code': 'GOLD_SILVER',
            'description': 'Gold Ring 5g',
            'quantity': 1,
            'unit': 'Grams',
            'unit_value': 35000.00,
            'total_item_value': 35000.00,
        }, format='json')
        self.assertEqual(p4_res.status_code, status.HTTP_201_CREATED)
        self.assertIn('/P-04', p4_res.data['property_uid'])

        # Verify all 4 unique UIDs
        uids = [p1_res.data['property_uid'], p2_res.data['property_uid'], p3_res.data['property_uid'], p4_res.data['property_uid']]
        self.assertEqual(len(set(uids)), 4)

        # Verify Register Total
        reg_detail = self.client.get(f'/api/muddemal/registers/{reg.id}/')
        val = reg_detail.data['valuations']
        expected_total = 850000.00 + 2400.00 + 500.00 + 35000.00
        self.assertAlmostEqual(val['total_registered_value'], expected_total, places=2)

    def test_05_cross_module_discovery_and_idempotent_linking(self):
        """Verify cross-module discovery from SeizureRecords & Case JSON, and prevent duplicate links."""
        # Add a SeizureRecord in the DB
        SeizureRecords.objects.create(
            case=self.case,
            object_name='Country Pistol 7.65mm',
            description='Country-made pistol with one magazine',
            name='Kailash'
        )

        # Discover
        disc_res = self.client.get(f'/api/muddemal/cases/{self.case.id}/discoverable-properties/')
        self.assertEqual(disc_res.status_code, status.HTTP_200_OK)
        discovered = disc_res.data['discovered_properties']
        self.assertGreaterEqual(len(discovered), 2) # 1 from SeizureRecords, 1 from case stolenProperties

        # Link the pistol
        pistol_item = next(d for d in discovered if 'Pistol' in d['title'])
        link_res = self.client.post(f'/api/muddemal/cases/{self.case.id}/link-property/', {
            'source_module': pistol_item['source_module'],
            'source_record_id': pistol_item['source_record_id'],
            'description': pistol_item['description'],
            'category_code': 'WEAPON',
            'quantity': 1,
            'total_item_value': 25000,
        }, format='json')
        self.assertEqual(link_res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(link_res.data['is_newly_linked'])

        # Try linking the EXACT same pistol again -> must be idempotent, no duplicate!
        link_res2 = self.client.post(f'/api/muddemal/cases/{self.case.id}/link-property/', {
            'source_module': pistol_item['source_module'],
            'source_record_id': pistol_item['source_record_id'],
            'description': pistol_item['description'],
            'category_code': 'WEAPON',
            'quantity': 1,
            'total_item_value': 25000,
        }, format='json')
        self.assertEqual(link_res2.status_code, status.HTTP_200_OK)
        self.assertFalse(link_res2.data['is_newly_linked'])
        self.assertEqual(link_res2.data['property']['property_uid'], link_res.data['property']['property_uid'])

        # Re-verify discovery shows it as already linked
        disc_res2 = self.client.get(f'/api/muddemal/cases/{self.case.id}/discoverable-properties/')
        pistol_check = next(d for d in disc_res2.data['discovered_properties'] if 'Pistol' in d['title'])
        self.assertTrue(pistol_check['is_already_linked'])
        self.assertEqual(pistol_check['linked_property_uid'], link_res.data['property']['property_uid'])

    def test_06_stolen_property_recovery_calculation(self):
        """Verify stolen vs recovered property calculations, partial recovery, and recovery percentage."""
        reg = MuddemalRegister.objects.create(
            muddemal_register_no='MUDD/KHADAK/2026/0002',
            police_station_id='KHADAK',
            station_name='Khadak Police Station',
            cr_case=self.case,
            cr_number_snapshot='CR-125/2026',
        )
        stolen_cat = MuddemalPropertyCategory.objects.get(category_code='STOLEN_PROPERTY')

        # Stolen Item 1: ₹1,00,000 (Not recovered)
        MuddemalProperty.objects.create(
            property_uid='KHADAK/CR-125/2026/P-01',
            muddemal_record=reg,
            property_category=stolen_cat,
            description='Stolen Laptop Apple MacBook',
            quantity=1,
            total_item_value=Decimal('100000.00'),
            property_status='Stolen – Not Recovered',
        )

        # Stolen Item 2: ₹1,00,000 (Fully recovered)
        MuddemalProperty.objects.create(
            property_uid='KHADAK/CR-125/2026/P-02',
            muddemal_record=reg,
            property_category=stolen_cat,
            description='Stolen Cash INR',
            quantity=1,
            total_item_value=Decimal('100000.00'),
            property_status='Recovered',
        )

        val = calculate_register_valuations(reg)
        self.assertEqual(val['total_stolen_value'], 200000.00)
        self.assertEqual(val['recovered_property_value'], 100000.00)
        self.assertEqual(val['not_recovered_property_value'], 100000.00)
        self.assertEqual(val['recovery_percentage_numeric'], 50.0)
        self.assertEqual(val['recovery_percentage'], '50.00%')

    def test_07_fsl_alerts_and_resolution(self):
        """Verify FSL pending alerts at 7, 15, 30 days and resolution when report is received."""
        reg = MuddemalRegister.objects.create(
            muddemal_register_no='MUDD/KHADAK/2026/0003',
            police_station_id='KHADAK',
            station_name='Khadak Police Station',
            cr_case=self.case,
            cr_number_snapshot='CR-125/2026',
        )
        bio_cat = MuddemalPropertyCategory.objects.get(category_code='BIOLOGICAL_SAMPLE')

        # Property 1: FSL Required = True, but not dispatched, seized 20 days ago (Warning: >15 days)
        prop_fsl_pending = MuddemalProperty.objects.create(
            property_uid='KHADAK/CR-125/2026/P-01',
            muddemal_record=reg,
            property_category=bio_cat,
            description='Blood stained cloth sample',
            quantity=1,
            total_item_value=Decimal('0.00'),
            seizure_date=date.today() - timedelta(days=20),
            fsl_required=True,
            property_status='Seized',
        )

        alerts = get_fsl_alerts(station_name=reg.station_name)
        self.assertEqual(alerts['summary']['total_send_pending'], 1)
        self.assertEqual(alerts['summary']['warning_15_days'], 1)

        # Now dispatch Property 1 to FSL
        disp_res = self.client.post(f'/api/muddemal/properties/{prop_fsl_pending.id}/fsl/', {
            'fsl_reference_no': 'FSL/PUNE/2026/999',
            'dispatch_date': str(date.today()),
            'dispatch_details': 'Sent to FSL Pune via PC Shinde',
        }, format='json')
        self.assertEqual(disp_res.status_code, status.HTTP_201_CREATED)
        fsl_rec_id = disp_res.data['fsl_record']['id']

        # After dispatch, send_pending should be 0, report_pending should be 1
        alerts2 = get_fsl_alerts(station_name=reg.station_name)
        self.assertEqual(alerts2['summary']['total_send_pending'], 0)
        self.assertEqual(alerts2['summary']['total_report_pending'], 1)

        # Now receive the FSL report -> Alert resolves!
        rec_res = self.client.post(f'/api/muddemal/properties/{prop_fsl_pending.id}/fsl/', {
            'fsl_record_id': fsl_rec_id,
            'report_received_status': 'Received',
            'report_reference': 'REPORT-PUNE-2026-FINAL',
        }, format='json')
        self.assertEqual(rec_res.status_code, status.HTTP_201_CREATED)

        alerts3 = get_fsl_alerts(station_name=reg.station_name)
        self.assertEqual(alerts3['summary']['total_send_pending'], 0)
        self.assertEqual(alerts3['summary']['total_report_pending'], 0)

    def test_08_custody_movement_and_disposal_lifecycle(self):
        """Verify chain of custody movement history and final disposal/Supurdnama."""
        reg = MuddemalRegister.objects.create(
            muddemal_register_no='MUDD/KHADAK/2026/0004',
            police_station_id='KHADAK',
            station_name='Khadak Police Station',
            cr_case=self.case,
            cr_number_snapshot='CR-125/2026',
        )
        veh_cat = MuddemalPropertyCategory.objects.get(category_code='VEHICLE')

        prop = MuddemalProperty.objects.create(
            property_uid='KHADAK/CR-125/2026/P-01',
            muddemal_record=reg,
            property_category=veh_cat,
            description='Maruti Swift Car',
            quantity=1,
            total_item_value=Decimal('400000.00'),
            property_status='Seized',
        )

        # 1. Record movement to court
        m_res = self.client.post(f'/api/muddemal/properties/{prop.id}/movements/', {
            'from_location': 'Muddemal Room (मालखाना)',
            'to_location': 'JMFC Court Pune No. 3',
            'movement_type': 'Sent to Court',
            'responsible_officer': 'ASI More',
            'reference_no': 'OUT/2026/55',
            'new_property_status': 'Produced Before Court',
        }, format='json')
        self.assertEqual(m_res.status_code, status.HTTP_201_CREATED)
        from apps.core.tenancy import set_tenant_schema
        set_tenant_schema('maharashtra')
        prop.refresh_from_db()
        self.assertEqual(prop.property_status, 'Produced Before Court')

        # 2. Record Supurdnama return to owner as per court order
        disp_res = self.client.post(f'/api/muddemal/properties/{prop.id}/disposal/', {
            'disposal_type': 'Supurdnama',
            'court_order_reference': 'COURT/CR125/ORDER/2026',
            'owner_recipient_details': {'name': 'Suresh Patil', 'contact': '9876543210'},
            'supurdnama_details': {'bond_amount': 400000, 'condition': 'Produce when called'},
        }, format='json')
        self.assertEqual(disp_res.status_code, status.HTTP_201_CREATED)
        set_tenant_schema('maharashtra')
        prop.refresh_from_db()
        self.assertEqual(prop.property_status, 'Released on Supurdnama')

        # 3. Check Audit Trail
        audit_res = self.client.get(f'/api/muddemal/properties/{prop.id}/audit-trail/')
        self.assertEqual(audit_res.status_code, status.HTTP_200_OK)
        actions = [a['action'] for a in audit_res.data['audit_trail']]
        self.assertIn('CUSTODY_MOVEMENT', actions)
        self.assertIn('DISPOSAL_RECORDED', actions)

    def test_09_dashboards_endpoints(self):
        """Verify Stolen, Seized, Pending, and Monthly/Yearly dashboard APIs."""
        stolen_dash = self.client.get('/api/muddemal/dashboards/stolen/')
        self.assertEqual(stolen_dash.status_code, status.HTTP_200_OK)
        self.assertIn('total_theft_cases', stolen_dash.data['dashboard'])

        seized_dash = self.client.get('/api/muddemal/dashboards/seized/')
        self.assertEqual(seized_dash.status_code, status.HTTP_200_OK)
        self.assertIn('total_seized_property_value', seized_dash.data['dashboard'])
        self.assertIn('vehicles_seized', seized_dash.data['dashboard'])

        pending_dash = self.client.get('/api/muddemal/dashboards/pending/')
        self.assertEqual(pending_dash.status_code, status.HTTP_200_OK)
        self.assertIn('fsl_send_pending_count', pending_dash.data['dashboard'])

        my_dash = self.client.get('/api/muddemal/dashboards/monthly-yearly/')
        self.assertEqual(my_dash.status_code, status.HTTP_200_OK)
        self.assertIn('monthly_report', my_dash.data['report'])
        self.assertEqual(len(my_dash.data['report']['monthly_report']), 12)

    def test_10_autofetch_cross_module_crime_prohibition_gambling(self):
        """
        Verify that qualifying seized properties recorded in Crime, Prohibition,
        Gambling, and other source modules appear automatically in Muddemal.
        """
        station = 'Shivajinagar Police Station'

        # 1. Crime module case with SeizureRecord
        crime_case = CaseRecord.objects.create(
            id='case-crime-auto-1',
            module_key='crime',
            sub_category='Hurt',
            title='Assault with Iron Rod',
            case_number='CR-201/2026',
            station_name=station,
            complainant='Rahul Kadam',
            accused='Sunil Pawar',
        )
        SeizureRecords.objects.create(
            case=crime_case,
            description='Iron rod 3 feet long used in assault',
            object_name='Iron Rod',
            name='Sunil Pawar',
        )

        # 2. Prohibition module case with seized liquor
        prohib_case = CaseRecord.objects.create(
            id='case-prohib-auto-1',
            module_key='prohibition',
            sub_category='Prohibition',
            title='Raid on Illegal Liquor Den',
            case_number='CR-202/2026',
            station_name=station,
            complainant='State on complaint of PSI Mane',
            accused='Baburao Shinde',
            extra_fields={
                'prohibition_details': {
                    'liquor_type': 'Desi Daru',
                    'bottles': 48,
                    'value': 4800,
                }
            }
        )

        # 3. Gambling module case with seized cash and playing cards
        gambling_case = CaseRecord.objects.create(
            id='case-gambling-auto-1',
            module_key='gambling',
            sub_category='Gambling',
            title='Matka Club Raid',
            case_number='CR-203/2026',
            station_name=station,
            complainant='State on complaint of PI Kulkarni',
            accused='Anil Gaikwad',
            extra_fields={
                'gambling_details': {
                    'cash_amount': 25000,
                    'articles': '52 Playing cards and betting charts',
                }
            }
        )

        # Query centralized Muddemal properties API
        res = self.client.get(f'/api/muddemal/properties/?station_name={station}')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        props = res.data['results'] if 'results' in res.data else res.data

        # Verify Crime property was auto-fetched
        crime_props = [p for p in props if p['cr_number'] == 'CR-201/2026']
        self.assertEqual(len(crime_props), 1)
        self.assertIn('Iron rod', crime_props[0]['description'])
        self.assertEqual(crime_props[0]['category_code'], 'WEAPON')
        self.assertEqual(crime_props[0]['source_module'], 'crime')
        self.assertTrue('CR-201/2026' in crime_props[0]['property_uid'])

        # Verify Prohibition property was auto-fetched
        proh_props = [p for p in props if p['cr_number'] == 'CR-202/2026']
        self.assertEqual(len(proh_props), 1)
        self.assertEqual(proh_props[0]['category_code'], 'ALCOHOL')
        self.assertEqual(proh_props[0]['source_module'], 'prohibition')
        self.assertTrue(proh_props[0]['fsl_required'])
        self.assertEqual(float(proh_props[0]['total_item_value']), 4800.0)

        # Verify Gambling properties were auto-fetched (Cash and Articles)
        gamb_props = [p for p in props if p['cr_number'] == 'CR-203/2026']
        self.assertEqual(len(gamb_props), 2)
        cash_prop = next(p for p in gamb_props if p['category_code'] == 'CASH')
        self.assertEqual(float(cash_prop['total_item_value']), 25000.0)
        self.assertEqual(cash_prop['source_module'], 'gambling')

    def test_11_autofetch_duplicate_prevention_on_repeated_query(self):
        """
        Verify that repeat refreshes and repeated sync calls do NOT duplicate
        properties or inflate dashboard valuations.
        """
        station = 'Deccan Police Station'
        case = CaseRecord.objects.create(
            id='case-deccan-dup-1',
            module_key='crime',
            sub_category='Theft',
            title='House Break-in Deccan',
            case_number='CR-301/2026',
            station_name=station,
            extra_fields={
                'stolenProperties': [
                    {'property': 'Diamond Ring', 'estValue': 50000, 'recovered': 'yes'}
                ]
            }
        )

        # First fetch
        res1 = self.client.get(f'/api/muddemal/properties/?station_name={station}')
        self.assertEqual(res1.status_code, status.HTTP_200_OK)
        count1 = res1.data['count'] if 'count' in res1.data else len(res1.data)
        self.assertEqual(count1, 1)

        # Repeat query 5 times in succession
        for _ in range(5):
            res_repeat = self.client.get(f'/api/muddemal/properties/?station_name={station}')
            count_repeat = res_repeat.data['count'] if 'count' in res_repeat.data else len(res_repeat.data)
            self.assertEqual(count_repeat, 1)

        # Explicit manual sync action
        sync_res = self.client.post(f'/api/muddemal/properties/sync/', {'station_name': station}, format='json')
        self.assertEqual(sync_res.status_code, status.HTTP_200_OK)

        # Query again — count must STILL be exactly 1!
        final_res = self.client.get(f'/api/muddemal/properties/?station_name={station}')
        final_count = final_res.data['count'] if 'count' in final_res.data else len(final_res.data)
        self.assertEqual(final_count, 1)

    def test_12_autofetch_station_access_control(self):
        """
        Verify that queries for a specific station only return properties
        originating from cases belonging to that station.
        """
        # Case in Station Alpha
        CaseRecord.objects.create(
            id='case-station-a',
            module_key='crime',
            title='Theft at Alpha',
            case_number='CR-A/2026',
            station_name='Station Alpha',
            extra_fields={'stolenProperties': [{'property': 'Laptop Alpha', 'estValue': 60000}]}
        )

        # Case in Station Beta
        CaseRecord.objects.create(
            id='case-station-b',
            module_key='prohibition',
            title='Raid at Beta',
            case_number='CR-B/2026',
            station_name='Station Beta',
            extra_fields={'prohibition_details': {'liquor_type': 'Beer', 'bottles': 10, 'value': 2000}}
        )

        # Query Alpha
        res_a = self.client.get('/api/muddemal/properties/?station_name=Station Alpha')
        props_a = res_a.data['results'] if 'results' in res_a.data else res_a.data
        for p in props_a:
            self.assertEqual(p['station_name'], 'Station Alpha')
            self.assertNotEqual(p['station_name'], 'Station Beta')

        # Query Beta
        res_b = self.client.get('/api/muddemal/properties/?station_name=Station Beta')
        props_b = res_b.data['results'] if 'results' in res_b.data else res_b.data
        for p in props_b:
            self.assertEqual(p['station_name'], 'Station Beta')
            self.assertNotEqual(p['station_name'], 'Station Alpha')

    def test_13_update_source_property_reflects_in_muddemal(self):
        """
        Verify that updates to source property description, valuation, or status
        in source modules automatically reflect in Muddemal without creating duplicates.
        """
        station = 'Kothrud Police Station'
        case = CaseRecord.objects.create(
            id='case-kothrud-update-1',
            module_key='crime',
            sub_category='Theft',
            title='Gold Ring Theft',
            case_number='CR-401/2026',
            station_name=station,
            extra_fields={
                'stolenProperties': [
                    {'property': 'Gold Ring 5g', 'estValue': 25000, 'recovered': 'no'}
                ]
            }
        )

        # Initial fetch
        res1 = self.client.get(f'/api/muddemal/properties/?station_name={station}')
        props1 = res1.data['results'] if 'results' in res1.data else res1.data
        self.assertEqual(len(props1), 1)
        prop_uid = props1[0]['property_uid']
        self.assertEqual(float(props1[0]['total_item_value']), 25000.0)
        self.assertEqual(props1[0]['property_status'], 'Stolen – Not Recovered')

        # Update source property (recovered = yes, valuation = 30000)
        case.extra_fields = {
            'stolenProperties': [
                {'property': 'Gold Ring 5g (Recovered)', 'estValue': 30000, 'recovered': 'yes'}
            ]
        }
        case.save()

        # Refresh / re-query Muddemal
        res2 = self.client.get(f'/api/muddemal/properties/?station_name={station}')
        props2 = res2.data['results'] if 'results' in res2.data else res2.data

        # Must still be exactly 1 property with the SAME UID
        self.assertEqual(len(props2), 1)
        self.assertEqual(props2[0]['property_uid'], prop_uid)
        self.assertIn('Recovered', props2[0]['description'])
        self.assertEqual(props2[0]['category_code'], 'RECOVERED_STOLEN_PROPERTY')
        self.assertEqual(props2[0]['property_status'], 'Recovered')


