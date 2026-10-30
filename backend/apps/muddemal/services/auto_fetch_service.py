import logging
import re
from decimal import Decimal
from typing import List, Dict, Any, Optional, Tuple
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from apps.cases.models import CaseRecord
from apps.crimetab.models import SeizureRecords
from apps.muddemal.models import (
    MuddemalRegister,
    MuddemalProperty,
    MuddemalPropertyCategory,
    MuddemalPropertyMovement,
    MuddemalAuditLog,
    MuddemalConfig,
)
from apps.muddemal.services.id_generator import (
    generate_unique_property_uid,
    generate_unique_register_number,
)
from apps.muddemal.services.valuation_service import compute_item_value

logger = logging.getLogger(__name__)

# Fast memory cache to debounce high-frequency auto-sync calls (e.g. repeated page refreshes)
_LAST_SYNC_CACHE: Dict[str, float] = {}
SYNC_DEBOUNCE_SECONDS = 3.0


def resolve_source_module_info(case: CaseRecord) -> Tuple[str, str]:
    """
    Determines the normalized source module code and display name for a CaseRecord.
    Supports Crime (Form 1-5), Form 6, Prohibition, Gambling, NDPS, Theft, Two-Four Wheeler, etc.
    """
    mod_raw = str(getattr(case, 'module_key', '') or '').strip().lower()
    sub_raw = str(getattr(case, 'sub_category', '') or '').strip()
    extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
    crime_cat = str(extra.get('crimeCategory') or extra.get('category') or sub_raw).strip()

    # Dynamic lookup against MuddemalConfig connected_modules
    try:
        cfg = MuddemalConfig.objects.filter(config_key='connected_modules').first()
        if cfg and isinstance(cfg.config_value, list):
            for m in cfg.config_value:
                m_code = str(m.get('code', '')).lower()
                if m_code and m_code != 'all' and m_code == mod_raw:
                    return m['code'], m.get('display_name', m['code'].title())
    except Exception:
        pass

    # 1. Prohibition
    if mod_raw == 'prohibition' or 'prohibition' in sub_raw.lower() or 'prohibition' in crime_cat.lower():
        return 'prohibition', 'Prohibition'

    # 2. Gambling
    if mod_raw == 'gambling' or 'gambling' in sub_raw.lower() or 'gambling' in crime_cat.lower() or 'जुगार' in sub_raw:
        return 'gambling', 'Gambling'

    # 3. NDPS (Narcotics)
    if mod_raw == 'ndps' or 'ndps' in sub_raw.lower() or 'ndps' in crime_cat.lower() or 'narcotic' in sub_raw.lower():
        return 'ndps', 'NDPS (Narcotics)'

    # 4. Two / Four Wheeler Vehicle Theft
    if mod_raw in ['two_four_wheeler', 'two_wheeler'] or 'wheeler' in sub_raw.lower() or 'वाहन' in sub_raw:
        return 'two_four_wheeler', 'Two / Four Wheeler'

    # 5. Theft / Burglary / HBT / Chain Snatching
    if (mod_raw in ['theft', 'hbt', 'robbery', 'dacoity', 'chain_snatching', 'sand_theft'] or
            any(k in sub_raw.lower() for k in ['theft', 'burglary', 'hbt', 'robbery', 'dacoity', 'चोरी'])):
        display = sub_raw if sub_raw else 'Theft / Burglary'
        return 'theft', f"Crime ({display})"

    # 6. Arms Act / Weapons
    if mod_raw in ['weapons', 'arms_act'] or 'arms' in sub_raw.lower() or 'weapon' in sub_raw.lower():
        return 'weapons', 'Arms Act / Weapons'

    # 7. Form 1 to 5 (Crime)
    if mod_raw in ['form_1_5', 'form_iv', 'form_i_v', '1_to_5']:
        display = sub_raw or crime_cat or 'Crime (Form I to V)'
        return 'crime', f"Crime ({display})" if sub_raw else "Crime (Form I to V)"

    # 8. Form VI (Special & Local Laws)
    if mod_raw in ['form_6', 'form_vi', 'part_6']:
        display = sub_raw or crime_cat or 'Special Acts (Form VI)'
        return 'form_6', f"Form VI ({display})" if sub_raw else "Form VI (Special Acts)"

    # Fallback
    display_name = sub_raw or crime_cat or mod_raw.replace('_', ' ').title() or 'PMS Source'
    mod_code = mod_raw if mod_raw else 'pms_source'
    return mod_code, display_name


