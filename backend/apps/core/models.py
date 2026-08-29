import uuid
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver


class AuditLog(models.Model):
    """
    Append-only security audit log stored in database.
    Tracks critical actions: logins, biometric auth, case creation/updates, admin actions.
    """
    id = models.BigAutoField(primary_key=True)
    event = models.CharField(max_length=128, db_index=True)
    uid = models.CharField(max_length=128, default='anonymous', db_index=True)
    platform = models.CharField(max_length=32, default='unknown')
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'core_auditlog'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.event}] user={self.uid} platform={self.platform} at {self.created_at}"


class SosAlert(models.Model):
    """
    Emergency Duress & Distress SOS Alerts.
    Triggers high-priority broadcast alerts to District Admins & Control Room.
    """
    STATUS_CHOICES = (
        ('ACTIVE_DURESS', 'Active Duress'),
        ('RESOLVED', 'Resolved'),
    )

    id = models.CharField(max_length=128, primary_key=True, default=uuid.uuid4)
    officer_id = models.CharField(max_length=128, db_index=True)
    officer_name = models.CharField(max_length=255, blank=True)
    seva_number = models.CharField(max_length=64, blank=True)
    designation = models.CharField(max_length=128, blank=True)
    station_name = models.CharField(max_length=255, blank=True, db_index=True)
    district = models.CharField(max_length=128, blank=True, null=True, db_index=True)
    contact_number = models.CharField(max_length=32, blank=True)
    status = models.CharField(max_length=32, choices=STATUS_CHOICES, default='ACTIVE_DURESS', db_index=True)
    note = models.TextField(blank=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    accuracy = models.FloatField(null=True, blank=True)
    maps_url = models.TextField(blank=True)
    is_resolved = models.BooleanField(default=False)
    resolution_note = models.TextField(blank=True)
    resolved_by_uid = models.CharField(max_length=128, blank=True, null=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'core_sosalert'
        ordering = ['-created_at']

    def __str__(self):
        return f"🚨 EMERGENCY SOS [{self.status}] Officer: {self.officer_name} ({self.station_name})"


@receiver(post_save, sender=SosAlert)
def broadcast_sos_alert_notification(sender, instance, created, **kwargs):
    """
    Django Signal: Automatically broadcasts high-priority NotificationRecord to 
    District Admin & Control Room when a new emergency SOS distress alert is triggered.
    """
    if created and instance.status == 'ACTIVE_DURESS':
        from apps.users.models import NotificationRecord
        
        # Broadcast to station & district leadership
        title = f"🚨 EMERGENCY SOS: Officer {instance.officer_name}"
        body = (
            f"Officer {instance.officer_name} ({instance.designation}) triggered EMERGENCY SOS "
            f"at {instance.station_name}. Location: {instance.latitude}, {instance.longitude}. "
            f"Contact: {instance.contact_number}"
        )
        
        # Notification for District Admin / Control Room
        NotificationRecord.objects.create(
            target_role_id='district_admin',
            target_station_name=instance.station_name,
            target_district=instance.district or '',
            title=title,
            body=body,
            category='alert',
            registration_uid=instance.officer_id,
            status='pending',
        )
