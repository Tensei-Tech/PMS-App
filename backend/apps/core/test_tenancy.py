import threading
from django.test import TestCase, RequestFactory
from django.db import connection, transaction
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


    def test_cross_request_connection_reuse_isolation(self):
        """
        Critical cross-request connection reuse test:
        1. Request A handles 'kerala_test_cross', queries data, completes via process_response.
        2. Request B arrives on the SAME connection with NO state headers/context.
        3. Confirm Request B does NOT see Kerala data or Kerala search_path on the connection.
        """
        from django.http import HttpResponse
        from apps.core.middleware import TenantMiddleware

        # 1. Provision Kerala schema and insert record
        kerala_schema = 'kerala_test_cross'
        provision_state_schema(kerala_schema, state_code='KL', state_name='Kerala')
        with TenantContext(kerala_schema):
            MasterDivision.objects.get_or_create(
                name='Kochi Division',
                state_code='KL',
                defaults={'code': 'DIV-KL-KOC', 'state_name': 'Kerala'}
            )

        rf = RequestFactory()
        middleware = TenantMiddleware(lambda r: HttpResponse("OK"))

        # 2. Request A: Kerala request
        req_a = rf.get('/api/test/', HTTP_X_TENANT_SCHEMA=kerala_schema)
        middleware.process_request(req_a)
        self.assertEqual(req_a.state_schema, kerala_schema)

        # Inside Request A, Kerala division is accessible
        with connection.cursor() as cursor:
            cursor.execute("SHOW search_path;")
            sp_a = cursor.fetchone()[0]
            self.assertTrue(kerala_schema in sp_a)

        res_a = HttpResponse("OK")
        middleware.process_response(req_a, res_a)

        # 3. Verify connection search_path is immediately reset to 'public' (NOT 'kerala_test_cross' or 'maharashtra')
        with connection.cursor() as cursor:
            cursor.execute("SHOW search_path;")
            post_a_sp = cursor.fetchone()[0]
            self.assertEqual(post_a_sp, 'public')

        # 4. Request B: Arrives with NO state headers on the SAME database connection
        req_b = rf.get('/api/test/')
        
        # Verify before Request B's resolution, the connection is clean 'public'
        with connection.cursor() as cursor:
            cursor.execute("SHOW search_path;")
            pre_b_sp = cursor.fetchone()[0]
            self.assertEqual(pre_b_sp, 'public')

        middleware.process_request(req_b)
        self.assertEqual(req_b.state_schema, 'public')
        self.assertEqual(get_active_tenant_schema(req_b), 'public')

        # Confirm previous tenant's schema is not present in Request B's search path (no cross-tenant leakage)
        with connection.cursor() as cursor:
            cursor.execute("SHOW search_path;")
            b_active_sp = cursor.fetchone()[0]
            self.assertNotIn(kerala_schema, b_active_sp)
            self.assertEqual(b_active_sp, 'public')

        # Complete Request B
        res_b = HttpResponse("OK")
        middleware.process_response(req_b, res_b)
        with connection.cursor() as cursor:
            cursor.execute("SHOW search_path;")
            post_b_sp = cursor.fetchone()[0]
            self.assertEqual(post_b_sp, 'public')


    def test_concurrent_threads_schema_isolation(self):
        """Confirm simultaneous threads with different tenants maintain isolated stacks without cross-contamination."""
        errors = []

        def worker(schema_name):
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
            threading.Thread(target=worker, args=(f"tenant_{i}",))
            for i in range(4)
        ]
        for t in threads:
            t.start()
        for t in threads:
            t.join()

        self.assertEqual(len(errors), 0, f"Thread concurrency errors: {errors}")

    def test_no_tenant_header_division_lookup_fail_fast_boundary(self):
        """
        Regression test for 'no tenant header + division lookup':
        Confirm that querying division endpoints without any state context
        fails fast with HTTP 400 Bad Request instead of attempting to query public.master_divisions
        or silently returning empty data.
        """
        from apps.public_master.views import MasterDivisionsView
        from apps.crimetab.views import LocationDivisionsView
        rf = RequestFactory()

        # 1. MasterDivisionsView with no header / query param
        req1 = rf.get('/api/v1/master/hierarchy/divisions/')
        res1 = MasterDivisionsView.as_view()(req1)
        self.assertEqual(res1.status_code, 400)
        self.assertIn('error', res1.data)
        self.assertIn('State tenant context is required', res1.data['error'])

        # 2. LocationDivisionsView with no header / query param
        req2 = rf.get('/api/v1/crimetab/locations/divisions/')
        res2 = LocationDivisionsView.as_view()(req2)
        self.assertEqual(res2.status_code, 400)
        self.assertIn('error', res2.data)
        self.assertIn('State tenant context is required', res2.data['error'])

    def test_explicit_tenant_header_division_lookup_success(self):
        """
        Confirm that division endpoints with explicit state context
        properly route to tenant schema and return HTTP 200 OK with data.
        """
        from apps.public_master.views import MasterDivisionsView
        from apps.crimetab.views import LocationDivisionsView
        from apps.public_master.models import StateRegistry

        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )

        rf = RequestFactory()

        # 1. Query with ?state_code=MH
        req1 = rf.get('/api/v1/master/hierarchy/divisions/?state_code=MH')
        res1 = MasterDivisionsView.as_view()(req1)
        self.assertEqual(res1.status_code, 200)
        self.assertIsInstance(res1.data, list)

        # 2. Query with ?state_id=MH
        req2 = rf.get('/api/v1/crimetab/locations/divisions/?state_id=MH')
        res2 = LocationDivisionsView.as_view()(req2)
        self.assertEqual(res2.status_code, 200)
        self.assertIsInstance(res2.data, list)


