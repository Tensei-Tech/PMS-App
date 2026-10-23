"""Run a test inside a state's schema, like a real request does."""
from apps.core.tenancy import TenantContext

# A state schema that exists on every migrated database (migration 0133 gives it the
# RTI / History Sheeter / MPDA / N.C. tables).
TEST_STATE_SCHEMA = 'maharashtra'


def enter_state_schema(testcase, schema=TEST_STATE_SCHEMA):
    """Open TenantContext(schema) for the rest of the test and close it afterwards."""
    context = TenantContext(schema)
    context.__enter__()
    testcase.addCleanup(context.__exit__, None, None, None)
