from rest_framework import serializers
from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategoryGroup, CaseCategory, CaseCategoryLink
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CategoryFieldOverride,
    SectionFieldTemplate,
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
        fields = ['value_id', 'case', 'field_def', 'field_key', 'field_label', 'field_value', 'created_at']


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
    class Meta:
        model = RemandCustody
        fields = '__all__'

    def validate(self, data):
        # Enforce check constraint logic at serializer validation level as well
        mcr = data.get('mcr')
        pr_bond = data.get('pr_bond')
        bail = data.get('bail')
        surety_name = data.get('surety_name')
        jail = data.get('jail')

        if pr_bond and not mcr:
            raise serializers.ValidationError({
                'pr_bond': 'PR Bond can only be set when MCR is Yes.'
            })

        if (surety_name or jail) and not bail:
            raise serializers.ValidationError({
                'bail': 'Surety Name and Jail can only be set when Bail is Yes.'
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
