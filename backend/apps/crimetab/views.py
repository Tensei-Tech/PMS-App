import uuid
import logging
from django.db import transaction, IntegrityError
from django.db.models import Q
from rest_framework import status, viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny

from apps.cases.models import CaseRecord
from apps.public_master.models import MasterDivision
from apps.stations.models import District, PoliceStation
from apps.crimetab.models.groupings import CaseCategoryGroup, CaseCategory, CaseCategoryLink
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CaseExtraFieldValue,
)
from apps.crimetab.models.common_form import (
    CrimeRegistrationInfo,
    Act,
    ActSection,
    ActSubsection,
    CrimeCaseActsSections,
    CrimeSpot,
    CasesPerson,
    CrimeCaseResponsibility,
    ArrestReleaseStatus,
    RemandCustody,
    CctvTechnical,
    ProceduralChecklist,
    CaseForensics,
    SeizureRecords,
    PreventiveActionItems,
    PreventiveBond,
    DischargeStatus,
    ScrutinyPipeline,
    FinalVerdict,
)
from apps.crimetab.serializers import (
    CaseCategoryGroupSerializer,
    CaseCategorySerializer,
    FullCaseDetailSerializer,
    ActSerializer,
    ActSectionSerializer,
)
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.counter_service import get_group_counters, get_category_counters
from apps.crimetab.services.person_service import get_or_create_person_for_case

logger = logging.getLogger(__name__)


# ==========================================
# 1. Group & Category ViewSets
# ==========================================
class CaseCategoryGroupViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CaseCategoryGroup.objects.all().order_by('display_order', 'group_id')
    serializer_class = CaseCategoryGroupSerializer
    permission_classes = [AllowAny]

    @action(detail=True, methods=['get'])
    def counters(self, request, pk=None):
        station_name = request.query_params.get('station_name') or getattr(request, 'station_name', None)
        data = get_group_counters(int(pk), station_name=station_name)
        return Response(data)

    @action(detail=True, methods=['get'])
    def categories(self, request, pk=None):
        cats = CaseCategory.objects.filter(group_id=pk, is_active=True).order_by('display_order', 'category_id')
        serializer = CaseCategorySerializer(cats, many=True)
        return Response(serializer.data)


class CaseCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CaseCategorySerializer
    permission_classes = [AllowAny]
    pagination_class = None
    lookup_value_regex = r'[^/]+'

    def get_queryset(self):
        qs = CaseCategory.objects.filter(is_active=True).order_by('display_order', 'category_id')
        params = self.request.query_params

        # 1. Standalone filter: /api/categories/?standalone=true (group IS NULL)
        standalone = params.get('standalone')
        if standalone is not None:
            if standalone.lower() in ['true', '1']:
                qs = qs.filter(group__isnull=True)
            elif standalone.lower() in ['false', '0']:
                qs = qs.filter(group__isnull=False)

        # 2. Top-level only filter: /api/categories/?top_level=true (parent IS NULL)
        top_level = params.get('top_level')
        if top_level is not None:
            if top_level.lower() in ['true', '1']:
                qs = qs.filter(parent_category__isnull=True)
            elif top_level.lower() in ['false', '0']:
                qs = qs.filter(parent_category__isnull=False)

        # 3. Group filter: /api/categories/?group=1 or ?group=I TO V or ?group_code=VI
        group_val = params.get('group') or params.get('group_id')
        if group_val:
            if str(group_val).isdigit():
                qs = qs.filter(group_id=int(group_val))
            else:
                qs = qs.filter(Q(group__group_code__iexact=group_val) | Q(group__group_name__iexact=group_val))

        group_code = params.get('group_code')
        if group_code:
            qs = qs.filter(group__group_code__iexact=group_code)

        # 4. Parent filter: /api/categories/?parent=36 or ?parent_category_id=36
        parent_id = params.get('parent') or params.get('parent_id') or params.get('parent_category_id')
        if parent_id:
            if str(parent_id).isdigit():
                qs = qs.filter(parent_category_id=int(parent_id))

        # 5. Search filter: /api/categories/?search=theft
        search = params.get('search')
        if search:
            qs = qs.filter(category_name__icontains=search.strip())

        return qs

    @action(detail=False, methods=['get'])
    def standalone(self, request):
        """
        GET /api/categories/standalone/?station_name=...
        Returns all top-level standalone tabs with their live counters.
        """
        station_name = request.query_params.get('station_name') or getattr(request, 'station_name', None)
        include_counters = request.query_params.get('include_counters', 'true').lower() in ['true', '1']
        cats = CaseCategory.objects.filter(
            group__isnull=True,
            parent_category__isnull=True,
            is_active=True
        ).order_by('display_order', 'category_id')

        results = []
        for c in cats:
            c_data = CaseCategorySerializer(c).data
            if include_counters:
                c_data['counters'] = get_category_counters(c.category_id, station_name=station_name)
            c_data['has_children'] = CaseCategory.objects.filter(parent_category_id=c.category_id, is_active=True).exists()
            results.append(c_data)
        return Response(results)

    @action(detail=False, methods=['get'], url_path='dashboard-tabs')
    def dashboard_tabs(self, request):
        """
        GET /api/categories/dashboard-tabs/?station_name=...
        Returns unified dashboard structure:
        - groups: 1 to 5 and Part 6 with their top-level categories and live counters
        - standalone: all standalone categories with live counters
        """
        station_name = request.query_params.get('station_name') or getattr(request, 'station_name', None)
        groups_data = []
        for g in CaseCategoryGroup.objects.all().order_by('display_order', 'group_id'):
            g_cats = CaseCategory.objects.filter(group=g, parent_category__isnull=True, is_active=True).order_by('display_order', 'category_id')
            groups_data.append({
                'group_id': g.group_id,
                'group_name': g.group_name,
                'group_code': g.group_code,
                'display_order': g.display_order,
                'counters': get_group_counters(g.group_id, station_name=station_name),
                'categories': [
                    {
                        **CaseCategorySerializer(cat).data,
                        'counters': get_category_counters(cat.category_id, station_name=station_name),
                        'has_children': CaseCategory.objects.filter(parent_category_id=cat.category_id, is_active=True).exists(),
                    }
                    for cat in g_cats
                ]
            })

        standalone_cats = CaseCategory.objects.filter(
            group__isnull=True,
            parent_category__isnull=True,
            is_active=True
        ).order_by('display_order', 'category_id')

        standalone_data = [
            {
                **CaseCategorySerializer(cat).data,
                'counters': get_category_counters(cat.category_id, station_name=station_name),
                'has_children': CaseCategory.objects.filter(parent_category_id=cat.category_id, is_active=True).exists(),
            }
            for cat in standalone_cats
        ]

        return Response({
            'groups': groups_data,
            'standalone': standalone_data,
        })

    @action(detail=False, methods=['get'])
    def standalone(self, request):
        """
        GET /api/categories/standalone/
        Returns all active standalone categories (group_id IS NULL).
        """
        station_name = request.query_params.get('station_name') or getattr(request, 'station_name', None)
        standalone_cats = CaseCategory.objects.filter(
            group__isnull=True,
            is_active=True
        ).order_by('display_order', 'category_id')
        results = []
        for cat in standalone_cats:
            c_data = CaseCategorySerializer(cat).data
            c_data['counters'] = get_category_counters(cat.category_id, station_name=station_name)
            c_data['has_children'] = CaseCategory.objects.filter(parent_category_id=cat.category_id, is_active=True).exists()
            results.append(c_data)
        return Response(results)

    @action(detail=True, methods=['get'])
    def counters(self, request, pk=None):
        if str(pk).isdigit():
            cat_id = int(pk)
        else:
            cat = CaseCategory.objects.filter(category_name__iexact=pk).first()
            if not cat:
                return Response({'error': f'Category {pk} not found'}, status=status.HTTP_404_NOT_FOUND)
            cat_id = cat.category_id

        station_name = request.query_params.get('station_name') or getattr(request, 'station_name', None)
        data = get_category_counters(cat_id, station_name=station_name)
        return Response(data)

    @action(detail=True, methods=['get'])
    def children(self, request, pk=None):
        if str(pk).isdigit():
            cat_id = int(pk)
        else:
            cat = CaseCategory.objects.filter(category_name__iexact=pk).first()
            if not cat:
                return Response({'error': f'Category {pk} not found'}, status=status.HTTP_404_NOT_FOUND)
            cat_id = cat.category_id

        station_name = request.query_params.get('station_name') or getattr(request, 'station_name', None)
        children_cats = CaseCategory.objects.filter(parent_category_id=cat_id, is_active=True).order_by('display_order', 'category_id')
        results = []
        for c in children_cats:
            c_data = CaseCategorySerializer(c).data
            c_data['counters'] = get_category_counters(c.category_id, station_name=station_name)
            c_data['has_children'] = CaseCategory.objects.filter(parent_category_id=c.category_id, is_active=True).exists()
            results.append(c_data)
        return Response(results)

    @action(detail=True, methods=['get'], url_path='form-definition')
    def form_definition(self, request, pk=None):
        if str(pk).isdigit():
            category_id = int(pk)
        else:
            cat = CaseCategory.objects.filter(
                Q(category_name__iexact=pk) | Q(category_code__iexact=pk)
            ).first()
            if not cat:
                return Response({'error': f'Category {pk} not found'}, status=status.HTTP_404_NOT_FOUND)
            category_id = cat.category_id

        case_id = request.query_params.get('case_id')
        section_ids_raw = request.query_params.get('section_ids') or request.query_params.get('sections') or ''
        section_ids = [s.strip() for s in section_ids_raw.split(',') if s.strip()]

        form_def = get_form_definition(
            category_id=category_id,
            case_id=case_id,
            charged_section_ids=section_ids
        )
        return Response(form_def)

    @action(detail=True, methods=['get'])
    def cases(self, request, pk=None):
        if str(pk).isdigit():
            category_id = int(pk)
            category = CaseCategory.objects.filter(pk=category_id).first()
        else:
            category = CaseCategory.objects.filter(category_name__iexact=pk).first()
            category_id = category.category_id if category else None

        if not category:
            return Response({'error': 'Category not found'}, status=status.HTTP_404_NOT_FOUND)

        station_name = request.query_params.get('station_name')
        status_filter = request.query_params.get('status')
        search = request.query_params.get('search')

        from apps.crimetab.services.counter_service import get_descendant_category_ids
        descendant_ids = get_descendant_category_ids(category_id)
        linked_case_ids = CaseCategoryLink.objects.filter(category_id__in=descendant_ids).values_list('case_id', flat=True)

        cat_names = list(CaseCategory.objects.filter(category_id__in=descendant_ids).values_list('category_name', flat=True))
        q_filter = Q(id__in=linked_case_ids)
        for name in cat_names:
            q_filter |= Q(sub_category__iexact=name)

        qs = CaseRecord.objects.filter(q_filter)

        if station_name:
            qs = qs.filter(station_name__iexact=station_name)
        if status_filter:
            qs = qs.filter(status__iexact=status_filter)
        if search:
            qs = qs.filter(
                Q(case_number__icontains=search) |
                Q(title__icontains=search) |
                Q(complainant__icontains=search) |
                Q(accused__icontains=search)
            )

        serializer = FullCaseDetailSerializer(qs.order_by('-created_at')[:100], many=True)
        return Response({
            'category_id': category_id,
            'category_name': category.category_name,
            'total_cases': qs.count(),
            'cases': serializer.data,
        })


