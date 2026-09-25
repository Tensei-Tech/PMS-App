import os
import json
from pathlib import Path
from django.core.management.base import BaseCommand
from django.db import transaction
from django.conf import settings

from apps.crimetab.models.groupings import CaseCategoryGroup, CaseCategory
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CategoryFieldTemplate,
    SectionFieldTemplate,
)
from apps.crimetab.models.common_form import (
    Act,
    ActSection,
    ActSubsection,
)


class Command(BaseCommand):
    help = 'Seeds BNS 2023 Acts, Sections, Subsections, Baseline Common Form Template, Category links, and CategoryFieldTemplate records.'

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write("=" * 60)
        self.stdout.write("Starting Common Form Seeding (Phase 1)...")
        self.stdout.write("=" * 60)

        # -------------------------------------------------------------
        # 1. Acts, Sections, Subsections (BNS 2023 Master)
        # -------------------------------------------------------------
        self.stdout.write("Seeding Acts & Sections...")

        bns_act, _ = Act.objects.get_or_create(
            act_name="Bharatiya Nyaya Sanhita 2023",
            defaults={"display_order": 1}
        )

        bns_json_path = Path(settings.BASE_DIR).parent / "backend" / "data" / "bns_2023_sections.json"
        if not bns_json_path.exists():
            bns_json_path = Path(settings.BASE_DIR) / "data" / "bns_2023_sections.json"

        sec_count = 0
        subsec_count = 0

        if bns_json_path.exists():
            with open(bns_json_path, 'r', encoding='utf-8') as f:
                bns_data = json.load(f)

            for item in bns_data:
                sec_num = str(item.get("section_number") or item.get("section", "")).strip()
                sec_title = str(item.get("section_title") or item.get("title", "")).strip()
                if not sec_num:
                    continue

                act_sec, _ = ActSection.objects.update_or_create(
                    act=bns_act,
                    section_number=sec_num,
                    defaults={"section_title": sec_title or f"Section {sec_num}"}
                )
                sec_count += 1

                subsections = item.get("subsections") or []
                for sub in subsections:
                    sub_code = str(sub.get("subsection_code") or sub.get("code") or sub).strip()
                    if sub_code:
                        ActSubsection.objects.get_or_create(
                            section=act_sec,
                            subsection_code=sub_code
                        )
                        subsec_count += 1

        self.stdout.write(f"  Acts/Sections: {sec_count} sections, {subsec_count} subsections loaded.")

        # -------------------------------------------------------------
        # 2. Baseline Field Template (88 Fields)
        # -------------------------------------------------------------
        self.stdout.write("Seeding Baseline Field Template (88 Common Fields)...")

        baseline_tmpl, _ = FieldTemplate.objects.get_or_create(
            template_name="Common Form Baseline Template"
        )

        # Clear existing fields to guarantee fresh order and keys
        FieldTemplateField.objects.filter(template=baseline_tmpl).delete()

        common_fields = [
            # 1. Registration Info
            ('CR Number', 'cr_number', 'common', 'text', True, 10),
            ('Registration Date & Time', 'registered_datetime', 'common', 'datetime', True, 20),
            ('Unknown Accused Involved', 'is_unknown_accused', 'common', 'checkbox', False, 30),

            # 2. Crime Spot
            ('Village / Town', 'village_town', 'common', 'text', False, 40),
            ('Area Name', 'area_name', 'common', 'text', False, 50),
            ('Crime Spot Full Address', 'full_address', 'common', 'textarea', False, 60),
            ('Occurrence Date & Time', 'occurrence_datetime', 'common', 'datetime', False, 70),

            # 3. Acts & Sections (Charges)
            ('Acts & Sections Filed', 'charges', 'common', 'chips', False, 80),

            # 4. Complainant KYC
            ('Complainant Name', 'complainant_name', 'common', 'text', False, 90),
            ('Complainant Age', 'complainant_age', 'common', 'number', False, 100),
            ('Complainant Gender', 'complainant_gender', 'common', 'dropdown', False, 110),
            ('Complainant Occupation', 'complainant_occupation', 'common', 'text', False, 120),
            ('Complainant Mobile', 'complainant_mobile', 'common', 'text', False, 130),
            ('Complainant Aadhaar', 'complainant_aadhaar', 'common', 'text', False, 140),
            ('Complainant PAN', 'complainant_pan', 'common', 'text', False, 150),
            ('Complainant Religion', 'complainant_religion', 'common', 'text', False, 160),
            ('Complainant Caste', 'complainant_caste', 'common', 'text', False, 170),
            ('Complainant Address', 'complainant_address', 'common', 'textarea', False, 180),

            # 5. Accused KYC
            ('Accused Name', 'accused_name', 'common', 'text', False, 190),
            ('Accused Age', 'accused_age', 'common', 'number', False, 200),
            ('Accused Gender', 'accused_gender', 'common', 'dropdown', False, 210),
            ('Accused Occupation', 'accused_occupation', 'common', 'text', False, 220),
            ('Accused Mobile', 'accused_mobile', 'common', 'text', False, 230),
            ('Accused Aadhaar', 'accused_aadhaar', 'common', 'text', False, 240),
            ('Accused PAN', 'accused_pan', 'common', 'text', False, 250),
            ('Accused Religion', 'accused_religion', 'common', 'text', False, 260),
            ('Accused Caste', 'accused_caste', 'common', 'text', False, 270),
            ('Accused Address', 'accused_address', 'common', 'textarea', False, 280),

            # 6. Unidentified Accused
            ('Approximate Age', 'approximate_age', 'common', 'text', False, 290),
            ('Skin Colour', 'skin_colour', 'common', 'text', False, 300),
            ('Possible Occupation', 'possible_occupation', 'common', 'text', False, 310),
            ('Identification Mark', 'identification_mark', 'common', 'textarea', False, 320),
            ('Height', 'height', 'common', 'text', False, 330),
            ('Physical Description', 'description', 'common', 'textarea', False, 340),

            # 7. Responsibility
            ('IO Name', 'io_name', 'common', 'text', False, 350),
            ('IO Designation', 'io_designation', 'common', 'text', False, 360),
            ('Registered By Name', 'registered_by_name', 'common', 'text', False, 370),
            ('Registered By Designation', 'registered_by_designation', 'common', 'text', False, 380),

            # 8. Arrest & Release Status
            ('Arrest Date & Time', 'arrest_datetime', 'common', 'datetime', False, 390),
            ('Sec 47/48 BNSS Complied', 'sec_47_48_bnss', 'common', 'checkbox', False, 400),
            ('Relative / Friend Informed', 'relative_friend_name', 'common', 'text', False, 410),
            ('Relative / Friend Relation', 'relative_friend_relation', 'common', 'text', False, 420),
            ('Release on Notice', 'release_on_notice', 'common', 'checkbox', False, 430),
            ('Release on Notice Date & Time', 'release_on_notice_datetime', 'common', 'datetime', False, 440),
            ('Anticipatory Bail', 'anticipatory_bail', 'common', 'checkbox', False, 450),
            ('Anticipatory Bail Date & Time', 'anticipatory_bail_datetime', 'common', 'datetime', False, 460),
            ('Death of Accused', 'death_of_accused', 'common', 'checkbox', False, 470),
            ('Death of Accused Date & Time', 'death_of_accused_datetime', 'common', 'datetime', False, 480),

            # 9. Remand & Custody
            ('PCR (Days)', 'pcr_days', 'common', 'number', False, 490),
            ('MCR', 'mcr', 'common', 'checkbox', False, 500),
            ('PR Bond', 'pr_bond', 'common', 'checkbox', False, 510),
            ('Bail', 'bail', 'common', 'checkbox', False, 520),
            ('Surety Name', 'surety_name', 'common', 'text', False, 530),
            ('Jail', 'jail', 'common', 'checkbox', False, 540),

            # 10. CCTV & Technical
            ('CCTV Checked', 'cctv_checked', 'common', 'checkbox', False, 550),
            ('CDR Sent Date', 'cdr_sent_date', 'common', 'date', False, 560),
            ('CDR Received Date', 'cdr_received_date', 'common', 'date', False, 570),

            # 11. Procedural Checklist
            ('Spot Panchanama', 'spot_panchanama', 'common', 'checkbox', False, 580),
            ('Seizure Panchanama', 'seizure_panchanama', 'common', 'checkbox', False, 590),
            ('Search Panchanama', 'search_panchanama', 'common', 'checkbox', False, 600),
            ('Personal Search Panchanama', 'personal_search_panchanama', 'common', 'checkbox', False, 610),
            ('Memorandum Panchanama', 'memorandum_panchanama', 'common', 'checkbox', False, 620),
            ('Identification Panchanama', 'identification_panchanama', 'common', 'checkbox', False, 630),
            ('Identification Parade Panchanama', 'identification_parade_panchanama', 'common', 'checkbox', False, 640),

            # 12. Forensics
            ('E-Shakshya', 'e_shakshya', 'common', 'checkbox', False, 650),
            ('Fingerprint Taken', 'fingerprint_taken', 'common', 'checkbox', False, 660),
            ('NAFIS Fingerprint', 'nafis_fingerprint', 'common', 'checkbox', False, 670),

            # 13. Seizures
            ('Seizure Description', 'seizure_description', 'common', 'textarea', False, 680),
            ('Seizure From Whom', 'seizure_person_name', 'common', 'text', False, 690),

            # 14. Preventive Action Items
            ('Preventive Action Type', 'preventive_action_type', 'common', 'dropdown', False, 700),
            ('Preventive Action Date', 'preventive_action_date', 'common', 'date', False, 710),
            ('Preventive Action Outward No', 'preventive_outward_no', 'common', 'text', False, 720),

            # 15. Preventive Bond
            ('Bond Date', 'bond_date', 'common', 'date', False, 730),
            ('Bond Cancellation Date', 'bond_cancellation_date', 'common', 'date', False, 740),

            # 16. Discharge Status
            ('Discharged Accused', 'is_discharged', 'common', 'checkbox', False, 750),

            # 17. Scrutiny Pipeline
            ('SDPO/ACP Send Date', 'sdpo_acp_send_date', 'common', 'date', False, 760),
            ('SDPO/ACP Grant Date', 'sdpo_acp_grant_date', 'common', 'date', False, 770),
            ('Addl SP/DCP Send Date', 'addl_sp_dcp_send_date', 'common', 'date', False, 780),
            ('Addl SP/DCP Grant Date', 'addl_sp_dcp_grant_date', 'common', 'date', False, 790),
            ('Addl CP Send Date', 'addl_cp_send_date', 'common', 'date', False, 800),
            ('Addl CP Grant Date', 'addl_cp_grant_date', 'common', 'date', False, 810),
            ('APP Send Date', 'app_send_date', 'common', 'date', False, 820),
            ('APP Grant Date', 'app_grant_date', 'common', 'date', False, 830),

            # 18. Final Verdict
            ('Charge Sheet No', 'charge_sheet_no', 'common', 'text', False, 840),
            ('A Final Number', 'a_final_number', 'common', 'text', False, 850),
            ('B Final Number', 'b_final_number', 'common', 'text', False, 860),
            ('C Final Number', 'c_final_number', 'common', 'text', False, 870),
            ('NC Final Number', 'nc_final_number', 'common', 'text', False, 880),
            ('Abeted Summary No', 'abeted_summary_no', 'common', 'text', False, 890),
            ('Stay by High Court Date', 'stay_by_high_court_date', 'common', 'date', False, 900),
            ('Quashed by High Court Date', 'quashed_by_high_court_date', 'common', 'date', False, 910),
        ]

        for label, key, src, ftype, req, order in common_fields:
            FieldTemplateField.objects.create(
                template=baseline_tmpl,
                field_label=label,
                field_key=key,
                field_source=src,
                field_type=ftype,
                is_required=req,
                display_order=order,
            )

        self.stdout.write(f"  Created {len(common_fields)} fields in Baseline Template.")

        # -------------------------------------------------------------
        # 3. Link Baseline Template to "1 to 5" and "Part 6" Categories
        # -------------------------------------------------------------
        self.stdout.write("Linking Categories to Baseline Template...")

        # Categories in "1 to 5" (group_id=1) and "Part 6" (group_id=2)
        target_cats = CaseCategory.objects.filter(group_id__in=[1, 2])
        updated_count = target_cats.update(template=baseline_tmpl)
        self.stdout.write(f"  Linked {updated_count} sub-tab categories to Baseline Template in CaseCategory.")

        # Also populate CategoryFieldTemplate for all target categories
        for cat in target_cats:
            CategoryFieldTemplate.objects.get_or_create(
                category=cat,
                template=baseline_tmpl
            )
        self.stdout.write(f"  Created CategoryFieldTemplate rows for all {target_cats.count()} sub-tabs.")

        # Explicitly ensure Standalone categories (A.D., Suicide, N.C.) are NOT linked
        standalone_excluded = CaseCategory.objects.filter(
            group__isnull=True
        )
        standalone_excluded.update(template=None)
        CategoryFieldTemplate.objects.filter(category__in=standalone_excluded).delete()
        self.stdout.write(f"  Confirmed {standalone_excluded.count()} standalone categories (A.D., Suicide, N.C., etc.) are UNLINKED.")

        # -------------------------------------------------------------
        # 4. Extra Templates (Trigger A extra & Trigger B dynamic)
        # -------------------------------------------------------------
        self.stdout.write("Setting up Dynamic Section-Triggered and Tab-Specific Templates...")

        # Murder Extra Template
        tmpl_murder_extra, _ = FieldTemplate.objects.get_or_create(
            template_name='Murder Section Extra Fields'
        )
        FieldTemplateField.objects.filter(template=tmpl_murder_extra).delete()
        murder_extra_fields = [
            ('Deceased Name', 'deceased_name', 'custom', 'text', False, 1000),
            ('Deceased Age', 'deceased_age', 'custom', 'number', False, 1010),
            ('Deceased Gender', 'deceased_gender', 'custom', 'dropdown', False, 1020),
            ('Inquest Panchanama Details', 'inquest_panchanama', 'custom', 'textarea', False, 1030),
            ('Post-Mortem Report Date', 'pm_report_date', 'custom', 'date', False, 1040),
            ('Cause of Death', 'cause_of_death', 'custom', 'textarea', False, 1050),
        ]
        for label, key, src, ftype, req, order in murder_extra_fields:
            FieldTemplateField.objects.create(
                template=tmpl_murder_extra,
                field_label=label,
                field_key=key,
                field_source=src,
                field_type=ftype,
                is_required=req,
                display_order=order,
            )

        # Hurt Extra Template
        tmpl_hurt_extra, _ = FieldTemplate.objects.get_or_create(
            template_name='Hurt Section Extra Fields'
        )
        FieldTemplateField.objects.filter(template=tmpl_hurt_extra).delete()
        hurt_extra_fields = [
            ('Injured Person Name', 'injured_name', 'custom', 'text', False, 1100),
            ('Injury Type / Severity', 'injury_type', 'custom', 'text', False, 1110),
            ('Medical Certificate Date', 'medical_certificate_date', 'custom', 'date', False, 1120),
            ('Hospital Name', 'hospital_name', 'custom', 'text', False, 1130),
        ]
        for label, key, src, ftype, req, order in hurt_extra_fields:
            FieldTemplateField.objects.create(
                template=tmpl_hurt_extra,
                field_label=label,
                field_key=key,
                field_source=src,
                field_type=ftype,
                is_required=req,
                display_order=order,
            )

        # Trigger A fix: Link Murder category to BOTH Baseline and Murder Extra Template
        murder_cat = CaseCategory.objects.filter(category_name='Murder', group_id__in=[1, 2]).first()
        if murder_cat:
            CategoryFieldTemplate.objects.get_or_create(
                category=murder_cat,
                template=tmpl_murder_extra
            )
            self.stdout.write("  Linked Murder category to Murder Section Extra Fields via CategoryFieldTemplate (Trigger A).")

        # Map Sections to Templates (Trigger B)
        # BNS 101 / 103 -> Murder Extra Template
        sec_murder_101 = ActSection.objects.filter(act=bns_act, section_number='101').first()
        sec_murder_103 = ActSection.objects.filter(act=bns_act, section_number='103').first()
        if sec_murder_101:
            SectionFieldTemplate.objects.update_or_create(section=sec_murder_101, defaults={'template': tmpl_murder_extra})
        if sec_murder_103:
            SectionFieldTemplate.objects.update_or_create(section=sec_murder_103, defaults={'template': tmpl_murder_extra})

        # BNS 115 / 117 / 118 -> Hurt Extra Template
        sec_hurt_115 = ActSection.objects.filter(act=bns_act, section_number='115').first()
        sec_hurt_117 = ActSection.objects.filter(act=bns_act, section_number='117').first()
        sec_hurt_118 = ActSection.objects.filter(act=bns_act, section_number='118').first()
        if sec_hurt_115:
            SectionFieldTemplate.objects.update_or_create(section=sec_hurt_115, defaults={'template': tmpl_hurt_extra})
        if sec_hurt_117:
            SectionFieldTemplate.objects.update_or_create(section=sec_hurt_117, defaults={'template': tmpl_hurt_extra})
        if sec_hurt_118:
            SectionFieldTemplate.objects.update_or_create(section=sec_hurt_118, defaults={'template': tmpl_hurt_extra})

        self.stdout.write(self.style.SUCCESS("Successfully completed Common Form seeding!"))
