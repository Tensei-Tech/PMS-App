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
    assert test_data[1]['extra_fields']['nafis_status'] == 'Chargesheeted'
    assert test_data[1]['extra_fields']['nafis_status_color'] == 'green'

    # Cleanup
    c_pending.delete()
    c_completed.delete()
    c_unrelated.delete()
    print("All NAFIS verification assertions succeeded perfectly!")

except Exception as e:
    import traceback
    traceback.print_exc()
