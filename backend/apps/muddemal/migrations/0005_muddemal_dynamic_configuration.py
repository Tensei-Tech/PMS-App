from django.db import migrations

"""
Migration 0005: Muddemal module dynamic database configuration.
Stores configurable tabs, disposal status mappings, FSL dispatch reasons,
FSL report statuses, disposal authorities, movement configurations,
and connected source modules catalog in the database (MuddemalConfig & OptionValue).
"""

CONFIGS = [
    {
        'config_key': 'property_statuses',
        'config_value': [
            {'code': 'Stolen \u2013 Not Recovered', 'label': 'Stolen \u2013 Not Recovered', 'color': '#DC2626', 'category': 'pending'},
            {'code': 'Recovered', 'label': 'Recovered', 'color': '#059669', 'category': 'pending'},
            {'code': 'Partially Recovered', 'label': 'Partially Recovered', 'color': '#D97706', 'category': 'pending'},
            {'code': 'Seized', 'label': 'Seized', 'color': '#2563EB', 'category': 'pending'},
            {'code': 'Sent to FSL', 'label': 'Sent to FSL', 'color': '#7C3AED', 'category': 'pending'},
            {'code': 'FSL Report Pending', 'label': 'FSL Report Pending', 'color': '#EA580C', 'category': 'pending'},
            {'code': 'Produced Before Court', 'label': 'Produced Before Court', 'color': '#0891B2', 'category': 'pending'},
            {'code': 'Released on Supurdnama', 'label': 'Released on Supurdnama', 'color': '#16A34A', 'category': 'disposal'},
            {'code': 'Returned to Owner', 'label': 'Returned to Owner', 'color': '#10B981', 'category': 'disposal'},
            {'code': 'Pending Disposal', 'label': 'Pending Disposal', 'color': '#F59E0B', 'category': 'pending'},
            {'code': 'Disposed', 'label': 'Disposed', 'color': '#6B7280', 'category': 'disposal'},
            {'code': 'Destroyed', 'label': 'Destroyed', 'color': '#374151', 'category': 'disposal'},
        ],
        'description': 'Master list of property lifecycle statuses with semantic categories'
    },
    {
        'config_key': 'status_categories',
        'config_value': {
            'disposal': [
                'Released on Supurdnama',
                'Returned to Owner',
                'Disposed',
                'Destroyed',
            ],
            'pending': [
                'Stolen \u2013 Not Recovered',
                'Recovered',
                'Partially Recovered',
                'Seized',
                'Sent to FSL',
                'FSL Report Pending',
                'Produced Before Court',
                'Pending Disposal',
            ],
        },
        'description': 'Semantic grouping of property statuses for dashboard tabs and filtering'
    },
    {
        'config_key': 'dashboard_tabs',
        'config_value': [
            {
                'key': 'All',
                'label': 'Total Cases',
                'status_category': 'all',
                'display_order': 1,
                'badge_bg': '0xFFE8F1FC',
                'badge_fg': '0xFF1976D2',
            },
            {
                'key': 'Pending',
                'label': 'Pending',
                'status_category': 'pending',
                'display_order': 2,
                'badge_bg': '0xFFFFF3E0',
                'badge_fg': '0xFFE65100',
            },
            {
                'key': 'Disposal',
                'label': 'Disposal',
                'status_category': 'disposal',
                'display_order': 3,
                'badge_bg': '0xFFE8F5E9',
                'badge_fg': '0xFF2E7D32',
            },
        ],
        'description': 'Dynamic top status tabs for Muddemal dashboard'
    },
    {
        'config_key': 'disposal_authorities',
        'config_value': [
            {'code': 'JMFC', 'label': 'Judicial Magistrate First Class (JMFC)'},
            {'code': 'CJM', 'label': 'Chief Judicial Magistrate (CJM)'},
            {'code': 'SESSIONS', 'label': 'Sessions Court'},
            {'code': 'SPECIAL_COURT', 'label': 'Special Court (NDPS/MCOCA/MPID)'},
            {'code': 'SDM', 'label': 'Sub-Divisional Magistrate (SDM)'},
            {'code': 'DM', 'label': 'District Magistrate (DM)'},
            {'code': 'POLICE_COMMISSIONER', 'label': 'Commissioner of Police / SP'},
            {'code': 'OTHER', 'label': 'Other Authorized Court / Authority'},
        ],
        'description': 'Authorized disposal and Supurdnama sanction authorities'
    },
    {
        'config_key': 'fsl_dispatch_reasons',
        'config_value': [
            'Sample sent for forensic chemical analysis',
            'DNA analysis & profiling',
            'Ballistic examination of firearm/ammunition',
            'Toxicology & viscera analysis',
            'Cyber digital evidence & mobile forensics',
            'Handwriting & questioned document analysis',
            'Other forensic examination',
        ],
        'description': 'Standard reasons for dispatching property to Forensic Science Laboratory'
    },
    {
        'config_key': 'fsl_report_statuses',
        'config_value': [
            {'code': 'Received', 'label': 'Report Received (Positive/Valid)', 'is_positive': True},
            {'code': 'Inconclusive', 'label': 'Report Inconclusive', 'is_positive': False},
            {'code': 'Negative', 'label': 'Report Negative', 'is_positive': False},
            {'code': 'Partial', 'label': 'Partial Report Received', 'is_positive': True},
        ],
        'description': 'Standard FSL report examination status options'
    },
    {
        'config_key': 'fsl_reference_format',
        'config_value': {
            'prefix': 'FSL',
            'format': '{PREFIX}/{LAB}/{YEAR}/{SEQ:04d}',
            'default_lab': 'PUNE',
            'labs': [
                {'code': 'PUNE', 'name': 'Regional Forensic Science Laboratory, Pune'},
                {'code': 'MUMBAI', 'name': 'Directorate of Forensic Science Laboratories, Mumbai'},
                {'code': 'NAGPUR', 'name': 'Regional Forensic Science Laboratory, Nagpur'},
                {'code': 'AURANGABAD', 'name': 'Regional Forensic Science Laboratory, Chhatrapati Sambhajinagar'},
                {'code': 'NASHIK', 'name': 'Regional Forensic Science Laboratory, Nashik'},
                {'code': 'AMRAVATI', 'name': 'Regional Forensic Science Laboratory, Amravati'},
                {'code': 'NANDED', 'name': 'Regional Forensic Science Laboratory, Nanded'},
                {'code': 'KOLHAPUR', 'name': 'Regional Forensic Science Laboratory, Kolhapur'},
            ],
        },
        'description': 'Configurable format and regional laboratory catalog for FSL reference generation'
    },
    {
        'config_key': 'movement_defaults',
        'config_value': {
            'default_from_location': '',
            'default_to_location': '',
            'default_movement_type': '',
        },
        'description': 'Default location and movement selections (empty by default for strict user intent)'
    },
    {
        'config_key': 'connected_modules',
        'config_value': [
            {
                'code': 'all',
                'display_name': 'All PMS Modules',
                'description': 'Aggregated view of properties across all PMS modules',
                'icon': 'hub_outlined',
                'is_active': True,
                'display_order': 1,
            },
            {
                'code': 'crime',
                'display_name': 'Crime (Form I to V)',
                'description': 'Seized and stolen property from general IPC/BNS crime registrations',
                'icon': 'local_police_rounded',
                'is_active': True,
                'display_order': 2,
            },
            {
                'code': 'prohibition',
                'display_name': 'Prohibition',
                'description': 'Liquor, bottles, bulk wash, and vehicle seizures under Bombay Prohibition Act',
                'icon': 'liquor_rounded',
                'is_active': True,
                'display_order': 3,
            },
            {
                'code': 'gambling',
                'display_name': 'Gambling',
                'description': 'Cash, playing cards, charts, and tokens seized under Gambling Prevention Act',
                'icon': 'casino_rounded',
                'is_active': True,
                'display_order': 4,
            },
            {
                'code': 'ndps',
                'display_name': 'NDPS (Narcotics)',
                'description': 'Ganja, charas, MD, and psychotropic substances with mandatory FSL',
                'icon': 'medication_rounded',
                'is_active': True,
                'display_order': 5,
            },
            {
                'code': 'theft',
                'display_name': 'Theft / Burglary',
                'description': 'Stolen and recovered gold, cash, and articles from HBT and theft cases',
                'icon': 'lock_open_rounded',
                'is_active': True,
                'display_order': 6,
            },
            {
                'code': 'two_four_wheeler',
                'display_name': 'Two / Four Wheeler',
                'description': 'Stolen and recovered motorcycles, cars, and vehicles',
                'icon': 'directions_car_rounded',
                'is_active': True,
                'display_order': 7,
            },
            {
                'code': 'weapons',
                'display_name': 'Arms Act / Weapons',
                'description': 'Pistols, revolvers, cartridges, swords, and knives seized under Arms Act',
                'icon': 'gavel_rounded',
                'is_active': True,
                'display_order': 8,
            },
            {
                'code': 'form_6',
                'display_name': 'Form VI (Special Acts)',
                'description': 'Property seized under various Special and Local Laws (SLL)',
                'icon': 'description_rounded',
                'is_active': True,
                'display_order': 9,
            },
            {
                'code': 'manual',
                'display_name': 'Direct Muddemal Entry',
                'description': 'Directly registered properties inside Muddemal Register',
                'icon': 'post_add_rounded',
                'is_active': True,
                'display_order': 10,
            },
        ],
        'description': 'Connected source-module registry for Muddemal discovery and auto-fetch'
    },
]


