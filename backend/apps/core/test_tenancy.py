import threading
from django.test import TestCase, RequestFactory
from django.db import connection
from apps.core.tenancy import (
    TenantContext,
    set_tenant_schema,
    get_active_tenant_schema,
    provision_state_schema,
    _get_schema_stack,
)
from apps.public_master.models import MasterDivision


class TenancyStackSafetyTests(TestCase):
    """
    Tests proving stack-safety, nested context restoration,
    and clean tenant resolution without leakage.
    """

    def setUp(self):
        # Clear thread-local stack before each test
        stack = _get_schema_stack()
        stack.clear()
        set_tenant_schema('public')

    def tearDown(self):
        stack = _get_schema_stack()
        stack.clear()
        set_tenant_schema('public')

    def test_nested_tenant_context_restoration(self):
        """
        Test item 2:
        enter TenantContext('kerala'), inside that enter TenantContext('maharashtra'),
        exit the inner one, confirm search_path correctly returns to 'kerala' (not 'public').
        Then exit the outer one, confirm it returns to 'public'.
        """
        self.assertEqual(get_active_tenant_schema(), 'public')

        with TenantContext('kerala'):
            self.assertEqual(get_active_tenant_schema(), 'kerala')
            with connection.cursor() as cursor:
                cursor.execute("SHOW search_path;")
                current_sp = cursor.fetchone()[0]
                self.assertTrue(current_sp.startswith('"kerala"') or current_sp.startswith('kerala'))

            with TenantContext('maharashtra'):
                self.assertEqual(get_active_tenant_schema(), 'maharashtra')
                with connection.cursor() as cursor:
                    cursor.execute("SHOW search_path;")
                    current_sp = cursor.fetchone()[0]
                    self.assertTrue(current_sp.startswith('"maharashtra"') or current_sp.startswith('maharashtra'))

            # Exited inner 'maharashtra' -> must be 'kerala'
            self.assertEqual(get_active_tenant_schema(), 'kerala')
            with connection.cursor() as cursor:
                cursor.execute("SHOW search_path;")
                current_sp = cursor.fetchone()[0]
                self.assertTrue(current_sp.startswith('"kerala"') or current_sp.startswith('kerala'))

        # Exited outer 'kerala' -> must be 'public'
        self.assertEqual(get_active_tenant_schema(), 'public')
        with connection.cursor() as cursor:
            cursor.execute("SHOW search_path;")
            current_sp = cursor.fetchone()[0]
            self.assertTrue(current_sp.startswith('public') or 'public' in current_sp)

    def test_multi_level_deep_nesting(self):
        """Test nesting 3 levels deep: state1 -> state2 -> state3"""
        with TenantContext('state_one'):
            self.assertEqual(get_active_tenant_schema(), 'state_one')
            with TenantContext('state_two'):
                self.assertEqual(get_active_tenant_schema(), 'state_two')
                with TenantContext('state_three'):
                    self.assertEqual(get_active_tenant_schema(), 'state_three')
                self.assertEqual(get_active_tenant_schema(), 'state_two')
            self.assertEqual(get_active_tenant_schema(), 'state_one')
        self.assertEqual(get_active_tenant_schema(), 'public')

    def test_exception_safety_in_nested_context(self):
        """Confirm stack pops cleanly even if an exception occurs inside inner block."""
        with TenantContext('outer_tenant'):
            self.assertEqual(get_active_tenant_schema(), 'outer_tenant')
            try:
                with TenantContext('failing_inner_tenant'):
                    self.assertEqual(get_active_tenant_schema(), 'failing_inner_tenant')
                    raise RuntimeError("Simulated failure in inner tenant")
            except RuntimeError:
                pass
            
            # Stack must have recovered to outer_tenant
            self.assertEqual(get_active_tenant_schema(), 'outer_tenant')
        self.assertEqual(get_active_tenant_schema(), 'public')

    def test_tenant_resolution_header_precedence(self):
        """Test get_active_tenant_schema with request headers and fallbacks."""
        rf = RequestFactory()

        # 1. Inside TenantContext, thread context takes precedence
        with TenantContext('context_tenant'):
            req = rf.get('/api/test/', HTTP_X_TENANT_SCHEMA='header_tenant')
            self.assertEqual(get_active_tenant_schema(req), 'context_tenant')

        # 2. Outside TenantContext, HTTP_X_TENANT_SCHEMA is used
        req1 = rf.get('/api/test/', HTTP_X_TENANT_SCHEMA='bihar')
        self.assertEqual(get_active_tenant_schema(req1), 'bihar')

        # 3. HTTP_X_STATE_SCHEMA fallback
        req2 = rf.get('/api/test/', HTTP_X_STATE_SCHEMA='punjab')
        self.assertEqual(get_active_tenant_schema(req2), 'punjab')

        # 4. No headers, no context -> returns 'public' (loud warning logged)
        req_empty = rf.get('/api/test/')
        self.assertEqual(get_active_tenant_schema(req_empty), 'public')

        # 5. No request object at all -> returns 'public'
        self.assertEqual(get_active_tenant_schema(None), 'public')

    def test_tenant_middleware_no_headers_resolves_to_public(self):
        """
        Verify that TenantMiddleware processes a request with no state header or JWT
        by intentionally assigning schema_name='public' (NOT 'maharashtra' or another tenant).
        """
        from apps.core.middleware import TenantMiddleware
        rf = RequestFactory()
        req = rf.get('/api/v1/master/states/')
        middleware = TenantMiddleware(lambda r: None)
        middleware.process_request(req)

        self.assertEqual(req.state_schema, 'public')
        self.assertIn(req.state_code, (None, ''))
        self.assertEqual(get_active_tenant_schema(req), 'public')
        with connection.cursor() as cursor:
            cursor.execute("SHOW search_path;")
            current_sp = cursor.fetchone()[0]
            self.assertTrue('public' in current_sp)


    def test_provision_state_schema_and_isolation(self):
        """Test provisioning a fresh tenant schema from scratch and querying master_divisions."""
        test_schema = 'kerala_test_unit'
        provision_state_schema(test_schema, state_code='KL', state_name='Kerala')

        with TenantContext(test_schema):
            # Verify we can query master_divisions in the new schema
            divs = list(MasterDivision.objects.all())
            self.assertIsInstance(divs, list)

    def test_concurrent_threads_schema_isolation(self):
        """Confirm simultaneous threads with different tenants maintain isolated stacks without cross-contamination."""
        errors = []

        def worker(schema_name, expected_depth):
            try:
                for _ in range(5):
                    with TenantContext(schema_name):
                        active = get_active_tenant_schema()
                        if active != schema_name:
                            errors.append(f"Expected {schema_name}, got {active}")
                        # Nested call inside thread
                        with TenantContext(f"{schema_name}_sub"):
                            sub_active = get_active_tenant_schema()
                            if sub_active != f"{schema_name}_sub":
                                errors.append(f"Expected {schema_name}_sub, got {sub_active}")
                        # Post inner exit
                        post_active = get_active_tenant_schema()
                        if post_active != schema_name:
                            errors.append(f"Post inner exit expected {schema_name}, got {post_active}")
            except Exception as e:
                errors.append(str(e))

        threads = [
            threading.Thread(target=worker, args=(f"tenant_{i}", 1))
            for i in range(10)
        ]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        self.assertEqual(len(errors), 0, f"Thread concurrency errors: {errors}")

