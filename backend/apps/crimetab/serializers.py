from rest_framework import serializers
from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategoryGroup, CaseCategory, CaseCategoryLink
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CategoryFieldOverride,
    SectionFieldTemplate,
    CaseExtraFieldValue,
    OptionValue,
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


# ==========================================
# 1. Grouping Serializers
# ==========================================
class CaseCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = CaseCategory
        fields = '__all__'


class CaseCategoryGroupSerializer(serializers.ModelSerializer):
    categories = CaseCategorySerializer(many=True, read_only=True)

    class Meta:
        model = CaseCategoryGroup
        fields = ['group_id', 'group_name', 'group_code', 'display_order', 'created_at', 'categories']


class CaseCategoryLinkSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.category_name', read_only=True)
    category_code = serializers.CharField(source='category.category_code', read_only=True)

    class Meta:
        model = CaseCategoryLink
        fields = '__all__'


# ==========================================
# 2. Dynamic Field Engine Serializers
# ==========================================
class FieldTemplateFieldSerializer(serializers.ModelSerializer):
    class Meta:
        model = FieldTemplateField
        fields = '__all__'


class FieldTemplateSerializer(serializers.ModelSerializer):
    fields = FieldTemplateFieldSerializer(many=True, read_only=True)

    class Meta:
        model = FieldTemplate
        fields = '__all__'


class CategoryFieldOverrideSerializer(serializers.ModelSerializer):
    class Meta:
        model = CategoryFieldOverride
        fields = '__all__'


class SectionFieldTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SectionFieldTemplate
        fields = '__all__'


class CaseExtraFieldValueSerializer(serializers.ModelSerializer):
    field_key = serializers.CharField(source='field_def.field_key', read_only=True)
    field_label = serializers.CharField(source='field_def.field_label', read_only=True)

    class Meta:
        model = CaseExtraFieldValue
        fields = ['value_id', 'case', 'field_def', 'field_key', 'field_label', 'field_value', 'row_no',
                  'created_at']


class OptionValueSerializer(serializers.ModelSerializer):
    class Meta:
        model = OptionValue
        fields = ['id', 'option_group', 'option_value', 'display_order', 'is_active']



# ==========================================
# 3. Acts & Sections Reference Serializers
# ==========================================
class ActSubsectionSerializer(serializers.ModelSerializer):
    class Meta:
        model = ActSubsection
        fields = '__all__'


class ActSectionSerializer(serializers.ModelSerializer):
    subsections = ActSubsectionSerializer(many=True, read_only=True)

    class Meta:
        model = ActSection
        fields = '__all__'


class ActSerializer(serializers.ModelSerializer):
    sections = ActSectionSerializer(many=True, read_only=True)

    class Meta:
        model = Act
        fields = '__all__'


class CrimeCaseActsSectionsSerializer(serializers.ModelSerializer):
    act_name = serializers.CharField(source='act.act_name', read_only=True)
    section_number = serializers.CharField(source='section.section_number', read_only=True)
    section_title = serializers.CharField(source='section.section_title', read_only=True)
    subsection_code = serializers.CharField(source='subsection.subsection_code', read_only=True)

    class Meta:
        model = CrimeCaseActsSections
        fields = [
            'charge_id', 'case', 'act', 'section', 'subsection',
            'act_name', 'section_number', 'section_title', 'subsection_code',
            'created_at'
        ]


# ==========================================
# 4. Common Form Child Model Serializers
# ==========================================
class CrimeRegistrationInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = CrimeRegistrationInfo
        fields = '__all__'


class CrimeSpotSerializer(serializers.ModelSerializer):
    class Meta:
        model = CrimeSpot
        fields = '__all__'


class CrimeCaseResponsibilitySerializer(serializers.ModelSerializer):
    class Meta:
        model = CrimeCaseResponsibility
        fields = '__all__'


class ArrestReleaseStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = ArrestReleaseStatus
        fields = '__all__'