def forwards(apps, schema_editor):
    # Ensure tenant schema and public schema are in the search path
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SET search_path TO maharashtra, public;")

    MuddemalConfig = apps.get_model('muddemal', 'MuddemalConfig')

    for cfg in CONFIGS:
        MuddemalConfig.objects.update_or_create(
            config_key=cfg['config_key'],
            defaults={
                'config_value': cfg['config_value'],
                'description': cfg['description'],
            }
        )

    # Also seed OptionValue if model exists in crimetab
    try:
        OptionValue = apps.get_model('crimetab', 'OptionValue')
        option_seeds = [
            ('muddemal_movement_locations', [
                'Muddemal Room (\u092e\u093e\u0932\u0916\u093e\u0928\u093e)',
                'Court (\u0928\u094d\u092f\u093e\u092f\u093e\u0932\u092f)',
                'FSL Laboratory (\u0935\u093f\u0927\u093f \u0935\u093f\u091c\u094d\u091e\u093e\u0928 \u092a\u094d\u0930\u092f\u094b\u0917\u0936\u093e\u0933\u093e)',
                'Police Station Lockup (\u092a\u094b\u0932\u0940\u0938 \u0920\u093e\u0923\u0947)',
                'Owner Custody (\u092e\u093e\u0932\u0915 \u0924\u093e\u092c\u093e)',
                'Disposal Site (\u0935\u093f\u0932\u094d\u0939\u0947\u0935\u093e\u091f \u091c\u093e\u0917\u093e)',
                'Other Station (\u0907\u0924\u0930 \u092a\u094b\u0932\u0940\u0938 \u0920\u093e\u0923\u0947)',
            ]),
            ('muddemal_movement_types', [
                'Muddemal Room In',
                'Sent to Court',
                'Returned from Court',
                'Sent to FSL',
                'Received from FSL',
                'Released on Supurdnama',
                'Disposed',
                'Transfer',
            ]),
            ('muddemal_disposal_types', [
                'Released on Supurdnama',
                'Returned to Owner',
                'Disposed by Public Auction',
                'Destroyed as per Court Order',
                'Forfeited to State Government',
                'Other Disposal',
            ]),
            ('muddemal_disposal_authorities', [
                'Judicial Magistrate First Class (JMFC)',
                'Chief Judicial Magistrate (CJM)',
                'Sessions Court',
                'Special Court (NDPS/MCOCA/MPID)',
                'Sub-Divisional Magistrate (SDM)',
                'District Magistrate (DM)',
                'Commissioner of Police / SP',
                'Other Authorized Court / Authority',
            ]),
            ('muddemal_fsl_dispatch_reasons', [
                'Sample sent for forensic chemical analysis',
                'DNA analysis & profiling',
                'Ballistic examination of firearm/ammunition',
                'Toxicology & viscera analysis',
                'Cyber digital evidence & mobile forensics',
                'Handwriting & questioned document analysis',
                'Other forensic examination',
            ]),
            ('muddemal_fsl_report_statuses', [
                'Report Received (Positive/Valid)',
                'Report Inconclusive',
                'Report Negative',
                'Partial Report Received',
            ]),
        ]

        for group, vals in option_seeds:
            for idx, val in enumerate(vals, start=1):
                OptionValue.objects.update_or_create(
                    option_group=group,
                    option_value=val,
                    defaults={'display_order': idx, 'is_active': True}
                )
    except Exception:
        pass


def backwards(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SET search_path TO maharashtra, public;")
    MuddemalConfig = apps.get_model('muddemal', 'MuddemalConfig')
    for cfg in CONFIGS:
        MuddemalConfig.objects.filter(config_key=cfg['config_key']).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('muddemal', '0004_update_ui_labels'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
