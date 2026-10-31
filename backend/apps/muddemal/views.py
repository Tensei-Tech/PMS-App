import logging
from rest_framework import viewsets, status
from rest_framework.views import APIView

logger = logging.getLogger(__name__)
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from decimal import Decimal

from apps.cases.models import CaseRecord
from apps.muddemal.models import (
    MuddemalRegister,
    MuddemalPropertyCategory,
    MuddemalFieldDefinition,
    MuddemalProperty,
    MuddemalPropertyMovement,
    MuddemalFSLRecord,
    MuddemalDisposal,
    MuddemalAuditLog,
    MuddemalConfig,
)
from apps.muddemal.serializers import (
    MuddemalConfigSerializer,
    MuddemalPropertyCategorySerializer,
    MuddemalFieldDefinitionSerializer,
    MuddemalRegisterSerializer,
    MuddemalPropertySerializer,
    MuddemalPropertyMovementSerializer,
    MuddemalFSLRecordSerializer,
    MuddemalDisposalSerializer,
    MuddemalAuditLogSerializer,
)
from apps.muddemal.services.id_generator import (
    generate_unique_register_number,
    generate_unique_property_uid,
)
from apps.muddemal.services.valuation_service import (
    compute_item_value,
    calculate_register_valuations,
)
from apps.muddemal.services.cross_module_service import (
    discover_case_source_properties,
    link_source_property_to_muddemal,
)
from apps.muddemal.services.fsl_alert_service import get_fsl_alerts
from apps.muddemal.services.dashboard_service import (
    get_stolen_property_dashboard,
    get_seized_property_dashboard,
    get_pending_muddemal_dashboard,
    get_month_year_reports,
)


class MuddemalTenantMixin:
    """
    Ensures active tenant schema is safely resolved to the appropriate state schema
    (defaulting to 'maharashtra') for all Muddemal operations, preventing UndefinedTable
    errors when requests arrive without explicit state headers.
    """
    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        from apps.core.tenancy import set_tenant_schema
        schema = getattr(request, 'state_schema', None)
        if not schema or schema == 'public':
            state_code = getattr(request, 'state_code', None) or (
                request.headers.get('X-State-Code') if hasattr(request, 'headers') else None
            )
            if state_code and str(state_code).upper() != 'GLOBAL':
                from apps.core.middleware import _STATE_SCHEMA_CACHE
                schema = _STATE_SCHEMA_CACHE.get(str(state_code).upper(), 'maharashtra')
            else:
                schema = 'maharashtra'
        set_tenant_schema(schema)


