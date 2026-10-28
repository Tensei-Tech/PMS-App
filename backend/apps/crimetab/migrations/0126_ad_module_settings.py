from django.db import migrations

"""
Migration 0126: A.D. hub settings (data only)

module_settings 'ad' for the A.D. hub (/api/ad/): the tab whose sub-tabs open
the hub (STAND_AD), the form template, tab / button labels, messages, PDF texts
and the list card layout. list_card_fields: comma separated boxes, each a field
key or 'group.child'; keys joined with '+' share one box. Permissions ad:*
(checked only when ad.enforce_permissions is 'true'). Idempotent; existing
values are never overwritten.
"""

SETTINGS = [
    ('target_category_code', 'STAND_AD'),
    ('template_name', 'AD Form Fields'),
    ('number_field_key', 'case_number'),
    ('enforce_permissions', 'false'),
    ('page_size', '20'),
    ('counts_cache_timeout', '45'),
    ('aadhaar_length', '12'),
    ('aadhaar_visible_digits', '4'),
    ('aadhaar_mask_char', 'X'),
    ('yes_value', 'Yes'),
    ('list_card_fields', 'case_number,ad_deceased_identity,ad_deceased.ad_deceased_name,'
                         'ad_cause_of_death,ad_postmortem+ad_postmortem_date,'
                         'ad_sdm_granted+ad_sdm_granted_date'),
    ('list_serial_label', 'Sr.'),
    ('tab_total_label', 'Total cases'),
    ('tab_pending_label', 'Pending'),
    ('tab_disposal_label', 'Disposal'),
    ('pending_definition_message', 'Pending: SDM Granted is not yet "Yes" with its date. '
                                   'A case moves to Disposal when SDM Granted is Yes and the date is filled.'),
    ('add_button_label', 'Add A.D.'),
    ('btn_edit_label', 'Edit'),
    ('btn_view_label', 'View'),
    ('btn_pdf_label', 'PDF'),
    ('search_placeholder', 'Search A.D. by AD No., name or any detail...'),
    ('empty_list_message', 'No A.D. cases found.'),
    ('empty_request_message', 'Cannot save an empty A.D. At least one field must be filled.'),
    ('not_found_message', 'A.D. case not found.'),
    ('missing_state_message', 'State code could not be resolved from authenticated user credentials.'),
    ('no_station_message', 'User does not belong to a valid police station.'),
    ('request_failed_message', 'The request could not be completed. Please try again.'),
    ('invalid_request_message', 'Invalid request.'),
    ('invalid_mobile_message', 'Mobile number must be exactly 10 digits.'),
    ('invalid_aadhaar_message', 'Aadhar card number must be exactly {length} digits.'),
    ('save_success_message', 'A.D. saved successfully.'),
    ('update_success_message', 'A.D. updated successfully.'),
    ('pdf_failed_message', 'Failed to generate PDF. Please try again.'),
    ('pdf_subtitle', 'ACCIDENTAL DEATH (A.D.) REPORT'),
    ('pdf_filename_prefix', 'AD'),
    ('pdf_department_suffix', 'DEPARTMENT'),
    ('pdf_police_department_suffix', 'POLICE DEPARTMENT'),
    ('pdf_fallback_title', 'POLICE DEPARTMENT'),
    ('pdf_no_rows_message', 'None recorded.'),
    ('pdf_footer_text', 'CONFIDENTIAL - FOR OFFICIAL USE ONLY'),
    ('pdf_generated_label', 'Generated on {time}'),
    ('pdf_page_label', 'Page {page} of {total}'),
    ('datetime_format', '%d/%m/%Y %H:%M'),
]

PERMISSIONS = [
    ('ad:create', 'Create A.D. cases'),
    ('ad:view', 'View A.D. cases'),
    ('ad:update', 'Update A.D. cases'),
    ('ad:pdf', 'Generate A.D. PDF'),
]


def forwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(module_key='ad', setting_key=key,
                                            defaults={'setting_value': value})
    try:
        Permission = apps.get_model('public_master', 'Permission')
    except LookupError:
        return
    for pid, desc in PERMISSIONS:
        Permission.objects.get_or_create(id=pid, defaults={'module': 'ad', 'description': desc})


def backwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='ad', setting_key__in=[k for k, _ in SETTINGS]).delete()
    try:
        Permission = apps.get_model('public_master', 'Permission')
    except LookupError:
        return
    Permission.objects.filter(id__in=[p for p, _ in PERMISSIONS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0125_ad_form_fields'),
        # Pinned: '__latest__' moved with every new public_master migration and
        # made this already-applied migration depend on an unapplied one
        # (InconsistentMigrationHistory on deploy).
        ('public_master', '0016_dynamicuiconfig'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
