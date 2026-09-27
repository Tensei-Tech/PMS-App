"""
Transfer service stubs pending Phase 2 rebuild.
"""
from typing import Dict, Any


def execute_case_transfer(case_id: str, transfer_payload: Dict[str, Any], officer_profile: Any = None):
    raise NotImplementedError("Case transfer is disabled pending Phase 2 rebuild.")


def assign_transferred_case(transfer_id: int, assigned_to_io_uid: str, assigned_to_io_name: str, assigning_officer: Any = None):
    raise NotImplementedError("Assigning transferred case is disabled pending Phase 2 rebuild.")
