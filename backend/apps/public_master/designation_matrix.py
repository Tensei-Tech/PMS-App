"""
Which designations may hold which admin role, from the
PMS Police Admin Role / Designation Matrix (4-Level Admin Matrix).

MUST     - normally the primary designation for that admin level.
OPTIONAL - allowed when the officer's posting supports it.
NEVER    - not given that admin level.

One designation can be allowed at several levels. A spelling variant of a
designation (e.g. "Addl. SP" for "Add.SP") follows the same row.
"""
MUST, OPTIONAL, NEVER = 'must', 'optional', 'never'

ADMIN_ROLES = ('state_admin', 'district_admin', 'division_admin', 'station_admin')

#              State      District   Division   Station
MATRIX = {
    'DG':     (MUST,     NEVER,     NEVER,     NEVER),
    'ADG':    (MUST,     OPTIONAL,  NEVER,     NEVER),
    'IG':     (MUST,     OPTIONAL,  NEVER,     NEVER),
    'DIG':    (MUST,     OPTIONAL,  OPTIONAL,  NEVER),
    'CP':     (OPTIONAL, MUST,      OPTIONAL,  NEVER),
    'SP':     (OPTIONAL, MUST,      OPTIONAL,  NEVER),
    'SSP':    (OPTIONAL, MUST,      OPTIONAL,  NEVER),
    'Add.SP': (OPTIONAL, OPTIONAL,  MUST,      NEVER),
    'Add.CP': (OPTIONAL, OPTIONAL,  MUST,      NEVER),
    'DCP':    (OPTIONAL, MUST,      MUST,      NEVER),
    'ACP':    (NEVER,    OPTIONAL,  MUST,      NEVER),
    'DySP':   (NEVER,    OPTIONAL,  MUST,      NEVER),
    'SDPO':   (NEVER,    OPTIONAL,  MUST,      NEVER),
    'PI':     (NEVER,    OPTIONAL,  OPTIONAL,  MUST),
    'API':    (NEVER,    NEVER,     OPTIONAL,  MUST),
    'PSI':    (NEVER,    NEVER,     OPTIONAL,  MUST),
    'SI':     (NEVER,    NEVER,     OPTIONAL,  MUST),
    'SHO':    (NEVER,    NEVER,     NEVER,     MUST),
}

SPELLINGS = {
    'DGP': 'DG',
    'ADGP': 'ADG',
    'Addl.SP': 'Add.SP',
    'Addl. SP': 'Add.SP',
    'Addl. CP': 'Add.CP',
    'Addl.CP': 'Add.CP',
    'Dy. SP': 'DySP',
    'Station Head': 'SHO',
}


def rules_for(code):
    """The matrix row for a designation code (or its spelling variant), or None."""
    return MATRIX.get(SPELLINGS.get(code, code))


def admin_fields(code, allowed_categories=()):
    """
    Designation field values for a matrix row: the four is_*_admin_allowed
    flags and allowed_admin_roles (MUST levels first, so the app pre-selects
    the primary one), plus 'admin_officer' in allowed_categories.
    """
    row = rules_for(code)
    if row is None:
        return None
    must = [role for role, rule in zip(ADMIN_ROLES, row) if rule == MUST]
    optional = [role for role, rule in zip(ADMIN_ROLES, row) if rule == OPTIONAL]
    categories = [c for c in allowed_categories if c != 'admin_officer']
    if 'field_officer' not in categories and code not in ('DG', 'DGP', 'ADG', 'ADGP'):
        categories.insert(0, 'field_officer')
    categories.append('admin_officer')
    return {
        'is_state_admin_allowed': row[0] != NEVER,
        'is_district_admin_allowed': row[1] != NEVER,
        'is_division_admin_allowed': row[2] != NEVER,
        'is_station_admin_allowed': row[3] != NEVER,
        'allowed_admin_roles': must + optional,
        'allowed_categories': categories,
    }


def apply_matrix(designation_model):
    """Update every existing designation row that the matrix covers."""
    updated = 0
    for designation in designation_model.objects.all():
        fields = admin_fields(designation.code, designation.allowed_categories or [])
        if fields is None:
            continue
        for name, value in fields.items():
            setattr(designation, name, value)
        designation.save(update_fields=list(fields))
        updated += 1
    return updated


# A city (police commissionerate) admin, and everyone a city admin onboards,
# holds one of these designations.
CITY_DESIGNATIONS = ('DG', 'ADG', 'CP', 'Jt.CP', 'Addl. CP', 'DCP', 'ACP', 'PI', 'API', 'PSI')


def _designation_key(value):
    return ''.join(ch for ch in str(value or '').upper() if ch.isalnum())


_CITY_KEYS = {_designation_key(d) for d in CITY_DESIGNATIONS} | {'ADDCP', 'JOINTCP'}


def is_city_designation(value):
    """True for a city designation, whatever its spacing or dots ('Addl.CP', 'JT. CP')."""
    return _designation_key(value) in _CITY_KEYS


# A district admin, and everyone a district admin onboards, holds one of these.
DISTRICT_DESIGNATIONS = ('DG', 'ADG', 'IG', 'DIG', 'SP', 'Addl. SP', 'SDPO', 'PI', 'API', 'PSI')

_DISTRICT_KEYS = {_designation_key(d) for d in DISTRICT_DESIGNATIONS} | {'ADDSP'}


def is_district_designation(value):
    """True for a district designation, whatever its spacing or dots ('Add.SP', 'ADDL SP')."""
    return _designation_key(value) in _DISTRICT_KEYS


# A division admin sits under a city or under a district, so holds a
# designation from either list (just one list when a city or district admin
# onboards them).
DIVISION_DESIGNATIONS = tuple(dict.fromkeys(CITY_DESIGNATIONS + DISTRICT_DESIGNATIONS))


def is_division_designation(value):
    return is_city_designation(value) or is_district_designation(value)