def infer_property_category_code(
    name: str = '',
    desc: str = '',
    source_type: str = '',
    module_code: str = ''
) -> str:
    """
    Intelligently maps candidate property text and source module to one of the 21 backend categories:
    STOLEN_PROPERTY, RECOVERED_STOLEN_PROPERTY, SEIZED_PROPERTY, WEAPON, FIREARM, EXPLOSIVE,
    NARCOTIC, ALCOHOL, GAMBLING, CASH, GOLD_SILVER, JEWELLERY, VEHICLE, ELECTRONIC,
    COUNTERFEIT_CURRENCY, DOCUMENTS, BIOLOGICAL_SAMPLE, HAZARDOUS_CHEMICAL, WILDLIFE_FOREST,
    CYBER_DIGITAL_EVIDENCE, MISCELLANEOUS.
    """
    combined = f"{name} {desc} {source_type} {module_code}".lower()

    # 1. Alcohol / Prohibition
    if module_code == 'prohibition' or any(k in combined for k in [
        'liquor', 'alcohol', 'beer', 'whisky', 'wine', 'desi daru', 'country liquor',
        'foreign liquor', 'मद्य', 'दारू', 'हातभट्टी', 'देशी दारू', 'विदेशी दारू', 'bottles', 'बाटल्या'
    ]):
        return 'ALCOHOL'

    # 2. Gambling
    if module_code == 'gambling' or any(k in combined for k in [
        'gambling', 'playing card', 'playing cards', 'patte', 'dice', 'tokens', 'chart',
        'matka', 'वर्ली मटका', 'जुगार', 'पत्त्यांचा', 'जुगाराचे साहित्य', 'board'
    ]):
        if any(k in combined for k in ['cash', 'currency', 'rupees', 'रोख', 'रक्कम', 'amount']):
            return 'CASH'
        return 'GAMBLING'

    # 3. Narcotic / NDPS
    if module_code == 'ndps' or any(k in combined for k in [
        'ganja', 'charas', 'opium', 'heroin', 'mephedrone', 'md', 'narcotic', 'drugs',
        'cocaine', ' गांजा', 'चरस', 'अफीम', 'ब्राऊन शुगर', 'सायकोट्रॉपिक'
    ]):
        return 'NARCOTIC'

    # 4. Firearm (Pistol, Gun, Revolver, Cartridge)
    if any(k in combined for k in [
        'pistol', 'revolver', 'gun', 'rifle', 'bullet', 'cartridge', 'firearm', 'katta',
        'देशी कट्टा', 'पिस्तूल', 'रिव्हॉल्व्हर', 'बंदूक', 'जिवंत काडतुसे'
    ]):
        return 'FIREARM'

    # 5. Weapon (Knife, Sword, Dagger, Iron Rod)
    if any(k in combined for k in [
        'weapon', 'sword', 'knife', 'dagger', 'gupti', 'talwar', 'chaku', 'iron rod', 'koyta',
        'चाकू', 'तलवार', 'गुप्ती', 'कोयता', 'लोखंडी रॉड', 'शस्त्र'
    ]):
        return 'WEAPON'

    # 6. Explosive
    if any(k in combined for k in [
        'explosive', 'detonator', 'gelatin', 'rdx', 'bomb', 'स्फोटक', 'जिलेटिन कांड्या', 'डेटोनेटर'
    ]):
        return 'EXPLOSIVE'

    # 7. Cash & Currency
    if any(k in combined for k in [
        'cash', 'currency', 'rupees', 'inr', 'notes', 'रोख', 'रक्कम', 'भारतीय चलन'
    ]):
        return 'CASH'

    # 8. Counterfeit Currency
    if any(k in combined for k in [
        'counterfeit', 'fake currency', 'fake note', 'ficn', 'बनावट नोटा'
    ]):
        return 'COUNTERFEIT_CURRENCY'

    # 9. Gold & Silver
    if any(k in combined for k in [
        'gold', 'silver', 'soya', 'soona', 'chandi', 'bullion', 'सोने', 'चांदी', 'तळे', 'तोळे'
    ]):
        return 'GOLD_SILVER'

    # 10. Jewellery & Ornaments
    if any(k in combined for k in [
        'jewel', 'ring', 'necklace', 'chain', 'bangle', 'mangalsutra', 'earring',
        'दागिने', 'अंगठी', 'मंगळसूत्र', 'हार', 'बांगड्या'
    ]):
        return 'JEWELLERY'

    # 11. Vehicle
    if module_code == 'two_four_wheeler' or any(k in combined for k in [
        'car', 'bike', 'motorcycle', 'scooter', 'vehicle', 'truck', 'auto', 'tempo',
        'chassis', 'वाहन', 'गाडी', 'मोटारसायकल', 'स्कूटर', 'चारचाकी', 'दुचाकी'
    ]):
        return 'VEHICLE'

    # 12. Electronic
    if any(k in combined for k in [
        'mobile', 'phone', 'smartphone', 'laptop', 'computer', 'dvr', 'sim', 'tablet',
        'मोबाईल', 'स्मार्टफोन', 'लॅपटॉप', 'संगणक', 'सिम कार्ड'
    ]):
        return 'ELECTRONIC'

    # 13. Cyber & Digital Evidence
    if any(k in combined for k in [
        'hard disk', 'pen drive', 'pendrive', 'server', 'cctv', 'digital evidence', 'व्हिडिओ रेकॉर्डर'
    ]):
        return 'CYBER_DIGITAL_EVIDENCE'

    # 14. Biological Sample & Viscera
    if any(k in combined for k in [
        'blood', 'viscera', 'sample', 'swab', 'dna', 'व्हिसेरा', 'रक्ताचे नमुने', 'शवविच्छेदन'
    ]):
        return 'BIOLOGICAL_SAMPLE'

    # 15. Wildlife & Forest
    if any(k in combined for k in [
        'wildlife', 'forest', 'skin', 'horn', 'sand', 'चंदन', 'वाळू', 'वन्यजीव', 'कातडे'
    ]):
        return 'WILDLIFE_FOREST'

    # 16. Documents & Fraud
    if any(k in combined for k in [
        'stamp', 'stamp paper', 'deed', 'forged', 'document', 'passport', 'कागदपत्रे', 'स्टॅम्प'
    ]):
        return 'DOCUMENTS'

    # 17. Stolen vs Recovered
    if 'recovered' in source_type.lower() or 'जप्त' in combined:
        return 'RECOVERED_STOLEN_PROPERTY'
    if 'stolen' in source_type.lower() or 'theft' in source_type.lower() or 'चोरी' in combined:
        return 'STOLEN_PROPERTY'

    # 18. Default fallback
    return 'SEIZED_PROPERTY'


