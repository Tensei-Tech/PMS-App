import datetime
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.db.models import Q
from apps.cases.models import CaseRecord
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = "Send automated reminders for NAFIS cases (at 15, 20, 25, 30 days and daily after 30 days) when pending/without chargesheet."

    def handle(self, *args, **kwargs):
        try:
            from apps.users.models import NotificationRecord
        except ImportError:
            try:
                from apps.core.models import NotificationRecord
            except ImportError:
                self.stdout.write(self.style.ERROR('Could not find NotificationRecord model.'))
                return

        # NAFIS pending condition:
        # Cases matching NAFIS criteria without a charge sheet
        has_cs_q = (
            Q(extra_fields__has_key='charge_sheet_number') | 
            Q(extra_fields__has_key='charge_sheet_no') | 
            Q(extra_fields__has_key='cc_st_number') | 
            Q(extra_fields__has_key='ccStNumber')
        ) & ~Q(extra_fields__charge_sheet_number='') & ~Q(extra_fields__charge_sheet_no='') & ~Q(extra_fields__cc_st_number='') & ~Q(extra_fields__ccStNumber='')

        # The NAFIS tab's own list: crime cases with fingerprint / NAFIS details
        # (service records such as licence or passport are left out)
        from apps.cases.utils import get_cases_by_status
        all_nafis = get_cases_by_status('nafis').select_related('forensics')
        from apps.cases.serializers import NafisCaseRecordSerializer
        dummy_serializer = NafisCaseRecordSerializer()

        today = timezone.now().date()
        reminders_sent = 0

        for case in all_nafis:
            # Skip if fingerprints have already been taken (status is Done)
            if dummy_serializer._has_fingerprint_taken(case):
                continue

            reg_date = case.created_at.date() if case.created_at else today
            days_passed = (today - reg_date).days

            # Send reminder if:
            # - Exactly 15 days, 20 days, 25 days, or 30 days
            # - After 30 days: daily (every day)
            should_remind = False
            urgency_text = ""
            if days_passed in (15, 20, 25, 30):
                should_remind = True
                urgency_text = f"Day {days_passed} Milestone Reminder"
            elif days_passed > 30:
                should_remind = True
                urgency_text = f"Overdue Daily Reminder ({days_passed} days elapsed)"

            if should_remind:
                io_name = case.assigned_officer
                target_uid = case.assigned_officer_uid or ''

                title = f"NAFIS Reminder ({urgency_text}): CR No {case.case_number}"
                body = (
                    f"This NAFIS case registered at {case.station_name} has passed {days_passed} days. "
                    f"Please complete fingerprint recording and update Charge Sheet status immediately."
                )

                if io_name:
                    io_users = User.objects.filter(Q(name__iexact=io_name) | Q(username__iexact=io_name))
                    if io_users.exists():
                        for io_user in io_users:
                            NotificationRecord.objects.create(
                                target_user_uid=str(io_user.pk),
                                target_station_name=case.station_name,
                                title=title,
                                body=body,
                                category='reminder',
                                registration_uid=case.case_number,
                                status='pending',
                                is_read=False
                            )
                            reminders_sent += 1
                        continue

                # Fallback to station notification or assigned_officer_uid
                NotificationRecord.objects.create(
                    target_user_uid=target_uid,
                    target_station_name=case.station_name,
                    title=title,
                    body=body,
                    category='reminder',
                    registration_uid=case.case_number,
                    status='pending',
                    is_read=False
                )
                reminders_sent += 1

        self.stdout.write(self.style.SUCCESS(f'Successfully sent {reminders_sent} NAFIS reminders.'))