# ==========================================
# 2. Case Helper Methods
# ==========================================
from datetime import datetime
from django.utils.dateparse import parse_datetime, parse_date


def _parse_dt(val):
    if not val or not str(val).strip():
        return None
    s = str(val).strip()
    parsed = parse_datetime(s)
    if parsed:
        return parsed
    for fmt in [
        '%d/%m/%Y %H:%M',
        '%d/%m/%Y %H:%M:%S',
        '%d/%m/%Y %I:%M %p',
        '%d/%m/%Y',
        '%d-%m-%Y %H:%M',
        '%d-%m-%Y %H:%M:%S',
        '%d-%m-%Y',
        '%Y-%m-%d %H:%M:%S',
        '%Y-%m-%d %H:%M',
        '%Y-%m-%d',
    ]:
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            continue
    return None


def _parse_d(val):
    if not val or not str(val).strip():
        return None
    s = str(val).strip()
    parsed = parse_date(s)
    if parsed:
        return parsed
    dt = _parse_dt(s)
    return dt.date() if dt else None


def _save_case_child_entities(case: CaseRecord, data: dict):
    """
    Saves or updates all 1:1 and 1:N relational entities from the JSON payload.
    Unifies Seizure, Arrest, and Discharge around get_or_create_person_for_case across all tabs.
    """
    extra = data.get('extra_fields') or {}
    cf = extra.get('commonForm') if isinstance(extra, dict) else {}
    m = {**(extra if isinstance(extra, dict) else {}), **(cf if isinstance(cf, dict) else {}), **data}

    # 1. Registration Info
    reg_data = m.get('registration_info') or {}
    cr_no = reg_data.get('cr_number') or m.get('crNo') or data.get('case_number')
    reg_dt = _parse_dt(reg_data.get('registered_datetime') or m.get('regDate') or data.get('incident_date'))
    is_unk = bool(reg_data.get('is_unknown_accused', False) or m.get('isUnknownAccused', False))
    if cr_no or reg_dt or is_unk:
        CrimeRegistrationInfo.objects.update_or_create(
            case=case,
            defaults={
                'cr_number': cr_no or case.case_number,
                'registered_datetime': reg_dt,
                'is_unknown_accused': is_unk,
            }
        )

    # 2. Crime Spot
    spot_data = m.get('crime_spot') or {}
    v_town = spot_data.get('village_town') or m.get('spotVillage')
    a_name = spot_data.get('area_name') or m.get('spotArea')
    f_addr = spot_data.get('full_address') or m.get('spotAddress') or data.get('location')
    occ_dt = _parse_dt(spot_data.get('occurrence_datetime') or m.get('occurrenceDateTime') or data.get('incident_date'))
    if v_town or a_name or f_addr or occ_dt:
        CrimeSpot.objects.update_or_create(
            case=case,
            defaults={
                'village_town': v_town,
                'area_name': a_name,
                'full_address': f_addr,
                'occurrence_datetime': occ_dt,
            }
        )

    # 3. Responsibility
    resp_data = m.get('responsibility') or m.get('caseResponsibility') or {}
    io_nm = resp_data.get('io_name') or resp_data.get('ioName') or data.get('assigned_officer')
    io_desig = resp_data.get('io_designation') or resp_data.get('ioDesig')
    reg_nm = resp_data.get('registered_by_name') or resp_data.get('regName') or data.get('created_by')
    reg_desig = resp_data.get('registered_by_designation') or resp_data.get('regDesig')
    if io_nm or reg_nm:
        CrimeCaseResponsibility.objects.update_or_create(
            case=case,
            defaults={
                'io_name': io_nm,
                'io_designation': io_desig,
                'registered_by_name': reg_nm,
                'registered_by_designation': reg_desig,
            }
        )

    # 4. Charges (Acts & Sections)
    charges_data = m.get('charges')
    if charges_data is not None:
        CrimeCaseActsSections.objects.filter(case=case).delete()
        if isinstance(charges_data, dict):
            for _, ch in charges_data.items():
                if isinstance(ch, dict):
                    act_name = ch.get('act')
                    sections = ch.get('sections', [])
                    act_obj = Act.objects.filter(act_name__iexact=act_name).first() if act_name else None
                    if act_obj:
                        for s_num in sections:
                            sec_obj = ActSection.objects.filter(act=act_obj, section_number__iexact=str(s_num).strip()).first()
                            if sec_obj:
                                CrimeCaseActsSections.objects.create(
                                    case=case,
                                    act=act_obj,
                                    section=sec_obj,
                                )
        elif isinstance(charges_data, list):
            for ch in charges_data:
                if isinstance(ch, dict):
                    act_id = ch.get('act_id') or ch.get('act')
                    section_id = ch.get('section_id') or ch.get('section')
                    subsection_id = ch.get('subsection_id') or ch.get('subsection')
                    if act_id and section_id:
                        CrimeCaseActsSections.objects.create(
                            case=case,
                            act_id=int(act_id),
                            section_id=int(section_id),
                            subsection_id=int(subsection_id) if subsection_id else None,
                        )

    # 5. Persons
    persons_data = m.get('persons')
    if persons_data is not None and isinstance(persons_data, list):
        CasesPerson.objects.filter(case=case).delete()
        for p in persons_data:
            CasesPerson.objects.create(
                case=case,
                role=p.get('role', 'accused'),
                name=p.get('name'),
                age=p.get('age'),
                gender=p.get('gender'),
                occupation=p.get('occupation') or p.get('occ'),
                mobile=p.get('mobile'),
                aadhaar=p.get('aadhaar'),
                pan=p.get('pan'),
                religion=p.get('religion'),
                caste=p.get('caste'),
                address=p.get('address'),
                approximate_age=p.get('approximate_age'),
                skin_colour=p.get('skin_colour'),
                possible_occupation=p.get('possible_occupation'),
                identification_mark=p.get('identification_mark'),
                height=p.get('height'),
                description=p.get('description'),
            )
    else:
        def _add_person(role, p_map):
            if not isinstance(p_map, dict):
                return
            nm = p_map.get('name')
            if not nm or not str(nm).strip():
                return
            cleaned = str(nm).strip()
            existing = CasesPerson.objects.filter(case=case, name__iexact=cleaned, role=role).first()
            if not existing:
                CasesPerson.objects.create(
                    case=case,
                    role=role,
                    name=cleaned,
                    age=p_map.get('age'),
                    gender=p_map.get('gender'),
                    occupation=p_map.get('occ') or p_map.get('occupation'),
                    mobile=p_map.get('mobile'),
                    aadhaar=p_map.get('aadhaar'),
                    pan=p_map.get('pan'),
                    religion=p_map.get('religion'),
                    caste=p_map.get('caste'),
                    address=p_map.get('address'),
                )

        _add_person('complainant', m.get('complainant'))
        _add_person('victim', m.get('victim'))
        _add_person('deceased', m.get('deceased'))
        _add_person('injured', m.get('injured'))

        for acc in (m.get('accused') if isinstance(m.get('accused'), list) else []):
            _add_person('accused', acc)
        for susp in (m.get('suspectedAccused') if isinstance(m.get('suspectedAccused'), list) else []):
            _add_person('suspect', susp)
        for unid in (m.get('unidentifiedList') if isinstance(m.get('unidentifiedList'), list) else []):
            if isinstance(unid, dict):
                CasesPerson.objects.create(
                    case=case,
                    role='unidentified',
                    name=unid.get('description') or 'Unidentified Person',
                    approximate_age=unid.get('approxAge'),
                    gender=unid.get('gender', 'Male'),
                    skin_colour=unid.get('skinColor'),
                    possible_occupation=unid.get('occupation'),
                    identification_mark=unid.get('otherPhysicalMarkers'),
                    height=unid.get('approxHeight'),
                    address=unid.get('lastKnownAddress'),
                    description=unid.get('description'),
                )

    # 6. Arrests (Pick existing or type new)
    arrests_data = m.get('arrests') or m.get('arrest_records') or m.get('arrestRelease')
    if arrests_data is not None and isinstance(arrests_data, list):
        for arr in arrests_data:
            if not isinstance(arr, dict):
                continue
            target_pid = arr.get('existing_person_id') or arr.get('person_id') or arr.get('person')
            typed_nm = arr.get('typed_name') or arr.get('name') or arr.get('accusedName')
            if not target_pid and not typed_nm:
                continue
            p_id = get_or_create_person_for_case(
                case_id=case.id,
                typed_name=typed_nm,
                existing_person_id=target_pid,
                role='accused'
            )
            arr_dt = _parse_dt(arr.get('arrest_datetime') or arr.get('arrestDt'))
            sec_47 = arr.get('sec_47_48_bnss') if 'sec_47_48_bnss' in arr else arr.get('sec47_48')
            rel_nm = arr.get('relative_friend_name') or arr.get('relName')
            rel_rel = arr.get('relative_friend_relation') or arr.get('relationship')
            rel_not = arr.get('release_on_notice') if 'release_on_notice' in arr else arr.get('relOnNotice')
            rel_not_dt = _parse_dt(arr.get('release_on_notice_datetime') or arr.get('relOnNoticeDt'))
            ant_bail = arr.get('anticipatory_bail') if 'anticipatory_bail' in arr else arr.get('anticipatoryBail')
            ant_bail_dt = _parse_dt(arr.get('anticipatory_bail_datetime') or arr.get('anticipatoryBailDt'))
            death = arr.get('death_of_accused') if 'death_of_accused' in arr else arr.get('isDeceased')
            death_dt = _parse_dt(arr.get('death_of_accused_datetime') or arr.get('deathDt'))

            ArrestReleaseStatus.objects.update_or_create(
                person_id=p_id,
                defaults={
                    'arrest_datetime': arr_dt,
                    'sec_47_48_bnss': sec_47,
                    'relative_friend_name': rel_nm,
                    'relative_friend_relation': rel_rel,
                    'release_on_notice': rel_not,
                    'release_on_notice_datetime': rel_not_dt,
                    'anticipatory_bail': ant_bail,
                    'anticipatory_bail_datetime': ant_bail_dt,
                    'death_of_accused': death,
                    'death_of_accused_datetime': death_dt,
                }
            )

    # 7. Discharges (Pick existing or type new)
    discharges_data = m.get('discharges') or m.get('discharge_records')
    if discharges_data is not None and isinstance(discharges_data, list):
        for dis in discharges_data:
            if isinstance(dis, dict):
                target_pid = dis.get('existing_person_id') or dis.get('person_id') or dis.get('person')
                typed_nm = dis.get('typed_name') or dis.get('name')
                if target_pid or typed_nm:
                    p_id = get_or_create_person_for_case(
                        case_id=case.id,
                        typed_name=typed_nm,
                        existing_person_id=target_pid,
                        role='accused'
                    )
                    DischargeStatus.objects.update_or_create(
                        person_id=p_id,
                        defaults={'is_discharged': dis.get('is_discharged', True)}
                    )

    # Also handle dischargeByAccused / dischargeDetails from CommonForm
    discharge_by_acc = m.get('dischargeByAccused') or {}
    if isinstance(discharge_by_acc, dict):
        for acc_name, is_dis in discharge_by_acc.items():
            if is_dis:
                p_id = get_or_create_person_for_case(
                    case_id=case.id,
                    typed_name=acc_name,
                    role='accused'
                )
                DischargeStatus.objects.update_or_create(
                    person_id=p_id,
                    defaults={'is_discharged': True}
                )

    custom_dis = m.get('customDischargeList') or []
    if isinstance(custom_dis, list):
        for item in custom_dis:
            if isinstance(item, dict) and item.get('name'):
                p_id = get_or_create_person_for_case(
                    case_id=case.id,
                    typed_name=item['name'],
                    role='accused'
                )
                DischargeStatus.objects.update_or_create(
                    person_id=p_id,
                    defaults={'is_discharged': True}
                )

    # 8. Seizures (Pick existing or type new person -> seized_from_person_id)
    seizures_data = m.get('seizures') or m.get('seizure_records') or m.get('stolenProperties') or m.get('recoveredProperties')
    if seizures_data is not None and isinstance(seizures_data, list):
        SeizureRecords.objects.filter(case=case).delete()
        for s in seizures_data:
            if not isinstance(s, dict):
                continue
            desc = s.get('description') or s.get('desc') or s.get('property')
            if not desc or not str(desc).strip():
                continue
            target_pid = s.get('seized_from_person_id') or s.get('existing_person_id') or s.get('person_id')
            from_whom = s.get('fromWhom') or s.get('from')
            other_name = s.get('otherName')
            typed_nm = s.get('name') or s.get('typed_name') or (other_name if other_name else (from_whom if from_whom and from_whom != 'Other (Type New Name)' else None))
            resolved_pid = None
            if target_pid or (typed_nm and str(typed_nm).strip()):
                resolved_pid = get_or_create_person_for_case(
                    case_id=case.id,
                    typed_name=typed_nm,
                    existing_person_id=target_pid,
                    role='accused'
                )
                if not typed_nm and resolved_pid:
                    p_obj = CasesPerson.objects.filter(pk=resolved_pid).first()
                    if p_obj:
                        typed_nm = p_obj.name

            SeizureRecords.objects.create(
                case=case,
                description=str(desc).strip(),
                name=typed_nm,
                seized_from_person_id=resolved_pid
            )

    # 9. CCTV & Technical
    cctv_data = m.get('cctv_technical') or {}
    cctv_chk = cctv_data.get('cctv_checked') if 'cctv_checked' in cctv_data else m.get('cctvChecked')
    cdr_s = _parse_d(cctv_data.get('cdr_sent_date') or m.get('cdrSent'))
    cdr_r = _parse_d(cctv_data.get('cdr_received_date') or m.get('cdrRecv'))
    if cctv_chk is not None or cdr_s or cdr_r:
        CctvTechnical.objects.update_or_create(
            case=case,
            defaults={
                'cctv_checked': cctv_chk,
                'cdr_sent_date': cdr_s,
                'cdr_received_date': cdr_r,
            }
        )

    # 10. Forensics
    for_data = m.get('forensics') or m.get('case_forensics') or {}
    inv_notes = m.get('investigationNotes') or {}
    e_sh = for_data.get('e_shakshya') if 'e_shakshya' in for_data else (m.get('eshakshValue') == 'Yes' or m.get('eshakshValue') is True)
    fp = for_data.get('fingerprint_taken') if 'fingerprint_taken' in for_data else (inv_notes.get('fingerprintVal') == 'Yes' or inv_notes.get('fingerprintVal') is True)
    nafis = for_data.get('nafis_fingerprint') if 'nafis_fingerprint' in for_data else bool(inv_notes.get('nafisFingerprint'))
    if e_sh or fp or nafis or for_data or inv_notes:
        CaseForensics.objects.update_or_create(
            case=case,
            defaults={
                'e_shakshya': e_sh,
                'fingerprint_taken': fp,
                'nafis_fingerprint': nafis,
            }
        )

    # 11. Checklists
    checklist_data = m.get('procedural_checklists')
    if checklist_data is not None and isinstance(checklist_data, list):
        ProceduralChecklist.objects.filter(case=case).delete()
        for item in checklist_data:
            if isinstance(item, dict):
                item_name = item.get('item_name')
                if item_name:
                    ProceduralChecklist.objects.create(
                        case=case,
                        item_name=item_name,
                        is_checked=bool(item.get('is_checked', False)),
                        event_datetime=_parse_dt(item.get('event_datetime')),
                    )
    elif 'proceduralChecks' in m:
        p_checks = m.get('proceduralChecks') or {}
        p_dates = m.get('proceduralDates') or {}
        ProceduralChecklist.objects.filter(case=case).delete()
        for k, v in p_checks.items():
            if v:
                dt = _parse_dt(p_dates.get(k))
                ProceduralChecklist.objects.create(
                    case=case,
                    item_name=k,
                    is_checked=True,
                    event_datetime=dt,
                )

    # 12. Preventive Action Items & Bond
    prev_actions = m.get('preventive_actions') or m.get('preventive_action_items')
    if prev_actions is not None and isinstance(prev_actions, list):
        PreventiveActionItems.objects.filter(case=case).delete()
        for pa in prev_actions:
            if isinstance(pa, dict):
                act_type = pa.get('action_type')
                act_date = _parse_d(pa.get('action_date'))
                if act_type and act_date:
                    PreventiveActionItems.objects.create(
                        case=case,
                        action_type=act_type,
                        action_date=act_date,
                        outward_number=pa.get('outward_number')
                    )
    elif 'preventive' in m:
        prev_map = m['preventive'] or {}
        act_type = prev_map.get('action')
        act_date = _parse_d(prev_map.get('actionDate'))
        if act_type and act_date:
            PreventiveActionItems.objects.filter(case=case).delete()
            PreventiveActionItems.objects.create(
                case=case,
                action_type=act_type,
                action_date=act_date,
                outward_number=prev_map.get('outwardNumber')
            )
        b_dt = _parse_d(prev_map.get('bondDate'))
        b_c_dt = _parse_d(prev_map.get('bondCancellation'))
        if b_dt or b_c_dt:
            PreventiveBond.objects.update_or_create(
                case=case,
                defaults={
                    'bond_date': b_dt,
                    'bond_cancellation_date': b_c_dt,
                }
            )

    pb_data = m.get('preventive_bond')
    if pb_data and isinstance(pb_data, dict):
        PreventiveBond.objects.update_or_create(
            case=case,
            defaults={
                'bond_date': _parse_d(pb_data.get('bond_date')),
                'bond_cancellation_date': _parse_d(pb_data.get('bond_cancellation_date')),
            }
        )

    # 13. Scrutiny Pipeline
    scr_data = m.get('scrutiny_pipeline') or m.get('scrutiny')
    if scr_data and isinstance(scr_data, dict):
        ScrutinyPipeline.objects.update_or_create(
            case=case,
            defaults={
                'sdpo_acp_send_date': _parse_d(scr_data.get('sdpo_acp_send_date') or scr_data.get('sdpoSend')),
                'sdpo_acp_grant_date': _parse_d(scr_data.get('sdpo_acp_grant_date') or scr_data.get('sdpoGrant')),
                'addl_sp_dcp_send_date': _parse_d(scr_data.get('addl_sp_dcp_send_date') or scr_data.get('spSend')),
                'addl_sp_dcp_grant_date': _parse_d(scr_data.get('addl_sp_dcp_grant_date') or scr_data.get('spGrant')),
                'addl_cp_send_date': _parse_d(scr_data.get('addl_cp_send_date') or scr_data.get('cpSend')),
                'addl_cp_grant_date': _parse_d(scr_data.get('addl_cp_grant_date') or scr_data.get('cpGrant')),
                'app_send_date': _parse_d(scr_data.get('app_send_date') or scr_data.get('appSend')),
                'app_grant_date': _parse_d(scr_data.get('app_grant_date') or scr_data.get('appGrant')),
            }
        )

    # 14. Final Verdict
    fv_data = m.get('final_verdict') or m.get('court')
    if fv_data and isinstance(fv_data, dict):
        FinalVerdict.objects.update_or_create(
            case=case,
            defaults={
                'charge_sheet_no': fv_data.get('charge_sheet_no') or fv_data.get('chargeSheetNumber'),
                'a_final_number': fv_data.get('a_final_number') or fv_data.get('aFinalNo'),
                'b_final_number': fv_data.get('b_final_number') or fv_data.get('bFinalNo'),
                'c_final_number': fv_data.get('c_final_number') or fv_data.get('cFinalNo'),
                'nc_final_number': fv_data.get('nc_final_number') or fv_data.get('ncFinalNo'),
                'abeted_summary_no': fv_data.get('abeted_summary_no') or fv_data.get('abatedSummaryNo'),
                'stay_by_high_court_date': _parse_d(fv_data.get('stay_by_high_court_date') or fv_data.get('stayHighCourtDate')),
                'quashed_by_high_court_date': _parse_d(fv_data.get('quashed_by_high_court_date') or fv_data.get('quashedHighCourt')),
            }
        )

    # 15. Category Links
    cat_ids = list(data.get('category_ids') or [])
    primary_cat_id = data.get('category_id')
    if primary_cat_id and primary_cat_id not in cat_ids:
        cat_ids.append(primary_cat_id)

    if not cat_ids:
        found_cat = None
        if case.sub_category:
            found_cat = CaseCategory.objects.filter(category_name__iexact=case.sub_category.strip()).first()
        if not found_cat and case.module_key:
            found_cat = CaseCategory.objects.filter(Q(category_code__iexact=case.module_key.strip()) | Q(category_name__iexact=case.module_key.strip())).first()
        if found_cat:
            cat_ids.append(found_cat.category_id)
            primary_cat_id = found_cat.category_id

    if cat_ids:
        CaseCategoryLink.objects.filter(case=case).delete()
        for idx, cid in enumerate(cat_ids):
            is_pri = (cid == primary_cat_id) or (idx == 0 and not primary_cat_id)
            CaseCategoryLink.objects.create(
                case=case,
                category_id=int(cid),
                is_primary=is_pri
            )

    # 16. Custom Dynamic Extra Fields
    extra_field_vals = data.get('extra_field_values') or {}
    if isinstance(extra_field_vals, dict):
        for k, v in extra_field_vals.items():
            f_def = FieldTemplateField.objects.filter(field_key=k).first()
            if f_def:
                CaseExtraFieldValue.objects.update_or_create(
                    case=case,
                    field_def=f_def,
                    defaults={'field_value': str(v) if v is not None else ''}
                )


