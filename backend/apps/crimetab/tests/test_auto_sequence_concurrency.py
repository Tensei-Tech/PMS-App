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

    def test_concurrent_sequences_unique(self):
        num_threads = 10
        results = []
        errors = []

        def worker():
            try:
                seq = get_next_category_sequence(
                    self.category,
                    field_key='sr_no',
                    station_name='test_station',
                    increment=True
                )
                results.append(seq)
            except Exception as e:
                errors.append(e)

        threads = [threading.Thread(target=worker) for _ in range(num_threads)]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        self.assertEqual(len(errors), 0, f"Errors occurred during concurrency test: {errors}")
        self.assertEqual(len(results), num_threads)
        # All assigned sequence numbers must be distinct
        self.assertEqual(len(set(results)), num_threads, f"Duplicates detected in sequences: {results}")

    def test_auto_assign_category_sequences_generic(self):
        extra = {'foo': 'bar'}
        updated = auto_assign_category_sequences(self.category, extra, station_name='test_station')
        self.assertIn('sr_no', updated)
        self.assertTrue(updated['sr_no'].isdigit())
        self.assertEqual(updated['foo'], 'bar')

    def test_get_dashboard_tools_from_db(self):
        tools = get_dashboard_tools()
        self.assertIsInstance(tools, list)
        tadipar_tool = next((t for t in tools if t.get('module_key') == 'tadipar'), None)
        self.assertIsNotNone(tadipar_tool, "Tadipar tool must be present in dynamic dashboard tools")
        self.assertEqual(tadipar_tool.get('label'), 'Tadipar')
        self.assertEqual(tadipar_tool.get('icon'), 'assets/icons/tadipar.svg')