def parse_numeric_valuation(val_any: Any) -> Decimal:
    """Safely extracts clean decimal valuation from various string or number formats."""
    if val_any is None:
        return Decimal('0.00')
    if isinstance(val_any, (int, float, Decimal)):
        try:
            return round(Decimal(str(val_any)), 2)
        except Exception:
            return Decimal('0.00')

    cleaned = re.sub(r'[^\d.]', '', str(val_any)).strip()
    if not cleaned:
        return Decimal('0.00')
    try:
        return round(Decimal(cleaned), 2)
    except Exception:
        return Decimal('0.00')


def discover_all_case_source_properties(case: CaseRecord) -> List[Dict[str, Any]]:
    """
    Comprehensively discovers all eligible seized, stolen, or recovered property entries
    originating from any PMS module for a given CaseRecord:
    1. Relational database table `seizure_records`
    2. Case JSON `extra_fields.stolenProperties` / `stolenProperty`
    3. Case JSON `extra_fields.recoveredProperties`
    4. Module-specific JSON keys (prohibition_details, gambling_details, ndps_details, two_four_wheeler)
    5. Case JSON `extra_fields.seizures` (if not already captured in table)
    6. Case JSON `extra_fields.muddemalItems`

    Returns deduplicated candidate property dictionaries with stable source identifiers.
    """
    discovered: List[Dict[str, Any]] = []
    seen_signatures = set()  # To avoid duplicate candidates inside the same case

    mod_code, mod_display = resolve_source_module_info(case)
    case_ref_text = case.case_number or case.title or f"Case #{case.id}"

    # 1. Discover from `seizure_records` database table
    try:
        db_seizures = SeizureRecords.objects.filter(case=case).order_by('seizure_id')
        for s in db_seizures:
            src_id = f"seizure_{s.seizure_id}"
            person_name = s.name
            if not person_name and s.seized_from_person:
                person_name = s.seized_from_person.name

            desc_text = (s.description or s.object_name or 'Seized Property').strip()
            title_text = (s.object_name or (desc_text[:50] if desc_text else 'Seized Item')).strip()
            cat_code = infer_property_category_code(
                name=title_text,
                desc=desc_text,
                source_type='seizure',
                module_code=mod_code
            )

            # Deduplication key for intra-case
            sig = (desc_text.lower(), cat_code)
            if sig in seen_signatures:
                continue
            seen_signatures.add(sig)

            seizure_dt = s.created_at.date() if s.created_at else (
                case.incident_date.date() if case.incident_date else timezone.now().date()
            )

            fsl_needed = cat_code in ['ALCOHOL', 'NARCOTIC', 'FIREARM', 'BIOLOGICAL_SAMPLE', 'CYBER_DIGITAL_EVIDENCE']

            discovered.append({
                'source_module': mod_code,
                'source_module_display_name': mod_display,
                'source_record_id': src_id,
                'source_table': 'seizure_records',
                'title': title_text,
                'description': desc_text,
                'seized_from': person_name or '',
                'owner_name': case.complainant or '',
                'quantity': Decimal('1.00'),
                'unit': 'Numbers',
                'unit_value': Decimal('0.00'),
                'total_item_value': Decimal('0.00'),
                'property_category_code': cat_code,
                'property_status': 'Seized',
                'fsl_required': fsl_needed,
                'seizure_date': seizure_dt,
                'raw_source': 'Database (seizure_records table)',
            })
    except Exception as e:
        logger.warning(f"Error reading SeizureRecords for case {case.id}: {e}")

    # 2. Discover from `extra_fields` JSON
    extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}

    # 2a. Stolen Properties list (`stolenProperties`)
    stolen_list = extra.get('stolenProperties') or extra.get('stolen_properties')
    if isinstance(stolen_list, list):
        for idx, item in enumerate(stolen_list):
            if not isinstance(item, dict):
                continue
            src_id = f"stolen_prop_{idx}"
            desc = str(item.get('description') or item.get('desc') or item.get('property') or 'Stolen Property').strip()
            if not desc:
                continue

            est_val = parse_numeric_valuation(item.get('estValue') or item.get('value') or item.get('estimated_value'))
            from_person = str(item.get('from') or item.get('stolen_from') or case.complainant or '').strip()
            qty = parse_numeric_valuation(item.get('quantity') or 1) or Decimal('1.00')

            is_recovered = str(item.get('recovered', '')).lower() in ['yes', 'true', '1']
            cat_code = 'RECOVERED_STOLEN_PROPERTY' if is_recovered else infer_property_category_code(
                desc=desc,
                source_type='recovered' if is_recovered else 'stolen',
                module_code=mod_code
            )

            sig = (desc.lower(), cat_code)
            if sig in seen_signatures:
                continue
            seen_signatures.add(sig)

            discovered.append({
                'source_module': 'theft' if mod_code == 'crime' else mod_code,
                'source_module_display_name': mod_display,
                'source_record_id': src_id,
                'source_table': 'CaseRecord.extra_fields.stolenProperties',
                'title': desc[:50],
                'description': desc,
                'seized_from': from_person,
                'owner_name': case.complainant or from_person,
                'quantity': qty,
                'unit': 'Numbers',
                'unit_value': round(est_val / qty, 2) if qty > 0 else est_val,
                'total_item_value': est_val,
                'property_category_code': cat_code,
                'property_status': 'Recovered' if is_recovered else 'Stolen – Not Recovered',
                'fsl_required': False,
                'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                'raw_source': 'Case JSON (stolenProperties)',
            })

    # 2b. Single stolenProperty
    single_stolen = extra.get('stolenProperty') or extra.get('stolen_property')
    if isinstance(single_stolen, dict) and not stolen_list:
        desc = str(single_stolen.get('description') or single_stolen.get('property') or 'Stolen Property').strip()
        if desc:
            est_val = parse_numeric_valuation(single_stolen.get('estValue') or single_stolen.get('value'))
            from_p = str(single_stolen.get('from') or case.complainant or '').strip()
            is_rec = str(single_stolen.get('recovered', '')).lower() in ['yes', 'true', '1']
            cat_code = 'RECOVERED_STOLEN_PROPERTY' if is_rec else 'STOLEN_PROPERTY'

            sig = (desc.lower(), cat_code)
            if sig not in seen_signatures:
                seen_signatures.add(sig)
                discovered.append({
                    'source_module': 'theft' if mod_code == 'crime' else mod_code,
                    'source_module_display_name': mod_display,
                    'source_record_id': 'stolen_prop_single',
                    'source_table': 'CaseRecord.extra_fields.stolenProperty',
                    'title': desc[:50],
                    'description': desc,
                    'seized_from': from_p,
                    'owner_name': case.complainant or from_p,
                    'quantity': Decimal('1.00'),
                    'unit': 'Numbers',
                    'unit_value': est_val,
                    'total_item_value': est_val,
                    'property_category_code': cat_code,
                    'property_status': 'Recovered' if is_rec else 'Stolen – Not Recovered',
                    'fsl_required': False,
                    'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                    'raw_source': 'Case JSON (stolenProperty single)',
                })

    # 2c. Recovered Properties list (`recoveredProperties`)
    rec_list = extra.get('recoveredProperties') or extra.get('recovered_properties')
    if isinstance(rec_list, list):
        for idx, item in enumerate(rec_list):
            if not isinstance(item, dict):
                continue
            src_id = f"recovered_prop_{idx}"
            desc = str(item.get('description') or item.get('desc') or item.get('property') or 'Recovered Property').strip()
            if not desc:
                continue

            est_val = parse_numeric_valuation(item.get('value') or item.get('estValue'))
            sig = (desc.lower(), 'RECOVERED_STOLEN_PROPERTY')
            if sig in seen_signatures:
                continue
            seen_signatures.add(sig)

            discovered.append({
                'source_module': mod_code,
                'source_module_display_name': mod_display,
                'source_record_id': src_id,
                'source_table': 'CaseRecord.extra_fields.recoveredProperties',
                'title': desc[:50],
                'description': desc,
                'seized_from': str(item.get('seized_from') or item.get('from') or ''),
                'owner_name': case.complainant or '',
                'quantity': Decimal('1.00'),
                'unit': 'Numbers',
                'unit_value': est_val,
                'total_item_value': est_val,
                'property_category_code': 'RECOVERED_STOLEN_PROPERTY',
                'property_status': 'Recovered',
                'fsl_required': False,
                'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                'raw_source': 'Case JSON (recoveredProperties)',
            })

    # 2d. Vehicle details (`two_four_wheeler`, `vehicle_details`, `vehicleStolen`)
    veh_data = extra.get('two_four_wheeler') or extra.get('vehicle_details') or extra.get('vehicleStolen')
    if isinstance(veh_data, dict) and (veh_data.get('reg_number') or veh_data.get('registration_number') or veh_data.get('vehNo') or veh_data.get('make') or veh_data.get('model')):
        reg_no = str(veh_data.get('reg_number') or veh_data.get('registration_number') or veh_data.get('vehNo') or '').strip()
        make = str(veh_data.get('make') or veh_data.get('company') or '').strip()
        model = str(veh_data.get('model') or '').strip()
        val = parse_numeric_valuation(veh_data.get('value') or veh_data.get('estimated_value'))
        desc = f"Vehicle: {make} {model} Reg: {reg_no or 'N/A'}".strip()

        sig = (desc.lower(), 'VEHICLE')
        if sig not in seen_signatures:
            seen_signatures.add(sig)
            discovered.append({
                'source_module': 'two_four_wheeler',
                'source_module_display_name': 'Two / Four Wheeler',
                'source_record_id': f"vehicle_{reg_no or '0'}",
                'source_table': 'CaseRecord.extra_fields.vehicle_details',
                'title': desc[:50],
                'description': desc,
                'seized_from': str(veh_data.get('driver') or veh_data.get('owner') or ''),
                'owner_name': str(veh_data.get('owner') or case.complainant or ''),
                'quantity': Decimal('1.00'),
                'unit': 'Numbers',
                'unit_value': val,
                'total_item_value': val,
                'property_category_code': 'VEHICLE',
                'property_status': 'Seized' if veh_data.get('seized') else 'Stolen – Not Recovered',
                'fsl_required': False,
                'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                'raw_source': 'Case JSON (vehicle_details)',
            })

    # 2e. Gambling Module details (`gambling_details`, `gambling`)
    gamb_data = extra.get('gambling_details') or (extra.get('gambling') if isinstance(extra.get('gambling'), dict) else None)
    if isinstance(gamb_data, dict) and (gamb_data.get('cash_amount') or gamb_data.get('cash') or gamb_data.get('total_cash') or gamb_data.get('articles') or gamb_data.get('board')):
        cash_val = parse_numeric_valuation(gamb_data.get('cash_amount') or gamb_data.get('cash') or gamb_data.get('total_cash'))
        if cash_val > 0:
            sig = (f"gambling cash {cash_val}".lower(), 'CASH')
            if sig not in seen_signatures:
                seen_signatures.add(sig)
                discovered.append({
                    'source_module': 'gambling',
                    'source_module_display_name': 'Gambling',
                    'source_record_id': 'gambling_cash_seizure',
                    'source_table': 'CaseRecord.extra_fields.gambling_details',
                    'title': f"Gambling Seized Cash ₹{cash_val}",
                    'description': f"Seized Cash from gambling raid: ₹{cash_val}",
                    'seized_from': case.accused or '',
                    'owner_name': '',
                    'quantity': Decimal('1.00'),
                    'unit': 'Numbers',
                    'unit_value': cash_val,
                    'total_item_value': cash_val,
                    'property_category_code': 'CASH',
                    'property_status': 'Seized',
                    'fsl_required': False,
                    'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                    'raw_source': 'Case JSON (gambling_details)',
                })

        articles = str(gamb_data.get('articles') or gamb_data.get('gambling_articles') or gamb_data.get('board') or '').strip()
        if articles:
            sig = (articles.lower(), 'GAMBLING')
            if sig not in seen_signatures:
                seen_signatures.add(sig)
                discovered.append({
                    'source_module': 'gambling',
                    'source_module_display_name': 'Gambling',
                    'source_record_id': 'gambling_articles_seizure',
                    'source_table': 'CaseRecord.extra_fields.gambling_details',
                    'title': f"Gambling Articles: {articles[:40]}",
                    'description': f"Gambling Articles seized: {articles}",
                    'seized_from': case.accused or '',
                    'owner_name': '',
                    'quantity': Decimal('1.00'),
                    'unit': 'Numbers',
                    'unit_value': Decimal('0.00'),
                    'total_item_value': Decimal('0.00'),
                    'property_category_code': 'GAMBLING',
                    'property_status': 'Seized',
                    'fsl_required': False,
                    'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                    'raw_source': 'Case JSON (gambling_details)',
                })

    # 2f. Prohibition Module details (`prohibition_details`, `prohibition`)
    proh_data = extra.get('prohibition_details') or (extra.get('prohibition') if isinstance(extra.get('prohibition'), dict) else None)
    if isinstance(proh_data, dict) and (proh_data.get('liquor_type') or proh_data.get('type') or proh_data.get('bottles') or proh_data.get('quantity') or proh_data.get('value')):
        l_type = str(proh_data.get('liquor_type') or proh_data.get('type') or 'Country Liquor').strip()
        bottles = str(proh_data.get('bottles') or proh_data.get('quantity') or '').strip()
        proh_val = parse_numeric_valuation(proh_data.get('value') or proh_data.get('total_value'))
        desc = f"Seized Liquor: {l_type} {bottles} bottles".strip()

        sig = (desc.lower(), 'ALCOHOL')
        if sig not in seen_signatures:
            seen_signatures.add(sig)
            discovered.append({
                'source_module': 'prohibition',
                'source_module_display_name': 'Prohibition',
                'source_record_id': 'prohibition_liquor_seizure',
                'source_table': 'CaseRecord.extra_fields.prohibition_details',
                'title': f"Prohibition Liquor: {l_type}",
                'description': desc,
                'seized_from': case.accused or '',
                'owner_name': '',
                'quantity': parse_numeric_valuation(bottles) or Decimal('1.00'),
                'unit': 'Bottles',
                'unit_value': proh_val,
                'total_item_value': proh_val,
                'property_category_code': 'ALCOHOL',
                'property_status': 'Seized',
                'fsl_required': True,
                'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                'raw_source': 'Case JSON (prohibition_details)',
            })

    # 2g. NDPS Module details (`ndps_details`, `ndps`)
    ndps_data = extra.get('ndps_details') or (extra.get('ndps') if isinstance(extra.get('ndps'), dict) else None)
    if isinstance(ndps_data, dict) and (ndps_data.get('substance') or ndps_data.get('drug_name') or ndps_data.get('weight_grams') or ndps_data.get('value')):
        substance = str(ndps_data.get('substance') or ndps_data.get('drug_name') or 'Narcotic Substance').strip()
        weight_grams = str(ndps_data.get('weight_grams') or ndps_data.get('quantity') or '').strip()
        ndps_val = parse_numeric_valuation(ndps_data.get('value') or ndps_data.get('market_value'))
        desc = f"Seized Narcotic: {substance} ({weight_grams} grams)".strip()

        sig = (desc.lower(), 'NARCOTIC')
        if sig not in seen_signatures:
            seen_signatures.add(sig)
            discovered.append({
                'source_module': 'ndps',
                'source_module_display_name': 'NDPS',
                'source_record_id': 'ndps_substance_seizure',
                'source_table': 'CaseRecord.extra_fields.ndps_details',
                'title': f"NDPS: {substance}",
                'description': desc,
                'seized_from': case.accused or '',
                'owner_name': '',
                'quantity': parse_numeric_valuation(weight_grams) or Decimal('1.00'),
                'unit': 'Grams',
                'unit_value': ndps_val,
                'total_item_value': ndps_val,
                'property_category_code': 'NARCOTIC',
                'property_status': 'Seized',
                'fsl_required': True,
                'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                'raw_source': 'Case JSON (ndps_details)',
            })

    # 2h. Raw seizures list in JSON if not already in SeizureRecords (`extra_fields.seizures`)
    json_seizures = extra.get('seizures') or extra.get('seizure_records') or extra.get('commonForm', {}).get('seizures')
    if isinstance(json_seizures, list):
        for idx, s in enumerate(json_seizures):
            if not isinstance(s, dict):
                continue
            desc = str(s.get('description') or s.get('desc') or s.get('object_name') or s.get('property') or '').strip()
            if not desc:
                continue

            cat_code = infer_property_category_code(name=desc, desc=desc, source_type='seizure', module_code=mod_code)
            sig = (desc.lower(), cat_code)
            if sig in seen_signatures:
                continue
            seen_signatures.add(sig)

            discovered.append({
                'source_module': mod_code,
                'source_module_display_name': mod_display,
                'source_record_id': f"extra_seizure_{idx}",
                'source_table': 'CaseRecord.extra_fields.seizures',
                'title': desc[:50],
                'description': desc,
                'seized_from': str(s.get('name') or s.get('fromWhom') or s.get('from') or ''),
                'owner_name': case.complainant or '',
                'quantity': Decimal('1.00'),
                'unit': 'Numbers',
                'unit_value': Decimal('0.00'),
                'total_item_value': Decimal('0.00'),
                'property_category_code': cat_code,
                'property_status': 'Seized',
                'fsl_required': cat_code in ['ALCOHOL', 'NARCOTIC', 'FIREARM', 'BIOLOGICAL_SAMPLE'],
                'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                'raw_source': 'Case JSON (seizures)',
            })

    # 2i. Direct single seizure in extra_fields
    s_desc = str(extra.get('seizure_description') or extra.get('object_name') or '').strip()
    if s_desc:
        cat_code = infer_property_category_code(name=s_desc, desc=s_desc, source_type='seizure', module_code=mod_code)
        sig = (s_desc.lower(), cat_code)
        if sig not in seen_signatures:
            seen_signatures.add(sig)
            discovered.append({
                'source_module': mod_code,
                'source_module_display_name': mod_display,
                'source_record_id': f"direct_seizure_{case.id}",
                'source_table': 'CaseRecord.extra_fields.seizure_description',
                'title': str(extra.get('object_name') or s_desc)[:50],
                'description': s_desc,
                'seized_from': str(extra.get('seizure_person_name') or case.accused or ''),
                'owner_name': case.complainant or '',
                'quantity': Decimal('1.00'),
                'unit': 'Numbers',
                'unit_value': Decimal('0.00'),
                'total_item_value': Decimal('0.00'),
                'property_category_code': cat_code,
                'property_status': 'Seized',
                'fsl_required': cat_code in ['ALCOHOL', 'NARCOTIC', 'FIREARM', 'BIOLOGICAL_SAMPLE'],
                'seizure_date': case.incident_date.date() if case.incident_date else timezone.now().date(),
                'raw_source': 'Case JSON (seizure_description)',
            })

    return discovered


