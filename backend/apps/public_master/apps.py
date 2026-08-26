from django.apps import AppConfig


class PublicMasterConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.public_master'
    verbose_name = 'Public Master System (Global Architecture)'
