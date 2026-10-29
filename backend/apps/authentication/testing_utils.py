"""Helpers for tests that sign up through the public API."""
from django.db import DatabaseError, transaction

from apps.core.tenancy import TenantContext
from apps.public_master.models import StateRegistry
from apps.users.models import OfficerProfile


def activate_account(email):
    """
    Public sign-up leaves accounts pending; activate one directly. Sign-up
    saves the profile in the state schema and a public copy, and login reads
    the state schema, so every copy is updated.
    """
    schemas = set(StateRegistry.objects.values_list('schema_name', flat=True)) | {'public'}
    for schema in schemas:
        try:
            # Savepoint: a registered state whose schema was never provisioned
            # must not break the test's transaction.
            with TenantContext(schema), transaction.atomic():
                OfficerProfile.objects.filter(email=email).update(account_status='active')
        except DatabaseError:
            pass
