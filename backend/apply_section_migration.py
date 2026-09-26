import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection

def run_section_migration():
    with connection.cursor() as cursor:
        # 1. Add section column if not exists
        cursor.execute("""
            ALTER TABLE field_template_fields 
            ADD COLUMN IF NOT EXISTS section VARCHAR(100);
        """)
        
        # 2. Map field_key to Section Headings
        section_mappings = {
            # Form 1 - Crime Registration Info
            'cr_number': 'Form 1 - Crime Registration Info',
            'registered_datetime': 'Form 1 - Crime Registration Info',
            'is_unknown_accused': 'Form 1 - Crime Registration Info',

            # Form 2 - Crime Spot
            'village_town': 'Form 2 - Crime Spot',
            'area_name': 'Form 2 - Crime Spot',
            'full_address': 'Form 2 - Crime Spot',
            'occurrence_datetime': 'Form 2 - Crime Spot',

            # Form 3 - Acts & Sections
            'charges': 'Form 3 - Acts & Sections',

            # Form 4 - Complainant
            'complainant_name': 'Form 4 - Complainant',
            'complainant_age': 'Form 4 - Complainant',
            'complainant_gender': 'Form 4 - Complainant',
            'complainant_occupation': 'Form 4 - Complainant',
            'complainant_mobile': 'Form 4 - Complainant',
            'complainant_aadhaar': 'Form 4 - Complainant',
            'complainant_pan': 'Form 4 - Complainant',
            'complainant_religion': 'Form 4 - Complainant',
            'complainant_caste': 'Form 4 - Complainant',
            'complainant_address': 'Form 4 - Complainant',

            # Form 5 - Accused
            'accused_name': 'Form 5 - Accused',
            'accused_age': 'Form 5 - Accused',
            'accused_gender': 'Form 5 - Accused',
            'accused_occupation': 'Form 5 - Accused',
            'accused_mobile': 'Form 5 - Accused',
            'accused_aadhaar': 'Form 5 - Accused',
            'accused_pan': 'Form 5 - Accused',
            'accused_religion': 'Form 5 - Accused',
            'accused_caste': 'Form 5 - Accused',
            'accused_address': 'Form 5 - Accused',

            # Form 6 - Unidentified Accused
            'approximate_age': 'Form 6 - Unidentified Accused',
            'skin_colour': 'Form 6 - Unidentified Accused',
            'possible_occupation': 'Form 6 - Unidentified Accused',
            'identification_mark': 'Form 6 - Unidentified Accused',
            'height': 'Form 6 - Unidentified Accused',
            'description': 'Form 6 - Unidentified Accused',

            # Form 7 - Responsibility
            'io_name': 'Form 7 - Responsibility',
            'io_designation': 'Form 7 - Responsibility',
            'registered_by_name': 'Form 7 - Responsibility',
            'registered_by_designation': 'Form 7 - Responsibility',

            # Form 8 - Arrest & Release Status
            'arrest_datetime': 'Form 8 - Arrest & Release Status',
            'sec_47_48_bnss': 'Form 8 - Arrest & Release Status',
            'relative_friend_name': 'Form 8 - Arrest & Release Status',
            'relative_friend_relation': 'Form 8 - Arrest & Release Status',
            'release_on_notice': 'Form 8 - Arrest & Release Status',
            'release_on_notice_datetime': 'Form 8 - Arrest & Release Status',
            'anticipatory_bail': 'Form 8 - Arrest & Release Status',
            'anticipatory_bail_datetime': 'Form 8 - Arrest & Release Status',
            'death_of_accused': 'Form 8 - Arrest & Release Status',
            'death_of_accused_datetime': 'Form 8 - Arrest & Release Status',

            # Form 9 - Remand & Custody
            'pcr_days': 'Form 9 - Remand & Custody',
            'mcr': 'Form 9 - Remand & Custody',
            'pr_bond': 'Form 9 - Remand & Custody',
            'bail': 'Form 9 - Remand & Custody',
            'surety_name': 'Form 9 - Remand & Custody',
            'jail': 'Form 9 - Remand & Custody',

            # Form 10 - CCTV & Technical
            'cctv_checked': 'Form 10 - CCTV & Technical',
            'cdr_sent_date': 'Form 10 - CCTV & Technical',
            'cdr_received_date': 'Form 10 - CCTV & Technical',

            # Form 11 - Procedural Checklist
            'spot_panchanama': 'Form 11 - Procedural Checklist',
            'seizure_panchanama': 'Form 11 - Procedural Checklist',
            'search_panchanama': 'Form 11 - Procedural Checklist',
            'personal_search_panchanama': 'Form 11 - Procedural Checklist',
            'memorandum_panchanama': 'Form 11 - Procedural Checklist',
            'identification_panchanama': 'Form 11 - Procedural Checklist',
            'identification_parade_panchanama': 'Form 11 - Procedural Checklist',

            # Form 12 - Forensics
            'e_shakshya': 'Form 12 - Forensics',
            'fingerprint_taken': 'Form 12 - Forensics',
            'nafis_fingerprint': 'Form 12 - Forensics',

            # Form 13 - Seizures
            'seizure_description': 'Form 13 - Seizures',
            'seizure_person_name': 'Form 13 - Seizures',

            # Form 14 - Preventive Action Items
            'preventive_action_type': 'Form 14 - Preventive Action Items',
            'preventive_action_date': 'Form 14 - Preventive Action Items',
            'preventive_outward_no': 'Form 14 - Preventive Action Items',

            # Form 15 - Preventive Bond
            'bond_date': 'Form 15 - Preventive Bond',
            'bond_cancellation_date': 'Form 15 - Preventive Bond',

            # Form 16 - Discharge Status
            'is_discharged': 'Form 16 - Discharge Status',

            # Form 17 - Scrutiny Pipeline
            'sdpo_acp_send_date': 'Form 17 - Scrutiny Pipeline',
            'sdpo_acp_grant_date': 'Form 17 - Scrutiny Pipeline',
            'addl_sp_dcp_send_date': 'Form 17 - Scrutiny Pipeline',
            'addl_sp_dcp_grant_date': 'Form 17 - Scrutiny Pipeline',
            'addl_cp_send_date': 'Form 17 - Scrutiny Pipeline',
            'addl_cp_grant_date': 'Form 17 - Scrutiny Pipeline',
            'app_send_date': 'Form 17 - Scrutiny Pipeline',
            'app_grant_date': 'Form 17 - Scrutiny Pipeline',

            # Form 18 - Final Verdict
            'charge_sheet_no': 'Form 18 - Final Verdict',
            'a_final_number': 'Form 18 - Final Verdict',
            'b_final_number': 'Form 18 - Final Verdict',
            'c_final_number': 'Form 18 - Final Verdict',
            'nc_final_number': 'Form 18 - Final Verdict',
            'abeted_summary_no': 'Form 18 - Final Verdict',
            'stay_by_high_court_date': 'Form 18 - Final Verdict',
            'quashed_by_high_court_date': 'Form 18 - Final Verdict',

            # Extras (Murder)
            'deceased_name': 'Special Section / Template Details',
            'deceased_age': 'Special Section / Template Details',
            'deceased_gender': 'Special Section / Template Details',
            'inquest_panchanama': 'Special Section / Template Details',
            'pm_report_date': 'Special Section / Template Details',
            'cause_of_death': 'Special Section / Template Details',

            # Extras (Hurt)
            'injured_name': 'Special Section / Template Details',
            'injury_type': 'Special Section / Template Details',
            'medical_certificate_date': 'Special Section / Template Details',
            'hospital_name': 'Special Section / Template Details',
        }

        for key, section_heading in section_mappings.items():
            cursor.execute(
                "UPDATE field_template_fields SET section = %s WHERE field_key = %s;",
                [section_heading, key]
            )

        # 3. Verification query requested by user
        cursor.execute("""
            SELECT 
                COUNT(*) AS total_rows,
                COUNT(section) AS rows_with_section,
                COUNT(*) - COUNT(section) AS rows_still_missing
            FROM field_template_fields;
        """)
        res = cursor.fetchone()
        print(f"VERIFICATION RESULT: total_rows={res[0]}, rows_with_section={res[1]}, rows_still_missing={res[2]}")

if __name__ == '__main__':
    run_section_migration()
