from django.test import SimpleTestCase

from apps.cases.views import NAFISCaseWiseView


def _status(extra):
    item = {'extra_fields': dict(extra)}
    NAFISCaseWiseView()._enrich_data([item])
    ef = item['extra_fields']
    return ef['nafis_status'], ef['nafis_reason']


class NafisCaseWiseStatusTests(SimpleTestCase):
    """NAFIS case-wise list: Done / Pending from both the older form's keys and
    the Common Form's Evidence checkboxes with their dates."""

    def test_evidence_checkboxes_with_dates_are_done(self):
        self.assertEqual(_status({
            'fingerprint_taken': True, 'fingerprint_taken_date': '01/11/2026',
            'nafis_fingerprint': True, 'nafis_fingerprint_date': '02/11/2026',
        })[0], 'Done')

    def test_ticked_without_date_says_date_missing(self):
        status, reason = _status({'fingerprint_taken': True, 'nafis_fingerprint': True})
        self.assertEqual(status, 'Pending')
        self.assertEqual(reason, 'Fingerprint Date Missing, NAFIS Date Missing')

    def test_unticked_is_pending(self):
        status, reason = _status({'fingerprint_taken': False})
        self.assertEqual(status, 'Pending')
        self.assertEqual(reason, 'Fingerprint Pending, NAFIS Pending')

    def test_older_form_keys_still_work(self):
        self.assertEqual(_status({
            'fingerprintVal': 'Yes', 'fingerprintDate': '01/11/2026',
            'nafisFingerprint': 'Yes', 'nafisDate': '02/11/2026',
        })[0], 'Done')
        self.assertEqual(_status({'fingerprintVal': 'No', 'nafisDate': '02/11/2026'}),
                         ('Pending', 'Fingerprint Not Taken'))
