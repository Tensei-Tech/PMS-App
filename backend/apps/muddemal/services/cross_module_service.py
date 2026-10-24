from decimal import Decimal
from typing import List, Dict, Any, Optional
from django.db import transaction
from django.utils import timezone
from apps.cases.models import CaseRecord
from apps.crimetab.models import SeizureRecords
from apps.muddemal.models import (
    MuddemalRegister,
    MuddemalProperty,
    MuddemalPropertyCategory,
    MuddemalAuditLog,
)
from apps.muddemal.services.id_generator import generate_unique_property_uid
from apps.muddemal.services.valuation_service import compute_item_value


def _infer_category_code(name: str, desc: str, source_type: str = '') -> str:
    """Intelligently infer property category code from description and source type."""
    combined = f"{name} {desc} {source_type}".lower()
    if any(k in combined for k in ['car', 'bike', 'motorcycle', 'scooter', 'vehicle', 'truck', 'auto', 'वाहन', 'गाडी']):
        return 'VEHICLE'
    if any(k in combined for k in ['liquor', 'alcohol', 'beer', 'wine', 'desi daru', 'country liquor', 'दारू', 'मद्य']):
        return 'ALCOHOL'
    if any(k in combined for k in ['weapon', 'pistol', 'revolver', 'knife', 'sword', 'katta', 'चाकू', 'तलवार', 'पिस्तूल']):
        return 'WEAPON'
    if any(k in combined for k in ['card', 'cards', 'gambling', 'patte', 'जुगार', 'पत्त्यांचा']):
        return 'GAMBLING'
    if any(k in combined for k in ['cash', 'currency', 'rupees', 'inr', 'रोख', 'रक्कम']):
        return 'CASH'
    if any(k in combined for k in ['gold', 'silver', 'jewel', 'ring', 'necklace', 'सोने', 'चांदी', 'दागिने']):
        return 'GOLD_SILVER'
    if any(k in combined for k in ['mobile', 'phone', 'laptop', 'computer', 'dvr', 'sim', 'मोबाईल']):
        return 'ELECTRONIC'
    if any(k in combined for k in ['ganja', 'charas', 'opium', 'mephedrone', 'md', 'narcotic', 'गांजा']):
        return 'NARCOTIC'
    if any(k in combined for k in ['blood', 'viscera', 'sample', 'swab', 'dna', 'व्हिसेरा']):
        return 'BIOLOGICAL_SAMPLE'
    if 'stolen' in source_type.lower() or 'theft' in source_type.lower():
        return 'STOLEN_PROPERTY'
    return 'SEIZED_PROPERTY'


def discover_case_source_properties(case: CaseRecord, register: Optional[MuddemalRegister] = None) -> List[Dict[str, Any]]:
    """
    Discovers all candidate seized and stolen properties linked to a CaseRecord across PMS modules:
    1. Database table `seizure_records`
    2. Case `extra_fields` (stolenProperties, stolenProperty, seizures, vehicleStolen)
    Returns items flagged with `is_already_linked` and their Muddemal Property UID if present.
    """
    discovered: List[Dict[str, Any]] = []

    # Find existing linked properties for this case
    existing_linked = MuddemalProperty.objects.filter(
        muddemal_record__cr_case=case
    ).values('id', 'property_uid', 'source_module', 'source_record_id')

    linked_map = {}
    for p in existing_linked:
        key = f"{p['source_module']}::{p['source_record_id']}"
        linked_map[key] = p

    # 1. Discover from SeizureRecords database table
    db_seizures = SeizureRecords.objects.filter(case=case)
    for s in db_seizures:
        src_id = f"seizure_{s.seizure_id}"
        src_mod = 'seizure_records'
        lookup_key = f"{src_mod}::{src_id}"
        is_linked = lookup_key in linked_map
        linked_info = linked_map.get(lookup_key)

        person_name = s.name
        if not person_name and s.seized_from_person:
            person_name = s.seized_from_person.name

        inferred_cat = _infer_category_code(s.object_name or '', s.description or '', 'seizure')

        discovered.append({
            'source_module': src_mod,
            'source_record_id': src_id,
            'title': s.object_name or (s.description[:40] if s.description else 'Seizure Item'),
            'description': s.description or s.object_name or '',
            'seized_from': person_name or '',
            'quantity': 1.0,
            'unit': 'Numbers',
            'unit_value': 0.0,
            'total_item_value': 0.0,
            'inferred_category_code': inferred_cat,
            'is_already_linked': is_linked,
            'linked_property_uid': linked_info['property_uid'] if linked_info else None,
            'linked_property_id': linked_info['id'] if linked_info else None,
            'raw_source': 'Database (seizure_records table)',
        })

    # 2. Discover from CaseRecord.extra_fields
    extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}

    # 2a. Stolen Properties list
    stolen_list = extra.get('stolenProperties') or extra.get('stolen_properties')
    if isinstance(stolen_list, list):
        for idx, item in enumerate(stolen_list):
            if not isinstance(item, dict):
                continue
            src_id = f"stolen_prop_{idx}"
            src_mod = 'theft_stolen_properties'
            lookup_key = f"{src_mod}::{src_id}"
            is_linked = lookup_key in linked_map
            linked_info = linked_map.get(lookup_key)

            desc = item.get('description') or item.get('property') or 'Stolen Item'
            val_str = item.get('estValue') or item.get('value') or item.get('estimated_value') or '0'
            try:
                est_val = float(str(val_str).replace(',', '').replace('₹', '').strip() or 0)
            except Exception:
                est_val = 0.0

            from_person = item.get('from') or item.get('stolen_from') or ''
            qty_str = item.get('quantity') or '1'
            try:
                qty = float(qty_str)
            except Exception:
                qty = 1.0

            is_recovered = str(item.get('recovered', '')).lower() in ['yes', 'true', '1']
            cat_code = 'RECOVERED_STOLEN_PROPERTY' if is_recovered else 'STOLEN_PROPERTY'

            discovered.append({
                'source_module': src_mod,
                'source_record_id': src_id,
                'title': str(item.get('property') or desc)[:50],
                'description': str(desc),
                'seized_from': str(from_person),
                'quantity': qty,
                'unit': 'Numbers',
                'unit_value': est_val / qty if qty > 0 else est_val,
                'total_item_value': est_val,
                'inferred_category_code': cat_code,
                'is_already_linked': is_linked,
                'linked_property_uid': linked_info['property_uid'] if linked_info else None,
                'linked_property_id': linked_info['id'] if linked_info else None,
                'raw_source': 'Case JSON (stolenProperties list)',
            })

    # 2b. Single stolenProperty
    single_stolen = extra.get('stolenProperty') or extra.get('stolen_property')
    if isinstance(single_stolen, dict) and not stolen_list:
        src_id = "stolen_prop_single"
        src_mod = 'theft_stolen_property'
        lookup_key = f"{src_mod}::{src_id}"
        is_linked = lookup_key in linked_map
        linked_info = linked_map.get(lookup_key)

        desc = single_stolen.get('description') or single_stolen.get('property') or 'Stolen Property'
        val_str = single_stolen.get('estValue') or single_stolen.get('value') or '0'
        try:
            est_val = float(str(val_str).replace(',', '').replace('₹', '').strip() or 0)
        except Exception:
            est_val = 0.0

        discovered.append({
            'source_module': src_mod,
            'source_record_id': src_id,
            'title': str(desc)[:50],
            'description': str(desc),
            'seized_from': str(single_stolen.get('from') or ''),
            'quantity': 1.0,
            'unit': 'Numbers',
            'unit_value': est_val,
            'total_item_value': est_val,
            'inferred_category_code': 'STOLEN_PROPERTY',
            'is_already_linked': is_linked,
            'linked_property_uid': linked_info['property_uid'] if linked_info else None,
            'linked_property_id': linked_info['id'] if linked_info else None,
            'raw_source': 'Case JSON (stolenProperty single)',
        })

    return discovered