@transaction.atomic
def sync_single_case_properties(case: CaseRecord, user_uid: str = '') -> List[MuddemalProperty]:
    """
    Idempotently synchronizes all candidate properties of a single CaseRecord into Muddemal.
    - Ensures a master MuddemalRegister exists for the CR case.
    - Idempotently creates or updates MuddemalProperty entries.
    - Guarantees zero duplicate properties.
    - Preserves existing chain-of-custody movements, FSL records, and disposal status.
    """
    from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema
    active = get_active_tenant_schema()
    if not active or active == 'public':
        set_tenant_schema('maharashtra')

    candidates = discover_all_case_source_properties(case)
    if not candidates:
        return []

    # 1. Resolve or create MuddemalRegister for this CR case
    register = MuddemalRegister.objects.filter(cr_case=case).first()
    if not register:
        reg_no = generate_unique_register_number(case.station_name)
        register = MuddemalRegister.objects.create(
            muddemal_register_no=reg_no,
            police_station_id=case.station_name,
            station_name=case.station_name,
            cr_case=case,
            cr_number_snapshot=case.case_number or case.title or f"CR-{case.id}",
            registration_date=case.incident_date.date() if case.incident_date else timezone.now().date(),
            investigating_officer_id=case.assigned_officer_uid or '',
            investigating_officer_name=case.assigned_officer or '',
            record_status='Active',
            remarks=f"Auto-created Muddemal Register for CR {case.case_number or case.id}",
            created_by=user_uid or 'auto_sync',
        )

    # Cache active property categories
    categories_cache = {c.category_code: c for c in MuddemalPropertyCategory.objects.all()}
    default_cat = categories_cache.get('SEIZED_PROPERTY') or MuddemalPropertyCategory.objects.first()
    if not default_cat:
        default_cat, _ = MuddemalPropertyCategory.objects.get_or_create(
            category_code='SEIZED_PROPERTY',
            defaults={
                'category_name': 'Seized Property',
                'display_order': 11,
                'is_active': True,
            }
        )
        categories_cache['SEIZED_PROPERTY'] = default_cat

    synced_properties = []

    for item in candidates:
        src_mod = item['source_module']
        src_id = item['source_record_id']
        desc = item['description']
        cat_code = item['property_category_code']
        cat_obj = categories_cache.get(cat_code, default_cat)
        if not cat_obj:
            cat_obj, _ = MuddemalPropertyCategory.objects.get_or_create(
                category_code=cat_code or 'SEIZED_PROPERTY',
                defaults={
                    'category_name': (cat_code or 'SEIZED_PROPERTY').replace('_', ' ').title(),
                    'display_order': 99,
                    'is_active': True,
                }
            )
            categories_cache[cat_obj.category_code] = cat_obj

        # 2. Strict Deduplication Lookup:
        # Check by (muddemal_record, source_record_id) OR by (muddemal_record, description, category)
        prop = MuddemalProperty.objects.filter(
            muddemal_record=register,
            source_record_id=src_id
        ).first()

        if not prop:
            prop = MuddemalProperty.objects.filter(
                muddemal_record=register,
                description=desc,
                property_category=cat_obj
            ).first()

        tot_val = compute_item_value(item['quantity'], item['unit_value'], item['total_item_value'])

        if prop:
            # Update source references and description if modified in source, preserve custody/lifecycle
            prop.source_module = src_mod
            prop.source_record_id = src_id
            prop.description = desc
            if cat_obj and prop.property_category_id != cat_obj.id:
                prop.property_category = cat_obj
            if item.get('property_status') and prop.property_status != item['property_status']:
                prop.property_status = item['property_status']
            if tot_val > 0:
                prop.total_item_value = tot_val
                prop.valuation_status = 'Assessed'
            if item.get('seized_from') and not prop.seized_from:
                prop.seized_from = item['seized_from']
            if item.get('owner_name') and not prop.owner_name:
                prop.owner_name = item['owner_name']

            # Inject source metadata into extra_fields
            extra_f = prop.extra_fields if isinstance(prop.extra_fields, dict) else {}
            extra_f.update({
                'source_module_id': src_mod,
                'source_module_display_name': item['source_module_display_name'],
                'source_table': item['source_table'],
                'original_record_id': str(case.id),
                'original_record_reference': case.case_number or case.title,
                'auto_fetched': True,
                'last_synced_at': timezone.now().isoformat(),
            })
            prop.extra_fields = extra_f
            prop.save()
            synced_properties.append(prop)
        else:
            # 3. Create new MuddemalProperty
            prop_uid, serial_no = generate_unique_property_uid(register)

            extra_meta = {
                'source_module_id': src_mod,
                'source_module_display_name': item['source_module_display_name'],
                'source_table': item['source_table'],
                'original_record_id': str(case.id),
                'original_record_reference': case.case_number or case.title,
                'auto_fetched': True,
                'first_synced_at': timezone.now().isoformat(),
            }

            new_prop = MuddemalProperty.objects.create(
                property_uid=prop_uid,
                muddemal_record=register,
                source_module=src_mod,
                source_record_id=src_id,
                property_category=cat_obj,
                property_serial_no=serial_no,
                description=desc,
                quantity=item['quantity'],
                unit=item['unit'],
                unit_value=item['unit_value'],
                total_item_value=tot_val,
                valuation_status='Assessed' if tot_val > 0 else 'Pending',
                owner_name=item['owner_name'],
                seized_from=item['seized_from'],
                seizure_date=item['seizure_date'],
                property_status=item['property_status'],
                fsl_required=item['fsl_required'],
                remarks=f"Auto-fetched from {item['source_module_display_name']} ({item['source_table']})",
                extra_fields=extra_meta,
                created_by=user_uid or 'auto_sync',
            )

            # 4. Automatically create initial custody movement: Inward into Muddemal Room
            MuddemalPropertyMovement.objects.create(
                property=new_prop,
                from_location=item.get('seized_from') or 'Seizure Spot',
                to_location='Muddemal Room (मालखाना)',
                movement_type='Muddemal Room In',
                responsible_officer=case.assigned_officer or 'Muddemal In-Charge',
                reference_no=register.muddemal_register_no,
                remarks=f"Initial custody intake from {item['source_module_display_name']}",
                created_by=user_uid or 'auto_sync',
            )

            # 5. Audit Log
            MuddemalAuditLog.objects.create(
                property=new_prop,
                muddemal_record=register,
                action='AUTO_FETCH_DISCOVERY',
                performed_by=user_uid or 'auto_sync',
                performed_by_name='Muddemal Auto-Fetch Engine',
                details={
                    'source_module': src_mod,
                    'source_record_id': src_id,
                    'property_uid': prop_uid,
                    'valuation': float(tot_val),
                    'category': cat_obj.category_code,
                    'case_number': case.case_number or case.title,
                }
            )
            synced_properties.append(new_prop)

    return synced_properties


