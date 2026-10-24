from django.db import migrations


def seed_muddemal_initial_data(apps, schema_editor):
    MuddemalPropertyCategory = apps.get_model('muddemal', 'MuddemalPropertyCategory')
    MuddemalFieldDefinition = apps.get_model('muddemal', 'MuddemalFieldDefinition')
    MuddemalConfig = apps.get_model('muddemal', 'MuddemalConfig')

    # 1. Seed Configs
    configs = [
        {
            'config_key': 'fsl_alert_thresholds',
            'config_value': {
                'threshold_1_days': 7,
                'threshold_2_days': 15,
                'threshold_3_days': 30,
            },
            'description': 'Configurable thresholds (in days) for FSL dispatch and report pending alerts'
        },
        {
            'config_key': 'property_statuses',
            'config_value': [
                {'code': 'Stolen – Not Recovered', 'label': 'Stolen – Not Recovered', 'color': '#DC2626'},
                {'code': 'Recovered', 'label': 'Recovered', 'color': '#059669'},
                {'code': 'Partially Recovered', 'label': 'Partially Recovered', 'color': '#D97706'},
                {'code': 'Seized', 'label': 'Seized', 'color': '#2563EB'},
                {'code': 'Sent to FSL', 'label': 'Sent to FSL', 'color': '#7C3AED'},
                {'code': 'FSL Report Pending', 'label': 'FSL Report Pending', 'color': '#EA580C'},
                {'code': 'Produced Before Court', 'label': 'Produced Before Court', 'color': '#0891B2'},
                {'code': 'Released on Supurdnama', 'label': 'Released on Supurdnama', 'color': '#16A34A'},
                {'code': 'Returned to Owner', 'label': 'Returned to Owner', 'color': '#10B981'},
                {'code': 'Pending Disposal', 'label': 'Pending Disposal', 'color': '#F59E0B'},
                {'code': 'Disposed', 'label': 'Disposed', 'color': '#6B7280'},
                {'code': 'Destroyed', 'label': 'Destroyed', 'color': '#374151'},
            ],
            'description': 'Master list of property lifecycle statuses'
        },
        {
            'config_key': 'measurement_units',
            'config_value': [
                'Numbers', 'Pieces', 'Bottles', 'Packets', 'Bags', 'Boxes',
                'Litres', 'Millilitres', 'Grams', 'Kilograms', 'Tolas', 'Quintals', 'Other'
            ],
            'description': 'Measurement units for seized / stolen properties'
        },
        {
            'config_key': 'valuation_statuses',
            'config_value': ['Pending', 'Estimated', 'Assessed', 'Verified'],
            'description': 'Status of valuation assessment'
        },
        {
            'config_key': 'movement_locations',
            'config_value': [
                'Muddemal Room (मालखाना)',
                'Court (न्यायालय)',
                'FSL Laboratory (विधि विज्ञान प्रयोगशाळा)',
                'Police Station Lockup (पोलीस ठाणे)',
                'Owner Custody (मालक ताबा)',
                'Disposal Site (विल्हेवाट जागा)',
                'Other Station (इतर पोलीस ठाणे)'
            ],
            'description': 'Standard custody movement locations'
        },
        {
            'config_key': 'movement_types',
            'config_value': [
                'Muddemal Room In',
                'Sent to Court',
                'Returned from Court',
                'Sent to FSL',
                'Received from FSL',
                'Released on Supurdnama',
                'Disposed',
                'Transfer'
            ],
            'description': 'Standard custody movement types'
        },
        {
            'config_key': 'disposal_types',
            'config_value': [
                'Released on Supurdnama',
                'Returned to Owner',
                'Disposed by Public Auction',
                'Destroyed as per Court Order',
                'Forfeited to State Government',
                'Other Disposal'
            ],
            'description': 'Final disposal and return categories'
        }
    ]

    for cfg in configs:
        MuddemalConfig.objects.update_or_create(
            config_key=cfg['config_key'],
            defaults={'config_value': cfg['config_value'], 'description': cfg['description']}
        )

    # 2. Seed 21 Mandatory Categories
    categories_data = [
        ('STOLEN_PROPERTY', 'Stolen Property', 1, {'is_theft': True}),
        ('RECOVERED_STOLEN_PROPERTY', 'Recovered Stolen Property', 2, {'is_recovery': True}),
        ('SEIZED_PROPERTY', 'Seized Property', 3, {'is_seizure': True}),
        ('WEAPON', 'Weapon / Dangerous Article', 4, {'fsl_eligible': True}),
        ('VEHICLE', 'Vehicle', 5, {'has_rto': True, 'supurdnama_eligible': True}),
        ('ALCOHOL', 'Alcohol / Prohibition Property', 6, {'fsl_eligible': True, 'destruction_eligible': True}),
        ('NARCOTIC', 'Narcotic / Contraband Property', 7, {'fsl_eligible': True, 'high_security': True}),
        ('GAMBLING', 'Gambling Property', 8, {'cash_tracking': True}),
        ('ELECTRONIC', 'Electronic / Digital Device', 9, {'cyber_fsl': True}),
        ('CASH', 'Cash / Currency', 10, {'safe_custody': True}),
        ('GOLD_SILVER', 'Gold / Silver / Jewellery', 11, {'precious_metal': True}),
        ('DOCUMENTS', 'Documents', 12, {'evidentiary': True}),
        ('BIOLOGICAL_SAMPLE', 'Biological Sample', 13, {'fsl_eligible': True, 'cold_storage': True}),
        ('VISCERA', 'Viscera', 14, {'fsl_eligible': True, 'postmortem': True}),
        ('CHEMICAL_SAMPLE', 'Chemical Sample', 15, {'fsl_eligible': True, 'hazardous': True}),
        ('FOOD_DRUG_SAMPLE', 'Food / Drug / Other Sample', 16, {'fsl_eligible': True}),
        ('FSL_SAMPLE', 'FSL Sample', 17, {'fsl_eligible': True}),
        ('OTHER_CASE_PROPERTY', 'Other Case Property', 18, {}),
        ('COURT_MUDDEMAL', 'Court Muddemal', 19, {'court_custody': True}),
        ('UNCLAIMED_PROPERTY', 'Unclaimed / Unknown Property', 20, {'auction_eligible': True}),
        ('OTHER', 'Other', 21, {}),
    ]

    cat_map = {}
    for code, name, order, rules in categories_data:
        cat_obj, _ = MuddemalPropertyCategory.objects.update_or_create(
            category_code=code,
            defaults={
                'category_name': name,
                'display_order': order,
                'is_active': True,
                'applicable_property_rules': rules,
            }
        )
        cat_map[code] = cat_obj

    # 3. Seed Dynamic Field Definitions for Categories
    field_defs = []

    # VEHICLE FIELDS
    veh_cat = cat_map['VEHICLE']
    field_defs.extend([
        (veh_cat, 'vehicle_type', 'Vehicle Type', 'dropdown', True, ['Car', 'Two-wheeler', 'Four-wheeler', 'Truck', 'Auto Rickshaw', 'Bus', 'Tractor', 'Other'], 1),
        (veh_cat, 'registration_number', 'Registration Number', 'text', True, [], 2),
        (veh_cat, 'make', 'Make / Manufacturer', 'text', False, [], 3),
        (veh_cat, 'model', 'Model / Variant', 'text', False, [], 4),
        (veh_cat, 'chassis_number', 'Chassis Number', 'text', False, [], 5),
        (veh_cat, 'engine_number', 'Engine Number', 'text', False, [], 6),
        (veh_cat, 'vehicle_color', 'Color', 'text', False, [], 7),
        (veh_cat, 'owner_name', 'Owner Name', 'text', False, [], 8),
        (veh_cat, 'seized_from', 'Seized From (Person/Spot)', 'text', False, [], 9),
        (veh_cat, 'seizure_date', 'Seizure Date', 'date', False, [], 10),
        (veh_cat, 'vehicle_valuation', 'Vehicle Valuation (₹)', 'decimal', False, [], 11),
        (veh_cat, 'supurdnama_date', 'Supurdnama Date', 'date', False, [], 12),
    ])

    # ALCOHOL / PROHIBITION FIELDS
    alc_cat = cat_map['ALCOHOL']
    field_defs.extend([
        (alc_cat, 'alcohol_type', 'Type of Alcohol', 'dropdown', True, ['Country Liquor (देशी दारू)', 'IMFL (विदेशी दारू)', 'Beer (बिअर)', 'Wine', 'Spurious / Haathbhatti (हातभट्टी दारू)', 'Other'], 1),
        (alc_cat, 'brand', 'Brand / Manufacturer', 'text', False, [], 2),
        (alc_cat, 'bottle_container_type', 'Bottle / Container Type', 'dropdown', False, ['Glass Bottle (काचेची बाटली)', 'Plastic Bottle (प्लॅस्टिक बाटली)', 'Can (कॅन)', 'Barrel (बॅरेल)', 'Pouch (पाऊच)', 'Rubber Tube (ट्यूब)', 'Other'], 3),
        (alc_cat, 'number_of_bottles', 'Number of Bottles / Containers', 'number', False, [], 4),
        (alc_cat, 'total_quantity', 'Total Quantity', 'decimal', True, [], 5),
        (alc_cat, 'quantity_unit', 'Quantity Unit', 'dropdown', True, ['Litres', 'Millilitres', 'Bottles', 'Boxes', 'Tubes'], 6),
        (alc_cat, 'fsl_sent_date', 'FSL Sent Date', 'date', False, [], 7),
        (alc_cat, 'fsl_report_received_status', 'FSL Report Status', 'dropdown', False, ['Pending', 'Received', 'Inconclusive'], 8),
        (alc_cat, 'fsl_report_received_date', 'FSL Report Date', 'date', False, [], 9),
        (alc_cat, 'disposal_status', 'Disposal Status', 'dropdown', False, ['Pending Disposal', 'Destroyed as per Order', 'Released', 'Other'], 10),
    ])

    # WEAPON / DANGEROUS ARTICLE FIELDS
    weap_cat = cat_map['WEAPON']
    field_defs.extend([
        (weap_cat, 'weapon_type', 'Weapon Type', 'dropdown', True, ['Firearm / Pistol / Revolver (पिस्तूल/रिव्हॉल्व्हर)', 'Rifle / Musket (बंदूक)', 'Knife / Dagger (चाकू/सुरा)', 'Sword / Talwar (तलवार)', 'Kukri / Chopper (कोयता)', 'Iron Rod / Pipe (लोखंडी रॉड/पाईप)', 'Lathi / Wooden Stick (काठी/लाठी)', 'Explosive Material', 'Other'], 1),
        (weap_cat, 'weapon_subtype', 'Subtype / Make', 'dropdown', False, ['Country-made / Desi Katta (देशी कट्टा)', 'Factory Made / Licensed', 'Sharp-edged Blade', 'Blunt Impact Weapon', 'Other'], 2),
        (weap_cat, 'description', 'Description & Dimensions', 'textarea', False, [], 3),
        (weap_cat, 'quantity', 'Quantity', 'number', True, [], 4),
        (weap_cat, 'identification_marks', 'Identification Marks / Serial No', 'text', False, [], 5),
        (weap_cat, 'seized_from', 'Seized From', 'text', False, [], 6),
        (weap_cat, 'fsl_required', 'FSL Examination Required?', 'checkbox', False, [], 7),
        (weap_cat, 'fsl_details', 'Ballistic / Forensic Examination Details', 'textarea', False, [], 8),
    ])

    # GAMBLING FIELDS
    gamb_cat = cat_map['GAMBLING']
    field_defs.extend([
        (gamb_cat, 'playing_cards', 'Playing Cards Seized?', 'dropdown', True, ['Yes', 'No'], 1),
        (gamb_cat, 'number_of_card_packs', 'Number of Card Packs', 'number', False, [], 2),
        (gamb_cat, 'gambling_board_articles', 'Gambling Board / Chart Articles', 'textarea', False, [], 3),
        (gamb_cat, 'cash_seized', 'Cash Seized on Spot?', 'dropdown', True, ['Yes', 'No'], 4),
        (gamb_cat, 'total_cash_amount', 'Total Cash Amount (₹)', 'decimal', False, [], 5),
        (gamb_cat, 'other_gambling_articles', 'Other Gambling Articles (Dice, Tokens, etc.)', 'textarea', False, [], 6),
        (gamb_cat, 'seizure_date', 'Seizure Date', 'date', False, [], 7),
    ])

    # CASH / CURRENCY FIELDS
    cash_cat = cat_map['CASH']
    field_defs.extend([
        (cash_cat, 'currency_type', 'Currency Type', 'dropdown', True, ['Indian Rupees (INR)', 'Foreign Currency', 'Counterfeit Currency / FICN'], 1),
        (cash_cat, 'denomination_details', 'Denomination Breakdown (e.g. ₹500x100, ₹200x50)', 'textarea', False, [], 2),
        (cash_cat, 'total_amount', 'Total Amount (₹)', 'decimal', True, [], 3),
        (cash_cat, 'seized_from', 'Seized From', 'text', False, [], 4),
        (cash_cat, 'seizure_date', 'Seizure Date', 'date', False, [], 5),
        (cash_cat, 'cash_status', 'Cash Custody Status', 'dropdown', False, ['Deposited in Bank', 'Kept in Police Safe (मालखाना)', 'Released as per Order', 'Forfeited to State', 'Other'], 6),
    ])

    # GOLD / SILVER / JEWELLERY FIELDS
    jewel_cat = cat_map['GOLD_SILVER']
    field_defs.extend([
        (jewel_cat, 'article_type', 'Article Type', 'dropdown', True, ['Chain / Mangalsutra', 'Ring', 'Bangles / Kangan', 'Necklace / Haar', 'Earrings', 'Anklets (पैंजण)', 'Gold / Silver Bar', 'Coins', 'Other Jewellery'], 1),
        (jewel_cat, 'material', 'Material / Metal', 'dropdown', True, ['Gold (सोने)', 'Silver (चांदी)', 'Platinum', 'Diamond Studded', 'Artificial / Imitation', 'Other'], 2),
        (jewel_cat, 'description', 'Description & Purity Marks', 'textarea', False, [], 3),
        (jewel_cat, 'weight', 'Weight', 'decimal', True, [], 4),
        (jewel_cat, 'weight_unit', 'Weight Unit', 'dropdown', True, ['Grams', 'Tolas', 'Milligrams', 'Kilograms'], 5),
        (jewel_cat, 'quantity', 'Quantity (No. of Pieces)', 'number', True, [], 6),
        (jewel_cat, 'identification_mark', 'Identification Marks / Hallmarks', 'text', False, [], 7),
        (jewel_cat, 'market_value', 'Assessed Market Value (₹)', 'decimal', False, [], 8),
        (jewel_cat, 'recovery_date', 'Recovery Date', 'date', False, [], 9),
        (jewel_cat, 'recovered_from', 'Recovered From', 'text', False, [], 10),
        (jewel_cat, 'released_to_owner', 'Released to Owner?', 'dropdown', False, ['No', 'Yes'], 11),
    ])

    # ELECTRONIC / DIGITAL DEVICE FIELDS
    elec_cat = cat_map['ELECTRONIC']
    field_defs.extend([
        (elec_cat, 'device_type', 'Device Type', 'dropdown', True, ['Mobile Phone', 'Laptop', 'Tablet', 'Desktop Computer', 'Hard Disk', 'Pen Drive', 'Memory Card', 'DVR / NVR', 'CCTV Camera', 'SIM Card', 'Smart Watch', 'Other'], 1),
        (elec_cat, 'brand_model', 'Brand & Model', 'text', False, [], 2),
        (elec_cat, 'imei_serial_number', 'IMEI / Serial Number / MAC Address', 'text', False, [], 3),
        (elec_cat, 'owner_name', 'Owner / User Name', 'text', False, [], 4),
        (elec_cat, 'seized_from', 'Seized From', 'text', False, [], 5),
        (elec_cat, 'fsl_required', 'Cyber / Forensic Analysis Required?', 'checkbox', False, [], 6),
        (elec_cat, 'fsl_sent_date', 'FSL Sent Date', 'date', False, [], 7),
        (elec_cat, 'fsl_report_status', 'FSL Report Status', 'dropdown', False, ['Pending', 'Received', 'Inconclusive'], 8),
        (elec_cat, 'fsl_report_date', 'FSL Report Date', 'date', False, [], 9),
        (elec_cat, 'return_to_owner', 'Return to Owner?', 'dropdown', False, ['No', 'Yes'], 10),
    ])

    # BIOLOGICAL / VISCERA / FSL SAMPLE FIELDS
    bio_cat = cat_map['BIOLOGICAL_SAMPLE']
    visc_cat = cat_map['VISCERA']
    fsl_cat = cat_map['FSL_SAMPLE']
    for cat in [bio_cat, visc_cat, fsl_cat]:
        field_defs.extend([
            (cat, 'person_name', 'Deceased / Related Person Name', 'text', False, [], 1),
            (cat, 'age', 'Age', 'number', False, [], 2),
            (cat, 'gender', 'Gender', 'dropdown', False, ['Male', 'Female', 'Other'], 3),
            (cat, 'postmortem_date', 'Postmortem / Collection Date', 'date', False, [], 4),
            (cat, 'sample_type', 'Sample Type', 'dropdown', True, ['Viscera Bottle 1 (Stomach & Contents)', 'Viscera Bottle 2 (Liver, Kidney, Spleen)', 'Blood Sample in Preservative', 'Urine Sample', 'Vaginal / Urethral Swab', 'Nail Clippings', 'Hair Sample', 'DNA Sample', 'Stomach Wash', 'Other'], 5),
            (cat, 'sample_identification_number', 'Sample Seal / Identification No', 'text', True, [], 6),
            (cat, 'collection_hospital', 'Hospital / Medical Officer', 'text', False, [], 7),
            (cat, 'fsl_sent_date', 'FSL Sent Date', 'date', False, [], 8),
            (cat, 'fsl_report_received', 'FSL Report Received?', 'dropdown', False, ['No', 'Yes', 'Pending'], 9),
            (cat, 'fsl_report_date', 'FSL Report Date', 'date', False, [], 10),
        ])

    # STOLEN / RECOVERED / SEIZED / OTHER GENERAL FIELDS
    for code in ['STOLEN_PROPERTY', 'RECOVERED_STOLEN_PROPERTY', 'SEIZED_PROPERTY', 'NARCOTIC', 'DOCUMENTS', 'CHEMICAL_SAMPLE', 'FOOD_DRUG_SAMPLE', 'OTHER_CASE_PROPERTY', 'COURT_MUDDEMAL', 'UNCLAIMED_PROPERTY', 'OTHER']:
        gen_cat = cat_map[code]
        field_defs.extend([
            (gen_cat, 'detailed_description', 'Detailed Description', 'textarea', False, [], 1),
            (gen_cat, 'identification_marks', 'Identification Marks / Serial Number', 'text', False, [], 2),
            (gen_cat, 'seized_or_recovered_from', 'Seized / Recovered From', 'text', False, [], 3),
            (gen_cat, 'estimated_market_value', 'Estimated / Assessed Value (₹)', 'decimal', False, [], 4),
            (gen_cat, 'special_storage_instructions', 'Storage / Handling Instructions', 'text', False, [], 5),
        ])

    for cat_obj, f_key, f_label, f_type, is_req, opts, disp_order in field_defs:
        MuddemalFieldDefinition.objects.update_or_create(
            category=cat_obj,
            field_key=f_key,
            defaults={
                'display_label': f_label,
                'field_type': f_type,
                'is_required': is_req,
                'dropdown_options': opts,
                'display_order': disp_order,
                'is_active': True,
            }
        )


def reverse_seed(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('muddemal', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(seed_muddemal_initial_data, reverse_seed),
    ]