@transaction.atomic
def link_source_property_to_muddemal(
    register: MuddemalRegister,
    source_module: str,
    source_record_id: str,
    property_category_code: Optional[str] = None,
    description: str = '',
    quantity: Any = 1,
    unit: str = 'Numbers',
    unit_value: Any = 0,
    total_item_value: Any = 0,
    seized_from: str = '',
    owner_name: str = '',
    seizure_date: Optional[Any] = None,
    property_status: str = 'Seized',
    fsl_required: bool = False,
    extra_fields: Optional[Dict[str, Any]] = None,
    user_uid: str = ''
) -> tuple[MuddemalProperty, bool]:
    """
    Idempotently links an existing module source property to a MuddemalRegister.
    If already linked under this register, returns the existing record (created=False).
    Otherwise creates a new MuddemalProperty (created=True) and logs an audit trail.
    """
    # 1. Idempotency Check
    existing = MuddemalProperty.objects.filter(
        muddemal_record=register,
        source_module=source_module,
        source_record_id=source_record_id
    ).first()

    if existing:
        return existing, False

    # 2. Resolve Category
    if not property_category_code:
        property_category_code = _infer_category_code(description, '', source_module)

    cat_obj = MuddemalPropertyCategory.objects.filter(category_code=property_category_code).first()
    if not cat_obj:
        cat_obj = MuddemalPropertyCategory.objects.filter(category_code='SEIZED_PROPERTY').first()
    if not cat_obj:
        cat_obj = MuddemalPropertyCategory.objects.first()

    # 3. Generate unique Property UID on backend
    property_uid, serial_no = generate_unique_property_uid(register)

    # 4. Compute valuation
    t_val = compute_item_value(quantity, unit_value, total_item_value)

    # 5. Create MuddemalProperty
    new_prop = MuddemalProperty.objects.create(
        property_uid=property_uid,
        muddemal_record=register,
        source_module=source_module,
        source_record_id=source_record_id,
        property_category=cat_obj,
        property_serial_no=serial_no,
        description=description or f"Imported from {source_module}",
        quantity=Decimal(str(quantity or 1)),
        unit=unit or 'Numbers',
        unit_value=Decimal(str(unit_value or 0)),
        total_item_value=t_val,
        valuation_status='Assessed' if t_val > 0 else 'Pending',
        seized_from=seized_from or '',
        owner_name=owner_name or '',
        seizure_date=seizure_date or timezone.now().date(),
        property_status=property_status,
        fsl_required=fsl_required,
        extra_fields=extra_fields or {},
        created_by=user_uid or 'system_import',
    )

    # 6. Audit Trail
    MuddemalAuditLog.objects.create(
        property=new_prop,
        muddemal_record=register,
        action='LINK_SOURCE_PROPERTY',
        performed_by=user_uid or 'system_import',
        performed_by_name=f"User {user_uid}" if user_uid else 'System Import',
        details={
            'source_module': source_module,
            'source_record_id': source_record_id,
            'property_uid': property_uid,
            'valuation': float(t_val),
            'category': cat_obj.category_code,
        }
    )

    return new_prop, True
