from apps.cases.models import CaseRecord
modules = ['pocso', 'crime_women', 'accident', 'cheating', '498_a_ipc', 'missing', 'kidnapping', 'victim']
print(f'Total cases: {CaseRecord.objects.count()}')
print(f'Victim cases: {CaseRecord.objects.filter(module_key__in=modules).count()}')
