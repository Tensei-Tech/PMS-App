import logging
from typing import Optional
from apps.crimetab.models.common_form import CasesPerson

logger = logging.getLogger(__name__)


def get_or_create_person_for_case(
    case_id: str,
    typed_name: Optional[str] = None,
    existing_person_id: Optional[int] = None,
    role: str = 'accused',
) -> int:
    """
    Resolves a person reference for Arrest / Discharge / Seizure.
    - If existing_person_id is given (user picked from dropdown), use it as-is.
    - If typed_name is given instead (user typed a new name not in the list),
      create a new CasesPerson record for them first, then use that new id.
    Returns a real person_id either way — never a bare string.
    """
    if existing_person_id:
        # If passed as object or string, cast to int
        try:
            return int(existing_person_id)
        except (ValueError, TypeError):
            pass

    if not typed_name or not str(typed_name).strip():
        raise ValueError("Must provide either existing_person_id or typed_name")

    cleaned_name = str(typed_name).strip()

    # If a person with this name already exists on the case for this role, reuse
    existing = CasesPerson.objects.filter(
        case_id=case_id,
        name__iexact=cleaned_name,
        role=role
    ).first()
    if existing:
        return existing.person_id

    new_person = CasesPerson.objects.create(
        case_id=case_id,
        role=role,
        name=cleaned_name
    )
    return new_person.person_id
