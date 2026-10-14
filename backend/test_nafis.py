import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.utils import get_cases_by_status
from apps.cases.models import CaseRecord
from apps.cases.views import NAFISCaseWiseView

try:
    # Cleanup any leftover test cases
    CaseRecord.objects.filter(case_number__startswith="TEST_").delete()

    print("Testing NAFIS logic according to requirements...")
    # 1. NAFIS marked as No without date -> Pending
    c_pending = CaseRecord.objects.create(
        case_number="TEST_NAFIS_PENDING",
        extra_fields={
            "investigationNotes": {
                "fingerprintVal": "no",
                "nafisFingerprint": "no"
            }
        }
    )

    # 2. NAFIS marked as Yes with date -> Completed
    c_completed = CaseRecord.objects.create(
        case_number="TEST_NAFIS_COMPLETED",
        extra_fields={
            "investigationNotes": {
                "fingerprintVal": "yes",
                "fingerprintDate": "12/10/2026",
                "nafisFingerprint": "yes",
                "nafisDate": "12/10/2026"
            }
        }
    )

    # 3. Unrelated case with no fingerprint tracking
    c_unrelated = CaseRecord.objects.create(
        case_number="TEST_UNRELATED",
        extra_fields={"category": "general"}
    )

    qs = get_cases_by_status('nafis')
    matched = list(qs.filter(case_number__startswith="TEST_").values_list('case_number', flat=True))
    print("Matched NAFIS cases:", matched)

    assert "TEST_NAFIS_PENDING" in matched, "Pending NAFIS case should be included in NAFIS tab"
    assert "TEST_NAFIS_COMPLETED" in matched, "Completed NAFIS case should be included in NAFIS tab"
    assert "TEST_UNRELATED" not in matched, "Unrelated case should not be in NAFIS tab"

    # Test enrichment logic
    test_data = [
        {'id': c_pending.id, 'case_number': c_pending.case_number, 'extra_fields': c_pending.extra_fields, 'assigned_officer': 'PSI Sharma'},
        {'id': c_completed.id, 'case_number': c_completed.case_number, 'extra_fields': c_completed.extra_fields, 'assigned_officer': 'PI Patil'},
    ]
    view = NAFISCaseWiseView()
    view._enrich_data(test_data)

    print("Enriched pending case:", test_data[0]['extra_fields'])
    print("Enriched completed case:", test_data[1]['extra_fields'])

    assert test_data[0]['extra_fields']['nafis_status'] == 'Pending'
    assert test_data[0]['extra_fields']['nafis_status_color'] == 'red'
    assert test_data[1]['extra_fields']['nafis_status'] == 'Done'
    assert test_data[1]['extra_fields']['nafis_status_color'] == 'green'

    # Test serializer formatting of section_act and status
    from apps.cases.serializers import NafisCaseRecordSerializer, format_section_act
    
    # 1. Dummy None acts_sections
    dummy_acts = [{'act': None, 'act_id': None, 'section': None, 'act_name': None, 'section_id': None, 'subsection': None, 'section_title': None, 'subsection_id': None, 'section_number': None, 'subsection_code': None}]
    assert format_section_act(dummy_acts) == '', f"Expected empty string for dummy acts, got {format_section_act(dummy_acts)}"
    assert format_section_act(str(dummy_acts)) == '', f"Expected empty string for stringified dummy acts, got {format_section_act(str(dummy_acts))}"

    # 2. Valid acts_sections
    valid_acts = [{'act_name': 'Indian Penal Code', 'section_number': '302'}]
    assert format_section_act(valid_acts) == 'IPC 302', f"Expected 'IPC 302', got {format_section_act(valid_acts)}"
    
    bns_acts = [{'act_name': 'Bharatiya Nyaya Sanhita, 2023', 'section_number': '103', 'subsection_code': '103(1)'}]
    assert format_section_act(bns_acts) == 'BNS 103(1)', f"Expected 'BNS 103(1)', got {format_section_act(bns_acts)}"

    c_pending.extra_fields['acts_sections'] = dummy_acts
    c_pending.save()
    c_completed.extra_fields['acts_sections'] = valid_acts
    c_completed.save()

    ser_pending = NafisCaseRecordSerializer(c_pending).data
    ser_completed = NafisCaseRecordSerializer(c_completed).data

    print("Serializer pending section_act:", repr(ser_pending['section_act']))
    print("Serializer completed section_act:", repr(ser_completed['section_act']))
    print("Serializer pending nafis_status:", repr(ser_pending['nafis_status']))
    print("Serializer completed nafis_status:", repr(ser_completed['nafis_status']))

    assert ser_pending['section_act'] == '', f"Expected empty section_act for pending case, got: {ser_pending['section_act']}"
    assert ser_completed['section_act'] == 'IPC 302', f"Expected 'IPC 302' for completed case, got: {ser_completed['section_act']}"
    assert ser_pending['nafis_status'] == 'Pending'
    assert ser_completed['nafis_status'] == 'Done'

    # Cleanup
    c_pending.delete()
    c_completed.delete()
    c_unrelated.delete()
    print("All NAFIS verification assertions succeeded perfectly!")

except Exception as e:
    import traceback
    traceback.print_exc()
