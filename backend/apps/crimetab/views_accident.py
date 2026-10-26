import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from .case_access import can_access_station, scope_by_station

from .models.accident import (
    RoadAccidentRecord,
    RoadAccidentVehicle,
    RoadAccidentInjured,
    RoadAccidentDeceased,
)
from .serializers_accident import (
    RoadAccidentRecordSerializer,
    RoadAccidentVehicleSerializer,
    RoadAccidentInjuredSerializer,
    RoadAccidentDeceasedSerializer,
)

logger = logging.getLogger(__name__)


# Accident records hold victims' personal data: login required, station-scoped.
class RoadAccidentListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        case_id = request.GET.get('case_id')
        station_name = request.GET.get('station_name')

        qs = scope_by_station(RoadAccidentRecord.objects.prefetch_related(
            'vehicles', 'injured_persons', 'deceased_persons'
        ).all(), request.user)

        if case_id:
            qs = qs.filter(case_id=case_id)
        if station_name:
            qs = qs.filter(station_name=station_name)

        serializer = RoadAccidentRecordSerializer(qs, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = RoadAccidentRecordSerializer(data=request.data)
        if serializer.is_valid():
            acc_rec = serializer.save()
            return Response(RoadAccidentRecordSerializer(acc_rec).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class RoadAccidentDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        acc_rec = RoadAccidentRecord.objects.prefetch_related(
            'vehicles', 'injured_persons', 'deceased_persons'
        ).filter(pk=pk).first()

        if not acc_rec:
            # Also fallback to check if pk is case_id string
            acc_rec = RoadAccidentRecord.objects.prefetch_related(
                'vehicles', 'injured_persons', 'deceased_persons'
            ).filter(case_id=str(pk)).first()

        if not acc_rec or not can_access_station(request.user, acc_rec.station_name):
            return Response({'error': 'Road accident record not found'}, status=status.HTTP_404_NOT_FOUND)

        return Response(RoadAccidentRecordSerializer(acc_rec).data, status=status.HTTP_200_OK)

    def patch(self, request, pk):
        acc_rec = RoadAccidentRecord.objects.filter(pk=pk).first()
        if not acc_rec:
            acc_rec = RoadAccidentRecord.objects.filter(case_id=str(pk)).first()

        if not acc_rec or not can_access_station(request.user, acc_rec.station_name):
            return Response({'error': 'Road accident record not found'}, status=status.HTTP_404_NOT_FOUND)

        serializer = RoadAccidentRecordSerializer(acc_rec, data=request.data, partial=True)
        if serializer.is_valid():
            updated = serializer.save()
            return Response(RoadAccidentRecordSerializer(updated).data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