class RemandCustodySerializer(serializers.ModelSerializer):
    person_name = serializers.CharField(source='person.name', read_only=True)

    class Meta:
        model = RemandCustody
        fields = '__all__'

    def validate(self, data):
        # Enforce check constraint logic at serializer validation level as well
        mcr = data.get('mcr')
        pr_bond = data.get('pr_bond')
        pr_bond_date = data.get('pr_bond_date')
        bail = data.get('bail')
        surety_name = data.get('surety_name')
        jail = data.get('jail')
        jail_date = data.get('jail_date')

        if pr_bond and not mcr:
            raise serializers.ValidationError({
                'pr_bond': 'PR Bond can only be set when MCR is Yes.'
            })
        if pr_bond_date and not pr_bond:
            raise serializers.ValidationError({
                'pr_bond_date': 'PR Bond Date can only be set when PR Bond is Yes.'
            })
        if surety_name and not bail:
            raise serializers.ValidationError({
                'surety_name': 'Surety Name can only be set when Bail is Yes.'
            })
        if jail and not mcr:
            raise serializers.ValidationError({
                'jail': 'Jail can only be set when MCR is Yes.'
            })
        if jail_date and not jail:
            raise serializers.ValidationError({
                'jail_date': 'Jail Date can only be set when Jail is Yes.'
            })

        return data


class DischargeStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = DischargeStatus
        fields = '__all__'


class CasesPersonSerializer(serializers.ModelSerializer):
    arrest_status = ArrestReleaseStatusSerializer(read_only=True)
    remand_custody = RemandCustodySerializer(read_only=True)
    discharge_status = DischargeStatusSerializer(read_only=True)

    class Meta:
        model = CasesPerson
        fields = '__all__'


class CctvTechnicalSerializer(serializers.ModelSerializer):
    class Meta:
        model = CctvTechnical
        fields = '__all__'


class ProceduralChecklistSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProceduralChecklist
        fields = '__all__'


class CaseForensicsSerializer(serializers.ModelSerializer):
    class Meta:
        model = CaseForensics
        fields = '__all__'


class SeizureRecordsSerializer(serializers.ModelSerializer):
    seized_from_person_name = serializers.CharField(source='seized_from_person.name', read_only=True)

    class Meta:
        model = SeizureRecords
        fields = '__all__'


class PreventiveActionItemsSerializer(serializers.ModelSerializer):
    person_name = serializers.CharField(source='person.name', read_only=True)

    class Meta:
        model = PreventiveActionItems
        fields = '__all__'


class PreventiveBondSerializer(serializers.ModelSerializer):
    class Meta:
        model = PreventiveBond
        fields = '__all__'


class ScrutinyPipelineSerializer(serializers.ModelSerializer):
    class Meta:
        model = ScrutinyPipeline
        fields = '__all__'


class FinalVerdictSerializer(serializers.ModelSerializer):
    class Meta:
        model = FinalVerdict
        fields = '__all__'


