from rest_framework import serializers
from apps.stations.models import PoliceStation


class PoliceStationSerializer(serializers.ModelSerializer):
    class Meta:
        model = PoliceStation
        fields = '__all__'