class MuddemalConfigView(MuddemalTenantMixin, APIView):
    """
    Returns all backend-driven configuration tokens:
    alert thresholds, measurement units, property statuses, movement types, disposal types.
    Ensures zero frontend hardcoding.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        configs = MuddemalConfig.objects.all()
        config_dict = {}
        for c in configs:
            config_dict[c.config_key] = c.config_value

        # Dynamically compute available years from DB records + current year
        years = set()
        years.add(timezone.now().year)
        try:
            reg_years = MuddemalRegister.objects.exclude(registration_date__isnull=True).values_list('registration_date__year', flat=True).distinct()
            for y in reg_years:
                if y:
                    years.add(int(y))
            prop_years = MuddemalProperty.objects.exclude(created_at__isnull=True).values_list('created_at__year', flat=True).distinct()
            for y in prop_years:
                if y:
                    years.add(int(y))
        except Exception as e:
            pass
        config_dict['available_years'] = sorted(list(years), reverse=True)

        # Always inject connected source modules metadata
        from apps.muddemal.services.auto_fetch_service import get_connected_source_modules_metadata
        config_dict['source_modules'] = get_connected_source_modules_metadata()

        # Inject categories summary
        cats = MuddemalPropertyCategory.objects.filter(is_active=True).order_by('display_order')
        from apps.muddemal.serializers import MuddemalPropertyCategorySerializer
        config_dict['categories'] = MuddemalPropertyCategorySerializer(cats, many=True).data

        return Response({
            'success': True,
            'configs': config_dict,
        })


class MuddemalCategoryViewSet(MuddemalTenantMixin, viewsets.ReadOnlyModelViewSet):
    """
    Lists and provides details for 21 backend-driven property categories.
    """
    permission_classes = [AllowAny]
    pagination_class = None
    queryset = MuddemalPropertyCategory.objects.filter(is_active=True).order_by('display_order')
    serializer_class = MuddemalPropertyCategorySerializer

    @action(detail=True, methods=['get'], url_path='fields')
    def get_category_fields(self, request, pk=None):
        """Fetch all dynamic form field definitions for this category."""
        # Support either numeric PK or category_code string
        if pk and not str(pk).isdigit():
            category = get_object_or_404(MuddemalPropertyCategory, category_code=pk)
        else:
            category = get_object_or_404(MuddemalPropertyCategory, pk=pk)

        fields = MuddemalFieldDefinition.objects.filter(
            category=category,
            is_active=True
        ).order_by('display_order', 'id')

        serializer = MuddemalFieldDefinitionSerializer(fields, many=True)
        return Response({
            'success': True,
            'category_code': category.category_code,
            'category_name': category.category_name,
            'rules': category.applicable_property_rules,
            'fields': serializer.data,
        })


class MuddemalRegisterViewSet(MuddemalTenantMixin, viewsets.ModelViewSet):
    """
    Muddemal Register management endpoints.
    A single CR case is linked to one or more registers.
    """
    permission_classes = [AllowAny]
    queryset = MuddemalRegister.objects.all().order_by('-registration_date', '-id')
    serializer_class = MuddemalRegisterSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        station = self.request.query_params.get('station_name')
        station_id = self.request.query_params.get('police_station_id')
        cr = self.request.query_params.get('cr_number')
        status_filter = self.request.query_params.get('record_status')
        io = self.request.query_params.get('io_name')
        year = self.request.query_params.get('year')

        if station and station.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
            qs = qs.filter(station_name=station)
        if station_id and station_id.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
            qs = qs.filter(police_station_id=station_id)
        if cr:
            qs = qs.filter(cr_number_snapshot__icontains=cr)
        if status_filter:
            qs = qs.filter(record_status=status_filter)
        if io:
            qs = qs.filter(investigating_officer_name__icontains=io)
        if year:
            qs = qs.filter(registration_date__year=int(year))

        return qs

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        station_name = data.get('station_name') or 'Default Station'
        station_id = data.get('police_station_id') or ''
        cr_case_id = data.get('cr_case_id') or data.get('cr_case')
        cr_snapshot = data.get('cr_number_snapshot') or data.get('cr_number') or ''

        # If cr_case_id provided, sync station and CR info
        case_obj = None
        if cr_case_id:
            case_obj = CaseRecord.objects.filter(pk=cr_case_id).first()
            if case_obj:
                if not cr_snapshot:
                    cr_snapshot = case_obj.case_number or case_obj.title
                if not station_name or station_name == 'Default Station':
                    station_name = case_obj.station_name

        # Auto-generate unique Register No
        register_no = data.get('muddemal_register_no')
        if not register_no:
            register_no = generate_unique_register_number(station_name, station_id)

        user_uid = getattr(request.user, 'uid', getattr(request.user, 'username', 'anonymous'))

        register = MuddemalRegister.objects.create(
            muddemal_register_no=register_no,
            police_station_id=station_id or (case_obj.station_name if case_obj else 'PS'),
            station_name=station_name,
            cr_case=case_obj,
            cr_number_snapshot=cr_snapshot or 'CR-00/2026',
            registration_date=data.get('registration_date') or timezone.now().date(),
            investigating_officer_id=data.get('investigating_officer_id') or (case_obj.assigned_officer_uid if case_obj else ''),
            investigating_officer_name=data.get('investigating_officer_name') or (case_obj.assigned_officer if case_obj else ''),
            record_status=data.get('record_status', 'Active'),
            remarks=data.get('remarks', ''),
            created_by=user_uid,
        )

        MuddemalAuditLog.objects.create(
            muddemal_record=register,
            action='CREATE_REGISTER',
            performed_by=user_uid,
            performed_by_name=getattr(request.user, 'name', user_uid),
            details={'register_no': register_no, 'cr_number': cr_snapshot, 'station': station_name}
        )

        serializer = self.get_serializer(register)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'], url_path='properties')
    def get_register_properties(self, request, pk=None):
        register = self.get_object()
        props = register.properties.all().order_by('property_serial_no', '-created_at')
        serializer = MuddemalPropertySerializer(props, many=True)
        valuations = calculate_register_valuations(register)
        return Response({
            'success': True,
            'register_no': register.muddemal_register_no,
            'cr_number': register.cr_number_snapshot,
            'valuations': valuations,
            'properties': serializer.data,
        })


class CasePropertiesView(MuddemalTenantMixin, APIView):
    """
    Endpoints for a specific CR Case:
    - Get all linked Muddemal properties
    - Discover properties from Crime / Seizure / Theft modules
    - Idempotently link discovered properties
    """
    permission_classes = [AllowAny]

    def get(self, request, case_id):
        case_obj = get_object_or_404(CaseRecord, pk=case_id)
        registers = MuddemalRegister.objects.filter(cr_case=case_obj).order_by('-registration_date')

        props = MuddemalProperty.objects.filter(
            muddemal_record__cr_case=case_obj
        ).order_by('property_serial_no', '-created_at')

        serializer = MuddemalPropertySerializer(props, many=True)
        reg_serializer = MuddemalRegisterSerializer(registers, many=True)

        return Response({
            'success': True,
            'case_id': case_obj.id,
            'cr_number': case_obj.case_number or case_obj.title,
            'station_name': case_obj.station_name,
            'registers': reg_serializer.data,
            'properties': serializer.data,
        })


class CaseDiscoverablePropertiesView(MuddemalTenantMixin, APIView):
    """
    Discovers candidate properties from SeizureRecords table and Case JSON extra_fields.
    Flags already linked properties to prevent duplicate linking.
    """
    permission_classes = [AllowAny]

    def get(self, request, case_id):
        case_obj = get_object_or_404(CaseRecord, pk=case_id)
        discovered = discover_case_source_properties(case_obj)
        return Response({
            'success': True,
            'case_id': case_obj.id,
            'cr_number': case_obj.case_number or case_obj.title,
            'discovered_count': len(discovered),
            'discovered_properties': discovered,
        })


class CaseLinkPropertyView(MuddemalTenantMixin, APIView):
    """
    Links a discovered source-module property into Muddemal idempotently.
    """
    permission_classes = [AllowAny]

    @transaction.atomic
    def post(self, request, case_id):
        case_obj = get_object_or_404(CaseRecord, pk=case_id)
        data = request.data

        # Find or create MuddemalRegister for this case
        register_id = data.get('muddemal_record_id') or data.get('register_id')
        register = None
        if register_id:
            register = MuddemalRegister.objects.filter(pk=register_id).first()

        if not register:
            register = MuddemalRegister.objects.filter(cr_case=case_obj).first()

        if not register:
            reg_no = generate_unique_register_number(case_obj.station_name)
            register = MuddemalRegister.objects.create(
                muddemal_register_no=reg_no,
                police_station_id=case_obj.station_name,
                station_name=case_obj.station_name,
                cr_case=case_obj,
                cr_number_snapshot=case_obj.case_number or case_obj.title,
                registration_date=timezone.now().date(),
                investigating_officer_id=case_obj.assigned_officer_uid or '',
                investigating_officer_name=case_obj.assigned_officer or '',
                record_status='Active',
                remarks='Auto-created register for property link',
                created_by=getattr(request.user, 'uid', 'system_import'),
            )

        source_module = data.get('source_module') or 'manual'
        source_record_id = data.get('source_record_id') or f"src_{timezone.now().timestamp()}"

        user_uid = getattr(request.user, 'uid', getattr(request.user, 'username', 'anonymous'))

        prop, created = link_source_property_to_muddemal(
            register=register,
            source_module=source_module,
            source_record_id=str(source_record_id),
            property_category_code=data.get('category_code') or data.get('property_category_code'),
            description=data.get('description', ''),
            quantity=data.get('quantity', 1),
            unit=data.get('unit', 'Numbers'),
            unit_value=data.get('unit_value', 0),
            total_item_value=data.get('total_item_value', 0),
            seized_from=data.get('seized_from', ''),
            owner_name=data.get('owner_name', ''),
            seizure_date=data.get('seizure_date'),
            property_status=data.get('property_status', 'Seized'),
            fsl_required=bool(data.get('fsl_required', False)),
            extra_fields=data.get('extra_fields', {}),
            user_uid=user_uid,
        )

        serializer = MuddemalPropertySerializer(prop)
        return Response({
            'success': True,
            'is_newly_linked': created,
            'message': 'Property successfully linked' if created else 'Property was already linked to this register',
            'property': serializer.data,
        }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class MuddemalPropertyViewSet(MuddemalTenantMixin, viewsets.ModelViewSet):
    """
    Centralized Muddemal Property ViewSet:
    - Automatically discovers and returns qualifying seized properties from all PMS source modules.
    - Preserves source relationships, original CR, and police station boundaries.
    - Prevents duplicates via stable source identifiers.
    - Generates unique property UIDs, calculates valuations, logs audits.
    """
    permission_classes = [AllowAny]
    queryset = MuddemalProperty.objects.select_related(
        'muddemal_record', 'muddemal_record__cr_case', 'property_category'
    ).prefetch_related('movements', 'fsl_records', 'disposals').all().order_by('-created_at')
    serializer_class = MuddemalPropertySerializer

    def get_queryset(self):
        # 1. Automatic data-fetching from all connected PMS source modules
        station = self.request.query_params.get('station_name')
        try:
            from apps.muddemal.services.auto_fetch_service import sync_all_source_module_properties
            sync_all_source_module_properties(
                station_name=station,
                user=self.request.user,
                force=False
            )
        except Exception as e:
            logger.warning(f"Error in Muddemal auto-sync during query: {e}")

        qs = super().get_queryset()

        # 2. Access control and station boundaries
        user = self.request.user
        if not (getattr(user, 'is_superuser', False) or getattr(user, 'is_staff', False)):
            user_st = getattr(user, 'station_name', '')
            add_st = getattr(user, 'additional_stations', []) or []
            allowed = [s for s in [user_st] + add_st if s]
            if allowed:
                qs = qs.filter(muddemal_record__station_name__in=allowed)

        if station and station.strip().upper() not in ['ALL', 'ALL STATIONS', 'ALL_STATIONS', 'ALL POLICE STATIONS']:
            qs = qs.filter(muddemal_record__station_name=station)

        # 3. Dynamic filters
        reg_id = self.request.query_params.get('register_id')
        if reg_id:
            qs = qs.filter(muddemal_record_id=reg_id)

        case_id = self.request.query_params.get('case_id')
        if case_id:
            qs = qs.filter(muddemal_record__cr_case_id=case_id)

        cr_number = self.request.query_params.get('cr_number')
        if cr_number:
            qs = qs.filter(muddemal_record__cr_number_snapshot__icontains=cr_number)

        cat = self.request.query_params.get('category_code') or self.request.query_params.get('category')
        if cat and cat.strip().upper() != 'ALL':
            qs = qs.filter(property_category__category_code=cat)

        status_p = self.request.query_params.get('property_status')
        if status_p and status_p.strip().upper() != 'ALL':
            qs = qs.filter(property_status=status_p)

        source_mod = self.request.query_params.get('source_module')
        if source_mod and source_mod.strip().lower() != 'all':
            qs = qs.filter(source_module__iexact=source_mod)

        fsl = self.request.query_params.get('fsl_required')
        if fsl is not None and str(fsl).strip() != '':
            qs = qs.filter(fsl_required=str(fsl).lower() in ['true', '1'])

        year = self.request.query_params.get('year')
        if year and str(year).isdigit():
            qs = qs.filter(
                Q(seizure_date__year=int(year)) |
                Q(muddemal_record__registration_date__year=int(year))
            )

        # Search filter
        search_q = self.request.query_params.get('search') or self.request.query_params.get('q')
        if search_q and search_q.strip():
            sq = search_q.strip()
            qs = qs.filter(
                Q(property_uid__icontains=sq) |
                Q(description__icontains=sq) |
                Q(owner_name__icontains=sq) |
                Q(seized_from__icontains=sq) |
                Q(muddemal_record__cr_number_snapshot__icontains=sq) |
                Q(muddemal_record__muddemal_register_no__icontains=sq) |
                Q(property_category__category_name__icontains=sq) |
                Q(source_module__icontains=sq)
            ).distinct()

        return qs

    @action(detail=False, methods=['post', 'get'], url_path='sync')
    def sync_sources(self, request):
        """
        Manually trigger/force auto-fetch sync across all PMS source modules.
        Returns detailed synchronization results and statistics.
        """
        station = request.query_params.get('station_name') or request.data.get('station_name')
        from apps.muddemal.services.auto_fetch_service import sync_all_source_module_properties
        res = sync_all_source_module_properties(
            station_name=station,
            user=request.user,
            force=True
        )
        return Response({
            'success': True,
            'message': 'Source modules successfully synced with Muddemal register',
            'result': res,
        })

    @action(detail=False, methods=['get'], url_path='summary')
    def get_summary(self, request):
        """
        Returns real-time backend-computed valuation aggregates directly from the database
        for the active station and query filters. Zero frontend hardcoding.
        """
        qs = self.get_queryset()
        from apps.muddemal.services.valuation_service import calculate_property_set_valuations
        valuations = calculate_property_set_valuations(qs)
        return Response({
            'success': True,
            'summary': valuations,
        })

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        register_id = data.get('muddemal_record') or data.get('muddemal_record_id')
        register = get_object_or_404(MuddemalRegister, pk=register_id)

        # Resolve category by code or id
        cat_id = data.get('property_category') or data.get('property_category_id')
        cat_code = data.get('category_code')
        cat_obj = None
        if cat_code:
            cat_obj = MuddemalPropertyCategory.objects.filter(category_code=cat_code).first()
        if not cat_obj and cat_id:
            if str(cat_id).isdigit():
                cat_obj = MuddemalPropertyCategory.objects.filter(pk=int(cat_id)).first()
            else:
                cat_obj = MuddemalPropertyCategory.objects.filter(category_code=str(cat_id)).first()
        if not cat_obj:
            cat_obj = MuddemalPropertyCategory.objects.first()

        # Generate unique Property UID on backend
        property_uid, serial_no = generate_unique_property_uid(register)

        # Automatic Backend Valuation
        qty = Decimal(str(data.get('quantity', 1) or 1))
        u_val = Decimal(str(data.get('unit_value', 0) or 0))
        tot_val = compute_item_value(qty, u_val, data.get('total_item_value'))

        user_uid = getattr(request.user, 'uid', getattr(request.user, 'username', 'anonymous'))

        new_prop = MuddemalProperty.objects.create(
            property_uid=property_uid,
            muddemal_record=register,
            source_module=data.get('source_module', 'manual'),
            source_record_id=data.get('source_record_id', ''),
            property_category=cat_obj,
            property_serial_no=serial_no,
            description=data.get('description', ''),
            quantity=qty,
            unit=data.get('unit', 'Numbers'),
            unit_value=u_val,
            total_item_value=tot_val,
            valuation_status=data.get('valuation_status', 'Assessed' if tot_val > 0 else 'Pending'),
            owner_name=data.get('owner_name', ''),
            seized_from=data.get('seized_from', ''),
            seizure_date=data.get('seizure_date') or timezone.now().date(),
            recovery_date=data.get('recovery_date'),
            property_status=data.get('property_status', 'Seized'),
            fsl_required=bool(data.get('fsl_required', False)),
            remarks=data.get('remarks', ''),
            extra_fields=data.get('extra_fields', {}),
            created_by=user_uid,
        )

        # Record Initial Custody Movement (Muddemal Room In)
        MuddemalPropertyMovement.objects.create(
            property=new_prop,
            from_location=data.get('seized_from') or 'Seizure Spot',
            to_location='Muddemal Room (मालखाना)',
            movement_type='Muddemal Room In',
            movement_date=timezone.now(),
            responsible_officer=register.investigating_officer_name or 'Station In-Charge',
            reference_no=register.muddemal_register_no,
            remarks='Initial property registration and deposit in Muddemal Room',
            created_by=user_uid,
        )

        MuddemalAuditLog.objects.create(
            property=new_prop,
            muddemal_record=register,
            action='CREATE_PROPERTY',
            performed_by=user_uid,
            performed_by_name=getattr(request.user, 'name', user_uid),
            details={
                'property_uid': property_uid,
                'category': cat_obj.category_code,
                'valuation': float(tot_val),
                'quantity': float(qty),
            }
        )

        serializer = self.get_serializer(new_prop)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @transaction.atomic
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', True)
        instance = self.get_object()
        data = request.data.copy()

        # Resolve category by category_code or property_category
        cat_code = data.get('category_code')
        cat_id = data.get('property_category') or data.get('property_category_id')
        if cat_code:
            cat_obj = MuddemalPropertyCategory.objects.filter(category_code=cat_code).first()
            if cat_obj:
                data['property_category'] = cat_obj.id
        elif cat_id and not str(cat_id).isdigit():
            cat_obj = MuddemalPropertyCategory.objects.filter(category_code=str(cat_id)).first()
            if cat_obj:
                data['property_category'] = cat_obj.id

        if not data.get('muddemal_record') and instance.muddemal_record_id:
            data['muddemal_record'] = instance.muddemal_record_id

        if not data.get('property_category') and instance.property_category_id:
            data['property_category'] = instance.property_category_id

        # Recompute total_item_value if quantity or unit_value is updated
        qty = data.get('quantity')
        u_val = data.get('unit_value')
        tot_val = data.get('total_item_value')
        if qty is not None or u_val is not None:
            try:
                d_qty = Decimal(str(qty if qty is not None else instance.quantity))
                d_uval = Decimal(str(u_val if u_val is not None else instance.unit_value))
                data['total_item_value'] = compute_item_value(d_qty, d_uval, tot_val)
            except Exception:
                pass

        # Clean empty date/number strings
        if data.get('seizure_date') == '' or data.get('seizure_date') is None:
            data['seizure_date'] = None
        if data.get('recovery_date') == '' or data.get('recovery_date') is None:
            data['recovery_date'] = None

        old_valuation = instance.total_item_value
        old_status = instance.property_status

        serializer = self.get_serializer(instance, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        user_uid = getattr(request.user, 'uid', getattr(request.user, 'username', 'anonymous'))
        serializer.save(updated_by=user_uid)

        instance.refresh_from_db()
        user_uid = getattr(request.user, 'uid', getattr(request.user, 'username', 'anonymous'))

        # Recalculate register valuations
        try:
            calculate_register_valuations(instance.muddemal_record)
        except Exception:
            pass

        # Log valuation change
        if instance.total_item_value != old_valuation:
            MuddemalAuditLog.objects.create(
                property=instance,
                muddemal_record=instance.muddemal_record,
                action='UPDATE_VALUATION',
                performed_by=user_uid,
                performed_by_name=getattr(request.user, 'name', user_uid),
                details={
                    'previous_value': float(old_valuation),
                    'new_value': float(instance.total_item_value),
                    'valuation_status': instance.valuation_status,
                }
            )

        # Log status transition
        if instance.property_status != old_status:
            MuddemalAuditLog.objects.create(
                property=instance,
                muddemal_record=instance.muddemal_record,
                action='STATUS_TRANSITION',
                performed_by=user_uid,
                performed_by_name=getattr(request.user, 'name', user_uid),
                details={
                    'previous_status': old_status,
                    'new_status': instance.property_status,
                }
            )

        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='movements')
    @transaction.atomic
    def record_movement(self, request, pk=None):
        """Append a new custody movement (append-only) and optionally update property status."""
        prop = self.get_object()
        data = request.data
        user_uid = getattr(request.user, 'uid', getattr(request.user, 'username', 'anonymous'))

        movement = MuddemalPropertyMovement.objects.create(
            property=prop,
            from_location=data.get('from_location', 'Muddemal Room (मालखाना)'),
            to_location=data.get('to_location', ''),
            movement_type=data.get('movement_type', 'Sent to Court'),
            movement_date=data.get('movement_date') or timezone.now(),
            responsible_officer=data.get('responsible_officer', ''),
            reference_no=data.get('reference_no', ''),
            remarks=data.get('remarks', ''),
            created_by=user_uid,
        )

        # Status synchronization if provided
        new_status = data.get('new_property_status')
        if new_status and new_status != prop.property_status:
            prop.property_status = new_status
            prop.save(update_fields=['property_status', 'updated_at'])

        MuddemalAuditLog.objects.create(
            property=prop,
            muddemal_record=prop.muddemal_record,
            action='CUSTODY_MOVEMENT',
            performed_by=user_uid,
            performed_by_name=getattr(request.user, 'name', user_uid),
            details={
                'from': movement.from_location,
                'to': movement.to_location,
                'movement_type': movement.movement_type,
                'reference_no': movement.reference_no,
            }
        )

        serializer = MuddemalPropertyMovementSerializer(movement)
        return Response({
            'success': True,
            'message': 'Chain of custody movement recorded',
            'movement': serializer.data,
            'property_status': prop.property_status,
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'], url_path='next-fsl-reference')
    def next_fsl_reference(self, request, pk=None):
        """Returns dynamically generated FSL reference number for a property."""
        prop = self.get_object()
        lab_code = request.query_params.get('lab_code')
        from apps.muddemal.services.id_generator import generate_unique_fsl_reference
        ref_no = generate_unique_fsl_reference(prop, lab_code=lab_code)
        return Response({
            'success': True,
            'fsl_reference_no': ref_no,
            'lab_code': lab_code,
        })

    @action(detail=True, methods=['post'], url_path='fsl')
    @transaction.atomic
    def record_fsl(self, request, pk=None):
        """Record FSL laboratory dispatch or receive report."""
        prop = self.get_object()
        data = request.data
        user_uid = getattr(request.user, 'uid', getattr(request.user, 'username', 'anonymous'))

        fsl_id = data.get('fsl_record_id')
        if fsl_id:
            # Update existing dispatch report
            fsl = get_object_or_404(MuddemalFSLRecord, pk=fsl_id, property=prop)
            fsl.report_received_status = data.get('report_received_status', 'Received')
            fsl.report_received_date = data.get('report_received_date') or timezone.now().date()
            fsl.report_reference = data.get('report_reference', fsl.report_reference)
            fsl.remarks = data.get('remarks', fsl.remarks)
            fsl.save()

            if fsl.report_received_status == 'Received':
                prop.property_status = 'Produced Before Court'
                prop.save(update_fields=['property_status', 'updated_at'])

            action_name = 'FSL_REPORT_RECEIVED'
        else:
            # Create new dispatch - ensure backend generated unique reference
            fsl_ref = (data.get('fsl_reference_no') or '').strip()
            if not fsl_ref:
                from apps.muddemal.services.id_generator import generate_unique_fsl_reference
                fsl_ref = generate_unique_fsl_reference(prop, lab_code=data.get('lab_code'))

            fsl = MuddemalFSLRecord.objects.create(
                property=prop,
                fsl_reference_no=fsl_ref,
                dispatch_date=data.get('dispatch_date') or timezone.now().date(),
                dispatch_details=data.get('dispatch_details', ''),
                report_received_status='Pending',
                remarks=data.get('remarks', ''),
                created_by=user_uid,
            )
            prop.property_status = 'FSL Report Pending'
            prop.fsl_required = True
            prop.save(update_fields=['property_status', 'fsl_required', 'updated_at'])
            action_name = 'FSL_DISPATCH'

        MuddemalAuditLog.objects.create(
            property=prop,
            muddemal_record=prop.muddemal_record,
            action=action_name,
            performed_by=user_uid,
            performed_by_name=getattr(request.user, 'name', user_uid),
            details={
                'fsl_reference_no': fsl.fsl_reference_no,
                'status': fsl.report_received_status,
                'report_date': str(fsl.report_received_date) if fsl.report_received_date else None,
            }
        )

        serializer = MuddemalFSLRecordSerializer(fsl)
        return Response({
            'success': True,
            'message': 'FSL details recorded',
            'fsl_record': serializer.data,
            'property_status': prop.property_status,
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], url_path='disposal')
    @transaction.atomic
    def record_disposal(self, request, pk=None):
        """Record return to owner, Supurdnama, destruction or court disposal."""
        prop = self.get_object()
        data = request.data
        user_uid = getattr(request.user, 'uid', getattr(request.user, 'username', 'anonymous'))

        disposal_type = data.get('disposal_type', 'Supurdnama')
        disposal = MuddemalDisposal.objects.create(
            property=prop,
            disposal_type=disposal_type,
            court_order_reference=data.get('court_order_reference', ''),
            order_date=data.get('order_date'),
            owner_recipient_details=data.get('owner_recipient_details', {}),
            supurdnama_details=data.get('supurdnama_details', {}),
            disposal_date=data.get('disposal_date') or timezone.now().date(),
            authorization_details=data.get('authorization_details', ''),
            remarks=data.get('remarks', ''),
            created_by=user_uid,
        )

        # Map to property status
        status_map = {
            'Supurdnama': 'Released on Supurdnama',
            'Returned to Owner': 'Returned to Owner',
            'Destruction': 'Destroyed',
            'Auction': 'Disposed',
            'Forfeiture': 'Disposed',
            'Other': 'Disposed',
        }
        prop.property_status = status_map.get(disposal_type, 'Disposed')
        prop.save(update_fields=['property_status', 'updated_at'])

        MuddemalAuditLog.objects.create(
            property=prop,
            muddemal_record=prop.muddemal_record,
            action='DISPOSAL_RECORDED',
            performed_by=user_uid,
            performed_by_name=getattr(request.user, 'name', user_uid),
            details={
                'disposal_type': disposal_type,
                'court_order': disposal.court_order_reference,
                'new_status': prop.property_status,
            }
        )

        serializer = MuddemalDisposalSerializer(disposal)
        return Response({
            'success': True,
            'message': 'Disposal recorded successfully',
            'disposal': serializer.data,
            'property_status': prop.property_status,
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'], url_path='audit-trail')
    def get_audit_trail(self, request, pk=None):
        prop = self.get_object()
        logs = MuddemalAuditLog.objects.filter(property=prop).order_by('-created_at')
        serializer = MuddemalAuditLogSerializer(logs, many=True)
        return Response({
            'success': True,
            'property_uid': prop.property_uid,
            'audit_trail': serializer.data,
        })


class FSLAlertsView(MuddemalTenantMixin, APIView):
    """
    Evaluates and returns pending FSL alerts against 7, 15, and 30 day thresholds.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        station = request.query_params.get('station_name')
        station_id = request.query_params.get('police_station_id')
        io_name = request.query_params.get('io_name')
        io_id = request.query_params.get('io_id')

        alerts = get_fsl_alerts(station, station_id, io_name, io_id)
        return Response({
            'success': True,
            'alerts': alerts,
        })


