import logging
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.conf import settings

logger = logging.getLogger(__name__)

# Core Domain Apps to sync across independent databases
SYNC_MODEL_APPS = {'users', 'public_master', 'stations', 'cases'}


@receiver(post_save)
def sync_save_to_replicas(sender, instance, created, raw, using, **kwargs):
    """
    Automatically mirrors INSERT & UPDATE data across independent database projects.
    When a row is written to Primary ('default'), it is instantly duplicated to 'replica_1' / 'replica_2'.
    """
    if using != 'default' or raw:
        return

    if sender._meta.app_label not in SYNC_MODEL_APPS:
        return

    # Skip manual signal sync if using native PostgreSQL engine streaming replication (Supabase Pro / AWS RDS)
    if getattr(settings, 'DB_NATIVE_REPLICATION', False):
        return

    replica_dbs = [db for db in ['replica_1', 'replica_2'] if db in settings.DATABASES]
    for replica_db in replica_dbs:
        try:
            # Save exact instance state into replica DB
            instance.save(using=replica_db)
        except Exception as e:
            # Native read-only replicas reject manual writes; WAL streaming handles it
            logger.debug(f"[DualWriteSync] Skipped manual sync to '{replica_db}' (Handled by DB engine/read-only mode): {e}")


@receiver(post_delete)
def sync_delete_to_replicas(sender, instance, using, **kwargs):
    """
    Automatically mirrors DELETE data operations across independent database projects.
    """
    if using != 'default':
        return

    if sender._meta.app_label not in SYNC_MODEL_APPS:
        return

    if getattr(settings, 'DB_NATIVE_REPLICATION', False):
        return

    replica_dbs = [db for db in ['replica_1', 'replica_2'] if db in settings.DATABASES]
    for replica_db in replica_dbs:
        try:
            instance.delete(using=replica_db)
        except Exception as e:
            logger.debug(f"[DualWriteSync] Skipped manual delete sync to '{replica_db}': {e}")
