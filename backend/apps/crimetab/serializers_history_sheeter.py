from rest_framework import serializers
from apps.crimetab.models.history_sheeter import (
    HistorySheeter,
    HistorySheeterRelatedPerson,
    HistorySheeterPreventiveAction,
    HistorySheeterCrime,
)
from apps.crimetab.standalone_helpers import format_display_date


class HistorySheeterRelatedPersonSerializer(serializers.ModelSerializer):
    class Meta:
        model = HistorySheeterRelatedPerson
        fields = [
            'id',
            'person_type',
            'name',
            'alias',
            'nickname',
            'age',
            'gender',
            'mobile_no',
            'address',
            'created_at',
        ]


class HistorySheeterPreventiveActionSerializer(serializers.ModelSerializer):
    class Meta:
        model = HistorySheeterPreventiveAction
        fields = [
            'id',
            'action_type',
            'action_other',
            'created_at',
        ]


class HistorySheeterCrimeSerializer(serializers.ModelSerializer):
    register_date_display = serializers.SerializerMethodField()

    class Meta:
        model = HistorySheeterCrime
        fields = [
            'id',
            'cr_no',
            'crime_head',
            'act_section',
            'act_id',
            'section_id',
            'subsection_id',
            'act_name',
            'section_number',
            'section_title',
            'subsection_code',
            'register_date',
            'register_date_display',
            'police_station',
            'created_at',
        ]

    def get_register_date_display(self, obj):
        return format_display_date(obj.register_date, 'history_sheeter')


class HistorySheeterListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for History Sheeter paginated list.
    """
    opening_date_display = serializers.SerializerMethodField()
    closure_date_display = serializers.SerializerMethodField()

    class Meta:
        model = HistorySheeter
        fields = [
            'id',
            'station_name',
            'sr_no',
            'name',
            'alias',
            'categories',
            'opening_date',
            'opening_date_display',
            'closure_date',
            'closure_date_display',
            'created_at',
        ]

    def get_opening_date_display(self, obj):
        return format_display_date(obj.opening_date, 'history_sheeter')

    def get_closure_date_display(self, obj):
        return format_display_date(obj.closure_date, 'history_sheeter')


class HistorySheeterDetailSerializer(serializers.ModelSerializer):
    """
    Detailed serializer for History Sheeter create, view, edit.
    Includes nested repeating child records.
    """
    related_persons = HistorySheeterRelatedPersonSerializer(many=True, read_only=True)
    preventive_actions = HistorySheeterPreventiveActionSerializer(many=True, read_only=True)
    crimes = HistorySheeterCrimeSerializer(many=True, read_only=True)

    opening_date_display = serializers.SerializerMethodField()
    order_date_display = serializers.SerializerMethodField()
    last_verification_date_display = serializers.SerializerMethodField()
    closure_date_display = serializers.SerializerMethodField()

    class Meta:
        model = HistorySheeter
        fields = '__all__'

    def get_opening_date_display(self, obj):
        return format_display_date(obj.opening_date, 'history_sheeter')

    def get_order_date_display(self, obj):
        return format_display_date(obj.order_date, 'history_sheeter')

    def get_last_verification_date_display(self, obj):
        return format_display_date(obj.last_verification_date, 'history_sheeter')

    def get_closure_date_display(self, obj):
        return format_display_date(obj.closure_date, 'history_sheeter')

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        prefixed = {}
        # Prefixed scalar fields
        for k, v in list(ret.items()):
            if not k.startswith('hs_') and k not in ('id', 'station_name', 'created_at', 'updated_at'):
                prefixed[f"hs_{k}"] = v

        prefixed['hs_category_type'] = instance.categories or []
        prefixed['hs_category_type_other'] = instance.category_other or ''
        prefixed['hs_same_as_above'] = 'Yes' if instance.same_as_above else 'No'

        if ret.get('opening_date_display'):
            prefixed['hs_opening_date'] = ret['opening_date_display']
        if ret.get('order_date_display'):
            prefixed['hs_order_date'] = ret['order_date_display']
        if ret.get('last_verification_date_display'):
            prefixed['hs_last_verification_date'] = ret['last_verification_date_display']
        if ret.get('closure_date_display'):
            prefixed['hs_closure_date'] = ret['closure_date_display']

        # Repeating group: hs_associates, hs_rivals, hs_sureties
        related = ret.get('related_persons') or []
        associates = []
        rivals = []
        sureties = []
        for r in related:
            pt = (r.get('person_type') or '').lower()
            r_copy = dict(r)
            if pt == 'associate':
                r_copy['hs_assoc_name'] = r.get('name') or ''
                r_copy['hs_assoc_alias'] = r.get('alias') or ''
                r_copy['hs_assoc_nickname'] = r.get('nickname') or ''
                r_copy['hs_assoc_age'] = r.get('age') or ''
                r_copy['hs_assoc_gender'] = r.get('gender') or ''
                r_copy['hs_assoc_mobile'] = r.get('mobile_no') or ''
                r_copy['hs_assoc_address'] = r.get('address') or ''
                associates.append(r_copy)
            elif pt == 'rival':
                r_copy['hs_rival_name'] = r.get('name') or ''
                r_copy['hs_rival_alias'] = r.get('alias') or ''
                r_copy['hs_rival_nickname'] = r.get('nickname') or ''
                r_copy['hs_rival_age'] = r.get('age') or ''
                r_copy['hs_rival_gender'] = r.get('gender') or ''
                r_copy['hs_rival_mobile'] = r.get('mobile_no') or ''
                r_copy['hs_rival_address'] = r.get('address') or ''
                rivals.append(r_copy)
            elif pt == 'surety':
                r_copy['hs_surety_name'] = r.get('name') or ''
                r_copy['hs_surety_alias'] = r.get('alias') or ''
                r_copy['hs_surety_nickname'] = r.get('nickname') or ''
                r_copy['hs_surety_age'] = r.get('age') or ''
                r_copy['hs_surety_gender'] = r.get('gender') or ''
                r_copy['hs_surety_mobile'] = r.get('mobile_no') or ''
                r_copy['hs_surety_address'] = r.get('address') or ''
                sureties.append(r_copy)

        prefixed['hs_associates'] = associates
        prefixed['hs_rivals'] = rivals
        prefixed['hs_sureties'] = sureties
        ret['associates'] = associates
        ret['rivals'] = rivals
        ret['sureties'] = sureties

        # Repeating group: hs_preventive_actions
        prev_actions = []
        for pa in ret.get('preventive_actions') or []:
            pa_copy = dict(pa)
            pa_copy['hs_preventive_action_type'] = pa.get('action_type') or ''
            pa_copy['hs_preventive_action_other'] = pa.get('action_other') or ''
            prev_actions.append(pa_copy)
        prefixed['hs_preventive_actions'] = prev_actions

        # Repeating group: hs_crime_chart
        crimes = []
        for cr in ret.get('crimes') or []:
            cr_copy = dict(cr)
            cr_copy['hs_crime_cr_no'] = cr.get('cr_no') or ''
            cr_copy['hs_crime_head'] = cr.get('crime_head') or ''
            # Rows picked from the Acts master go back to the picker as one
            # charge; older free-text rows keep their text
            if cr.get('act_id') or cr.get('act_name'):
                cr_copy['hs_crime_act_section'] = [{
                    'act_id': cr.get('act_id'),
                    'act_name': cr.get('act_name'),
                    'section_id': cr.get('section_id'),
                    'section_number': cr.get('section_number'),
                    'section_title': cr.get('section_title'),
                    'subsection_id': cr.get('subsection_id'),
                    'subsection_code': cr.get('subsection_code'),
                }]
            else:
                cr_copy['hs_crime_act_section'] = cr.get('act_section') or ''
            cr_copy['hs_crime_register_date'] = cr.get('register_date_display') or cr.get('register_date') or ''
            cr_copy['hs_crime_police_station'] = cr.get('police_station') or ''
            crimes.append(cr_copy)
        prefixed['hs_crime_chart'] = crimes
        ret['crime_chart'] = crimes

        ret.update(prefixed)
        return ret