class StolenPropertyDashboardView(MuddemalTenantMixin, APIView):
    """
    Stolen Property Dashboard metrics: Total Theft Cases, Total Stolen Value,
    Recovered Value, Not Recovered Value, Recovery %, 100% Recovery, Partial, Zero.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        data = get_stolen_property_dashboard(
            station_name=request.query_params.get('station_name'),
            police_station_id=request.query_params.get('police_station_id'),
            cr_number=request.query_params.get('cr_number'),
            io_name=request.query_params.get('io_name'),
            year=request.query_params.get('year'),
            month=request.query_params.get('month'),
        )
        return Response({'success': True, 'dashboard': data})


class SeizedPropertyDashboardView(MuddemalTenantMixin, APIView):
    """
    Seized Property Dashboard metrics across all categories.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        data = get_seized_property_dashboard(
            station_name=request.query_params.get('station_name'),
            police_station_id=request.query_params.get('police_station_id'),
            cr_number=request.query_params.get('cr_number'),
            io_name=request.query_params.get('io_name'),
            year=request.query_params.get('year'),
            month=request.query_params.get('month'),
        )
        return Response({'success': True, 'dashboard': data})


class PendingMuddemalDashboardView(MuddemalTenantMixin, APIView):
    """
    Pending Muddemal Dashboard metrics: FSL Send Pending, FSL Report Pending,
    Disposal Pending, Court Pending, Long-pending (>30, >90, >180 days).
    """
    permission_classes = [AllowAny]

    def get(self, request):
        data = get_pending_muddemal_dashboard(
            station_name=request.query_params.get('station_name'),
            police_station_id=request.query_params.get('police_station_id'),
            cr_number=request.query_params.get('cr_number'),
            io_name=request.query_params.get('io_name'),
            year=request.query_params.get('year'),
            month=request.query_params.get('month'),
        )
        return Response({'success': True, 'dashboard': data})