def sync_all_source_module_properties(
    station_name: Optional[str] = None,
    user=None,
    force: bool = False
) -> Dict[str, Any]:
    """
    Centralized auto-fetch engine for Digital Muddemal.
    Finds all eligible CaseRecord instances with properties in:
    - `seizure_records` table
    - `extra_fields` (stolenProperties, recoveredProperties, gambling, prohibition, ndps, vehicles)
    Filters by station_name and user station boundaries.
    Idempotently synchronizes properties into PostgreSQL with verified deduplication.
    """
    cache_key = f"sync_{station_name or 'ALL'}"
    now_ts = timezone.now().timestamp()
    if not force and cache_key in _LAST_SYNC_CACHE:
        if (now_ts - _LAST_SYNC_CACHE[cache_key]) < SYNC_DEBOUNCE_SECONDS:
            return {'status': 'debounced', 'message': 'Recently synced'}

    _LAST_SYNC_CACHE[cache_key] = now_ts

    # 1. Query all eligible CaseRecords
    # A case is eligible if it has related SeizureRecords or property keys in extra_fields
    seizure_case_ids = set(SeizureRecords.objects.values_list('case_id', flat=True))

    prop_query = (
        Q(id__in=list(seizure_case_ids)) |
        (Q(extra_fields__has_key='stolenProperties') & ~Q(extra_fields__stolenProperties=[]) & ~Q(extra_fields__stolenProperties=None)) |
        (Q(extra_fields__has_key='stolenProperty') & ~Q(extra_fields__stolenProperty={}) & ~Q(extra_fields__stolenProperty=None)) |
        (Q(extra_fields__has_key='recoveredProperties') & ~Q(extra_fields__recoveredProperties=[]) & ~Q(extra_fields__recoveredProperties=None)) |
        (Q(extra_fields__has_key='two_four_wheeler') & ~Q(extra_fields__two_four_wheeler={}) & ~Q(extra_fields__two_four_wheeler=None)) |
        (Q(extra_fields__has_key='vehicle_details') & ~Q(extra_fields__vehicle_details={}) & ~Q(extra_fields__vehicle_details=None)) |
        (Q(extra_fields__has_key='vehicleStolen') & ~Q(extra_fields__vehicleStolen={}) & ~Q(extra_fields__vehicleStolen=None)) |
        (Q(extra_fields__has_key='gambling_details') & ~Q(extra_fields__gambling_details={}) & ~Q(extra_fields__gambling_details=None)) |
        (Q(extra_fields__has_key='gambling') & ~Q(extra_fields__gambling={}) & ~Q(extra_fields__gambling=None)) |
        (Q(extra_fields__has_key='prohibition_details') & ~Q(extra_fields__prohibition_details={}) & ~Q(extra_fields__prohibition_details=None)) |
        (Q(extra_fields__has_key='prohibition') & ~Q(extra_fields__prohibition={}) & ~Q(extra_fields__prohibition=None)) |
        (Q(extra_fields__has_key='ndps_details') & ~Q(extra_fields__ndps_details={}) & ~Q(extra_fields__ndps_details=None)) |
        (Q(extra_fields__has_key='ndps') & ~Q(extra_fields__ndps={}) & ~Q(extra_fields__ndps=None)) |
        (Q(extra_fields__has_key='seizures') & ~Q(extra_fields__seizures=[]) & ~Q(extra_fields__seizures=None)) |
        (Q(extra_fields__has_key='seizure_records') & ~Q(extra_fields__seizure_records=[]) & ~Q(extra_fields__seizure_records=None)) |
        (Q(extra_fields__commonForm__has_key='seizures') & ~Q(extra_fields__commonForm__seizures=[]) & ~Q(extra_fields__commonForm__seizures=None)) |
        (Q(extra_fields__has_key='seizure_description') & ~Q(extra_fields__seizure_description='') & ~Q(extra_fields__seizure_description=None)) |
        (Q(extra_fields__has_key='object_name') & ~Q(extra_fields__object_name='') & ~Q(extra_fields__object_name=None))
    )

    cases_qs = CaseRecord.objects.filter(prop_query)

    # 2. Filter by station permissions
    if station_name and station_name.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
        cases_qs = cases_qs.filter(station_name=station_name)
    elif user and not (getattr(user, 'is_superuser', False) or getattr(user, 'is_staff', False)):
        st_name = getattr(user, 'station_name', '')
        add_st = getattr(user, 'additional_stations', []) or []
        allowed_stations = [s for s in [st_name] + add_st if s]
        if allowed_stations:
            cases_qs = cases_qs.filter(station_name__in=allowed_stations)

    total_cases = 0
    total_properties_synced = 0
    sources_breakdown: Dict[str, int] = {}

    for c in cases_qs.iterator():
        total_cases += 1
        props = sync_single_case_properties(c)
        total_properties_synced += len(props)
        for p in props:
            sources_breakdown[p.source_module] = sources_breakdown.get(p.source_module, 0) + 1

    return {
        'status': 'success',
        'cases_evaluated': total_cases,
        'properties_synced': total_properties_synced,
        'sources_breakdown': sources_breakdown,
        'timestamp': timezone.now().isoformat(),
    }