# ==========================================
# 3. Case CRUD Endpoints (Rebuilt)
# ==========================================
class CrimeCaseManageView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk=None):
        if pk:
            case = CaseRecord.objects.filter(pk=pk).first()
            if not case:
                return Response({'error': f'Case {pk} not found'}, status=status.HTTP_404_NOT_FOUND)
            serializer = FullCaseDetailSerializer(case)
            return Response(serializer.data)
        else:
            station_name = request.query_params.get('station_name')
            status_filter = request.query_params.get('status')
            module_key = request.query_params.get('module_key', 'crime')
            search = request.query_params.get('search')

            qs = CaseRecord.objects.filter(module_key=module_key)
            if station_name:
                qs = qs.filter(station_name__iexact=station_name)
            if status_filter:
                qs = qs.filter(status__iexact=status_filter)
            if search:
                qs = qs.filter(
                    Q(case_number__icontains=search) |
                    Q(title__icontains=search) |
                    Q(complainant__icontains=search) |
                    Q(accused__icontains=search)
                )

            serializer = FullCaseDetailSerializer(qs.order_by('-created_at')[:50], many=True)
            return Response({
                'count': qs.count(),
                'cases': serializer.data
            })

    def post(self, request):
        data = request.data
        case_id = data.get('id') or str(uuid.uuid4())
        case_number = data.get('case_number') or f"CR/{uuid.uuid4().hex[:6].upper()}"
        title = data.get('title') or f"Crime Incident {case_number}"
        station_name = data.get('station_name') or 'Default Station'

        try:
            with transaction.atomic():
                # 1. Create CaseRecord
                case = CaseRecord.objects.create(
                    id=case_id,
                    module_key=data.get('module_key', 'crime'),
                    title=title,
                    case_number=case_number,
                    description=data.get('description', ''),
                    complainant=data.get('complainant', ''),
                    accused=data.get('accused', ''),
                    location=data.get('location', ''),
                    incident_date=data.get('incident_date'),
                    priority=data.get('priority', 'Medium'),
                    status=data.get('status', 'Pending'),
                    assigned_officer=data.get('assigned_officer', ''),
                    assigned_officer_uid=data.get('assigned_officer_uid'),
                    sub_category=data.get('sub_category'),
                    created_by=data.get('created_by', ''),
                    station_name=station_name,
                    extra_fields=data.get('extra_fields', {}),
                )

                # 2. Save all child relational tables
                _save_case_child_entities(case, data)

            serializer = FullCaseDetailSerializer(case)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except (ValueError, IntegrityError) as e:
            logger.error(f"Error creating case: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.exception(f"Unexpected error creating case: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def put(self, request, pk=None):
        case = CaseRecord.objects.filter(pk=pk).first()
        if not case:
            return Response({'error': f'Case {pk} not found'}, status=status.HTTP_404_NOT_FOUND)

        data = request.data
        try:
            with transaction.atomic():
                # 1. Update CaseRecord fields if provided
                if 'title' in data:
                    case.title = data['title']
                if 'case_number' in data:
                    case.case_number = data['case_number']
                if 'description' in data:
                    case.description = data['description']
                if 'complainant' in data:
                    case.complainant = data['complainant']
                if 'accused' in data:
                    case.accused = data['accused']
                if 'location' in data:
                    case.location = data['location']
                if 'incident_date' in data:
                    case.incident_date = data['incident_date']
                if 'priority' in data:
                    case.priority = data['priority']
                if 'status' in data:
                    case.status = data['status']
                if 'assigned_officer' in data:
                    case.assigned_officer = data['assigned_officer']
                if 'assigned_officer_uid' in data:
                    case.assigned_officer_uid = data['assigned_officer_uid']
                if 'sub_category' in data:
                    case.sub_category = data['sub_category']
                if 'station_name' in data:
                    case.station_name = data['station_name']
                if 'extra_fields' in data:
                    case.extra_fields = data['extra_fields']

                case.save()

                # 2. Update child tables
                _save_case_child_entities(case, data)

            serializer = FullCaseDetailSerializer(case)
            return Response(serializer.data, status=status.HTTP_200_OK)

        except (ValueError, IntegrityError) as e:
            logger.error(f"Error updating case {pk}: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.exception(f"Unexpected error updating case {pk}: {str(e)}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CasePdfView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk=None):
        case = CaseRecord.objects.filter(pk=pk).first()
        if not case:
            return Response({'error': f'Case {pk} not found'}, status=status.HTTP_404_NOT_FOUND)

        serializer = FullCaseDetailSerializer(case)
        pdf_data = {
            'case_summary': serializer.data,
            'report_generated_at': str(case.updated_at),
            'police_station': case.station_name,
            'title': f"Case Investigation Report - {case.case_number}",
        }
        return Response(pdf_data, status=status.HTTP_200_OK)


# ==========================================
# 4. Transfer Workflow Endpoints (Phase 2 Stub)
# ==========================================
class CaseTransferView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, pk=None):
        return Response(
            {'detail': 'Case transfer is disabled pending Phase 2 rebuild.'},
            status=status.HTTP_501_NOT_IMPLEMENTED
        )