class MonthYearReportsView(MuddemalTenantMixin, APIView):
    """
    Month-wise and Year-wise comparative reports and trends.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        data = get_month_year_reports(
            station_name=request.query_params.get('station_name'),
            police_station_id=request.query_params.get('police_station_id'),
            year=request.query_params.get('year'),
        )
        return Response({'success': True, 'report': data})


class MuddemalAutoFetchStatusView(MuddemalTenantMixin, APIView):
    """
    Provides real-time inspection of connected source modules, auto-fetch status,
    and deduplicated property counts per source module.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        from apps.muddemal.services.auto_fetch_service import get_connected_source_modules_metadata
        modules = get_connected_source_modules_metadata()
        station = request.query_params.get('station_name')

        props_qs = MuddemalProperty.objects.all()
        if station and station.strip().upper() != 'ALL':
            props_qs = props_qs.filter(muddemal_record__station_name=station)

        total_props = props_qs.count()
        source_breakdown = {}
        for m in modules:
            code = m['code']
            if code == 'all':
                source_breakdown[code] = total_props
            else:
                source_breakdown[code] = props_qs.filter(source_module=code).count()

        return Response({
            'success': True,
            'status': 'active',
            'connected_source_modules': modules,
            'total_properties': total_props,
            'source_breakdown': source_breakdown,
            'last_sync_timestamp': timezone.now().isoformat(),
        })

