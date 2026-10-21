from rest_framework import serializers
from apps.crimetab.models.mpda import (
    MpdaProposal,
    MpdaAccusedPerson,
    MpdaGangMember,
    MpdaCrimeChartEntry,
)
from apps.crimetab.standalone_helpers import format_display_date


class MpdaAccusedPersonSerializer(serializers.ModelSerializer):
    class Meta:
        model = MpdaAccusedPerson
        fields = [
            'id',
            'display_order',
            'name',
            'age',
            'gender',
            'occupation',
            'mobile',
            'aadhaar',
            'pan',
            'cast',
            'religion',
            'address',
            'created_at',
        ]


class MpdaGangMemberSerializer(serializers.ModelSerializer):
    class Meta:
        model = MpdaGangMember
        fields = [
            'id',
            'name',
            'display_order',
            'age',
            'gender',
            'occupation',
            'mobile',
            'aadhaar',
            'pan',
            'cast',
            'religion',
            'address',
            'created_at',
        ]


class MpdaCrimeChartEntrySerializer(serializers.ModelSerializer):
    crime_date_display = serializers.SerializerMethodField()

    class Meta:
        model = MpdaCrimeChartEntry
        fields = [
            'id',
            'crime_type',
            'cr_no',
            'crime_date',
            'crime_date_display',
            'police_station',
            'act_id',
            'section_id',
            'subsection_id',
            'act_name',
            'section_number',
            'section_title',
            'subsection_code',
            'act_section',
            'created_at',
        ]

    def get_crime_date_display(self, obj):
        return format_display_date(obj.crime_date, 'mpda')


class MpdaProposalListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for MPDA proposals list.
    """
    accused_persons = MpdaAccusedPersonSerializer(many=True, read_only=True)
    detention_date_display = serializers.SerializerMethodField()
    detention_completion_date_display = serializers.SerializerMethodField()

    class Meta:
        model = MpdaProposal
        fields = [
            'id',
            'station_name',
            'proposal_no',
            'proposal_year',
            'proposal_no_and_year',
            'accused_name',
            'accused_gender',
            'accused_persons',
            'proposal_outcome',
            'mpda_category',
            'detained',
            'detention_date',
            'detention_date_display',
            'detention_completion_date',
            'detention_completion_date_display',
            'jail_name',
            'detention_order_revoked',
            'created_at',
        ]

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        # Populate primary accused info from accused_persons if available
        accused_list = ret.get('accused_persons') or []
        if accused_list:
            first_acc = accused_list[0]
            if not ret.get('accused_name'):
                ret['accused_name'] = first_acc.get('name')
            if not ret.get('accused_gender'):
                ret['accused_gender'] = first_acc.get('gender')
        return ret

    def get_detention_date_display(self, obj):
        return format_display_date(obj.detention_date, 'mpda')

    def get_detention_completion_date_display(self, obj):
        return format_display_date(obj.detention_completion_date, 'mpda')


class MpdaProposalDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for MPDA proposal create, view, edit.
    Includes nested repeating child records.
    """
    accused_persons = MpdaAccusedPersonSerializer(many=True, read_only=True)
    gang_members = MpdaGangMemberSerializer(many=True, read_only=True)
    crime_chart_entries = MpdaCrimeChartEntrySerializer(many=True, read_only=True)

    granted_date_display = serializers.SerializerMethodField()
    rejected_date_display = serializers.SerializerMethodField()
    detention_date_display = serializers.SerializerMethodField()
    detention_completion_date_display = serializers.SerializerMethodField()
    govt_confirmation_date_display = serializers.SerializerMethodField()
    order_revoked_date_display = serializers.SerializerMethodField()
    proposal_revoked_date_display = serializers.SerializerMethodField()

    class Meta:
        model = MpdaProposal
        fields = '__all__'

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        # Never expose io_uid
        ret.pop('io_uid', None)
        # Populate primary accused info from accused_persons if available
        accused_list = ret.get('accused_persons') or []
        if accused_list:
            first_acc = accused_list[0]
            if not ret.get('accused_name'):
                ret['accused_name'] = first_acc.get('name')
            if not ret.get('accused_gender'):
                ret['accused_gender'] = first_acc.get('gender')

        prefixed = {}
        # Prefixed scalar fields
        for k, v in list(ret.items()):
            if not k.startswith('mpda_') and k not in ('id', 'station_name', 'created_at', 'updated_at', 'created_by'):
                prefixed[f"mpda_{k}"] = v

        prefixed['mpda_govt_confirmation'] = instance.government_confirmation or ''
        prefixed['mpda_order_revoked'] = instance.detention_order_revoked or ''

        # Formatted display dates in form-friendly DD/MM/YYYY
        if ret.get('granted_date_display'):
            prefixed['mpda_granted_date'] = ret['granted_date_display']
        if ret.get('rejected_date_display'):
            prefixed['mpda_rejected_date'] = ret['rejected_date_display']
        if ret.get('detention_date_display'):
            prefixed['mpda_detention_date'] = ret['detention_date_display']
        if ret.get('detention_completion_date_display'):
            prefixed['mpda_detention_completion_date'] = ret['detention_completion_date_display']
        if ret.get('govt_confirmation_date_display'):
            prefixed['mpda_govt_confirmation_date'] = ret['govt_confirmation_date_display']
        if ret.get('order_revoked_date_display'):
            prefixed['mpda_order_revoked_date'] = ret['order_revoked_date_display']
        if ret.get('proposal_revoked_date_display'):
            prefixed['mpda_proposal_revoked_date'] = ret['proposal_revoked_date_display']

        # Repeating group: mpda_accused (normalized with both mpda_accused_* and unprefixed keys)
        normalized_accused = []
        for acc in ret.get('accused_persons') or []:
            acc_copy = dict(acc)
            for acc_k, acc_v in acc.items():
                if not acc_k.startswith('mpda_accused_'):
                    acc_copy[f"mpda_accused_{acc_k}"] = acc_v
            normalized_accused.append(acc_copy)
        prefixed['mpda_accused'] = normalized_accused
        ret['accused'] = normalized_accused

        # Repeating group: mpda_gang_members
        normalized_gang = []
        for gm in ret.get('gang_members') or []:
            gm_copy = dict(gm)
            gm_copy['mpda_gang_member_name'] = gm.get('name') or ''
            for col in ('age', 'gender', 'occupation', 'mobile', 'aadhaar',
                        'pan', 'cast', 'religion', 'address'):
                v = gm.get(col)
                gm_copy[f'mpda_gang_member_{col}'] = '' if v is None else str(v)
            normalized_gang.append(gm_copy)
        prefixed['mpda_gang_members'] = normalized_gang

        # Repeating group: mpda_crime_chart
        normalized_crimes = []
        for ce in ret.get('crime_chart_entries') or []:
            ce_copy = dict(ce)
            ce_copy['mpda_crime_type'] = ce.get('crime_type') or ''
            ce_copy['mpda_crime_cr_no'] = ce.get('cr_no') or ''
            ce_copy['mpda_crime_date'] = ce.get('crime_date') or ''
            ce_copy['mpda_crime_police_station'] = ce.get('police_station') or ''
            # Rows picked from the Acts master go back to the picker as one charge
            ce_copy['mpda_crime_act_section'] = [{
                k: ce.get(k) for k in (
                    'act_id', 'act_name', 'section_id', 'section_number',
                    'section_title', 'subsection_id', 'subsection_code')
            }] if (ce.get('act_id') or ce.get('act_name')) else (ce.get('act_section') or '')
            normalized_crimes.append(ce_copy)
        prefixed['mpda_crime_chart'] = normalized_crimes
        ret['crime_chart'] = normalized_crimes

        ret.update(prefixed)
        return ret

    def get_granted_date_display(self, obj):
        return format_display_date(obj.granted_date, 'mpda')

    def get_rejected_date_display(self, obj):
        return format_display_date(obj.rejected_date, 'mpda')

    def get_detention_date_display(self, obj):
        return format_display_date(obj.detention_date, 'mpda')

    def get_detention_completion_date_display(self, obj):
        return format_display_date(obj.detention_completion_date, 'mpda')

    def get_govt_confirmation_date_display(self, obj):
        return format_display_date(obj.govt_confirmation_date, 'mpda')

    def get_order_revoked_date_display(self, obj):
        return format_display_date(obj.order_revoked_date, 'mpda')

    def get_proposal_revoked_date_display(self, obj):
        return format_display_date(obj.proposal_revoked_date, 'mpda')
