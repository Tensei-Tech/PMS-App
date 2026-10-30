import re
from datetime import datetime
from django.db import transaction
from apps.muddemal.models import MuddemalRegister, MuddemalProperty, MuddemalConfig, MuddemalFSLRecord


def _clean_code(text: str, max_len: int = 10) -> str:
    """Extract clean uppercase alphanumeric code from a station or title."""
    if not text:
        return 'PS'
    cleaned = re.sub(r'[^A-Za-z0-9]', '', str(text)).upper()
    return cleaned[:max_len] if cleaned else 'PS'


def _clean_cr_number(cr_str: str) -> str:
    """Extract standard CR number string (e.g. '125/2026' -> '125')."""
    if not cr_str:
        return '00'
    match = re.search(r'(\d+)', str(cr_str))
    return match.group(1) if match else re.sub(r'[^A-Za-z0-9]', '', str(cr_str))[:10]


@transaction.atomic
def generate_unique_register_number(station_name: str, station_id: str = '') -> str:
    """
    Generates an atomic, unique Muddemal Register number.
    Format: MUDD/{STATION_CODE}/{YEAR}/{SEQ:04d}
    """
    year = datetime.now().year
    code = _clean_code(station_id or station_name, max_len=8)
    prefix = f"MUDD/{code}/{year}/"

    latest = (
        MuddemalRegister.objects.select_for_update()
        .filter(muddemal_register_no__startswith=prefix)
        .order_by('-id')
        .first()
    )

    if latest:
        try:
            last_seq = int(latest.muddemal_register_no.split('/')[-1])
            next_seq = last_seq + 1
        except (ValueError, IndexError):
            next_seq = (
                MuddemalRegister.objects.filter(muddemal_register_no__startswith=prefix).count() + 1
            )
    else:
        next_seq = 1

    candidate = f"{prefix}{next_seq:04d}"
    while MuddemalRegister.objects.filter(muddemal_register_no=candidate).exists():
        next_seq += 1
        candidate = f"{prefix}{next_seq:04d}"

    return candidate


@transaction.atomic
def generate_unique_property_uid(register: MuddemalRegister) -> tuple[str, int]:
    """
    Generates a unique Property UID on the backend with database-level concurrency protection.
    Format: CR-{CR_NO}/{YEAR} (with /P-{SERIAL:02d} suffix only if multiple properties exist for this CR)
    Returns: (property_uid, serial_no)
    """
    locked_reg = MuddemalRegister.objects.select_for_update().get(pk=register.pk)
    cr_part = _clean_cr_number(locked_reg.cr_number_snapshot)
    reg_year = locked_reg.registration_date.year if locked_reg.registration_date else datetime.now().year

    existing_count = MuddemalProperty.objects.filter(muddemal_record=locked_reg).count()
    serial_no = existing_count + 1

    base_uid = f"CR-{cr_part}/{reg_year}"
    if serial_no == 1 and not MuddemalProperty.objects.filter(property_uid=base_uid).exists():
        candidate = base_uid
    else:
        candidate = f"CR-{cr_part}/{reg_year}/P-{serial_no:02d}"

    while MuddemalProperty.objects.filter(property_uid=candidate).exists():
        serial_no += 1
        candidate = f"CR-{cr_part}/{reg_year}/P-{serial_no:02d}"

    return candidate, serial_no


@transaction.atomic
def generate_unique_fsl_reference(property_item: MuddemalProperty, lab_code: str = None) -> str:
    """
    Generates a unique, atomic FSL reference number based on backend database configuration.
    Uses MuddemalConfig ('fsl_reference_format') to ensure format and regional lab settings
    are fully database-driven without hardcoding.
    """
    cfg_row = MuddemalConfig.objects.filter(config_key='fsl_reference_format').first()
    cfg = cfg_row.config_value if cfg_row and isinstance(cfg_row.config_value, dict) else {}

    prefix = cfg.get('prefix', 'FSL')
    default_lab = cfg.get('default_lab', 'PUNE')
    selected_lab = _clean_code(lab_code or default_lab, max_len=12)
    year = datetime.now().year

    clean_prop_uid = re.sub(r'[^A-Za-z0-9]', '-', str(property_item.property_uid)).strip('-')
    fmt = cfg.get('format', '{prefix}/{lab}/{year}/{prop_uid}')

    try:
        base_ref = fmt.format(
            prefix=prefix,
            lab=selected_lab,
            year=year,
            prop_uid=clean_prop_uid
        )
    except Exception:
        base_ref = f"{prefix}/{selected_lab}/{year}/{clean_prop_uid}"

    candidate = base_ref
    seq = 1
    # Concurrency safe check against MuddemalFSLRecord
    while MuddemalFSLRecord.objects.select_for_update().filter(fsl_reference_no=candidate).exists():
        seq += 1
        candidate = f"{base_ref}-{seq:02d}"

    return candidate
