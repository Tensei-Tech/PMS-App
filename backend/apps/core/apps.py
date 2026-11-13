from django.apps import AppConfig
from django.db.models.signals import post_migrate


class CoreConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.core'

    def ready(self):
        import apps.core.signals
        from apps.core.state_schema_signals import sync_states_after_migrate
        post_migrate.connect(sync_states_after_migrate, sender=self,
                             dispatch_uid='core.sync_states_after_migrate')