class TransferredInInboxView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return Response(
            {'detail': 'Transferred-in inbox is disabled pending Phase 2 rebuild.'},
            status=status.HTTP_501_NOT_IMPLEMENTED
        )


class AssignTransferredCaseView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, pk=None):
        return Response(
            {'detail': 'Assigning transferred case is disabled pending Phase 2 rebuild.'},
            status=status.HTTP_501_NOT_IMPLEMENTED
        )


# ==========================================
# 5. Location Hierarchy Cascading Endpoints
# ==========================================
MAHARASHTRA_DISTRICT_TO_DIVISION = {
    # Chhatrapati Sambhajinagar Division (8 districts)
    'Chhatrapati Sambhajinagar': 'Chhatrapati Sambhajinagar',
    'Dharashiv': 'Chhatrapati Sambhajinagar',
    'Jalna': 'Chhatrapati Sambhajinagar',
    'Beed': 'Chhatrapati Sambhajinagar',
    'Latur': 'Chhatrapati Sambhajinagar',
    'Nanded': 'Chhatrapati Sambhajinagar',
    'Parbhani': 'Chhatrapati Sambhajinagar',
    'Hingoli': 'Chhatrapati Sambhajinagar',
    # Pune Division (5 districts)
    'Pune': 'Pune',
    'Satara': 'Pune',
    'Solapur': 'Pune',
    'Kolhapur': 'Pune',
    'Sangli': 'Pune',
    # Nashik Division (5 districts)
    'Nashik': 'Nashik',
    'Ahmednagar (Ahilyanagar)': 'Nashik',
    'Jalgaon': 'Nashik',
    'Dhule': 'Nashik',
    'Nandurbar': 'Nashik',
    # Konkan Division (7 districts)
    'Mumbai City': 'Konkan',
    'Mumbai Suburban': 'Konkan',
    'Thane': 'Konkan',
    'Palghar': 'Konkan',
    'Raigad': 'Konkan',
    'Ratnagiri': 'Konkan',
    'Sindhudurg': 'Konkan',
    # Nagpur Division (6 districts)
    'Nagpur': 'Nagpur',
    'Bhandara': 'Nagpur',
    'Gondia': 'Nagpur',
    'Chandrapur': 'Nagpur',
    'Gadchiroli': 'Nagpur',
    'Wardha': 'Nagpur',
    # Amravati Division (5 districts)
    'Amravati': 'Amravati',
    'Akola': 'Amravati',
    'Buldhana': 'Amravati',
    'Washim': 'Amravati',
    'Yavatmal': 'Amravati',
}


class LocationDivisionsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        state_id = request.query_params.get('state_id', '').strip()
        queryset = MasterDivision.objects.all().order_by('id')
        if state_id:
            queryset = queryset.filter(Q(state_code__iexact=state_id) | Q(state_name__iexact=state_id))
        divisions = [{'id': d.id, 'name': d.name, 'code': d.code, 'state_code': d.state_code} for d in queryset]
        return Response(divisions)


class LocationDistrictsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        division_id = request.query_params.get('division_id', '').strip()
        queryset = District.objects.all().order_by('name')

        div_to_id = {d.name.lower(): d.id for d in MasterDivision.objects.all()}
        div_id_to_name = {str(d.id): d.name for d in MasterDivision.objects.all()}

        if division_id:
            param = division_id.lower()
            div_name = div_id_to_name.get(param) or param
            allowed_districts = [
                dist_name for dist_name, d_div in MAHARASHTRA_DISTRICT_TO_DIVISION.items()
                if d_div.lower() == div_name.lower()
            ]
            if allowed_districts:
                queryset = queryset.filter(name__in=allowed_districts)

        districts = [{
            'id': d.district_id,
            'name': d.name,
            'code': d.code,
            'division_name': MAHARASHTRA_DISTRICT_TO_DIVISION.get(d.name, ''),
            'division_id': div_to_id.get(MAHARASHTRA_DISTRICT_TO_DIVISION.get(d.name, '').lower()),
        } for d in queryset]
        return Response(districts)


class LocationStationsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        district_id = request.query_params.get('district_id', '').strip()
        queryset = PoliceStation.objects.all().order_by('station_name')
        if district_id:
            param = district_id.strip()
            queryset = queryset.filter(
                Q(district__district_id__iexact=param) |
                Q(district__name__iexact=param) |
                Q(district_name__iexact=param) |
                Q(district_name__icontains=param)
            )
        stations = [{
            'id': s.station_id,
            'name': s.station_name,
            'district_id': s.district_id,
            'district_name': s.district_name or (s.district.name if s.district else ''),
            'address': s.address,
            'landline': s.landline,
        } for s in queryset]
        return Response(stations)
