import datetime
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db.models import Q
from apps.cases.models import CaseRecord
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = "Send automated reminders for POCSO cases crossing 30 days without chargesheet."

    def handle(self, *args, **kwargs):
        # We must import NotificationRecord here in case of circular dependencies
        # Let's try to find it in common paths
        try:
            from apps.users.models import NotificationRecord
        except ImportError:
            try:
                from apps.core.models import NotificationRecord
            except ImportError:
                self.stdout.write(self.style.ERROR('Could not find NotificationRecord model.'))
                return

        pocso_q = Q(module_key__iexact='pocso') | Q(sub_category__iexact='pocso') | Q(sub_category__icontains='pocso')
        has_cs_q = (
            Q(extra_fields__has_key='charge_sheet_number') | 
            Q(extra_fields__has_key='charge_sheet_no') | 
            Q(extra_fields__has_key='cc_st_number') | 
            Q(extra_fields__has_key='ccStNumber')
        ) & ~Q(extra_fields__charge_sheet_number='') & ~Q(extra_fields__charge_sheet_no='') & ~Q(extra_fields__cc_st_number='') & ~Q(extra_fields__ccStNumber='')

        pending_pocso = CaseRecord.objects.filter(pocso_q).exclude(has_cs_q)

        today = timezone.now().date()
        reminders_sent = 0

        for case in pending_pocso:
            reg_date = case.created_at.date() if case.created_at else today
            days_passed = (today - reg_date).days

            if 30 <= days_passed <= 60:
                if (days_passed - 30) % 5 == 0:
                    io_name = case.assigned_officer
                    if io_name:
                        # Try to find the exact IO user object or create an alert for the station
                        io_users = User.objects.filter(Q(name__iexact=io_name) | Q(username__iexact=io_name))
                        for io_user in io_users:
                            NotificationRecord.objects.create(
                                target_user_uid=str(io_user.pk),
                                target_station_name=case.station_name,
                                title=f"POCSO Alert: CR No {case.case_number}",
                                body=f"This POCSO case has crossed {days_passed} days without a Charge Sheet No.",
                                category='reminder',
                                registration_uid=case.case_number,
                                status='pending',
                                is_read=False
                            )
                            reminders_sent += 1

        self.stdout.write(self.style.SUCCESS(f'Successfully sent {reminders_sent} reminders.'))