def get_connected_source_modules_metadata() -> List[Dict[str, Any]]:
    """
    Returns the backend database-managed catalog of all connected PMS modules supporting seized property entries.
    Loads dynamically from MuddemalConfig ('connected_modules') with zero hardcoding.
    """
    try:
        cfg = MuddemalConfig.objects.filter(config_key='connected_modules').first()
        if cfg and isinstance(cfg.config_value, list) and len(cfg.config_value) > 0:
            return [m for m in cfg.config_value if m.get('is_active', True)]
    except Exception as e:
        logger.warning(f"Failed to load connected_modules from MuddemalConfig: {e}")

    return [
        {
            'code': 'all',
            'display_name': 'All PMS Modules',
            'description': 'Aggregated view of properties across all PMS modules',
            'icon': 'hub_outlined',
            'is_active': True,
        },
        {
            'code': 'crime',
            'display_name': 'Crime (Form I to V)',
            'description': 'Seized and stolen property from general IPC/BNS crime registrations',
            'icon': 'local_police_rounded',
            'is_active': True,
        },
        {
            'code': 'prohibition',
            'display_name': 'Prohibition',
            'description': 'Liquor, bottles, bulk wash, and vehicle seizures under Bombay Prohibition Act',
            'icon': 'liquor_rounded',
            'is_active': True,
        },
        {
            'code': 'gambling',
            'display_name': 'Gambling',
            'description': 'Cash, playing cards, charts, and tokens seized under Gambling Prevention Act',
            'icon': 'casino_rounded',
            'is_active': True,
        },
        {
            'code': 'ndps',
            'display_name': 'NDPS (Narcotics)',
            'description': 'Ganja, charas, MD, and psychotropic substances with mandatory FSL',
            'icon': 'medication_rounded',
            'is_active': True,
        },
        {
            'code': 'theft',
            'display_name': 'Theft / Burglary',
            'description': 'Stolen and recovered gold, cash, and articles from HBT and theft cases',
            'icon': 'lock_open_rounded',
            'is_active': True,
        },
        {
            'code': 'two_four_wheeler',
            'display_name': 'Two / Four Wheeler',
            'description': 'Stolen and recovered motorcycles, cars, and vehicles',
            'icon': 'directions_car_rounded',
            'is_active': True,
        },
        {
            'code': 'weapons',
            'display_name': 'Arms Act / Weapons',
            'description': 'Pistols, revolvers, cartridges, swords, and knives seized under Arms Act',
            'icon': 'gavel_rounded',
            'is_active': True,
        },
        {
            'code': 'form_6',
            'display_name': 'Form VI (Special Acts)',
            'description': 'Property seized under various Special and Local Laws (SLL)',
            'icon': 'description_rounded',
            'is_active': True,
        },
        {
            'code': 'manual',
            'display_name': 'Direct Muddemal Entry',
            'description': 'Directly registered properties inside Muddemal Register',
            'icon': 'post_add_rounded',
            'is_active': True,
        },
    ]