class CaseListSerializer(serializers.ModelSerializer):
    class Meta:
        model = CaseRecord
        fields = [
            'id', 'module_key', 'title', 'case_number', 'description',
            'complainant', 'accused', 'location', 'incident_date',
            'priority', 'status', 'assigned_officer', 'assigned_officer_uid',
            'sub_category', 'created_by', 'station_name', 'extra_fields',
            'created_at', 'updated_at'
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        try:
            extra = data.get('extra_fields')
            if not isinstance(extra, dict):
                extra = {}
                data['extra_fields'] = extra

            p_items = list(instance.preventive_action_items.all())
            if p_items:
                serialized_pa = [
                    {
                        'name': p.name or (p.person.name if p.person else None),
                        'action': p.action_type,
                        'action_type': p.action_type,
                        'action_date': p.action_date.strftime('%d/%m/%Y') if p.action_date else '',
                        'outward_number': p.outward_number or '',
                        'preventive_number': p.preventive_number or '',
                        'bond_date': p.bond_date.strftime('%d/%m/%Y') if p.bond_date else '',
                        'bond_cancellation_date': p.bond_cancellation_date.strftime('%d/%m/%Y') if p.bond_cancellation_date else '',
                    }
                    for p in p_items
                ]
                if not extra.get('preventive_actions'):
                    extra['preventive_actions'] = serialized_pa
                if not extra.get('preventive_action_items'):
                    extra['preventive_action_items'] = serialized_pa
                if not extra.get('preventive_action_type'):
                    extra['preventive_action_type'] = p_items[0].action_type
                if not extra.get('preventive_no') and p_items[0].preventive_number:
                    extra['preventive_no'] = p_items[0].preventive_number
                if not extra.get('preventive_outward_no') and p_items[0].outward_number:
                    extra['preventive_outward_no'] = p_items[0].outward_number

            if not extra.get('charges') and instance.charges.exists():
                charges_rel = list(instance.charges.select_related('act', 'section').all())
                if charges_rel:
                    extra['charges'] = [
                        {
                            'act': c.act.act_name if c.act else '',
                            'section': c.section.section_number if c.section else '',
                        }
                        for c in charges_rel
                    ]

            from apps.crimetab.models.accident import RoadAccidentRecord
            from apps.crimetab.serializers_accident import RoadAccidentRecordSerializer
            acc_rec = RoadAccidentRecord.objects.filter(case_id=str(instance.id)).first()
            if acc_rec:
                acc_data = RoadAccidentRecordSerializer(acc_rec).data
                data['road_accident'] = acc_data
                for k, v in acc_data.items():
                    if k not in extra or extra[k] is None or extra[k] == '':
                        extra[k] = v
                extra['acc_vehicles'] = acc_data.get('acc_vehicles', [])
                extra['vehicles'] = acc_data.get('vehicles', [])
                extra['acc_injured'] = acc_data.get('acc_injured', [])
                extra['injured'] = acc_data.get('injured', [])
                extra['acc_deceased'] = acc_data.get('acc_deceased', [])
                extra['deceased'] = acc_data.get('deceased', [])
        except Exception:
            pass
        return data


# ==========================================
# 5. Full-Case Detail Serializer
# ==========================================
class FullCaseDetailSerializer(serializers.ModelSerializer):
    registration_info = CrimeRegistrationInfoSerializer(read_only=True)
    crime_spot = CrimeSpotSerializer(source='spot', read_only=True)
    responsibility = CrimeCaseResponsibilitySerializer(read_only=True)
    charges = CrimeCaseActsSectionsSerializer(many=True, read_only=True)
    persons = CasesPersonSerializer(many=True, read_only=True)
    cctv_technical = CctvTechnicalSerializer(read_only=True)
    procedural_checklists = ProceduralChecklistSerializer(many=True, read_only=True)
    forensics = CaseForensicsSerializer(read_only=True)
    seizures = SeizureRecordsSerializer(many=True, read_only=True)
    preventive_actions = PreventiveActionItemsSerializer(source='preventive_action_items', many=True, read_only=True)
    preventive_bond = PreventiveBondSerializer(read_only=True)
    scrutiny_pipeline = ScrutinyPipelineSerializer(read_only=True)
    final_verdict = FinalVerdictSerializer(read_only=True)
    category_links = CaseCategoryLinkSerializer(many=True, read_only=True)
    extra_field_values = CaseExtraFieldValueSerializer(many=True, read_only=True)

    class Meta:
        model = CaseRecord
        fields = [
            'id', 'module_key', 'title', 'case_number', 'description',
            'complainant', 'accused', 'location', 'incident_date',
            'priority', 'status', 'assigned_officer', 'assigned_officer_uid',
            'sub_category', 'created_by', 'station_name', 'extra_fields',
            'created_at', 'updated_at',
            'registration_info', 'crime_spot', 'responsibility', 'charges',
            'persons', 'cctv_technical', 'procedural_checklists', 'forensics',
            'seizures', 'preventive_actions', 'preventive_bond',
            'scrutiny_pipeline', 'final_verdict',
            'category_links', 'extra_field_values'
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Table-stored template fields go back into extra_fields for the form
        try:
            from apps.crimetab.services.table_field_values import table_values_for_case
            table_vals = table_values_for_case(instance, list(instance.extra_field_values.all()))
            if table_vals:
                extra = data.get('extra_fields')
                if not isinstance(extra, dict):
                    extra = {}
                    data['extra_fields'] = extra
                extra.update(table_vals)
        except Exception as e:
            import logging
            logging.getLogger(__name__).warning(f"[FullCaseDetailSerializer] table field values not loaded: {e}")
        try:
            from apps.crimetab.models.accident import RoadAccidentRecord
            from apps.crimetab.serializers_accident import RoadAccidentRecordSerializer
            acc_rec = RoadAccidentRecord.objects.filter(case_id=str(instance.id)).first()
            if acc_rec:
                acc_data = RoadAccidentRecordSerializer(acc_rec).data
                data['road_accident'] = acc_data
                extra = data.get('extra_fields')
                if not isinstance(extra, dict):
                    extra = {}
                    data['extra_fields'] = extra
                for k, v in acc_data.items():
                    if k not in extra or extra[k] is None or extra[k] == '':
                        extra[k] = v
                extra['acc_vehicles'] = acc_data.get('acc_vehicles', [])
                extra['vehicles'] = acc_data.get('vehicles', [])
                extra['acc_injured'] = acc_data.get('acc_injured', [])
                extra['injured'] = acc_data.get('injured', [])
                extra['acc_deceased'] = acc_data.get('acc_deceased', [])
                extra['deceased'] = acc_data.get('deceased', [])
        except Exception:
            pass
        return data
