from django.core.management.base import BaseCommand
from django.db import transaction
from apps.crimetab.models.groupings import CaseCategoryGroup, CaseCategory
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    SectionFieldTemplate,
)
from apps.crimetab.models.common_form import Act, ActSection


class Command(BaseCommand):
    help = 'Seeds initial Crime Tab groups and categories strictly according to user specification (exact 59 rows)'

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write("Resetting & Seeding exact Crime Tab Categories (59 rows)...")

        # Clear existing categories to ensure clean exact state
        CaseCategory.objects.all().delete()
        CaseCategoryGroup.objects.all().delete()

        # 1. Create Groups
        g_1to5 = CaseCategoryGroup.objects.create(
            group_id=1,
            group_name='1 to 5',
            group_code='I TO V',
            display_order=1
        )
        g_part6 = CaseCategoryGroup.objects.create(
            group_id=2,
            group_name='Part 6',
            group_code='VI',
            display_order=2
        )

        # 2. Templates
        tmpl_general, _ = FieldTemplate.objects.get_or_create(template_name='General Crime Baseline Template')
        tmpl_homicide, _ = FieldTemplate.objects.get_or_create(template_name='Homicide / Murder Extra Template')
        tmpl_property, _ = FieldTemplate.objects.get_or_create(template_name='Property / Theft Extra Template')
        tmpl_dacoity, _ = FieldTemplate.objects.get_or_create(template_name='Dacoity Form Template')
        tmpl_robbery, _ = FieldTemplate.objects.get_or_create(template_name='Robbery Form Template')
        tmpl_sexual, _ = FieldTemplate.objects.get_or_create(template_name='Sexual Offence Extra Template')

        # Template fields
        general_fields = [
            ('Cr. No.', 'crNo', 'common', 'text', True, 10),
            ('Registered Date', 'regDate', 'common', 'date', True, 20),
            ('Brief Description', 'briefDescription', 'common', 'textarea', False, 30),
            ('Complainant Name', 'compName', 'common', 'text', True, 40),
            ('Victim Name', 'vName', 'common', 'text', False, 50),
            ('Accused Name', 'accusedName', 'common', 'text', False, 60),
            ('Crime Spot Address', 'spotAddress', 'common', 'textarea', False, 70),
            ('IO Name', '_ioName', 'common', 'text', True, 80),
        ]
        for label, key, src, ftype, req, order in general_fields:
            FieldTemplateField.objects.get_or_create(
                template=tmpl_general,
                field_key=key,
                defaults={'field_label': label, 'field_source': src, 'field_type': ftype, 'is_required': req, 'display_order': order}
            )

        # 3. Acts & Sections
        act_bns, _ = Act.objects.get_or_create(act_code='BNS', defaults={'act_name': 'Bharatiya Nyaya Sanhita 2023'})
        act_ipc, _ = Act.objects.get_or_create(act_code='IPC', defaults={'act_name': 'Indian Penal Code 1860'})

        sec_robbery, _ = ActSection.objects.get_or_create(act=act_bns, section_number='309', defaults={'title': 'Robbery', 'description': 'Robbery and associated offences under BNS 2023 (IPC 390, 392, 393, 394)'})
        sec_dacoity, _ = ActSection.objects.get_or_create(act=act_bns, section_number='310', defaults={'title': 'Dacoity', 'description': 'Dacoity and associated offences under BNS 2023 (IPC 391, 395, 396, 399, 400, 402)'})
        sec_robbery_dacoity_death, _ = ActSection.objects.get_or_create(act=act_bns, section_number='311', defaults={'title': 'Robbery, or dacoity, with attempt to cause death or grievous hurt', 'description': 'Corresponds to IPC 397'})
        sec_robbery_dacoity_armed, _ = ActSection.objects.get_or_create(act=act_bns, section_number='312', defaults={'title': 'Attempt to commit robbery or dacoity when armed with deadly weapon', 'description': 'Corresponds to IPC 398'})

        SectionFieldTemplate.objects.get_or_create(section=sec_robbery, template=tmpl_robbery)
        SectionFieldTemplate.objects.get_or_create(section=sec_dacoity, template=tmpl_dacoity)
        SectionFieldTemplate.objects.get_or_create(section=sec_robbery_dacoity_death, template=tmpl_robbery)
        SectionFieldTemplate.objects.get_or_create(section=sec_robbery_dacoity_armed, template=tmpl_robbery)

        # 3b. Subsections for 309 (Robbery) and 310 (Dacoity)
        from apps.crimetab.models.common_form import ActSubsection
        robbery_subsections = [
            ('1', 'Robbery definition / theft in order to committing theft (IPC 390)'),
            ('2', 'Robbery definition / extortion in order to committing extortion (IPC 390)'),
            ('3', 'Robbery definition / wrongful restraint or fear of instant hurt (IPC 390)'),
            ('4', 'Punishment for robbery (IPC 392)'),
            ('5', 'Attempt to commit robbery (IPC 393)'),
            ('6', 'Voluntarily causing hurt in committing robbery (IPC 394)'),
        ]
        for sub_code, desc in robbery_subsections:
            ActSubsection.objects.get_or_create(section=sec_robbery, subsection_code=sub_code, defaults={'description': desc})

        dacoity_subsections = [
            ('1', 'Dacoity definition (IPC 391)'),
            ('2', 'Punishment for dacoity (IPC 395)'),
            ('3', 'Dacoity with murder (IPC 396)'),
            ('4', 'Making preparation to commit dacoity (IPC 399)'),
            ('5', 'Punishment for belonging to gang of dacoits (IPC 400)'),
            ('6', 'Assembling for purpose of committing dacoity (IPC 402)'),
        ]
        for sub_code, desc in dacoity_subsections:
            ActSubsection.objects.get_or_create(section=sec_dacoity, subsection_code=sub_code, defaults={'description': desc})

        # =========================================================================
        # A. TABS UNDER '1 TO 5' ONLY (18 items)
        # =========================================================================
        tabs_1to5_only = [
            ('Murder', '101', tmpl_homicide),
            ('Attempt to Murder', '102', tmpl_general),
            ('Dacoity', '103', tmpl_dacoity),
            ('Robbery', '104', tmpl_robbery),
            ('HBT', '105', tmpl_property),
            ('Riot', '106', tmpl_general),
            ('Unlawful Assembly', '107', tmpl_general),
            ('CBT', '108', tmpl_general),
            ('Cheating', '109', tmpl_general),
            ('Mischief', '110', tmpl_general),
            ('Assault on Public Servant', '111', tmpl_general),
            ('Rape', '112', tmpl_sexual),
            ('Molestation', '113', tmpl_sexual),
            ('Extortion', '114', tmpl_general),
            ('IPC (A) 304', '115', tmpl_homicide),
            ('498 (A) IPC', '116', tmpl_general),
            ('Other IPC', '117', tmpl_general),
            ('Chain Snatching', '118', tmpl_property),
        ]
        for order, (name, code, tmpl) in enumerate(tabs_1to5_only, start=1):
            CaseCategory.objects.create(
                group=g_1to5,
                category_name=name,
                category_code=code,
                template=tmpl,
                display_order=order,
                is_active=True,
            )

        # =========================================================================
        # B. TABS UNDER '1 TO 5' THAT ALSO HAVE A SEPARATE TAB (10 items)
        #    (Inside '1 to 5' group, group_id = 1)
        # =========================================================================
        dual_tabs_1to5 = [
            ('Theft', '119', tmpl_property),
            ('Kidnapping', '120', tmpl_general),
            ('Hurt', '121', tmpl_general),
            ('Sand Theft', '122', tmpl_property),
            ('Two/Four Wheeler Theft', '123', tmpl_property),
            ('Missing', '124', tmpl_general),
            ('Crime Against Women', '125', tmpl_general),
            ('Accident', '126', tmpl_general),
            ('Sec 156(3)/175(3)(BNSS)', '127', tmpl_general),
            ('Coin', '128', tmpl_general),
        ]
        for order, (name, code, tmpl) in enumerate(dual_tabs_1to5, start=19):
            CaseCategory.objects.create(
                group=g_1to5,
                category_name=name,
                category_code=code,
                template=tmpl,
                display_order=order,
                is_active=True,
            )

        # =========================================================================
        # C. STANDALONE TWINS FOR 1-TO-5 DUAL-PRESENCE ITEMS (group_id = NULL)
        # =========================================================================
        standalone_twins_1to5 = [
            ('Theft', 'STAND_THEFT', tmpl_property),
            ('Kidnapping', 'STAND_KIDNAP', tmpl_general),
            ('Hurt', 'STAND_HURT', tmpl_general),
            ('Sand Theft', 'STAND_SAND', tmpl_property),
            ('Two/Four Wheeler Theft', 'STAND_VEHICLE', tmpl_property),
            ('Missing', 'STAND_MISSING', tmpl_general),
            ('Crime Against Women', 'STAND_WOMEN', tmpl_general),
            ('Accident', 'STAND_ACCIDENT', tmpl_general),
            ('Sec 156(3)/175(3)(BNSS)', 'STAND_BNSS_SEC', tmpl_general),
            ('Coin', 'STAND_COIN', tmpl_general),
        ]
        for order, (name, code, tmpl) in enumerate(standalone_twins_1to5, start=29):
            CaseCategory.objects.create(
                group=None,
                category_name=name,
                category_code=code,
                template=tmpl,
                display_order=order,
                is_active=True,
            )

        # =========================================================================
        # D. STANDALONE-ONLY CATEGORIES (3 items: Suicide, A.D., N.C.)
        # =========================================================================
        standalone_only = [
            ('Suicide', 'STAND_SUICIDE', tmpl_general),
            ('A.D.', 'STAND_AD', tmpl_general),
            ('N.C.', 'STAND_NC', tmpl_general),
        ]
        for order, (name, code, tmpl) in enumerate(standalone_only, start=39):
            CaseCategory.objects.create(
                group=None,
                category_name=name,
                category_code=code,
                template=tmpl,
                display_order=order,
                is_active=True,
            )

        # =========================================================================
        # E. TABS UNDER 'PART 6' THAT ALSO HAVE A SEPARATE TAB (9 items)
        #    (Inside Part 6 group, group_id = 2)
        # =========================================================================
        dual_tabs_part6 = [
            ('ST Drugs', '601', tmpl_general),
            ('Prohibition', '602', tmpl_general),
            ('Gambling', '603', tmpl_general),
            ('POCSO', '604', tmpl_sexual),
            ('NDPS', '605', tmpl_general),
            ('Gowans', '606', tmpl_general),
            ('IT Act', '607', tmpl_general),
            ('M.V Act', '608', tmpl_general),
            ('UAPA', '609', tmpl_general),
        ]
        for order, (name, code, tmpl) in enumerate(dual_tabs_part6, start=42):
            CaseCategory.objects.create(
                group=g_part6,
                category_name=name,
                category_code=code,
                template=tmpl,
                display_order=order,
                is_active=True,
            )

        # =========================================================================
        # F. STANDALONE TWINS FOR PART 6 DUAL-PRESENCE ITEMS (group_id = NULL)
        # =========================================================================
        standalone_twins_part6 = [
            ('ST Drugs', 'STAND_ST_DRUGS', tmpl_general),
            ('Prohibition', 'STAND_PROHIBITION', tmpl_general),
            ('Gambling', 'STAND_GAMBLING', tmpl_general),
            ('POCSO', 'STAND_POCSO', tmpl_sexual),
            ('NDPS', 'STAND_NDPS', tmpl_general),
            ('Gowans', 'STAND_GOWANS', tmpl_general),
            ('IT Act', 'STAND_IT_ACT', tmpl_general),
            ('M.V Act', 'STAND_MV_ACT', tmpl_general),
            ('UAPA', 'STAND_UAPA', tmpl_general),
        ]
        for order, (name, code, tmpl) in enumerate(standalone_twins_part6, start=51):
            CaseCategory.objects.create(
                group=None,
                category_name=name,
                category_code=code,
                template=tmpl,
                display_order=order,
                is_active=True,
            )

        total_count = CaseCategory.objects.count()
        self.stdout.write(self.style.SUCCESS(f"Total case_categories count = {total_count} (Expected: 59)"))
