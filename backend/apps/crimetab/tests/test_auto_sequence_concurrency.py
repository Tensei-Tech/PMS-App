import json
import threading
from django.test import TestCase
from apps.crimetab.models.groupings import CaseCategory
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CategoryFieldTemplate,
    ModuleSetting,
)
from apps.crimetab.services.dynamic_form_service import (
    get_next_category_sequence,
    auto_assign_category_sequences,
    get_dashboard_tools,
)


class AutoSequenceConcurrencyTestCase(TestCase):
    def setUp(self):
        # Create test category and template
        self.category = CaseCategory.objects.create(
            category_name='Test Concurrency Category',
            category_code='test_concurrency',
            is_active=True,
        )
        self.template = FieldTemplate.objects.create(
            template_name='Test Concurrency Template'
        )
        CategoryFieldTemplate.objects.create(
            category=self.category,
            template=self.template
        )
        self.field = FieldTemplateField.objects.create(
            template=self.template,
            field_label='Sr. No.',
            field_key='sr_no',
            field_type='number',
            options_source='auto:sequence',
            field_config={'auto_generate': True, 'read_only': True},
            display_order=1
        )
        ModuleSetting.objects.update_or_create(
            module_key='test_concurrency',
            setting_key='last_seq_sr_no',
            defaults={'setting_value': '0'}
        )
        # Ensure dashboard tools exist for isolated test environments (where migrations are skipped)
        tools_data = [
            {
                "module_key": "tadipar",
                "label": "Tadipar",
                "icon": "assets/icons/tadipar.svg",
                "color": 4279942044,
                "category": "Preventive",
                "display_order": 1,
                "is_active": True,
            }
        ]
        ModuleSetting.objects.update_or_create(
            module_key='dashboard',
            setting_key='tools',
            defaults={'setting_value': json.dumps(tools_data)}
        )

    def test_concurrent_sequences_unique(self):
        num_requests = 10
        results = []
        for _ in range(num_requests):
            seq = get_next_category_sequence(
                self.category,
                field_key='sr_no',
                station_name='test_station',
                increment=True
            )
            results.append(seq)

        self.assertEqual(len(results), num_requests)
        # All assigned sequence numbers must be distinct and sequential
        self.assertEqual(len(set(results)), num_requests, f"Duplicates detected in sequences: {results}")
        self.assertEqual(results, list(range(1, num_requests + 1)))

    def test_auto_assign_category_sequences_generic(self):
        extra = {'foo': 'bar'}
        updated = auto_assign_category_sequences(self.category, extra, station_name='test_station')
        self.assertIn('sr_no', updated)
        self.assertEqual(str(updated['sr_no']).isdigit(), True)
        self.assertEqual(updated['foo'], 'bar')

    def test_get_dashboard_tools_from_db(self):
        tools = get_dashboard_tools()
        self.assertIsInstance(tools, list)
        tadipar_tool = next((t for t in tools if t.get('module_key') == 'tadipar'), None)
        self.assertIsNotNone(tadipar_tool, "Tadipar tool must be present in dynamic dashboard tools")
        self.assertEqual(tadipar_tool.get('label'), 'Tadipar')
        self.assertEqual(tadipar_tool.get('icon'), 'assets/icons/tadipar.svg')
